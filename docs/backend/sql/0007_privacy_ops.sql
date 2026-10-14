-- =============================================================================
-- 0007_privacy_ops.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P5 (feature F5-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    PDPA operations: data-subject rights tracker with deadlines (s.30–36, PDPC 2024/2026
--             rules), breach log with the 72-hour PDPC deadline (s.37(4)), daily inactivity marking,
--             one-family JSON export, family erasure (keeps anonymised money records and detached
--             consent evidence), purge_expired_records v4 (complete).
--             Review fixes (00-overview § 15): processing restriction (PDPA s.34) as real columns + a DB guard
--             (R-09); restricted families are never marked inactive or auto-erased; purge v4 keeps used
--             credits (R-10) and marks children whose allergy info was purged (R-07). Activity for the
--             12-month rule = bookings, payments, packages, consent records, link use (R-25: wording fixed in
--             the notice instead of counting updated_at, which the system itself bumps). Second review: the
--             restriction guard also covers the family row itself and inactive contacts, and ignores FK set-null
--             columns (R-36); correcting disputed data = lift → correct → restrict (R-37, 50 § 18.4).
--             Behaviour checks: seed_dev.sql § 7b.8.
--             Decision 2 (14 Oct 2026): guardian_consent_records is covered by the restriction guard (grants refused,
--             withdrawals allowed), by export_family_data (access and portability), by erase_family (detached, kept
--             3 years) and by the purge; view marketing_follow_up_list (staff card P3-19). Checks: seed_dev § 7c.
--             Round two (14 Oct 2026, brief items 2, 4, 5): export_family_data reads health ONLY through
--             get_child_health(child, includeHealth) (the plain join is removed); marketing_follow_up_list has one row
--             per granted guardian and the label 'ครอบครัวน้อง' + the first active child's nickname (+ English label).
--             erase_family keeps credits (cherrylee.studio_cancel). Checks: seed_dev § 7d.
-- Delivery (review R-12): 0007 must be applied BEFORE family records (P3) go live, because retention,
--             export, erasure and restriction for families live here. It depends on 0005, so the order is
--             0004 → 0005 → 0007 → (Stage B publish); 0006/0006b wait for G9b.
-- Depends on: 0001–0005 (0006 may or may not be applied yet)
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must contain "dsr_requests", "erase_family".
--   The next nightly run of purge-expired-records starts deleting families inactive > 12 months
--   (after a 30-day notice window). Check More → Cloud → Jobs the next morning.
-- Rules: additive only. Safe to run twice.
-- Note: the architect's column name "right" is a reserved SQL keyword, so the column is
--       requested_right (type dsr_right).
-- Not legal advice: retention periods are proposals (00-overview § 12); lawyer to review.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'dsr_right') then
    create type public.dsr_right as enum
      ('access', 'portability', 'objection', 'erasure', 'restriction', 'rectification', 'withdraw_consent');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'dsr_channel') then
    create type public.dsr_channel as enum ('in_person', 'registered_mail', 'line', 'email', 'web');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'dsr_status') then
    create type public.dsr_status as enum
      ('received', 'in_review', 'waiting_for_requester', 'extended', 'completed', 'refused');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'breach_risk') then
    create type public.breach_risk as enum ('unlikely', 'risk', 'high');
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. dsr_requests — rights requests from parents (or others), owner only
--    Deadlines (set by trigger from received_at):
--      review_due_at = +15 days            (check the request is complete)
--      due_at        = +30 days            (access, portability, objection, restriction,
--                                           rectification, withdraw_consent)
--                    = +90 days            (erasure — including backups)
--      extended_until ≤ due_at + 30 days   (one extension, requester must be told)
--      retain_until  = responded_at (or received_at) + 3 years
-- -----------------------------------------------------------------------------

