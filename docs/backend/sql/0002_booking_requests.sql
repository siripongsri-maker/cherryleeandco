-- =============================================================================
-- 0002_booking_requests.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P1 (feature F1-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    booking requests from /book (PDPA s.24(3), pre-contract, D8/D9),
--             HMAC-IP rate limiting (D18), staff alert outbox (D7),
--             purge_expired_records() v1 + the two pg_cron jobs (D19).
-- Depends on: 0001_foundation.sql
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must now contain "booking_requests";
--   check More → Cloud → Jobs shows "purge-expired-records" and "cron-history-cleanup".
-- Rules: additive only. Safe to run twice (cron.schedule upserts by job name).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'booking_request_status') then
    create type public.booking_request_status as enum ('new', 'contacted', 'waitlisted', 'converted', 'closed', 'spam');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'contact_preference') then
    create type public.contact_preference as enum ('line', 'phone');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'package_code') then
    create type public.package_code as enum ('single', 'four', 'eight');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'preferred_day') then
    create type public.preferred_day as enum ('sat', 'sun', 'either');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'notification_kind') then
    create type public.notification_kind as enum ('booking_request', 'enrolment_submitted', 'consent_withdrawn');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'notify_status') then
    create type public.notify_status as enum ('pending', 'sent', 'failed', 'skipped');
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. Validation helper for booking_requests.children (used in a CHECK constraint)
--    Valid = JSON array of 1–3 objects, each exactly
--      { "age_years": <integer 6..12>, "nickname"?: <string 1..30 chars, or null> }
--    No other keys allowed.
-- -----------------------------------------------------------------------------

create or replace function public.is_valid_request_children(p jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case
    when p is null then false
    when jsonb_typeof(p) <> 'array' then false
    when jsonb_array_length(p) not between 1 and 3 then false
    else not exists (
      select 1
      from jsonb_array_elements(p) as e(item)
      where case
        when jsonb_typeof(e.item) <> 'object' then true
        when jsonb_typeof(e.item -> 'age_years') is distinct from 'number' then true
        when (e.item ->> 'age_years') !~ '^[0-9]{1,2}$' then true
        when (e.item ->> 'age_years')::integer not between 6 and 12 then true
        when (e.item -> 'nickname') is not null
             and jsonb_typeof(e.item -> 'nickname') not in ('string', 'null') then true
        when jsonb_typeof(e.item -> 'nickname') = 'string'
             and char_length(btrim(e.item ->> 'nickname')) not between 1 and 30 then true
        when exists (
          select 1 from jsonb_object_keys(e.item) as k(obj_key)
          where k.obj_key not in ('nickname', 'age_years')
        ) then true
        else false
      end
    )
  end;
$$;

revoke execute on function public.is_valid_request_children(jsonb) from public, anon;
grant execute on function public.is_valid_request_children(jsonb) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 3. booking_requests
--    Phones are stored normalised: digits only, local format, e.g. 0812345678 / 021234567.
--    session_id is added in 0003; converted_family_id in 0004.
-- -----------------------------------------------------------------------------

create table if not exists public.booking_requests (
  id                      uuid primary key default gen_random_uuid(),
  ref_code                text not null
                            constraint booking_requests_ref_code_format
                            check (ref_code ~ '^CL-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$'),
  status                  public.booking_request_status not null default 'new',
  guardian_name           text not null
                            constraint booking_requests_guardian_name_len
                            check (char_length(btrim(guardian_name)) between 1 and 80),
  contact_phone           text
                            constraint booking_requests_contact_phone_format
                            check (contact_phone is null or contact_phone ~ '^0[0-9]{8,9}$'),
  contact_line_id         text
                            constraint booking_requests_contact_line_id_format
                            check (contact_line_id is null or contact_line_id ~ '^\S{1,50}$'),
  preferred_contact       public.contact_preference not null default 'line',
  children                jsonb not null
                            constraint booking_requests_children_valid
                            check (public.is_valid_request_children(children)),
  children_count          smallint generated always as (
                            (case when jsonb_typeof(children) = 'array' then jsonb_array_length(children) else 0 end)::smallint
                          ) stored,
  package_code            public.package_code,            -- NULL = "not sure yet"
  preferred_day           public.preferred_day,
  preferred_date          date,
  message                 text
                            constraint booking_requests_message_len
                            check (message is null or char_length(message) <= 500),
  lang                    public.site_lang not null default 'th',
  privacy_notice_version  text not null
                            constraint booking_requests_privacy_notice_version_len
                            check (char_length(privacy_notice_version) between 1 and 40),
  staff_note              text
                            constraint booking_requests_staff_note_len
                            check (staff_note is null or char_length(staff_note) <= 1000),
  handled_by              uuid references auth.users (id) on delete set null,
  contacted_at            timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  retain_until            timestamptz not null default (now() + interval '6 months'),
  constraint booking_requests_ref_code_key unique (ref_code),
  -- D26 (review R-03): a LINE Official Account cannot start a chat with a LINE ID or message someone who has
  -- not messaged it first. So "line" means: the parent sends the ref code to @cherryleeandco and staff reply
  -- there; nothing else is required. Only a phone call-back needs a phone number.
  constraint booking_requests_phone_callback_has_phone
    check (preferred_contact <> 'phone' or contact_phone is not null)
);

comment on table public.booking_requests is
  'Booking request from /book. Lawful basis PDPA s.24(3) (pre-contract). Inserted only by the server (service role). Deleted 6 months after creation.';
comment on column public.booking_requests.contact_line_id is
  'Optional MATCHING HINT only (helps staff find the parent''s chat in @cherryleeandco). Staff never add parents by LINE ID (D26).';
comment on column public.booking_requests.preferred_contact is
  'line = the parent messages @cherryleeandco with the ref code and staff reply in that chat; phone = staff call contact_phone.';
comment on column public.booking_requests.children is
  'JSON array, 1–3 items: {"age_years": 6..12, "nickname"?: string ≤30}. No other child data at this stage (D9).';
comment on column public.booking_requests.message is
  'Free text ≤500. The form asks parents not to put health details here.';

create index if not exists booking_requests_status_created_idx on public.booking_requests (status, created_at desc);
create index if not exists booking_requests_created_idx on public.booking_requests (created_at desc);
create index if not exists booking_requests_retain_until_idx on public.booking_requests (retain_until);

create or replace trigger booking_requests_set_updated_at
  before update on public.booking_requests
  for each row execute function public.set_updated_at();

alter table public.booking_requests enable row level security;
revoke all on table public.booking_requests from anon, authenticated;
grant select, delete on table public.booking_requests to authenticated;
-- Staff may correct typos and track handling; they cannot change ref_code, lang,
-- privacy_notice_version, created_at or retain_until.
grant update (status, guardian_name, contact_phone, contact_line_id, preferred_contact, children,
              package_code, preferred_day, preferred_date, message, staff_note, handled_by, contacted_at)
  on table public.booking_requests to authenticated;
grant all on table public.booking_requests to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'booking_requests' and policyname = 'booking_requests_staff_select') then
    create policy "booking_requests_staff_select" on public.booking_requests
      for select to authenticated
      using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'booking_requests' and policyname = 'booking_requests_staff_update') then
    create policy "booking_requests_staff_update" on public.booking_requests
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'booking_requests' and policyname = 'booking_requests_owner_delete') then
    create policy "booking_requests_owner_delete" on public.booking_requests
      for delete to authenticated
      using ((select public.is_owner()));
  end if;
