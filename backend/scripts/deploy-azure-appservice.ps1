param(
  [string]$SubscriptionId = "",
  [string]$ResourceGroup = "flowsync-pro-rg",
  [string]$Location = "centralindia",
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

$azPath = Join-Path $env:ProgramFiles "Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
if (-not (Test-Path $azPath)) {
  throw "Azure CLI not found at $azPath"
}

function Invoke-Az {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  & $azPath @Args
  if ($LASTEXITCODE -ne 0) {
    throw "az command failed: az $($Args -join ' ')"
  }
}

function Get-EnvValue {
  param(
    [string]$FilePath,
    [string]$Key
  )
  if (-not (Test-Path $FilePath)) {
    return ""
  }

  $line = Get-Content $FilePath | Where-Object { $_ -match "^$Key=" } | Select-Object -First 1
  if (-not $line) {
    return ""
  }

  return ($line -replace "^$Key=", "").Trim()
}

function New-SecureSecret {
  $bytes = New-Object byte[] 48
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return [Convert]::ToBase64String($bytes)
}

function Convert-SupabaseDatabaseUrlForAzure {
  param(
    [string]$DatabaseUrl,
    [string]$PoolerHost
  )

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

function Set-AzWebAppSettings {
  param(
    [string]$ResourceGroup,
    [string]$AppName,
    [hashtable]$Settings
  )

  foreach ($entry in $Settings.GetEnumerator()) {
    if ($null -eq $entry.Value -or [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
      continue
    }

    $setting = "$($entry.Key)=$($entry.Value)" -replace "&", "^&"
    Invoke-Az webapp config appsettings set --resource-group $ResourceGroup --name $AppName --settings $setting --output none
  }
}

# Determine backend root and .env file location
$backendPath = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $backendPath ".env"

# Verify that the .env file exists; if not, warn the user but continue (some vars may be passed via parameters)
if (-not (Test-Path $envFile)) {
  Write-Warning "Backend .env file not found at $envFile. Environment variables must be provided via script parameters."
}

if ([string]::IsNullOrWhiteSpace($AppName)) {
  $suffix = (Get-Random -Minimum 10000 -Maximum 99999)
  $AppName = "flowsyncpro-api-$suffix"
}

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  $DatabaseUrl = Get-EnvValue -FilePath $envFile -Key "DATABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
  $JwtSecret = Get-EnvValue -FilePath $envFile -Key "JWT_SECRET"
}
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
  $JwtSecret = New-SecureSecret
}
if ([string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
  $FirebaseProjectId = Get-EnvValue -FilePath $envFile -Key "FIREBASE_PROJECT_ID"
}
if ([string]::IsNullOrWhiteSpace($FirebaseClientEmail)) {
  $FirebaseClientEmail = Get-EnvValue -FilePath $envFile -Key "FIREBASE_CLIENT_EMAIL"
}
if ([string]::IsNullOrWhiteSpace($FirebasePrivateKey)) {
  $FirebasePrivateKey = Get-EnvValue -FilePath $envFile -Key "FIREBASE_PRIVATE_KEY"
}

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  throw "DATABASE_URL is required. Put it in backend/.env or pass -DatabaseUrl."
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

Write-Host "Checking Azure login..."
try {
  Invoke-Az account show --output none
} catch {
  Write-Host "No active Azure session. Starting device-code login..."
  Invoke-Az login --use-device-code
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
  Write-Host "Setting subscription: $SubscriptionId"
  Invoke-Az account set --subscription $SubscriptionId
}

Write-Host "Creating resource group if it does not exist..."
Invoke-Az group create --name $ResourceGroup --location $Location --output none

Write-Host "Ensuring App Service plan exists and is Linux..."
# Check if a plan with the requested name exists
$planExists = Invoke-Az appservice plan show --name $PlanName --resource-group $ResourceGroup --query "name" --output tsv 2>$null
if ($planExists) {
  $osKind = Invoke-Az appservice plan show --name $PlanName --resource-group $ResourceGroup --query "kind" --output tsv
  if ($osKind -notlike "*linux*") {
    Write-Warning "Existing App Service plan '$PlanName' is not Linux. Creating a new Linux plan for this deployment."
    # Generate a unique Linux plan name based on the app name to avoid collisions
    $originalPlanName = $PlanName
    $PlanName = "${originalPlanName}-${AppName}" 
    Invoke-Az appservice plan create --name $PlanName --resource-group $ResourceGroup --is-linux --sku F1 --output none
  } else {
    Write-Host "App Service plan '$PlanName' already exists and is Linux."
  }
} else {
  # No plan exists, create a new Linux plan with the original name
  Invoke-Az appservice plan create --name $PlanName --resource-group $ResourceGroup --is-linux --sku F1 --output none
}

Write-Host "Deploying backend source to Azure Web App: $AppName"
Push-Location $backendPath
try {
  # Use 'az webapp up' which creates the app if missing; if app exists, it will redeploy.
  # Escape pipe for PowerShell: use backtick before |
  Invoke-Az webapp up --name $AppName --resource-group $ResourceGroup --plan $PlanName --runtime 'NODE:22-lts' --location $Location --sku F1 --output none
} catch {
  Write-Warning "az webapp up failed, attempting to create app explicitly."
  Invoke-Az webapp create --resource-group $ResourceGroup --plan $PlanName --name $AppName --runtime 'NODE:22-lts' --output none
} finally {
  Pop-Location
}

Write-Host "Configuring startup command and app settings..."
# Keep boot fast and reliable. Run prisma:deploy from the deploy machine when schema changes.
$startupCmd = "npm run start"
Invoke-Az webapp config set --resource-group $ResourceGroup --name $AppName --startup-file $startupCmd --output none

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

if (-not [string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
  $appSettings["FIREBASE_PROJECT_ID"] = $FirebaseProjectId
}
if (-not [string]::IsNullOrWhiteSpace($FirebaseClientEmail)) {
  $appSettings["FIREBASE_CLIENT_EMAIL"] = $FirebaseClientEmail
}
if (-not [string]::IsNullOrWhiteSpace($FirebasePrivateKey)) {
  $appSettings["FIREBASE_PRIVATE_KEY"] = $FirebasePrivateKey
}

Set-AzWebAppSettings -ResourceGroup $ResourceGroup -AppName $AppName -Settings $appSettings
Invoke-Az webapp restart --resource-group $ResourceGroup --name $AppName --output none

$hostName = (& $azPath webapp show --resource-group $ResourceGroup --name $AppName --query defaultHostName -o tsv)
$healthUrl = "https://$hostName/health"

Write-Host "Deployment complete."
Write-Host "Web App: https://$hostName"
Write-Host "Health:  $healthUrl"

if ([string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
  Write-Warning "FIREBASE_PROJECT_ID is missing. Google/Phone token exchange endpoints require it."
} elseif ([string]::IsNullOrWhiteSpace($FirebaseClientEmail) -or [string]::IsNullOrWhiteSpace($FirebasePrivateKey)) {
  Write-Warning "Firebase Admin service account env vars are missing. Public Google cert verification is enabled, but revoked-token checks require FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY."
}
