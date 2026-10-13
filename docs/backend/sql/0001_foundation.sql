-- =============================================================================
-- 0001_foundation.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P0 (feature F0-05)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    staff roles (owner | staff), role-check helpers used by every RLS policy,
--             audit log + generic audit trigger, shared trigger helpers
--             (set_updated_at, prevent_update_delete), single-row studio settings.
-- Depends on: Lovable Cloud enabled on main (G2) and the auth bootstrap prompt (G3).
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only, check src/integrations/supabase/types.ts now
--   contains "user_roles", then do G5 (owner role template in 40-integrations.md).
-- Rules: additive only (no DROP / RENAME / type change). Safe to run twice.
-- Not legal advice. Retention periods are proposals (00-overview § 12).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'app_role') then
    create type public.app_role as enum ('owner', 'staff');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'site_lang') then
    create type public.site_lang as enum ('th', 'en');
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. user_roles — which Cloud auth users are staff, and who is the owner
-- -----------------------------------------------------------------------------

create table if not exists public.user_roles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  role        public.app_role not null,
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users (id) on delete set null,
  constraint user_roles_user_role_key unique (user_id, role)
);

comment on table public.user_roles is
  'Staff roles for Lovable Cloud auth users. owner = studio owner (one person), staff = teachers/admins. No row = no access.';

create index if not exists user_roles_user_id_idx on public.user_roles (user_id);


-- -----------------------------------------------------------------------------
-- 3. Role-check helpers (SECURITY DEFINER, empty search_path, fully qualified)
--    is_staff() is TRUE for owner OR staff. is_owner() only for owner.
-- -----------------------------------------------------------------------------

create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = _user_id and ur.role = _role
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = (select auth.uid())
      and ur.role in ('owner'::public.app_role, 'staff'::public.app_role)
  );
$$;

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role((select auth.uid()), 'owner'::public.app_role);
$$;

-- Returns 'owner', 'staff' or NULL (signed in but no role). Used by requireStaff/requireOwner
-- through context.supabase.rpc('current_app_role').
create or replace function public.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when public.has_role((select auth.uid()), 'owner'::public.app_role) then 'owner'::public.app_role
    when public.has_role((select auth.uid()), 'staff'::public.app_role) then 'staff'::public.app_role
    else null
  end;
$$;

-- Guards for SECURITY DEFINER functions that staff OR the server may call.
-- "Server" = service_role (supabaseAdmin) or no API role at all (pg_cron / SQL editor run as postgres).
-- anon and signed-in users without a role are rejected.
create or replace function public.require_staff_or_server()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(auth.role(), 'none') in ('service_role', 'none') then
    return;
  end if;
  if not public.is_staff() then
    raise exception 'Not allowed: staff only' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.require_owner_or_server()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(auth.role(), 'none') in ('service_role', 'none') then
    return;
  end if;
  if not public.is_owner() then
    raise exception 'Not allowed: owner only' using errcode = '42501';
  end if;
end;
$$;

-- has_role(uuid, role) takes ANY user id, so a signed-in user without a role could probe other users' roles.
-- It is only called inside other SECURITY DEFINER functions (which run as the owner), so authenticated
-- does not need it (review R-20). is_staff()/is_owner()/current_app_role() only look at auth.uid().
revoke execute on function public.has_role(uuid, public.app_role) from public, anon, authenticated;
revoke execute on function public.is_staff() from public, anon;
revoke execute on function public.is_owner() from public, anon;
revoke execute on function public.current_app_role() from public, anon;
revoke execute on function public.require_staff_or_server() from public, anon;
revoke execute on function public.require_owner_or_server() from public, anon;
grant execute on function public.has_role(uuid, public.app_role) to service_role;
grant execute on function public.is_staff() to authenticated, service_role;
grant execute on function public.is_owner() to authenticated, service_role;
grant execute on function public.current_app_role() to authenticated, service_role;
grant execute on function public.require_staff_or_server() to authenticated, service_role;
grant execute on function public.require_owner_or_server() to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 4. Shared trigger helpers
-- -----------------------------------------------------------------------------