end
$$;
-- No INSERT policy: inserts come only from submitBookingRequest via the service role.


-- -----------------------------------------------------------------------------
-- 4. rate_limit_events — HMAC-SHA256(ip, IP_HASH_SECRET) hex; raw IPs never stored; kept 24 h
-- -----------------------------------------------------------------------------

create table if not exists public.rate_limit_events (
  id          bigint generated always as identity primary key,
  bucket      text not null check (char_length(bucket) between 1 and 40),
  key_hash    text not null check (key_hash ~ '^[0-9a-f]{64}$'),
  created_at  timestamptz not null default now()
);

comment on table public.rate_limit_events is
  'Rate-limit events keyed by an HMAC of the visitor IP (never the raw IP). Only check_rate_limit() touches it. Purged after 24 hours.';

create index if not exists rate_limit_events_lookup_idx on public.rate_limit_events (bucket, key_hash, created_at desc);
create index if not exists rate_limit_events_created_idx on public.rate_limit_events (created_at);

alter table public.rate_limit_events enable row level security;
revoke all on table public.rate_limit_events from anon, authenticated;
grant all on table public.rate_limit_events to service_role;
-- No policies at all: nobody but the service role / check_rate_limit() can see it.

-- Returns TRUE (allowed, and records one event) or FALSE (limit reached, nothing recorded).
-- Called only by the server: supabaseAdmin.rpc('check_rate_limit', { p_bucket: 'booking_request',
--   p_key_hash: <64 hex>, p_max_per_hour: 5, p_max_per_day: 20 }).
create or replace function public.check_rate_limit(p_bucket text, p_key_hash text, p_max_per_hour integer, p_max_per_day integer)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_last_hour integer;
  v_last_day  integer;
begin
  if p_bucket is null or char_length(p_bucket) not between 1 and 40
     or p_key_hash is null or p_key_hash !~ '^[0-9a-f]{64}$'
     or p_max_per_hour is null or p_max_per_hour < 1
     or p_max_per_day is null or p_max_per_day < 1 then
    raise exception 'check_rate_limit: invalid arguments' using errcode = '22023';
  end if;

  -- Serialise concurrent calls for the same key so two requests can't both slip through.
  perform pg_advisory_xact_lock(hashtextextended(p_bucket || ':' || p_key_hash, 0));

  select count(*) filter (where r.created_at > now() - interval '1 hour'),
         count(*)
    into v_last_hour, v_last_day
    from public.rate_limit_events r
   where r.bucket = p_bucket
     and r.key_hash = p_key_hash
     and r.created_at > now() - interval '24 hours';

  if v_last_hour >= p_max_per_hour or v_last_day >= p_max_per_day then
    return false;
  end if;

  insert into public.rate_limit_events (bucket, key_hash) values (p_bucket, p_key_hash);
  return true;