create table if not exists public.dsr_requests (
  id                     uuid primary key default gen_random_uuid(),
  family_id              uuid references public.families (id) on delete set null,
  requester_name         text not null check (char_length(btrim(requester_name)) between 1 and 80),
  requester_contact      text check (requester_contact is null or char_length(requester_contact) <= 120),
  requested_right        public.dsr_right not null,
  channel                public.dsr_channel not null,
  details                text check (details is null or char_length(details) <= 1000),
  received_at            timestamptz not null default now(),
  identity_verified_at   timestamptz,
  identity_verified_by   uuid references auth.users (id) on delete set null,
  review_due_at          timestamptz not null default now(),   -- overwritten by trigger
  due_at                 timestamptz not null default now(),   -- overwritten by trigger
  extended_until         timestamptz,
  status                 public.dsr_status not null default 'received',
  outcome                text check (outcome is null or char_length(outcome) <= 1000),
  refusal_reason         text check (refusal_reason is null or char_length(refusal_reason) <= 1000),
  responded_at           timestamptz,
  handled_by             uuid references auth.users (id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  retain_until           timestamptz not null default (now() + interval '3 years'),  -- overwritten by trigger
  constraint dsr_requests_refusal_has_reason
    check (status <> 'refused' or refusal_reason is not null),
  constraint dsr_requests_closed_has_response
    check (status not in ('completed', 'refused') or responded_at is not null)
);

comment on table public.dsr_requests is
  'PDPA rights requests and how they were answered. Owner only. Request logs kept 3 years after the response (PDPC 2026 access rules require ≥ 2 years).';
comment on column public.dsr_requests.details is 'What was asked, in a sentence. Never copy health details here.';

create index if not exists dsr_requests_status_due_idx on public.dsr_requests (status, due_at);
create index if not exists dsr_requests_family_idx on public.dsr_requests (family_id);
create index if not exists dsr_requests_retain_until_idx on public.dsr_requests (retain_until);

create or replace function public.set_dsr_deadlines()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.review_due_at := new.received_at + interval '15 days';
  new.due_at := new.received_at
                + case when new.requested_right = 'erasure'::public.dsr_right
                       then interval '90 days' else interval '30 days' end;
  if new.extended_until is not null and new.extended_until > new.due_at + interval '30 days' then
    raise exception 'An extension can add at most 30 days to the due date' using errcode = '23514';
  end if;
  new.retain_until := coalesce(new.responded_at, new.received_at) + interval '3 years';
  return new;
end;
$$;

revoke execute on function public.set_dsr_deadlines() from public, anon, authenticated;

create or replace trigger dsr_requests_deadlines
  before insert or update on public.dsr_requests
  for each row execute function public.set_dsr_deadlines();
create or replace trigger dsr_requests_set_updated_at
  before update on public.dsr_requests
  for each row execute function public.set_updated_at();
create or replace trigger dsr_requests_audit
  after insert or update or delete on public.dsr_requests
  for each row execute function public.audit_row_change();


-- -----------------------------------------------------------------------------
-- 3. breach_incidents — owner only. pdpc_deadline = aware_at + 72 hours (trigger).
--    retain_until = closed_at (or aware_at) + 5 years (trigger).
--    Never store the leaked data itself here: describe categories and counts only.
-- -----------------------------------------------------------------------------

create table if not exists public.breach_incidents (
  id                    uuid primary key default gen_random_uuid(),
  title                 text not null check (char_length(btrim(title)) between 1 and 200),
  description           text check (description is null or char_length(description) <= 4000),
  aware_at              timestamptz not null,
  pdpc_deadline         timestamptz not null default now(),   -- overwritten by trigger
  risk_level            public.breach_risk not null,
  data_categories       text[] not null default '{}'::text[],
  affected_count        integer check (affected_count is null or affected_count >= 0),
  measures              text check (measures is null or char_length(measures) <= 4000),
  pdpc_notified_at      timestamptz,
  subjects_notified_at  timestamptz,
  closed_at             timestamptz,
  created_by            uuid references auth.users (id) on delete set null,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  retain_until          timestamptz not null default (now() + interval '5 years')   -- overwritten by trigger
);

comment on table public.breach_incidents is
  'Personal-data breach log (PDPA s.37(4)): notify the PDPC within 72 hours of awareness unless the risk is unlikely; notify parents without delay when the risk is high. Owner only. Kept 5 years.';

create index if not exists breach_incidents_open_idx on public.breach_incidents (aware_at desc) where closed_at is null;
create index if not exists breach_incidents_retain_until_idx on public.breach_incidents (retain_until);

create or replace function public.set_breach_deadlines()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.pdpc_deadline := new.aware_at + interval '72 hours';
  new.retain_until := coalesce(new.closed_at, new.aware_at) + interval '5 years';
  return new;
end;
$$;

revoke execute on function public.set_breach_deadlines() from public, anon, authenticated;

create or replace trigger breach_incidents_deadlines
  before insert or update on public.breach_incidents
  for each row execute function public.set_breach_deadlines();
create or replace trigger breach_incidents_set_updated_at
  before update on public.breach_incidents
  for each row execute function public.set_updated_at();
create or replace trigger breach_incidents_audit
  after insert or update or delete on public.breach_incidents
  for each row execute function public.audit_row_change();


-- -----------------------------------------------------------------------------
-- 4. RLS: dsr_requests, breach_incidents — owner select/insert/update; nobody deletes (purge does)
-- -----------------------------------------------------------------------------

alter table public.dsr_requests enable row level security;
alter table public.breach_incidents enable row level security;
revoke all on table public.dsr_requests, public.breach_incidents from anon, authenticated;
grant select, insert, update on table public.dsr_requests, public.breach_incidents to authenticated;
grant all on table public.dsr_requests, public.breach_incidents to service_role;

do $$
declare
  v_table text;
begin
  foreach v_table in array array['dsr_requests', 'breach_incidents'] loop
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_owner_select') then
      execute format('create policy %I on public.%I for select to authenticated using ((select public.is_owner()))',
                     v_table || '_owner_select', v_table);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_owner_insert') then
      execute format('create policy %I on public.%I for insert to authenticated with check ((select public.is_owner()))',
                     v_table || '_owner_insert', v_table);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_owner_update') then
      execute format('create policy %I on public.%I for update to authenticated using ((select public.is_owner())) with check ((select public.is_owner()))',
                     v_table || '_owner_update', v_table);
    end if;
  end loop;
end
$$;


-- -----------------------------------------------------------------------------
-- 4b. Processing restriction (PDPA s.34) — review R-09
--     families.processing_restricted_at / restriction_note: set ONLY through set_family_restriction()
--     (owner). While set:
--       * new bookings, new private links, new GRANTED consents, and edits to the family row itself
--         (display_name, preferred_lang, staff_note; R-36), guardians, children and contacts are refused by the
--         database (23514 'Family processing is restricted');
--       * to CORRECT disputed data the owner lifts, corrects and restricts again (50 § 18.4, R-37);
--       * withdrawals and refusals are still allowed (they reduce processing);
--       * mark_inactive_families() skips the family and the nightly purge never auto-erases it;
--       * the owner can still export (s.30) or erase (s.33) it.
-- -----------------------------------------------------------------------------

alter table public.families add column if not exists processing_restricted_at timestamptz;
alter table public.families add column if not exists restriction_note text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'families_restriction_note_len') then
    alter table public.families
      add constraint families_restriction_note_len
      check (restriction_note is null or char_length(restriction_note) <= 200);
  end if;
