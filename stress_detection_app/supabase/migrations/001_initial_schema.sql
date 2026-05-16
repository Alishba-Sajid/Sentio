-- Run this in Supabase SQL Editor (Dashboard → SQL → New query)

-- Profiles (created after email signup)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text,
  department text,
  semester text,
  profile_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Stress recording sessions
create table if not exists public.stress_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  self_reported_stress smallint not null check (self_reported_stress between 1 and 10),
  video_storage_path text not null,
  audio_storage_path text not null,
  duration_seconds integer,
  introduction_seconds integer,
  pressure_seconds integer,
  pressure_tier integer default 1,
  phase_metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists stress_sessions_user_id_idx on public.stress_sessions (user_id);
create index if not exists stress_sessions_created_at_idx on public.stress_sessions (created_at desc);

-- Updated_at trigger
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;
alter table public.stress_sessions enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id);

drop policy if exists "Users read own sessions" on public.stress_sessions;
create policy "Users read own sessions"
  on public.stress_sessions for select
  using (auth.uid() = user_id);

drop policy if exists "Users insert own sessions" on public.stress_sessions;
create policy "Users insert own sessions"
  on public.stress_sessions for insert
  with check (auth.uid() = user_id);

-- Storage buckets (create in Dashboard → Storage if SQL fails)
insert into storage.buckets (id, name, public)
values
  ('session-videos', 'session-videos', false),
  ('session-audio', 'session-audio', false)
on conflict (id) do nothing;

drop policy if exists "Users upload own videos" on storage.objects;
create policy "Users upload own videos"
  on storage.objects for insert
  with check (
    bucket_id = 'session-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users read own videos" on storage.objects;
create policy "Users read own videos"
  on storage.objects for select
  using (
    bucket_id = 'session-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users upload own audio" on storage.objects;
create policy "Users upload own audio"
  on storage.objects for insert
  with check (
    bucket_id = 'session-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users read own audio" on storage.objects;
create policy "Users read own audio"
  on storage.objects for select
  using (
    bucket_id = 'session-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