end;
$$;

revoke execute on function public.check_rate_limit(text, text, integer, integer) from public, anon, authenticated;
grant execute on function public.check_rate_limit(text, text, integer, integer) to service_role;


-- -----------------------------------------------------------------------------
-- 5. staff_notifications — outbox for PII-free LINE staff alerts (D7)
--    The alert TEXT is never stored; it is rebuilt from ref_id when (re)sent.
--    ref_id points to: booking_requests.id (booking_request) | families.id (enrolment_submitted)
--                      | consent_records.id (consent_withdrawn). No FK on purpose (polymorphic).
-- -----------------------------------------------------------------------------

create table if not exists public.staff_notifications (
  id            uuid primary key default gen_random_uuid(),
  kind          public.notification_kind not null,
  ref_id        uuid not null,
  status        public.notify_status not null default 'pending',
  attempts      smallint not null default 0 check (attempts >= 0),
  last_error    text check (last_error is null or char_length(last_error) <= 200),  -- error CODE only, never PII
  sent_at       timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  retain_until  timestamptz not null default (now() + interval '30 days')
);

comment on table public.staff_notifications is
  'Outbox for LINE staff alerts. No message text, no names. X-Line-Retry-Key = id. Kept 30 days.';

create index if not exists staff_notifications_status_idx on public.staff_notifications (status, created_at desc);
create index if not exists staff_notifications_ref_idx on public.staff_notifications (kind, ref_id);
create index if not exists staff_notifications_retain_until_idx on public.staff_notifications (retain_until);

create or replace trigger staff_notifications_set_updated_at
  before update on public.staff_notifications
  for each row execute function public.set_updated_at();

alter table public.staff_notifications enable row level security;
revoke all on table public.staff_notifications from anon, authenticated;
grant select on table public.staff_notifications to authenticated;
grant update (status, attempts, last_error, sent_at) on table public.staff_notifications to authenticated;
grant all on table public.staff_notifications to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'staff_notifications' and policyname = 'staff_notifications_staff_select') then
    create policy "staff_notifications_staff_select" on public.staff_notifications
      for select to authenticated
      using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'staff_notifications' and policyname = 'staff_notifications_staff_update') then
    create policy "staff_notifications_staff_update" on public.staff_notifications
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 6. purge_expired_records() — v1 (replaced in full by 0004 v2, 0005 v3, 0007 v4)
--    Returns counts per table, e.g. {"rate_limit_events": 12, "booking_requests": 0, ...}
-- -----------------------------------------------------------------------------

create or replace function public.purge_expired_records()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_counts jsonb := jsonb_build_object('version', 1);
  v_n      bigint;
begin
  delete from public.rate_limit_events where created_at < now() - interval '24 hours';
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('rate_limit_events', v_n);

  delete from public.staff_notifications where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('staff_notifications', v_n);

  delete from public.booking_requests where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('booking_requests', v_n);

  delete from public.audit_log where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('audit_log', v_n);

  return v_counts;
end;
$$;

revoke execute on function public.purge_expired_records() from public, anon, authenticated;
grant execute on function public.purge_expired_records() to service_role;


-- -----------------------------------------------------------------------------
-- 7. Scheduled jobs (pg_cron, times in UTC)
--    purge-expired-records  15 19 * * *  = 02:15 Asia/Bangkok
--    cron-history-cleanup   0 20 * * *   = 03:00 Asia/Bangkok
--    cron.schedule() with an existing job name updates that job (pg_cron ≥ 1.3), so re-running is safe.
-- -----------------------------------------------------------------------------

-- Supabase's documented form (https://supabase.com/docs/guides/database/extensions/pg_cron).
-- If Lovable refuses CREATE EXTENSION here, ask it to "enable pg_cron for Jobs" and re-apply this file.
-- FALLBACK (review R-19): if cron.schedule is still refused, delete the extension line and the two
-- cron.schedule statements below from THIS draft (it is not applied yet), apply the rest, and build the
-- HTTP fallback job instead (90-task-breakdown.md card P1-16, route /api/cron/purge + a Lovable Job).
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'purge-expired-records',
  '15 19 * * *',
  $cron$select public.purge_expired_records();$cron$
);

select cron.schedule(
  'cron-history-cleanup',
  '0 20 * * *',
  $cron$delete from cron.job_run_details where end_time < now() - interval '7 days';$cron$
);

-- End of 0002_booking_requests.sql