end
$$;

comment on column public.families.processing_restricted_at is
  'PDPA s.34 restriction in force since this time (NULL = not restricted). Owner only, via set_family_restriction().';
comment on column public.families.restriction_note is
  'Short reason, e.g. "ระงับตามคำขอ DSR 2026-11-02". Never health details.';

-- BEFORE UPDATE on families: only set_family_restriction() may change the two restriction columns.
create or replace function public.guard_family_restriction_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.processing_restricted_at, new.restriction_note)
       is distinct from (old.processing_restricted_at, old.restriction_note)
     and coalesce(current_setting('cherrylee.allow_restriction_change', true), '') <> 'on' then
    raise exception 'Use set_family_restriction() to change a restriction' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- BEFORE INSERT/UPDATE on bookings, family_links, consent_records, guardian_consent_records, guardians, children, family_contacts,
-- and BEFORE UPDATE on families (R-36): refuse new processing for a restricted family. Erasure and the purge run
-- with cherrylee.allow_purge = 'on' and are never blocked. Columns that a foreign key sets to NULL when a staff
-- user or a booking request is deleted (identity_checked_by, created_by, source_request_id) count as system columns,
-- so offboarding a staff member or purging an old request never fails on a restricted family.
create or replace function public.block_restricted_family()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_family_id   uuid;
  -- columns the system maintains; changing only these is never "new processing"
  v_system_cols text[] := array['updated_at', 'last_session_on', 'allergy_check_needed_at', 'pending_link_changes',
                                'identity_checked_by', 'created_by'];
  -- families: system-managed columns (mark_inactive_families, FK set-null) and the restriction columns, which
  -- families_guard_restriction already limits to set_family_restriction()
  v_family_system_cols text[] := array['updated_at', 'status', 'last_activity_at', 'retain_until', 'created_by',
                                       'source_request_id', 'processing_restricted_at', 'restriction_note'];