-- BEFORE UPDATE: keep updated_at current.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- BEFORE UPDATE OR DELETE: makes a table append-only.
-- The ONLY bypass is inside purge_expired_records() / erase_family(), which run
--   select set_config('cherrylee.allow_purge', 'on', true);
-- (transaction-local). Never set this flag from application code.
create or replace function public.prevent_update_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('cherrylee.allow_purge', true), '') = 'on' then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;
  raise exception '% on % is not allowed: this table is append-only', tg_op, tg_table_name
    using errcode = '42501';
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.prevent_update_delete() from public, anon, authenticated;


-- -----------------------------------------------------------------------------
-- 5. audit_log — who did what to which row. NEVER field values.
-- -----------------------------------------------------------------------------

create table if not exists public.audit_log (
  id             bigint generated always as identity primary key,
  at             timestamptz not null default now(),
  actor_user_id  uuid,                      -- auth.uid(); no FK on purpose (log survives user deletion)
  actor_kind     text not null check (actor_kind in ('staff', 'system')),
  action         text not null check (char_length(action) between 1 and 40),
  table_name     text not null check (char_length(table_name) between 1 and 63),
  row_id         text,                      -- uuid (or other id) as text
  details        jsonb not null default '{}'::jsonb,  -- column NAMES only, function name, auth role
  retain_until   timestamptz not null default (now() + interval '12 months')
);

comment on table public.audit_log is
  'Audit trail (PDPC security notification). Holds actor, action, table, row id and changed column NAMES only. Never values. Kept 12 months.';

create index if not exists audit_log_at_idx on public.audit_log (at desc);
create index if not exists audit_log_table_row_idx on public.audit_log (table_name, row_id);
create index if not exists audit_log_actor_idx on public.audit_log (actor_user_id, at desc);
create index if not exists audit_log_retain_until_idx on public.audit_log (retain_until);

