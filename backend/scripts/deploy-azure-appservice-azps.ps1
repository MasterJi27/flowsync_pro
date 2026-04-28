param(
  [string]$SubscriptionId = "",
  [string]$TenantId = "9c6c1f7a-81b8-4298-b959-b46b425d9f3b",
  [string]$ResourceGroup = "flowsync-pro-rg",
  [string]$Location = "Central India",
  [string]$PlanName = "flowsync-pro-plan",
  [string]$AppName = "",
  [string]$CorsOrigin = "*",
  [string]$DatabaseUrl = "",
  [string]$SupabasePoolerHost = "aws-1-ap-northeast-1.pooler.supabase.com",
  [string]$JwtSecret = "",
  [string]$FirebaseProjectId = "",
  [string]$FirebaseClientEmail = "",
  [string]$FirebasePrivateKey = ""
)

$ErrorActionPreference = "Stop"

function Ensure-ModulePath {
  $userModulePath = Join-Path $HOME "Documents\WindowsPowerShell\Modules"
  if ($env:PSModulePath -notlike "*$userModulePath*") {
    $env:PSModulePath = "$userModulePath;$env:PSModulePath"
  }
}

function Ensure-Module {
  param([string]$Name)
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name $Name -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -Confirm:$false
  }
  Import-Module $Name -Force
}

function Get-EnvValue {
  param([string]$FilePath, [string]$Key)
  if (-not (Test-Path $FilePath)) { return "" }
  $line = Get-Content $FilePath | Where-Object { $_ -match "^$Key=" } | Select-Object -First 1
  if (-not $line) { return "" }
  return ($line -replace "^$Key=", "").Trim()
}

function New-SecureSecret {
  $bytes = New-Object byte[] 48
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return [Convert]::ToBase64String($bytes)
}

function Convert-SupabaseDatabaseUrlForAzure {
  param([string]$DatabaseUrl, [string]$PoolerHost)

  if ([string]::IsNullOrWhiteSpace($PoolerHost)) {
    return $DatabaseUrl
  }

  try {
    $uri = [Uri]$DatabaseUrl
  } catch {
    return $DatabaseUrl
  }

  if ($uri.Host -notmatch "^db\.([a-z0-9]+)\.supabase\.co$") {
    return $DatabaseUrl
  }

  $projectRef = $Matches[1]
  $password = ($uri.UserInfo -split ":", 2)[1]
  if ([string]::IsNullOrWhiteSpace($password)) {
    return $DatabaseUrl
  }

  return "postgresql://postgres.${projectRef}:${password}@${PoolerHost}:6543/postgres?pgbouncer=true"
}

function New-BackendZip {
  param([string]$BackendPath)

  $stage = Join-Path $env:TEMP ("flowsync-backend-stage-" + [guid]::NewGuid())
  $zipPath = Join-Path $env:TEMP ("flowsync-backend-" + [guid]::NewGuid() + ".zip")

  New-Item -ItemType Directory -Path $stage | Out-Null

  $excludeNames = @("node_modules", "dist", ".git", ".vscode", ".dart_tool")

  Get-ChildItem -Path $BackendPath -Force | Where-Object { $excludeNames -notcontains $_.Name } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $stage -Recurse -Force
  }

  Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zipPath -Force
  Remove-Item -Path $stage -Recurse -Force

  return $zipPath
}

Ensure-ModulePath
Ensure-Module Az.Accounts
Ensure-Module Az.Resources
Ensure-Module Az.Websites

$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) {
  Connect-AzAccount -Tenant $TenantId -UseDeviceAuthentication | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
  Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
}

$current = Get-AzContext
if (-not $current -or -not $current.Subscription -or [string]::IsNullOrWhiteSpace($current.Subscription.Id)) {
  throw "No active Azure subscription in current context."
}

$backendPath = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $backendPath ".env"

if ([string]::IsNullOrWhiteSpace($AppName)) {
  $suffix = Get-Random -Minimum 10000 -Maximum 99999
  $AppName = "flowsyncpro-api-$suffix"
}

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) { $DatabaseUrl = Get-EnvValue -FilePath $envFile -Key "DATABASE_URL" }
if ([string]::IsNullOrWhiteSpace($JwtSecret)) { $JwtSecret = Get-EnvValue -FilePath $envFile -Key "JWT_SECRET" }
if ([string]::IsNullOrWhiteSpace($JwtSecret)) { $JwtSecret = New-SecureSecret }
if ([string]::IsNullOrWhiteSpace($FirebaseProjectId)) { $FirebaseProjectId = Get-EnvValue -FilePath $envFile -Key "FIREBASE_PROJECT_ID" }
if ([string]::IsNullOrWhiteSpace($FirebaseClientEmail)) { $FirebaseClientEmail = Get-EnvValue -FilePath $envFile -Key "FIREBASE_CLIENT_EMAIL" }
if ([string]::IsNullOrWhiteSpace($FirebasePrivateKey)) { $FirebasePrivateKey = Get-EnvValue -FilePath $envFile -Key "FIREBASE_PRIVATE_KEY" }

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  throw "DATABASE_URL is required. Add it to backend/.env or pass -DatabaseUrl."
}