begin
  if coalesce(current_setting('cherrylee.allow_purge', true), '') = 'on' then
    return new;
  end if;
  if tg_table_name = 'families' then
    -- R-36 (D28 "profile edits"): while the restriction stays in force (before AND after this update), only
    -- system columns may change. Setting or lifting the restriction itself passes (one side is NULL).
    if (to_jsonb(old) ->> 'processing_restricted_at') is not null
       and (to_jsonb(new) ->> 'processing_restricted_at') is not null
       and (to_jsonb(new) - v_family_system_cols) is distinct from (to_jsonb(old) - v_family_system_cols) then
      raise exception 'Family processing is restricted' using errcode = '23514';
    end if;
    return new;
  end if;
  if tg_table_name in ('consent_records', 'guardian_consent_records') and (to_jsonb(new) ->> 'decision') <> 'granted' then
    return new;   -- withdrawals and refusals are always allowed (decision 2: a parent can always withdraw marketing)
  end if;
  if tg_table_name = 'bookings' and tg_op = 'UPDATE' then
    return new;   -- check-in/out, absent, cancel of existing bookings stay possible
  end if;
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - v_system_cols) = (to_jsonb(old) - v_system_cols) then
      return new;
    end if;
    -- removing a contact reduces processing: allowed when ONLY is_active goes true → false (R-36: editing an
    -- already inactive contact is still an edit and is refused)
    if tg_table_name = 'family_contacts'
       and (to_jsonb(old) ->> 'is_active') = 'true' and (to_jsonb(new) ->> 'is_active') = 'false'
       and (to_jsonb(new) - v_system_cols - 'is_active') = (to_jsonb(old) - v_system_cols - 'is_active') then
      return new;
    end if;
  end if;
  v_family_id := (to_jsonb(new) ->> 'family_id')::uuid;
  if v_family_id is null and tg_table_name = 'bookings' then
    select c.family_id into v_family_id from public.children c where c.id = (to_jsonb(new) ->> 'child_id')::uuid;
  end if;
  if v_family_id is not null and exists (
       select 1 from public.families f
        where f.id = v_family_id and f.processing_restricted_at is not null) then
    raise exception 'Family processing is restricted' using errcode = '23514';
  end if;
  return new;
end;
$$;