-- Write one audit row. Called only from other SECURITY DEFINER functions
-- (get_child_health, list_session_health_flags, export_family_data, erase_family).
create or replace function public.log_audit_event(p_action text, p_table text, p_row_id text, p_details jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  insert into public.audit_log (actor_user_id, actor_kind, action, table_name, row_id, details)
  values (
    v_uid,
    case when v_uid is null then 'system' else 'staff' end,
    p_action,
    p_table,
    p_row_id,
    coalesce(p_details, '{}'::jsonb) || jsonb_build_object('auth_role', auth.role())
  );
end;
$$;

-- AFTER INSERT OR UPDATE OR DELETE ... FOR EACH ROW.
-- Logs lower-cased TG_OP, table, row id and (for updates) the NAMES of changed columns.
-- An update that changes nothing except updated_at is not logged.
create or replace function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_row_id  text;
  v_columns jsonb := '[]'::jsonb;
begin
  if tg_op = 'DELETE' then
    v_row_id := to_jsonb(old) ->> 'id';
  elsif tg_op = 'INSERT' then
    v_row_id := to_jsonb(new) ->> 'id';
  else
    v_row_id := to_jsonb(new) ->> 'id';
    select coalesce(jsonb_agg(n.key order by n.key), '[]'::jsonb)
      into v_columns
      from jsonb_each(to_jsonb(new)) as n
      join jsonb_each(to_jsonb(old)) as o on o.key = n.key
     where n.value is distinct from o.value
       and n.key <> 'updated_at';
    if jsonb_array_length(v_columns) = 0 then
      return null;
    end if;
  end if;

  insert into public.audit_log (actor_user_id, actor_kind, action, table_name, row_id, details)
  values (
    v_uid,
    case when v_uid is null then 'system' else 'staff' end,
    lower(tg_op),
    tg_table_name,
    v_row_id,
    jsonb_build_object('columns', v_columns, 'auth_role', auth.role())
  );
  return null;
end;
$$;

revoke execute on function public.log_audit_event(text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.audit_row_change() from public, anon, authenticated;


-- -----------------------------------------------------------------------------
-- 6. user_roles: protect the last owner, triggers, RLS
-- -----------------------------------------------------------------------------

-- BEFORE UPDATE OR DELETE on user_roles: there must always be at least one owner.
create or replace function public.prevent_last_owner_removal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_removes_owner boolean := false;
begin
  -- Branch on TG_OP so NEW is never read in a DELETE trigger.
  if old.role = 'owner'::public.app_role then
    if tg_op = 'DELETE' then
      v_removes_owner := true;
    elsif new.role is distinct from 'owner'::public.app_role or new.user_id is distinct from old.user_id then
      v_removes_owner := true;
    end if;
  end if;

  if v_removes_owner and not exists (
       select 1 from public.user_roles ur
       where ur.role = 'owner'::public.app_role and ur.id <> old.id
     ) then
    raise exception 'Cannot remove the last owner. Give another user the owner role first.'
      using errcode = '42501';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke execute on function public.prevent_last_owner_removal() from public, anon, authenticated;

create or replace trigger user_roles_protect_last_owner
  before update or delete on public.user_roles
  for each row execute function public.prevent_last_owner_removal();

create or replace trigger user_roles_audit
  after insert or update or delete on public.user_roles
  for each row execute function public.audit_row_change();

alter table public.user_roles enable row level security;
revoke all on table public.user_roles from anon, authenticated;
grant select, insert, update, delete on table public.user_roles to authenticated;
grant all on table public.user_roles to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_roles' and policyname = 'user_roles_self_select') then
    create policy "user_roles_self_select" on public.user_roles
      for select to authenticated
      using (user_id = (select auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_roles' and policyname = 'user_roles_owner_select') then
    create policy "user_roles_owner_select" on public.user_roles
      for select to authenticated
      using ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_roles' and policyname = 'user_roles_owner_insert') then
    create policy "user_roles_owner_insert" on public.user_roles
      for insert to authenticated
      with check ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_roles' and policyname = 'user_roles_owner_update') then
    create policy "user_roles_owner_update" on public.user_roles
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_roles' and policyname = 'user_roles_owner_delete') then
    create policy "user_roles_owner_delete" on public.user_roles
      for delete to authenticated
      using ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 7. audit_log RLS: owner reads; nobody writes directly (triggers/functions only)
-- -----------------------------------------------------------------------------

alter table public.audit_log enable row level security;
revoke all on table public.audit_log from anon, authenticated;
grant select on table public.audit_log to authenticated;
grant all on table public.audit_log to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'audit_log' and policyname = 'audit_log_owner_select') then
    create policy "audit_log_owner_select" on public.audit_log
      for select to authenticated
      using ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 8. studio_settings — exactly one row (id = true)
-- -----------------------------------------------------------------------------

create table if not exists public.studio_settings (
  id                        boolean primary key default true check (id),
  booking_form_open         boolean not null default true,
  staff_alerts_enabled      boolean not null default true,
  default_session_capacity  integer check (default_session_capacity is null or default_session_capacity > 0),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  updated_by                uuid references auth.users (id) on delete set null
);

comment on table public.studio_settings is
  'Single-row studio settings. default_session_capacity is NULL until the owner sets it (group size is not published).';

insert into public.studio_settings (id) values (true) on conflict (id) do nothing;

create or replace trigger studio_settings_set_updated_at
  before update on public.studio_settings
  for each row execute function public.set_updated_at();

create or replace trigger studio_settings_audit
  after update on public.studio_settings
  for each row execute function public.audit_row_change();

alter table public.studio_settings enable row level security;
revoke all on table public.studio_settings from anon, authenticated;
grant select on table public.studio_settings to authenticated;
grant update (booking_form_open, staff_alerts_enabled, default_session_capacity, updated_by)
  on table public.studio_settings to authenticated;
grant all on table public.studio_settings to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'studio_settings' and policyname = 'studio_settings_staff_select') then
    create policy "studio_settings_staff_select" on public.studio_settings
      for select to authenticated
      using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'studio_settings' and policyname = 'studio_settings_owner_update') then
    create policy "studio_settings_owner_update" on public.studio_settings
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
end
$$;

-- End of 0001_foundation.sql