$RuntimeDatabaseUrl = Convert-SupabaseDatabaseUrlForAzure -DatabaseUrl $DatabaseUrl -PoolerHost $SupabasePoolerHost
if ($RuntimeDatabaseUrl -ne $DatabaseUrl) {
  Write-Host "Using Supabase pooler for Azure runtime: $SupabasePoolerHost"
}

Write-Host "Applying Prisma schema to database..."
$previousDatabaseUrl = $env:DATABASE_URL
$env:DATABASE_URL = $DatabaseUrl
Push-Location $backendPath
try {
  & npm.cmd run prisma:deploy
  if ($LASTEXITCODE -ne 0) {
    throw "npm run prisma:deploy failed"
  }
} finally {
  Pop-Location
  $env:DATABASE_URL = $previousDatabaseUrl
}

$null = New-AzResourceGroup -Name $ResourceGroup -Location $Location -Force

$plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroup -Name $PlanName -ErrorAction SilentlyContinue
if (-not $plan) {
  $plan = New-AzAppServicePlan -ResourceGroupName $ResourceGroup -Name $PlanName -Location $Location -Tier Free -NumberofWorkers 1 -Linux
}

$web = Get-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName -ErrorAction SilentlyContinue
if (-not $web) {
  $web = New-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName -Location $Location -AppServicePlan $PlanName -RuntimeStack "NODE|22-lts"
}

$appSettings = @{
  NODE_ENV = "production"
  PORT = "8080"
  DATABASE_URL = $RuntimeDatabaseUrl
  JWT_SECRET = $JwtSecret
  JWT_EXPIRES_IN = "8h"
  INVITE_EXPIRES_HOURS = "168"
  CORS_ORIGIN = $CorsOrigin
  TRUST_PROXY = "true"
  RATE_LIMIT_WINDOW_MS = "60000"
  RATE_LIMIT_MAX_REQUESTS = "120"
  AUTH_RATE_LIMIT_WINDOW_MS = "900000"
  AUTH_RATE_LIMIT_MAX_REQUESTS = "25"
  OVERDUE_SWEEP_CRON = "*/1 * * * *"
  ESCALATION_STEP_MINUTES = "5"
  SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  WEBSITE_WARMUP_PATH = "/health"
  WEBSITE_WARMUP_STATUSES = "200"
}

if (-not [string]::IsNullOrWhiteSpace($FirebaseProjectId)) { $appSettings["FIREBASE_PROJECT_ID"] = $FirebaseProjectId }
if (-not [string]::IsNullOrWhiteSpace($FirebaseClientEmail)) { $appSettings["FIREBASE_CLIENT_EMAIL"] = $FirebaseClientEmail }
if (-not [string]::IsNullOrWhiteSpace($FirebasePrivateKey)) { $appSettings["FIREBASE_PRIVATE_KEY"] = $FirebasePrivateKey }

Set-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName -AppSettings $appSettings -AppCommandLine "npm run start" | Out-Null

$zipPath = New-BackendZip -BackendPath $backendPath
try {
  Publish-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName -ArchivePath $zipPath -Force
} finally {
  if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
  }
}

Restart-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName | Out-Null

$updatedWeb = Get-AzWebApp -ResourceGroupName $ResourceGroup -Name $AppName
$host = $updatedWeb.DefaultHostName
Write-Host "Deployment complete."
Write-Host "Web App: https://$host"
Write-Host "Health:  https://$host/health"

if ([string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
  Write-Warning "FIREBASE_PROJECT_ID is missing. Google/Phone token exchange endpoints require it."
} elseif ([string]::IsNullOrWhiteSpace($FirebaseClientEmail) -or [string]::IsNullOrWhiteSpace($FirebasePrivateKey)) {
  Write-Warning "Firebase Admin service account env vars are missing. Public Google cert verification is enabled, but revoked-token checks require FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY."
}