-- Owner (or server) sets or lifts a restriction. p_note is kept short and never contains health details.
create or replace function public.set_family_restriction(p_family_id uuid, p_restricted boolean, p_note text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform public.require_owner_or_server();
  perform set_config('cherrylee.allow_restriction_change', 'on', true);
  update public.families f
     set processing_restricted_at = case when p_restricted then coalesce(f.processing_restricted_at, now()) else null end,
         restriction_note = case when p_restricted then nullif(btrim(p_note), '') else null end
   where f.id = p_family_id;
  if not found then
    perform set_config('cherrylee.allow_restriction_change', 'off', true);
    raise exception 'Family not found' using errcode = 'P0002';
  end if;
  perform set_config('cherrylee.allow_restriction_change', 'off', true);
  if p_restricted then
    -- unused enrol links would let new data in; manage links stay so the parent can still WITHDRAW consent
    update public.family_links fl
       set revoked_at = now()
     where fl.family_id = p_family_id
       and fl.purpose = 'enrol'::public.link_purpose
       and fl.used_at is null
       and fl.revoked_at is null;
  end if;
end;
$$;

revoke execute on function public.guard_family_restriction_columns() from public, anon, authenticated;
revoke execute on function public.block_restricted_family() from public, anon, authenticated;
revoke execute on function public.set_family_restriction(uuid, boolean, text) from public, anon;
grant execute on function public.set_family_restriction(uuid, boolean, text) to authenticated, service_role;

create or replace trigger families_guard_restriction
  before update on public.families
  for each row execute function public.guard_family_restriction_columns();
create or replace trigger families_block_restricted
  before update on public.families
  for each row execute function public.block_restricted_family();
create or replace trigger bookings_block_restricted
  before insert or update on public.bookings
  for each row execute function public.block_restricted_family();
create or replace trigger family_links_block_restricted
  before insert on public.family_links
  for each row execute function public.block_restricted_family();
create or replace trigger consent_records_block_restricted
  before insert on public.consent_records
  for each row execute function public.block_restricted_family();
create or replace trigger guardian_consent_records_block_restricted
  before insert on public.guardian_consent_records
  for each row execute function public.block_restricted_family();
create or replace trigger guardians_block_restricted
  before insert or update on public.guardians
  for each row execute function public.block_restricted_family();
create or replace trigger children_block_restricted
  before insert or update on public.children
  for each row execute function public.block_restricted_family();
create or replace trigger family_contacts_block_restricted
  before insert or update on public.family_contacts
  for each row execute function public.block_restricted_family();


-- -----------------------------------------------------------------------------
-- 5. mark_inactive_families() — run daily by purge_expired_records (v4); owner may also call it.
--    last activity = latest of: family created, non-cancelled booking session date, payment,
--    package purchase, consent record, link use. (Profile edits are NOT counted: system jobs touch
--    updated_at too. The privacy notice says exactly this list, review R-25.) Inactive = no activity for
--    12 months → status 'inactive' and retain_until = now() + 30 days (notice window shown in the admin).
--    Any new activity sets the family back to 'active' and clears retain_until.
--    RESTRICTED families (processing_restricted_at set) are skipped entirely (R-09).
--    families.status / last_activity_at / retain_until are SYSTEM-MANAGED: staff screens must not edit them.
--    Returns the number of families changed.
-- -----------------------------------------------------------------------------

create or replace function public.mark_inactive_families()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_changed integer;
begin
  perform public.require_owner_or_server();

  with activity as (
    select f.id,
           greatest(
             f.created_at,
             (select max(s.session_date::timestamp at time zone 'Asia/Bangkok')
                from public.bookings b
                join public.sessions s on s.id = b.session_id
               where b.family_id = f.id
                 and b.status <> 'cancelled'::public.booking_status),
             (select max(coalesce(p.paid_at, p.created_at)) from public.payments p where p.family_id = f.id),
             (select max(pp.created_at) from public.package_purchases pp where pp.family_id = f.id),
             (select max(cr.created_at) from public.consent_records cr where cr.family_id = f.id),
             (select max(fl.used_at) from public.family_links fl where fl.family_id = f.id)
           ) as last_at
      from public.families f
     where f.processing_restricted_at is null      -- R-09: restricted families are left alone
  ),
  target as (
    select a.id,
           a.last_at,
           (a.last_at < now() - interval '12 months') as is_inactive
      from activity a
  )
  update public.families f
     set last_activity_at = t.last_at,
         status = case when t.is_inactive then 'inactive'::public.family_status
                       else 'active'::public.family_status end,
         retain_until = case when t.is_inactive then coalesce(f.retain_until, now() + interval '30 days')
                             else null end
    from target t
   where t.id = f.id
     and (   f.last_activity_at is distinct from t.last_at
          or f.status is distinct from (case when t.is_inactive then 'inactive'::public.family_status
                                             else 'active'::public.family_status end)
          or (t.is_inactive and f.retain_until is null)
          or (not t.is_inactive and f.retain_until is not null));

  get diagnostics v_changed = row_count;
  return v_changed;
end;
$$;

revoke execute on function public.mark_inactive_families() from public, anon;
grant execute on function public.mark_inactive_families() to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 6. export_family_data(p_family_id, p_include_health) — owner only (PDPA s.30 access / s.31 portability).
--    Returns ONE family's data as jsonb (never another family's). Writes an audit row 'export'.
--    family_links are exported without token_hash. Files (slips, evidence) are referenced by path.
-- -----------------------------------------------------------------------------

-- Round two (14 Oct 2026, brief item 3, decision 3): child_health is read ONLY through the audited function
-- get_child_health(child, includeHealth), and only when the owner ticks includeHealth for this export. With false the
-- file has NO health data (no read at all, no child_health key content). No second route; the plain join is removed.
-- p_include_health has no default: the caller must choose (NULL is refused, 22004).
drop function if exists public.export_family_data(uuid);
create or replace function public.export_family_data(p_family_id uuid, p_include_health boolean)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_source_request uuid;
  v_result         jsonb;
