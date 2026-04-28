-- FlowSync Pro auth telemetry tables.
-- Safe to run multiple times.

create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  firebase_uid text not null unique,
  email text not null,
  name text,
  phone text,
  global_role text default 'CLIENT',
  last_login_at timestamptz,
  last_active_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.login_activity (
  id uuid primary key default gen_random_uuid(),
  firebase_uid text not null,
  identifier text,
  login_method text not null,
  success boolean not null default true,
  error_message text,
  backend_user_id text,
  active_role text,
  device_info text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_sessions (
  id uuid primary key default gen_random_uuid(),
  firebase_uid text not null,
  backend_user_id text,
  active_role text,
  token_preview text,
  device_info text,
  is_active boolean not null default true,
  last_active_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_profiles_firebase_uid
  on public.user_profiles(firebase_uid);

create index if not exists idx_login_activity_firebase_uid_created_at
  on public.login_activity(firebase_uid, created_at desc);

create index if not exists idx_user_sessions_firebase_uid_is_active
  on public.user_sessions(firebase_uid, is_active);
