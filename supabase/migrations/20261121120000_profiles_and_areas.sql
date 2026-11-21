-- Netsu foundation schema, row level security, and status transitions.
-- Apply in the Supabase SQL editor before anyone registers.
-- The publishable key cannot run this file.

create extension if not exists pgcrypto;

do $$ begin
  create type public.user_role as enum ('resident', 'worker', 'admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.schedule_status as enum (
    'draft', 'published', 'assigned', 'on_the_way', 'in_progress',
    'completed', 'delayed', 'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.truck_availability as enum ('available', 'assigned', 'unavailable');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.truck_maintenance as enum ('ok', 'in_maintenance');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.report_status as enum (
    'received', 'assigned', 'in_progress', 'completed', 'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.feedback_kind as enum ('feedback', 'complaint');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.feedback_status as enum ('new', 'reviewed', 'resolved');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.notification_channel as enum ('in_app', 'push', 'sms');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.delivery_status as enum ('pending', 'sent', 'failed', 'cancelled');
exception when duplicate_object then null; end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.service_areas (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kebele_code text not null unique,
  description text,
  active boolean not null default true,
  center_lat double precision,
  center_lng double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_areas_name_len check (char_length(name) between 1 and 80),
  constraint service_areas_code_len check (char_length(kebele_code) between 1 and 16)
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text not null unique,
  role public.user_role not null default 'resident',
  area_id uuid references public.service_areas (id),
  address text,
  lat double precision,
  lng double precision,
  active boolean not null default true,
  preferred_language text not null default 'en',
  notification_prefs jsonb not null default jsonb_build_object(
    'in_app', true,
    'push', true,
    'sms', false,
    'day_before', true,
    'same_day', true,
    'on_the_way', true,
    'completed', true
  ),
  fcm_tokens text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_phone_e164 check (phone ~ '^\+2519[0-9]{8}$'),
  constraint profiles_name_len check (char_length(full_name) between 1 and 120),
  constraint profiles_language check (preferred_language in ('en', 'am', 'om'))
);

create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area_id uuid not null references public.service_areas (id),
  description text,
  stops jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trucks (
  id uuid primary key default gen_random_uuid(),
  plate_number text not null unique,
  capacity numeric,
  availability public.truck_availability not null default 'available',
  maintenance public.truck_maintenance not null default 'ok',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collection_schedules (
  id uuid primary key default gen_random_uuid(),
  area_id uuid not null references public.service_areas (id),
  collection_date date not null,
  expected_start timestamptz not null,
  expected_end timestamptz,
  route_id uuid references public.routes (id),
  truck_id uuid references public.trucks (id),
  status public.schedule_status not null default 'draft',
  published_at timestamptz,
  created_by uuid references public.profiles (id),
  updated_by uuid references public.profiles (id),
  change_reason text,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.schedule_workers (
  schedule_id uuid not null references public.collection_schedules (id) on delete cascade,
  worker_id uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  primary key (schedule_id, worker_id)
);

create table if not exists public.schedule_history (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.collection_schedules (id) on delete cascade,
  changed_by uuid references public.profiles (id),
  changed_at timestamptz not null default now(),
  action text not null,
  previous jsonb,
  "new" jsonb,
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collection_tasks (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null unique references public.collection_schedules (id) on delete cascade,
  status public.schedule_status not null default 'assigned',
  started_at timestamptz,
  completed_at timestamptz,
  delay_reason text,
  completion_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id),
  area_id uuid references public.service_areas (id),
  schedule_id uuid references public.collection_schedules (id),
  type text not null,
  channel public.notification_channel not null,
  title text not null,
  message text not null,
  scheduled_send_at timestamptz not null,
  sent_at timestamptz,
  delivery_status public.delivery_status not null default 'pending',
  retry_count integer not null default 0,
  provider_message_id text,
  schedule_version integer,
  is_read boolean not null default false,
  read_at timestamptz,
  dedup_key text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.garbage_reports (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.profiles (id),
  area_id uuid not null references public.service_areas (id),
  address text,
  lat double precision,
  lng double precision,
  description text not null,
  image_path text,
  status public.report_status not null default 'received',
  assigned_worker_id uuid references public.profiles (id),
  assigned_truck_id uuid references public.trucks (id),
  admin_note text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.profiles (id),
  related_type text,
  related_id uuid,
  rating integer,
  comment text not null,
  type public.feedback_kind not null default 'feedback',
  status public.feedback_status not null default 'new',
  admin_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_rating check (rating is null or rating between 1 and 5),
  constraint feedback_related check (related_type is null or related_type in ('schedule', 'report', 'general'))
);

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists schedules_area_date_idx
  on public.collection_schedules (area_id, collection_date);
create index if not exists schedule_workers_worker_idx
  on public.schedule_workers (worker_id);
create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);
create index if not exists notifications_due_idx
  on public.notifications (delivery_status, scheduled_send_at);
create index if not exists reports_resident_created_idx
  on public.garbage_reports (resident_id, created_at desc);
create index if not exists profiles_area_idx on public.profiles (area_id);

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'service_areas', 'profiles', 'routes', 'trucks', 'collection_schedules',
    'schedule_history', 'collection_tasks', 'notifications', 'garbage_reports',
    'feedback', 'app_settings'
  ]
  loop
    execute format(
      'drop trigger if exists %I_set_updated_at on public.%I',
      tbl, tbl
    );
    execute format(
      'create trigger %I_set_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      tbl, tbl
    );
  end loop;
end $$;

create or replace function public.auth_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid()
    and active = true
$$;

revoke all on function public.auth_role() from public;
grant execute on function public.auth_role() to anon, authenticated;

-- Self-signup is always a resident. A role stored in user metadata is ignored.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  area uuid;
  language_code text;
  phone_number text;
begin
  phone_number := coalesce(new.raw_user_meta_data->>'phone', new.raw_user_meta_data->>'phone_number', '');
  if phone_number !~ '^\+2519[0-9]{8}$' then
    raise exception 'phone must be E.164 +2519XXXXXXXX';
  end if;

  begin
    area := nullif(coalesce(new.raw_user_meta_data->>'area_id', new.raw_user_meta_data->>'residential_area_id', ''), '')::uuid;
  exception when others then
    area := null;
  end;

  language_code := coalesce(new.raw_user_meta_data->>'preferred_language', 'en');
  if language_code not in ('en', 'am', 'om') then
    language_code := 'en';
  end if;

  insert into public.profiles (id, full_name, phone, role, area_id, address, preferred_language)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'Resident'),
    phone_number,
    'resident',
    area,
    nullif(trim(coalesce(new.raw_user_meta_data->>'address', '')), ''),
    language_code
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.protect_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- SQL editor and the service role have no end-user id. Signed-in residents do.
  if auth.uid() is null or public.auth_role() = 'admin' then
    return new;
  end if;
  if new.role is distinct from old.role
    or new.active is distinct from old.active
    or new.phone is distinct from old.phone
    or new.id is distinct from old.id
  then
    raise exception 'You cannot change role, active, or phone';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns
before update on public.profiles
for each row execute function public.protect_profile_columns();

create or replace function public.can_transition(
  from_status public.schedule_status,
  to_status public.schedule_status
)
returns boolean
language sql
immutable
as $$
  select case
    when from_status = 'draft' and to_status = 'published' then true
    when from_status = 'published' and to_status in ('assigned', 'delayed', 'cancelled') then true
    when from_status = 'assigned' and to_status in ('on_the_way', 'delayed', 'cancelled') then true
    when from_status = 'on_the_way' and to_status in ('in_progress', 'delayed', 'cancelled') then true
    when from_status = 'in_progress' and to_status in ('completed', 'delayed', 'cancelled') then true
    when from_status = 'delayed' and to_status in ('published', 'assigned', 'on_the_way', 'in_progress', 'cancelled') then true
    else false
  end
$$;

create or replace function public.protect_notification_columns()
returns trigger
language plpgsql
as $$
begin
  if to_jsonb(new) - 'is_read' - 'read_at' - 'updated_at'
     is distinct from
     to_jsonb(old) - 'is_read' - 'read_at' - 'updated_at'
  then
    raise exception 'Only the read state of a notification can be changed';
  end if;
  return new;
end;
$$;

drop trigger if exists notifications_protect_columns on public.notifications;
create trigger notifications_protect_columns
before update on public.notifications
for each row execute function public.protect_notification_columns();

create or replace function public.update_schedule_status(
  target_schedule uuid,
  next_status public.schedule_status,
  reason text default null
)
returns public.collection_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.collection_schedules;
  actor_role public.user_role;
  assigned boolean;
begin
  actor_role := public.auth_role();
  if actor_role is null then
    raise exception 'Not signed in';
  end if;

  select * into current_row
  from public.collection_schedules
  where id = target_schedule
  for update;

  if not found then
    raise exception 'Schedule not found';
  end if;

  select exists (
    select 1 from public.schedule_workers
    where schedule_id = target_schedule and worker_id = auth.uid()
  ) into assigned;

  if actor_role <> 'admin' and not (actor_role = 'worker' and assigned) then
    raise exception 'Not allowed to change this schedule';
  end if;

  if actor_role = 'worker' and next_status not in ('on_the_way', 'in_progress', 'completed', 'delayed') then
    raise exception 'Workers cannot set this status';
  end if;

  if not public.can_transition(current_row.status, next_status) then
    raise exception 'Status change from % to % is not allowed', current_row.status, next_status;
  end if;

  if next_status in ('delayed', 'cancelled') and nullif(trim(coalesce(reason, '')), '') is null then
    raise exception 'A reason is required';
  end if;

  insert into public.schedule_history (schedule_id, changed_by, action, previous, "new", reason)
  values (
    current_row.id,
    auth.uid(),
    'status',
    jsonb_build_object('status', current_row.status, 'version', current_row.version),
    jsonb_build_object('status', next_status, 'version', current_row.version),
    nullif(trim(coalesce(reason, '')), '')
  );

  update public.collection_schedules
  set status = next_status,
      updated_by = auth.uid(),
      change_reason = coalesce(nullif(trim(coalesce(reason, '')), ''), change_reason),
      published_at = case when next_status = 'published' then now() else published_at end
  where id = current_row.id
  returning * into current_row;

  return current_row;
end;
$$;

revoke all on function public.update_schedule_status(uuid, public.schedule_status, text) from public;
grant execute on function public.update_schedule_status(uuid, public.schedule_status, text) to authenticated;

alter table public.service_areas enable row level security;
alter table public.profiles enable row level security;
alter table public.routes enable row level security;
alter table public.trucks enable row level security;
alter table public.collection_schedules enable row level security;
alter table public.schedule_workers enable row level security;
alter table public.schedule_history enable row level security;
alter table public.collection_tasks enable row level security;
alter table public.notifications enable row level security;
alter table public.garbage_reports enable row level security;
alter table public.feedback enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists "areas readable" on public.service_areas;
create policy "areas readable"
on public.service_areas
for select
to anon, authenticated
using (active or public.auth_role() = 'admin');

drop policy if exists "areas admin write" on public.service_areas;
create policy "areas admin write"
on public.service_areas
for all
to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "profiles read own or admin" on public.profiles;
create policy "profiles read own or admin"
on public.profiles
for select
to authenticated
using (id = auth.uid() or public.auth_role() = 'admin');

drop policy if exists "profiles update own or admin" on public.profiles;
create policy "profiles update own or admin"
on public.profiles
for update
to authenticated
using (id = auth.uid() or public.auth_role() = 'admin')
with check (id = auth.uid() or public.auth_role() = 'admin');

drop policy if exists "routes admin all" on public.routes;
create policy "routes admin all"
on public.routes for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "routes worker read" on public.routes;
create policy "routes worker read"
on public.routes for select to authenticated
using (public.auth_role() = 'worker');

drop policy if exists "trucks admin all" on public.trucks;
create policy "trucks admin all"
on public.trucks for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "trucks worker read" on public.trucks;
create policy "trucks worker read"
on public.trucks for select to authenticated
using (public.auth_role() = 'worker');

drop policy if exists "schedules admin all" on public.collection_schedules;
create policy "schedules admin all"
on public.collection_schedules for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "schedules resident own area" on public.collection_schedules;
create policy "schedules resident own area"
on public.collection_schedules for select to authenticated
using (
  public.auth_role() = 'resident'
  and status <> 'draft'
  and area_id = (select p.area_id from public.profiles p where p.id = auth.uid())
);

drop policy if exists "schedules assigned worker" on public.collection_schedules;
create policy "schedules assigned worker"
on public.collection_schedules for select to authenticated
using (
  public.auth_role() = 'worker'
  and exists (
    select 1 from public.schedule_workers sw
    where sw.schedule_id = collection_schedules.id
      and sw.worker_id = auth.uid()
  )
);

drop policy if exists "schedule workers admin" on public.schedule_workers;
create policy "schedule workers admin"
on public.schedule_workers for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "schedule workers self read" on public.schedule_workers;
create policy "schedule workers self read"
on public.schedule_workers for select to authenticated
using (worker_id = auth.uid() or public.auth_role() = 'admin');

drop policy if exists "history admin" on public.schedule_history;
create policy "history admin"
on public.schedule_history for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "tasks admin" on public.collection_tasks;
create policy "tasks admin"
on public.collection_tasks for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "tasks assigned worker read" on public.collection_tasks;
create policy "tasks assigned worker read"
on public.collection_tasks for select to authenticated
using (
  exists (
    select 1 from public.schedule_workers sw
    where sw.schedule_id = collection_tasks.schedule_id
      and sw.worker_id = auth.uid()
  )
);

drop policy if exists "notifications own read" on public.notifications;
create policy "notifications own read"
on public.notifications for select to authenticated
using (recipient_id = auth.uid());

drop policy if exists "notifications own read flag" on public.notifications;
create policy "notifications own read flag"
on public.notifications for update to authenticated
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

drop policy if exists "reports resident insert" on public.garbage_reports;
create policy "reports resident insert"
on public.garbage_reports for insert to authenticated
with check (resident_id = auth.uid() and public.auth_role() = 'resident');

drop policy if exists "reports resident read own" on public.garbage_reports;
create policy "reports resident read own"
on public.garbage_reports for select to authenticated
using (resident_id = auth.uid() or public.auth_role() = 'admin');

drop policy if exists "reports admin write" on public.garbage_reports;
create policy "reports admin write"
on public.garbage_reports for update to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "reports assigned worker read" on public.garbage_reports;
create policy "reports assigned worker read"
on public.garbage_reports for select to authenticated
using (assigned_worker_id = auth.uid());

drop policy if exists "feedback resident insert" on public.feedback;
create policy "feedback resident insert"
on public.feedback for insert to authenticated
with check (resident_id = auth.uid() and public.auth_role() = 'resident');

drop policy if exists "feedback read" on public.feedback;
create policy "feedback read"
on public.feedback for select to authenticated
using (resident_id = auth.uid() or public.auth_role() = 'admin');

drop policy if exists "feedback admin update" on public.feedback;
create policy "feedback admin update"
on public.feedback for update to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

drop policy if exists "settings admin" on public.app_settings;
create policy "settings admin"
on public.app_settings for all to authenticated
using (public.auth_role() = 'admin')
with check (public.auth_role() = 'admin');

revoke all on all tables in schema public from anon, authenticated;
grant select on public.service_areas to anon, authenticated;
grant insert, update, delete on public.service_areas to authenticated;
grant select, update on public.profiles to authenticated;
grant select on public.routes, public.trucks to authenticated;
grant insert, update, delete on public.routes, public.trucks to authenticated;
grant select on public.collection_schedules, public.schedule_workers, public.schedule_history, public.collection_tasks to authenticated;
grant insert, update, delete on public.collection_schedules, public.schedule_workers to authenticated;
grant insert on public.schedule_history to authenticated;
grant select, update on public.notifications to authenticated;
grant select, insert on public.garbage_reports, public.feedback to authenticated;
grant update on public.garbage_reports, public.feedback to authenticated;
grant select on public.app_settings to authenticated;

insert into public.app_settings (key, value)
values
  ('day_before_lead_hours', '24'::jsonb),
  ('same_day_hours_before', '3'::jsonb),
  ('quiet_hours', '{"start":"21:00","end":"06:00"}'::jsonb),
  ('max_retries', '3'::jsonb),
  ('retry_backoff_minutes', '[5,15,60]'::jsonb)
on conflict (key) do nothing;

insert into public.service_areas (name, kebele_code, description, center_lat, center_lng)
values
  ('Kebele 01', '01', 'Sample service area', 7.673, 36.834),
  ('Kebele 04', '04', 'Sample service area', 7.661, 36.828),
  ('Kebele 07', '07', 'Sample service area', 7.655, 36.845)
on conflict (kebele_code) do nothing;

-- TODO(decision): anonymous read of active kebeles is enabled so residents can
-- pick an area before they have an account. Names and codes are public.

do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'report-images',
    'report-images',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  )
  on conflict (id) do update
  set file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;
exception
  when undefined_table or undefined_column then
    null;
end $$;