begin
  perform public.require_owner_or_server();
  if p_include_health is null then
    raise exception 'includeHealth must be true or false' using errcode = '22004';
  end if;

  select f.source_request_id into v_source_request from public.families f where f.id = p_family_id;
  if not found then
    raise exception 'Family not found' using errcode = 'P0002';
  end if;

  perform public.log_audit_event('export', 'families', p_family_id::text,
                                 jsonb_build_object('function', 'export_family_data', 'include_health', p_include_health));

  select jsonb_build_object(
    'export_format', 'cherrylee-family-export-v1',
    'exported_at', now(),
    'family', (select to_jsonb(f) from public.families f where f.id = p_family_id),
    'guardians', coalesce((select jsonb_agg(to_jsonb(g) order by g.created_at)
                             from public.guardians g where g.family_id = p_family_id), '[]'::jsonb),
    'children', coalesce((select jsonb_agg(to_jsonb(c) order by c.created_at)
                            from public.children c where c.family_id = p_family_id), '[]'::jsonb),
    'child_health', case when p_include_health then
                      coalesce((select jsonb_agg(to_jsonb(ch) order by c.created_at)
                                  from public.children c
                                 cross join lateral public.get_child_health(c.id, p_include_health) as ch
                                 where c.family_id = p_family_id), '[]'::jsonb)
                    else '[]'::jsonb end,
    'family_contacts', coalesce((select jsonb_agg(to_jsonb(fc) order by fc.created_at)
                                   from public.family_contacts fc where fc.family_id = p_family_id), '[]'::jsonb),
    'consent_records', coalesce((select jsonb_agg(to_jsonb(cr) order by cr.created_at)
                                   from public.consent_records cr where cr.family_id = p_family_id), '[]'::jsonb),
    'guardian_consent_records', coalesce((select jsonb_agg(to_jsonb(gcr) order by gcr.given_at)
                                            from public.guardian_consent_records gcr where gcr.family_id = p_family_id), '[]'::jsonb),
    'package_purchases', coalesce((select jsonb_agg(to_jsonb(pp) order by pp.purchased_on)
                                     from public.package_purchases pp where pp.family_id = p_family_id), '[]'::jsonb),
    'payments', coalesce((select jsonb_agg(to_jsonb(p) order by p.created_at)
                            from public.payments p where p.family_id = p_family_id), '[]'::jsonb),
    'bookings', coalesce((select jsonb_agg(to_jsonb(b) || jsonb_build_object('session_date', s.session_date)
                                           order by s.session_date)
                            from public.bookings b
                            join public.sessions s on s.id = b.session_id
                           where b.family_id = p_family_id), '[]'::jsonb),
    'booking_requests', coalesce((select jsonb_agg(to_jsonb(br) order by br.created_at)
                                    from public.booking_requests br
                                   where br.converted_family_id = p_family_id
                                      or br.id = v_source_request), '[]'::jsonb),
    'family_links', coalesce((select jsonb_agg(to_jsonb(fl) - 'token_hash' order by fl.created_at)
                                from public.family_links fl where fl.family_id = p_family_id), '[]'::jsonb),
    'media_appearances', coalesce((select jsonb_agg(jsonb_build_object(
                                            'child_id', mac.child_id,
                                            'asset_id', ma.id,
                                            'title', ma.title,
                                            'youtube_id', ma.youtube_id,
                                            'status', ma.status))
                                     from public.media_asset_children mac
                                     join public.media_assets ma on ma.id = mac.asset_id
                                     join public.children c on c.id = mac.child_id
                                    where c.family_id = p_family_id), '[]'::jsonb),
    'dsr_requests', coalesce((select jsonb_agg(to_jsonb(d) order by d.received_at)
                                from public.dsr_requests d where d.family_id = p_family_id), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke execute on function public.export_family_data(uuid, boolean) from public, anon;
grant execute on function public.export_family_data(uuid, boolean) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 7. erase_family(p_family_id) — owner (erasure request) or the nightly purge (retention).
--    1. cancels the family's future held/confirmed bookings (frees seats)
--    2. detaches consent_records: ids → NULL, retain_until = now() + 3 years (snapshots stay)
--    3. anonymises bookings (child/family/pickup → NULL, staff_note → NULL)
--    4. anonymises payments and package purchases (family_id → NULL, note → NULL);
--       amounts, dates, receipt numbers and slip files stay for accounting (s.24(6)) — G11
--    5. deletes the family's booking requests
--    6. deletes the family → cascades guardians, children (→ child_health, media links),
--       family_contacts, family_links
--    7. writes an audit row 'erase' with counts (no personal data)
--    Returns jsonb counts. Cannot be undone.
-- -----------------------------------------------------------------------------

create or replace function public.erase_family(p_family_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_prev_flag      text;
  v_source_request uuid;
  v_counts         jsonb := '{}'::jsonb;
  v_n              bigint;
begin
  perform public.require_owner_or_server();

  select f.source_request_id into v_source_request from public.families f where f.id = p_family_id;
  if not found then
    raise exception 'Family not found' using errcode = 'P0002';
  end if;

  v_prev_flag := current_setting('cherrylee.allow_purge', true);
  perform set_config('cherrylee.allow_purge', 'on', true);

  -- Round two: a system cancellation gives the credit back (validate_booking skips the notice rule).
  perform set_config('cherrylee.studio_cancel', 'on', true);
  update public.bookings b
     set status = 'cancelled'::public.booking_status
    from public.sessions s
   where s.id = b.session_id
     and b.family_id = p_family_id
     and b.status in ('held'::public.booking_status, 'confirmed'::public.booking_status)
     and s.session_date >= (now() at time zone 'Asia/Bangkok')::date;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('future_bookings_cancelled', v_n);
  perform set_config('cherrylee.studio_cancel', 'off', true);

  update public.consent_records
     set family_id = null,
         guardian_id = null,
         child_id = null,
         retain_until = now() + interval '3 years'
   where family_id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('consent_records_detached', v_n);

  -- Decision 2: the marketing choices of the family's guardians are detached the same way (guardian FK).
  update public.guardian_consent_records
     set family_id = null,
         guardian_id = null,
         retain_until = now() + interval '3 years'
   where family_id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('guardian_consent_records_detached', v_n);

  update public.bookings
     set family_id = null,
         child_id = null,
         picked_up_by_guardian_id = null,
         picked_up_by_contact_id = null,
         staff_note = null
   where family_id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('bookings_anonymised', v_n);

  update public.payments
     set family_id = null,
         note = null
   where family_id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('payments_anonymised', v_n);

  update public.package_purchases
     set family_id = null,
         staff_note = null
   where family_id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('package_purchases_anonymised', v_n);

  delete from public.booking_requests br
   where br.converted_family_id = p_family_id
      or br.id = v_source_request;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('booking_requests_deleted', v_n);

  delete from public.families f where f.id = p_family_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('families_deleted', v_n);

  perform public.log_audit_event('erase', 'families', p_family_id::text,
    jsonb_build_object('function', 'erase_family',
                       'by', case when auth.uid() is null then 'retention' else 'owner' end,
                       'counts', v_counts));

  perform set_config('cherrylee.allow_purge', coalesce(nullif(v_prev_flag, ''), 'off'), true);
  return v_counts;
end;
$$;

revoke execute on function public.erase_family(uuid) from public, anon;
grant execute on function public.erase_family(uuid) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 8. purge_expired_records() — v4 (complete; full re-declaration)
-- -----------------------------------------------------------------------------

create or replace function public.purge_expired_records()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_counts    jsonb := jsonb_build_object('version', 4);
  v_n         bigint;
  v_family_id uuid;
begin
  perform set_config('cherrylee.allow_purge', 'on', true);

  -- 1. Families: mark inactivity, then erase those past their retain_until.
  v_counts := v_counts || jsonb_build_object('families_marked', public.mark_inactive_families());

  v_n := 0;
  for v_family_id in
    select f.id from public.families f
     where f.retain_until is not null
       and f.retain_until < now()
       and f.processing_restricted_at is null      -- R-09: never auto-erase a restricted family
  loop
    perform public.erase_family(v_family_id);
    v_n := v_n + 1;
  end loop;
  v_counts := v_counts || jsonb_build_object('families_erased', v_n);
  perform set_config('cherrylee.allow_purge', 'on', true);

  -- 2. Short-lived data.
  delete from public.rate_limit_events where created_at < now() - interval '24 hours';
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('rate_limit_events', v_n);

  delete from public.staff_notifications where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('staff_notifications', v_n);

  delete from public.booking_requests where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('booking_requests', v_n);

  -- 3. Health: 6 months after the child's last (or next) non-cancelled session; mark the child (R-07).
  with purged as (
    delete from public.child_health h
     where h.updated_at < now() - interval '6 months'
       and not exists (
         select 1
           from public.bookings b
           join public.sessions s on s.id = b.session_id
          where b.child_id = h.child_id
            and b.status <> 'cancelled'::public.booking_status
            and s.session_date >= ((now() at time zone 'Asia/Bangkok') - interval '6 months')::date
       )
    returning h.child_id
  )
  update public.children c
     set allergy_check_needed_at = now()
    from purged
   where c.id = purged.child_id;
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('child_health', v_n);

  delete from public.family_links
   where expires_at < now() - interval '30 days'
      or revoked_at < now() - interval '30 days'
      or (purpose = 'enrol'::public.link_purpose and used_at < now() - interval '30 days');
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('family_links', v_n);

  -- 4. Attendance, then money (bookings are always younger than packages/payments).
  --    R-10: count the credits of expiring bookings first, so balances never "get credits back".
  -- Round two: a credit is used when consumes_credit and status is not 'cancelled' (absent and cancelled_late count;
  -- a cancellation with notice on time does not), the same rule as validate_booking and package_balances.
  update public.package_purchases pp
     set sessions_used_purged = least(pp.sessions_total, pp.sessions_used_purged + x.n)
    from (select b.package_purchase_id, count(*)::smallint as n
            from public.bookings b
           where b.retain_until < now()
             and b.consumes_credit
             and b.status <> 'cancelled'::public.booking_status
             and b.package_purchase_id is not null
           group by b.package_purchase_id) as x
   where pp.id = x.package_purchase_id;

  delete from public.bookings where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('bookings', v_n);

  delete from public.payments where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('payments', v_n);

  delete from public.package_purchases where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('package_purchases', v_n);

  -- 5. Detached consent evidence after 3 years.
  delete from public.consent_records where family_id is null and retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('consent_records', v_n);

  delete from public.guardian_consent_records where family_id is null and retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('guardian_consent_records', v_n);

  -- 6. Privacy operations logs.
  delete from public.dsr_requests where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('dsr_requests', v_n);

  delete from public.breach_incidents where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('breach_incidents', v_n);

  -- 7. Housekeeping.
  delete from public.storage_cleanup_queue where deleted_at < now() - interval '30 days';
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('storage_cleanup_queue', v_n);

  delete from public.audit_log where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('audit_log', v_n);

  perform set_config('cherrylee.allow_purge', 'off', true);
  return v_counts;
end;
$$;

revoke execute on function public.purge_expired_records() from public, anon, authenticated;
grant execute on function public.purge_expired_records() to service_role;

-- -----------------------------------------------------------------------------
-- 9. marketing_follow_up_list (decision 2, 14 Oct 2026; staff card P3-19; round two, brief items 4 and 5, 14 Oct 2026)
--    Staff only, read only. ONE ROW PER GUARDIAN whose CURRENT marketing choice is 'granted' (a family with two
--    consenting guardians has two rows, each with the same family label; brief item 5).
--    Columns (minimum to reach a family by hand from the studio's LINE OA chat):
--      family_id, guardian_id, guardian_name, family_label_th, family_label_en, consented_at.
--    Family label (brief item 4): 'ครอบครัวน้อง' + the NICKNAME of the family's first ACTIVE child (ordered by
--    created_at, then id); English: 'Family of ' + the same nickname. Nickname only: never a full name, age or health data.
--    The nickname is stored without the word น้อง, because the label adds it.
--    A family with no active child is not listed (no label to show); staff look at it on the family page.
--    Excluded: inactive families and restricted families (PDPA s.34: no new processing, marketing included).
--    Built on current_marketing_consents (0005), so the caller's RLS applies (staff only). No phone, e-mail or
--    LINE ID. No child data is shown to anyone outside staff. The guardian_name tells apart the two rows of one family.
-- -----------------------------------------------------------------------------

create or replace view public.marketing_follow_up_list
with (security_invoker = true)
as
select f.id                                 as family_id,
       g.id                                 as guardian_id,
       g.full_name                          as guardian_name,
       ('ครอบครัวน้อง' || first_child.nickname) as family_label_th,
       ('Family of ' || first_child.nickname)   as family_label_en,
       cm.given_at                          as consented_at
  from public.current_marketing_consents cm
  join public.guardians g on g.id = cm.guardian_id
  join public.families f on f.id = cm.family_id
  join lateral (
    select c.nickname
      from public.children c
     where c.family_id = f.id
       and c.is_active
     order by c.created_at, c.id
     limit 1
  ) as first_child on true
 where cm.decision = 'granted'
   and f.status = 'active'
   and f.processing_restricted_at is null;

revoke all on table public.marketing_follow_up_list from anon, authenticated;
grant select on table public.marketing_follow_up_list to authenticated;
grant select on table public.marketing_follow_up_list to service_role;

-- End of 0007_privacy_ops.sql
