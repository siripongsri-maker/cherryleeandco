-- =============================================================================
-- 0005_consent_health.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P4 (feature F4-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    consent evidence (D12): versioned immutable consent_texts, append-only
--             consent_records, current_consents view; health data under explicit consent (D10):
--             child_health + DB-enforced consent + audited read/write functions; children 10+
--             rules (D11) in consent_status(); private parent links (D13); media assets (D24);
--             private bucket consent-evidence; purge_expired_records v3.
--             Review fixes (00-overview § 15): consent-change alerts by trigger for every channel (R-05),
--             allergy_check_needed_at upkeep + richer roster flags (R-07), legacy media purposes and
--             website-on-YouTube rule (R-11), one-transaction functions submit_enrolment (R-15),
--             publish_consent_text (R-15), set_media_asset_children (R-15), one-call screen functions
--             consent_matrix and media_publishability (R-18), has_active_consent closed to authenticated (R-20);
--             second review: an unticked /enrol box never withdraws an earlier decision (R-33), a 10+ child's
--             health "no" blocks a guardian grant with 23514 (R-34), the first health_allergy text only from a
--             reviewed SQL draft (R-35). Behaviour checks: seed_dev.sql § 7b.
--             Decisions of 14 Oct 2026: purpose marketing_line (GUARDIAN scope only: table guardian_consent_records,
--             text in sql/0006a); purpose media_print (same rules as media_social); the four class clips of the
--             legacy seed are gated by a session setting until G0 Q15 is recorded (decision 7). Checks: seed_dev § 7c.
--             Round two (14 Oct 2026): allergen key 'flour' (brief item 7); get_child_health takes an
--             explicit includeHealth (brief item 3); the four class clips' legacy note is the owner's certification
--             (G0 Q15 ticked). The session-setting gate stays for the builder at G4 · 0005. Checks: seed_dev § 6, § 7d.
-- Depends on: 0001–0004
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must contain "consent_records", "child_health",
--   "get_child_health", "submit_enrolment", "guardian_consent_records" (the WHOLE file is applied at G4 · 0005 in Stage B, including
--   submit_enrolment; only the P4 screens wait for Stage C). Consent WORDING is seeded separately in 0006 after legal review (G9b).
-- Rules: additive only. Safe to run twice.
-- Not legal advice: the children-10+ approach (D11) and the consent wording need a Thai PDPA lawyer.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'consent_purpose') then
    create type public.consent_purpose as enum
      ('health_allergy', 'media_parents_group', 'media_website', 'media_social', 'media_youtube',
       'marketing_line', 'media_print');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'consent_decision') then
    create type public.consent_decision as enum ('granted', 'refused', 'withdrawn');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'consent_given_by') then
    create type public.consent_given_by as enum ('guardian', 'child');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'consent_channel') then
    create type public.consent_channel as enum ('web', 'line', 'paper', 'in_person');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'consent_method') then
    create type public.consent_method as enum ('checkbox', 'signature', 'staff_recorded_verbal');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'media_level') then
    create type public.media_level as enum ('face_visible', 'face_hidden');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'link_purpose') then
    create type public.link_purpose as enum ('enrol', 'manage');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'media_asset_kind') then
    create type public.media_asset_kind as enum ('youtube', 'photo', 'other');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'media_asset_status') then
    create type public.media_asset_status as enum ('active', 'taken_down');
  end if;
end
$$;

-- For a database where consent_purpose already existed without the two new values (not a fresh apply).
-- Each statement is a no-op when the value is present. marketing_line is GUARDIAN scope (see section 5b).
alter type public.consent_purpose add value if not exists 'marketing_line';
alter type public.consent_purpose add value if not exists 'media_print';


-- -----------------------------------------------------------------------------
-- 2. child_age_years(p_birth_month, p_on) — whole years; IMMUTABLE
--    The exact day of birth is unknown, so during the birth month the child is counted as
--    having already reached the new age (errs towards asking the child's own consent).
--    src/lib/backend/age.ts ageFromBirthMonth() MUST use the same rule.
-- -----------------------------------------------------------------------------

create or replace function public.child_age_years(p_birth_month date, p_on date)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_birth_month is null or p_on is null then null
    else (extract(year from p_on)::integer - extract(year from p_birth_month)::integer)
         - case when extract(month from p_on) < extract(month from p_birth_month) then 1 else 0 end
  end;
$$;

revoke execute on function public.child_age_years(date, date) from public, anon;
grant execute on function public.child_age_years(date, date) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 3. consent_texts — versioned TH/EN wording, immutable after insert (only retired_at may be set)
--    sha256 = hex SHA-256 of UTF-8 (title || '\n' || body_md), computed by the BEFORE INSERT trigger.
--    (Not a generated column: convert_to() is STABLE, and generated columns need IMMUTABLE.)
-- -----------------------------------------------------------------------------

create table if not exists public.consent_texts (
  id                               uuid primary key default gen_random_uuid(),
  purpose                          public.consent_purpose not null,
  version                          integer not null check (version > 0),
  lang                             public.site_lang not null,
  title                            text not null check (char_length(btrim(title)) between 1 and 200),
  body_md                          text not null check (char_length(btrim(body_md)) between 1 and 10000),
  sha256                           text not null default '',  -- always overwritten by consent_texts_guard()
  is_explicit                      boolean not null default false,
  requires_child_consent_from_age  smallint check (requires_child_consent_from_age is null
                                                   or requires_child_consent_from_age between 7 and 19),
  effective_from                   timestamptz not null default now(),
  retired_at                       timestamptz,
  created_by                       uuid,          -- staff user id; no FK (row is immutable)
  created_at                       timestamptz not null default now(),
  constraint consent_texts_purpose_version_lang_key unique (purpose, version, lang),
  constraint consent_texts_health_is_explicit check (purpose <> 'health_allergy' or is_explicit)
);

comment on table public.consent_texts is
  'Exact consent wording shown to parents (TH and EN, same version number). Never edited: publish a new version and retire the old one.';

create index if not exists consent_texts_purpose_idx on public.consent_texts (purpose, lang, version desc);

create or replace function public.consent_texts_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.sha256 := encode(sha256(convert_to(new.title || E'\n' || new.body_md, 'UTF8')), 'hex');
    new.created_at := now();
    return new;
  elsif tg_op = 'UPDATE' then
    if (new.id, new.purpose, new.version, new.lang, new.title, new.body_md, new.sha256, new.is_explicit,
        new.requires_child_consent_from_age, new.effective_from, new.created_by, new.created_at)
       is distinct from
       (old.id, old.purpose, old.version, old.lang, old.title, old.body_md, old.sha256, old.is_explicit,
        old.requires_child_consent_from_age, old.effective_from, old.created_by, old.created_at) then
      raise exception 'Consent texts cannot be edited. Publish a new version instead.' using errcode = '42501';
    end if;
    if old.retired_at is not null and new.retired_at is distinct from old.retired_at then
      raise exception 'This consent text is already retired.' using errcode = '42501';
    end if;
    return new;
  else
    if coalesce(current_setting('cherrylee.allow_purge', true), '') = 'on' then
      return old;
    end if;
    raise exception 'Consent texts cannot be deleted.' using errcode = '42501';
  end if;
end;
$$;

revoke execute on function public.consent_texts_guard() from public, anon, authenticated;

create or replace trigger consent_texts_guard
  before insert or update or delete on public.consent_texts
  for each row execute function public.consent_texts_guard();

alter table public.consent_texts enable row level security;
revoke all on table public.consent_texts from anon, authenticated;
grant select on table public.consent_texts to authenticated;
grant insert (purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age,
              effective_from, created_by)
  on table public.consent_texts to authenticated;
grant update (retired_at) on table public.consent_texts to authenticated;
grant all on table public.consent_texts to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'consent_texts' and policyname = 'consent_texts_staff_select') then
    create policy "consent_texts_staff_select" on public.consent_texts
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'consent_texts' and policyname = 'consent_texts_owner_insert') then
    create policy "consent_texts_owner_insert" on public.consent_texts
      for insert to authenticated with check ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'consent_texts' and policyname = 'consent_texts_owner_update') then
    create policy "consent_texts_owner_update" on public.consent_texts
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 4. family_links — private parent links (D13). Only the sha256 hex of the 32-byte token is stored.
--    enrol: single use, 14 days. manage: 90 days (R-21). Purged 30 days after expiry/revocation/use.
-- -----------------------------------------------------------------------------

create table if not exists public.family_links (
  id          uuid primary key default gen_random_uuid(),
  family_id   uuid not null references public.families (id) on delete cascade,
  purpose     public.link_purpose not null,
  token_hash  text not null check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at  timestamptz not null,
  used_at     timestamptz,
  revoked_at  timestamptz,
  created_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint family_links_token_hash_key unique (token_hash),
  constraint family_links_expiry_after_creation check (expires_at > created_at)
);

comment on table public.family_links is
  'Private links staff paste into the family''s LINE chat. token_hash = sha256 hex of the raw token; the raw token is never stored.';

create index if not exists family_links_family_idx on public.family_links (family_id, purpose);

create or replace trigger family_links_set_updated_at
  before update on public.family_links for each row execute function public.set_updated_at();
create or replace trigger family_links_audit
  after insert or update or delete on public.family_links for each row execute function public.audit_row_change();

alter table public.family_links enable row level security;
revoke all on table public.family_links from anon, authenticated;
grant select, insert on table public.family_links to authenticated;
grant update (revoked_at) on table public.family_links to authenticated;
grant all on table public.family_links to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'family_links' and policyname = 'family_links_staff_select') then
    create policy "family_links_staff_select" on public.family_links
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'family_links' and policyname = 'family_links_staff_insert') then
    create policy "family_links_staff_insert" on public.family_links
      for insert to authenticated
      with check ((select public.is_staff()) and created_by = (select auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'family_links' and policyname = 'family_links_staff_update') then
    create policy "family_links_staff_update" on public.family_links
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 5. consent_records — APPEND-ONLY consent evidence (PDPA s.19, s.20, s.26)
--    * family_id/guardian_id/child_id are NULL only after the family is erased; then
--      retain_until = erase time + 3 years (PDPA s.78 claims period) — set by erase_family (0007).
--    * guardian_name_snapshot / child_nickname_snapshot are copied at insert (who consented, as
--      written at that time). Kept with the detached record for legal defence — LAWYER TO CONFIRM.
--    * recorded_by and family_link_id have no FK on purpose: an FK action would UPDATE this
--      append-only table.
-- -----------------------------------------------------------------------------

create table if not exists public.consent_records (
  id                           uuid primary key default gen_random_uuid(),
  family_id                    uuid references public.families (id),
  guardian_id                  uuid references public.guardians (id),
  child_id                     uuid references public.children (id),
  purpose                      public.consent_purpose not null,
  consent_text_id              uuid not null references public.consent_texts (id),
  decision                     public.consent_decision not null,
  given_by                     public.consent_given_by not null,
  child_age_years_at_decision  smallint check (child_age_years_at_decision is null
                                               or child_age_years_at_decision between 0 and 25),
  media_level                  public.media_level,
  channel                      public.consent_channel not null,
  method                       public.consent_method not null,
  recorded_by                  uuid,
  evidence_path                text check (evidence_path is null
                                           or evidence_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|pdf)$'),
  family_link_id               uuid,
  guardian_name_snapshot       text,
  child_nickname_snapshot      text,
  created_at                   timestamptz not null default clock_timestamp(),
  retain_until                 timestamptz,
  constraint consent_records_attached_or_expiring
    check (family_id is not null or retain_until is not null),
  constraint consent_records_health_no_media_level
    check (purpose <> 'health_allergy' or media_level is null),
  constraint consent_records_media_grant_has_level
    check (purpose = 'health_allergy' or given_by = 'child' or decision <> 'granted' or media_level is not null),
  constraint consent_records_web_is_checkbox
    check (channel <> 'web' or method = 'checkbox'),
  constraint consent_records_child_recorded_by_staff
    check (given_by <> 'child' or (recorded_by is not null and channel in ('in_person', 'paper'))),
  -- Decision 2 (14 Oct 2026): the marketing choice is about the parent, never the child. It lives only in
  -- guardian_consent_records (section 5b), so a child-level row can never carry it.
  constraint consent_records_no_marketing
    check (purpose <> 'marketing_line')
);

comment on table public.consent_records is
  'Append-only consent evidence. Current state = latest row per child × purpose × given_by (view current_consents). UPDATE/DELETE blocked except inside purge/erase.';
comment on column public.consent_records.created_at is 'Set by trigger to clock_timestamp() so rows written in one transaction stay ordered.';

create index if not exists consent_records_child_purpose_idx
  on public.consent_records (child_id, purpose, given_by, created_at desc);
create index if not exists consent_records_family_idx on public.consent_records (family_id);
create index if not exists consent_records_retain_until_idx on public.consent_records (retain_until) where retain_until is not null;

-- BEFORE INSERT: integrity + snapshots + age at decision.
create or replace function public.validate_consent_record()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_text_purpose   public.consent_purpose;
  v_text_retired   timestamptz;
  v_text_effective timestamptz;
  v_text_explicit  boolean;
  v_child_family   uuid;
  v_child_nickname text;
  v_child_birth    date;
  v_guardian_name  text;
  v_guardian_resp  boolean;
begin
  new.created_at := clock_timestamp();
  new.retain_until := null;

  select ct.purpose, ct.retired_at, ct.effective_from, ct.is_explicit
    into v_text_purpose, v_text_retired, v_text_effective, v_text_explicit
    from public.consent_texts ct
   where ct.id = new.consent_text_id;
  if v_text_purpose is null then
    raise exception 'Consent text not found' using errcode = '23503';
  end if;
  if v_text_purpose <> new.purpose then
    raise exception 'Consent text purpose does not match the record purpose' using errcode = '23514';
  end if;
  if new.decision = 'granted' then
    if v_text_retired is not null and v_text_retired <= now() then
      raise exception 'A retired consent text cannot be used for a new grant' using errcode = '23514';
    end if;
    if v_text_effective > now() then
      raise exception 'This consent text is not in effect yet' using errcode = '23514';
    end if;
    if new.purpose = 'health_allergy' and not v_text_explicit then
      raise exception 'Health consent needs an explicit-consent text' using errcode = '23514';
    end if;
  end if;

  if new.family_id is null or new.child_id is null then
    raise exception 'family_id and child_id are required' using errcode = '23502';
  end if;

  select c.family_id, c.nickname, c.birth_month
    into v_child_family, v_child_nickname, v_child_birth
    from public.children c
   where c.id = new.child_id;
  if v_child_family is null or v_child_family <> new.family_id then
    raise exception 'Child does not belong to this family' using errcode = '23514';
  end if;

  if new.given_by = 'guardian' then
    if new.guardian_id is null then
      raise exception 'guardian_id is required when given_by = guardian' using errcode = '23502';
    end if;
    select g.full_name, g.has_parental_responsibility
      into v_guardian_name, v_guardian_resp
      from public.guardians g
     where g.id = new.guardian_id and g.family_id = new.family_id;
    if v_guardian_name is null then
      raise exception 'Guardian does not belong to this family' using errcode = '23514';
    end if;
    -- PDPA s.20: a grant must come from someone who has stated parental responsibility.
    if new.decision = 'granted' and not coalesce(v_guardian_resp, false) then
      raise exception 'Record the parental-responsibility statement for this guardian first' using errcode = '23514';
    end if;
  else
    new.guardian_id := null;
  end if;

  new.guardian_name_snapshot := v_guardian_name;
  new.child_nickname_snapshot := v_child_nickname;
  if new.child_age_years_at_decision is null then
    new.child_age_years_at_decision :=
      public.child_age_years(v_child_birth, (now() at time zone 'Asia/Bangkok')::date);
  end if;
  return new;
end;
$$;

-- AFTER INSERT: a health refusal/withdrawal (by guardian OR child) deletes the health row at once (D10/D11).
-- Review R-07: when a row was actually deleted, mark the child so the roster says "allergy info removed on
-- <date>: check with the family before cooking" (children.allergy_check_needed_at is not health data).
-- ⚖️ G9b lawyer question kept open: should a 10+ child's own "no" delete the guardian-provided row?
create or replace function public.apply_consent_withdrawal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.purpose = 'health_allergy'
     and new.decision in ('refused'::public.consent_decision, 'withdrawn'::public.consent_decision)
     and new.child_id is not null then
    delete from public.child_health h where h.child_id = new.child_id;
    if found then
      update public.children c
         set allergy_check_needed_at = now()
       where c.id = new.child_id;
    end if;
  end if;
  return null;
end;
$$;

-- AFTER INSERT: queue ONE PII-free staff alert whenever a decision moves AWAY from "granted" (review R-05).
-- Covers every channel (web /enrol, web /my, staff paper/in person/LINE) and both givers:
--   * guardian or child: the same giver's previous decision for this child × purpose was 'granted'; or
--   * child: the guardian's current decision is 'granted' (a 10+ child's "no" blocks publication / removes
--     health info even if the child never said yes before).
-- The server then pushes the queued row to LINE (deliverConsentAlert in staff-notify.server.ts); a row that
-- stays 'pending' is shown in the admin with a resend button, so nothing is lost if LINE is down.
create or replace function public.queue_consent_change_alert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prev           public.consent_decision;
  v_guardian_now   public.consent_decision;
begin
  if new.decision = 'granted'::public.consent_decision or new.child_id is null then
    return null;
  end if;

  select cr.decision into v_prev
    from public.consent_records cr
   where cr.child_id = new.child_id
     and cr.purpose = new.purpose
     and cr.given_by = new.given_by
     and cr.id <> new.id
   order by cr.created_at desc, cr.id desc
   limit 1;

  if new.given_by = 'child'::public.consent_given_by then
    select cr.decision into v_guardian_now
      from public.consent_records cr
     where cr.child_id = new.child_id
       and cr.purpose = new.purpose
       and cr.given_by = 'guardian'::public.consent_given_by
     order by cr.created_at desc, cr.id desc
     limit 1;
  end if;

  if v_prev is not distinct from 'granted'::public.consent_decision
     or v_guardian_now is not distinct from 'granted'::public.consent_decision then
    insert into public.staff_notifications (kind, ref_id, status)
    values ('consent_withdrawn'::public.notification_kind, new.id, 'pending'::public.notify_status);
  end if;
  return null;
end;
$$;

revoke execute on function public.validate_consent_record() from public, anon, authenticated;
revoke execute on function public.apply_consent_withdrawal() from public, anon, authenticated;
revoke execute on function public.queue_consent_change_alert() from public, anon, authenticated;

create or replace trigger consent_records_validate
  before insert on public.consent_records
  for each row execute function public.validate_consent_record();
create or replace trigger consent_records_append_only
  before update or delete on public.consent_records
  for each row execute function public.prevent_update_delete();
create or replace trigger consent_records_queue_storage_cleanup
  after delete on public.consent_records
  for each row execute function public.queue_storage_cleanup();
create or replace trigger consent_records_audit
  after insert or update or delete on public.consent_records
  for each row execute function public.audit_row_change();
create or replace trigger consent_records_queue_alert
  after insert on public.consent_records
  for each row execute function public.queue_consent_change_alert();
-- consent_records_apply_withdrawal is created after child_health exists (section 7).

alter table public.consent_records enable row level security;
revoke all on table public.consent_records from anon, authenticated;
grant select on table public.consent_records to authenticated;
grant insert (family_id, guardian_id, child_id, purpose, consent_text_id, decision, given_by,
              child_age_years_at_decision, media_level, channel, method, recorded_by, evidence_path,
              family_link_id)
  on table public.consent_records to authenticated;
grant all on table public.consent_records to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'consent_records' and policyname = 'consent_records_staff_select') then
    create policy "consent_records_staff_select" on public.consent_records
      for select to authenticated using ((select public.is_staff()));
  end if;
  -- Staff record paper / in-person / child consents; recorded_by must be themselves.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'consent_records' and policyname = 'consent_records_staff_insert') then
    create policy "consent_records_staff_insert" on public.consent_records
      for insert to authenticated
      with check ((select public.is_staff()) and recorded_by = (select auth.uid()));
  end if;
end
$$;
-- No UPDATE/DELETE policies or grants: append-only.


-- -----------------------------------------------------------------------------
-- 5b. guardian_consent_records — GUARDIAN-scope marketing choice (decision 2, 14 Oct 2026)
--     Purpose marketing_line: the parent's own opt-in to follow-up messages from the studio about classes,
--     by LINE, one family at a time (staff contact by hand from the LINE OA chat; no automated bulk sends).
--     * About the ADULT, never the child: there is no child column here, and no function, view or policy joins
--       children to this table. consent_records refuses purpose marketing_line (check consent_records_no_marketing).
--     * "Not now" = no row = not granted. Never pre-ticked. Giving = a 'granted' row; withdrawing = a NEW row with
--       decision 'withdrawn' (rows are never edited or deleted).
--     * Append-only like consent_records: UPDATE/DELETE raise 42501, except inside purge_expired_records() and
--       erase_family() (cherrylee.allow_purge). Erasure detaches the rows (0007 erase_family).
--     * No PDPA s.20 parental-responsibility rule here: the parent is the person who receives the messages.
--     * A restricted family (0007) can withdraw, but cannot record a new grant (0007 block_restricted_family).
-- -----------------------------------------------------------------------------

create table if not exists public.guardian_consent_records (
  id                      uuid primary key default gen_random_uuid(),
  family_id               uuid references public.families (id),     -- no action: NULL only after erase
  guardian_id             uuid references public.guardians (id),    -- no action (an FK action would UPDATE an append-only table)
  purpose                 public.consent_purpose not null default 'marketing_line',
  consent_text_id         uuid not null references public.consent_texts (id),
  decision                public.consent_decision not null,
  given_at                timestamptz not null default clock_timestamp(),  -- set by trigger; cannot be back-dated
  channel                 public.consent_channel not null,
  method                  public.consent_method not null,
  recorded_by             uuid,                                     -- staff user id (no FK); NULL for the parent's own web choice
  evidence_path           text check (evidence_path is null
                                      or evidence_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|pdf)$'),
  family_link_id          uuid,                                     -- the private link used (web); no FK
  guardian_name_snapshot  text,                                     -- set by trigger
  retain_until            timestamptz,                              -- NULL while the family exists; erase sets now() + 3 years
  constraint guardian_consent_records_marketing_only
    check (purpose = 'marketing_line'),
  constraint guardian_consent_records_grant_or_withdraw
    check (decision in ('granted', 'withdrawn')),
  constraint guardian_consent_records_web_is_checkbox
    check (channel <> 'web' or method = 'checkbox'),
  constraint guardian_consent_records_staff_recorded
    check (channel = 'web' or recorded_by is not null),
  constraint guardian_consent_records_attached_or_expiring
    check ((family_id is not null and guardian_id is not null) or retain_until is not null)
);

comment on table public.guardian_consent_records is
  'Append-only guardian-scope marketing choice (marketing_line). Current state = latest row per guardian (view current_marketing_consents). Holds no child data. UPDATE/DELETE blocked except inside purge/erase.';
comment on column public.guardian_consent_records.given_at is
  'Set by trigger to clock_timestamp() when the row is written. The decision cannot be back-dated. For a paper or LINE choice, the signed form or the message is the evidence (evidence_path).';

create index if not exists guardian_consent_records_guardian_idx
  on public.guardian_consent_records (guardian_id, given_at desc);
create index if not exists guardian_consent_records_family_idx on public.guardian_consent_records (family_id);
create index if not exists guardian_consent_records_retain_until_idx
  on public.guardian_consent_records (retain_until) where retain_until is not null;

-- BEFORE INSERT: text matches the purpose, a grant needs a text in effect, guardian belongs to the family.
create or replace function public.validate_guardian_consent_record()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_text_purpose    public.consent_purpose;
  v_text_retired    timestamptz;
  v_text_effective  timestamptz;
  v_guardian_family uuid;
  v_guardian_name   text;
begin
  new.given_at := clock_timestamp();
  new.retain_until := null;

  select ct.purpose, ct.retired_at, ct.effective_from
    into v_text_purpose, v_text_retired, v_text_effective
    from public.consent_texts ct
   where ct.id = new.consent_text_id;
  if v_text_purpose is null then
    raise exception 'Consent text not found' using errcode = '23503';
  end if;
  if v_text_purpose <> new.purpose then
    raise exception 'Consent text purpose does not match the record purpose' using errcode = '23514';
  end if;
  if new.decision = 'granted' then
    if v_text_retired is not null and v_text_retired <= now() then
      raise exception 'A retired consent text cannot be used for a new grant' using errcode = '23514';
    end if;
    if v_text_effective > now() then
      raise exception 'This consent text is not in effect yet' using errcode = '23514';
    end if;
  end if;

  if new.family_id is null or new.guardian_id is null then
    raise exception 'family_id and guardian_id are required' using errcode = '23502';
  end if;
  select g.family_id, g.full_name
    into v_guardian_family, v_guardian_name
    from public.guardians g
   where g.id = new.guardian_id;
  if v_guardian_family is null or v_guardian_family <> new.family_id then
    raise exception 'Guardian does not belong to this family' using errcode = '23514';
  end if;

  new.guardian_name_snapshot := v_guardian_name;
  return new;
end;
$$;

revoke execute on function public.validate_guardian_consent_record() from public, anon, authenticated;

create or replace trigger guardian_consent_records_validate
  before insert on public.guardian_consent_records
  for each row execute function public.validate_guardian_consent_record();
create or replace trigger guardian_consent_records_append_only
  before update or delete on public.guardian_consent_records
  for each row execute function public.prevent_update_delete();
create or replace trigger guardian_consent_records_queue_storage_cleanup
  after delete on public.guardian_consent_records
  for each row execute function public.queue_storage_cleanup();
create or replace trigger guardian_consent_records_audit
  after insert or update or delete on public.guardian_consent_records
  for each row execute function public.audit_row_change();
-- guardian_consent_records_block_restricted is created in 0007 (with the restriction guard).

alter table public.guardian_consent_records enable row level security;
revoke all on table public.guardian_consent_records from anon, authenticated;
grant select on table public.guardian_consent_records to authenticated;
grant insert (family_id, guardian_id, purpose, consent_text_id, decision, channel, method, recorded_by,
              evidence_path, family_link_id)
  on table public.guardian_consent_records to authenticated;
grant all on table public.guardian_consent_records to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'guardian_consent_records' and policyname = 'guardian_consent_records_staff_select') then
    create policy "guardian_consent_records_staff_select" on public.guardian_consent_records
      for select to authenticated using ((select public.is_staff()));
  end if;
  -- Staff record a parent's choice made on paper, by LINE or in person; recorded_by must be themselves.
  -- Web choices (the parent on /my) come from the server through a private link, never from a staff screen.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'guardian_consent_records' and policyname = 'guardian_consent_records_staff_insert') then
    create policy "guardian_consent_records_staff_insert" on public.guardian_consent_records
      for insert to authenticated
      with check ((select public.is_staff()) and channel <> 'web' and recorded_by = (select auth.uid()));
  end if;
end
$$;
-- No UPDATE/DELETE policies or grants: append-only.

-- Latest marketing choice per guardian (staff only through RLS). A guardian with no row is not granted.
create or replace view public.current_marketing_consents
with (security_invoker = true)
as
select distinct on (gcr.guardian_id)
  gcr.id          as guardian_consent_record_id,
  gcr.family_id,
  gcr.guardian_id,
  gcr.purpose,
  gcr.decision,
  gcr.given_at,
  gcr.channel,
  gcr.consent_text_id
from public.guardian_consent_records gcr
where gcr.guardian_id is not null
order by gcr.guardian_id, gcr.given_at desc, gcr.id desc;

revoke all on table public.current_marketing_consents from anon, authenticated;
grant select on table public.current_marketing_consents to authenticated;
grant select on table public.current_marketing_consents to service_role;


-- -----------------------------------------------------------------------------
-- 6. current_consents — latest decision per child × purpose × given_by
-- -----------------------------------------------------------------------------

create or replace view public.current_consents
with (security_invoker = true)
as
select distinct on (cr.child_id, cr.purpose, cr.given_by)
  cr.id               as consent_record_id,
  cr.family_id,
  cr.child_id,
  cr.purpose,
  cr.given_by,
  cr.decision,
  cr.media_level,
  cr.consent_text_id,
  cr.channel,
  cr.method,
  cr.created_at
from public.consent_records cr
where cr.child_id is not null
order by cr.child_id, cr.purpose, cr.given_by, cr.created_at desc, cr.id desc;

revoke all on table public.current_consents from anon, authenticated;
grant select on table public.current_consents to authenticated;
grant select on table public.current_consents to service_role;


-- -----------------------------------------------------------------------------
-- 7. child_health — allergy / foods to avoid / care notes (PDPA s.26, explicit consent only)
--    No table privileges for staff at all: read via get_child_health(child, includeHealth) / list_session_health_flags()
--    (both write an audit row), write via upsert_child_health().
-- -----------------------------------------------------------------------------

create table if not exists public.child_health (
  id               uuid primary key default gen_random_uuid(),
  child_id         uuid not null references public.children (id) on delete cascade,
  -- Allergen keys (round two, owner, 14 Oct 2026). Labels are in src/content (Thai and English):
  --   peanut (ถั่วลิสง) and tree_nut (ถั่วเปลือกแข็ง) are one group "ถั่ว" with two choices (both keys kept);
  --   wheat = "แป้งสาลี / ข้าวสาลี" (kept as its own key);
  --   flour = "แป้ง (ทุกชนิด และผลิตภัณฑ์จากแป้ง)" / "Flour (all kinds, and products made with flour)".
  allergens        text[] not null default '{}'::text[]
                     check (allergens <@ array['peanut', 'tree_nut', 'milk', 'egg', 'wheat', 'flour', 'soy',
                                               'fish', 'shellfish', 'sesame']::text[]),
  other_allergens  text check (other_allergens is null or char_length(other_allergens) <= 200),
  foods_to_avoid   text check (foods_to_avoid is null or char_length(foods_to_avoid) <= 300),
  care_notes       text check (care_notes is null or char_length(care_notes) <= 500),
  has_allergy      boolean generated always as (
                     cardinality(allergens) > 0 or char_length(coalesce(btrim(other_allergens), '')) > 0
                   ) stored,
  updated_by       uuid,         -- staff user id or NULL (parent via private link); no FK on purpose
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint child_health_child_id_key unique (child_id)
);

comment on table public.child_health is
  'Sensitive data (PDPA s.26). Exists only while the guardian''s explicit health_allergy consent is granted and the child has not refused. Never sent on LINE. foods_to_avoid never asks the reason.';

create or replace function public.enforce_health_consent()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_active_consent(new.child_id, 'health_allergy'::public.consent_purpose) then
    raise exception 'Health information needs the guardian''s explicit health consent first (health_allergy).'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke execute on function public.enforce_health_consent() from public, anon, authenticated;

create or replace trigger child_health_enforce_consent
  before insert or update on public.child_health
  for each row execute function public.enforce_health_consent();
create or replace trigger child_health_set_updated_at
  before update on public.child_health
  for each row execute function public.set_updated_at();
create or replace trigger child_health_audit
  after insert or update or delete on public.child_health
  for each row execute function public.audit_row_change();

create or replace trigger consent_records_apply_withdrawal
  after insert on public.consent_records
  for each row execute function public.apply_consent_withdrawal();

alter table public.child_health enable row level security;
revoke all on table public.child_health from anon, authenticated;
grant all on table public.child_health to service_role;
-- No policies: authenticated users can only reach this table through the functions below.


-- -----------------------------------------------------------------------------
-- 8. Consent helper functions
-- -----------------------------------------------------------------------------

-- TRUE when the latest GUARDIAN decision is 'granted' AND the child has not refused/withdrawn
-- (no child record = fine). Used by the child_health trigger. Does NOT apply the age-10 rule;
-- use consent_status() to decide whether media may be published.
create or replace function public.has_active_consent(p_child_id uuid, p_purpose public.consent_purpose)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce((
      select cr.decision = 'granted'::public.consent_decision
        from public.consent_records cr
       where cr.child_id = p_child_id
         and cr.purpose = p_purpose
         and cr.given_by = 'guardian'::public.consent_given_by
       order by cr.created_at desc, cr.id desc
       limit 1
    ), false)
    and
    coalesce((
      select cr.decision = 'granted'::public.consent_decision
        from public.consent_records cr
       where cr.child_id = p_child_id
         and cr.purpose = p_purpose
         and cr.given_by = 'child'::public.consent_given_by
       order by cr.created_at desc, cr.id desc
       limit 1
    ), true);
$$;

-- 'granted' | 'needs_child' | 'not_granted'   (D11)
--  * guardian's latest decision not 'granted'          → not_granted
--  * child's latest decision refused/withdrawn         → not_granted
--  * health_allergy: guardian granted is enough        → granted (child agreement is confirmed at the
--                                                        first session; a "no" deletes the row)
--  * media: child granted                              → granted
--           age unknown (no birth_month) or age ≥ threshold (text's requires_child_consent_from_age,
--           default 10) and no child decision           → needs_child
--           otherwise                                   → granted
create or replace function public.consent_status(p_child_id uuid, p_purpose public.consent_purpose)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_guardian_decision public.consent_decision;
  v_guardian_text_id  uuid;
  v_child_decision    public.consent_decision;
  v_threshold         integer;
  v_birth_month       date;
  v_age               integer;
begin
  perform public.require_staff_or_server();
  if p_purpose = 'marketing_line'::public.consent_purpose then
    raise exception 'marketing_line is a guardian purpose, not a child purpose' using errcode = '22023';
  end if;

  select cr.decision, cr.consent_text_id
    into v_guardian_decision, v_guardian_text_id
    from public.consent_records cr
   where cr.child_id = p_child_id
     and cr.purpose = p_purpose
     and cr.given_by = 'guardian'::public.consent_given_by
   order by cr.created_at desc, cr.id desc
   limit 1;

  select cr.decision
    into v_child_decision
    from public.consent_records cr
   where cr.child_id = p_child_id
     and cr.purpose = p_purpose
     and cr.given_by = 'child'::public.consent_given_by
   order by cr.created_at desc, cr.id desc
   limit 1;

  if v_guardian_decision is distinct from 'granted'::public.consent_decision then
    return 'not_granted';
  end if;
  if v_child_decision in ('refused'::public.consent_decision, 'withdrawn'::public.consent_decision) then
    return 'not_granted';
  end if;
  if p_purpose = 'health_allergy'::public.consent_purpose then
    return 'granted';
  end if;
  if v_child_decision = 'granted'::public.consent_decision then
    return 'granted';
  end if;

  select ct.requires_child_consent_from_age into v_threshold
    from public.consent_texts ct where ct.id = v_guardian_text_id;
  v_threshold := coalesce(v_threshold, 10);

  select c.birth_month into v_birth_month from public.children c where c.id = p_child_id;
  v_age := public.child_age_years(v_birth_month, (now() at time zone 'Asia/Bangkok')::date);

  if v_age is null or v_age >= v_threshold then
    return 'needs_child';
  end if;
  return 'granted';
end;
$$;

-- has_active_consent takes any child id and has no staff check; it is only used inside SECURITY DEFINER
-- code (the child_health trigger), so signed-in users don't need it (review R-20). consent_status checks
-- require_staff_or_server() itself.
revoke execute on function public.has_active_consent(uuid, public.consent_purpose) from public, anon, authenticated;
revoke execute on function public.consent_status(uuid, public.consent_purpose) from public, anon;
grant execute on function public.has_active_consent(uuid, public.consent_purpose) to service_role;
grant execute on function public.consent_status(uuid, public.consent_purpose) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 9. Audited health functions (the ONLY way to read or write child_health)
-- -----------------------------------------------------------------------------

-- Health notes for one child. Staff (or server). Writes ONE audit_log row per call that records the choice.
-- Round two (brief item 3, 14 Oct 2026): p_include_health is REQUIRED (no default; NULL is refused, 22004).
-- Allergens and other allergies are always returned (teachers need them in class). foods_to_avoid and care_notes
-- are returned only when p_include_health is true. The export passes true; the print sheet passes the staff choice.
drop function if exists public.get_child_health(uuid);
create or replace function public.get_child_health(p_child_id uuid, p_include_health boolean)
returns table (
  child_id         uuid,
  allergens        text[],
  other_allergens  text,
  foods_to_avoid   text,
  care_notes       text,
  has_allergy      boolean,
  updated_at       timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_staff_or_server();
  if p_include_health is null then
    raise exception 'includeHealth must be true or false' using errcode = '22004';
  end if;
  perform public.log_audit_event('read_health', 'child_health', p_child_id::text,
                                 jsonb_build_object('function', 'get_child_health',
                                                    'include_health', p_include_health));
  return query
    select h.child_id, h.allergens, h.other_allergens,
           case when p_include_health then h.foods_to_avoid end,
           case when p_include_health then h.care_notes end,
           h.has_allergy, h.updated_at
      from public.child_health h
     where h.child_id = p_child_id;
end;
$$;

-- Insert or replace one child's health row. Staff (saveChildHealth) or server (/enrol, service role).
-- Fails (42501) unless has_active_consent(child, 'health_allergy') — enforced by the table trigger.
-- Empty strings become NULL; allergens are de-duplicated and sorted.
create or replace function public.upsert_child_health(
  p_child_id        uuid,
  p_allergens       text[],
  p_other_allergens text,
  p_foods_to_avoid  text,
  p_care_notes      text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform public.require_staff_or_server();
  if not exists (select 1 from public.children c where c.id = p_child_id) then
    raise exception 'Child not found' using errcode = 'P0002';
  end if;

  insert into public.child_health (child_id, allergens, other_allergens, foods_to_avoid, care_notes, updated_by)
  values (
    p_child_id,
    coalesce((select array_agg(distinct a.val order by a.val)
                from unnest(p_allergens) as a(val)
               where a.val is not null), '{}'::text[]),
    nullif(btrim(p_other_allergens), ''),
    nullif(btrim(p_foods_to_avoid), ''),
    nullif(btrim(p_care_notes), ''),
    auth.uid()
  )
  on conflict (child_id) do update
    set allergens       = excluded.allergens,
        other_allergens = excluded.other_allergens,
        foods_to_avoid  = excluded.foods_to_avoid,
        care_notes      = excluded.care_notes,
        updated_by      = excluded.updated_by;

  -- Fresh information is on file again: clear the "info removed, check with the family" marker (R-07).
  update public.children c
     set allergy_check_needed_at = null
   where c.id = p_child_id
     and c.allergy_check_needed_at is not null;
end;
$$;

-- Roster view for one session: allergen chips + yes/no flags only (no free-text notes).
-- Writes ONE audit_log row per call (row_id = the session id).
-- Review R-07: the roster shows three states, never "no allergies" by default:
--   has_health_record and (has_allergy or other notes) → "Allergies: …"
--   has_health_record and nothing listed                → "Parent reported none (health_updated_at)"
--   no health record                                    → "No allergy info — check with the family before
--                                                           cooking" (+ "removed on allergy_check_needed_at")
create or replace function public.list_session_health_flags(p_session_id uuid)
returns table (
  child_id                 uuid,
  nickname                 text,
  health_consent           text,      -- consent_status(child, 'health_allergy')
  has_health_record        boolean,
  allergens                text[],
  has_allergy              boolean,
  has_other_allergens      boolean,
  has_foods_to_avoid       boolean,
  has_care_notes           boolean,
  health_updated_at        timestamptz,
  allergy_check_needed_at  timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_staff_or_server();
  perform public.log_audit_event('read_health', 'child_health', p_session_id::text,
                                 jsonb_build_object('function', 'list_session_health_flags', 'scope', 'session'));
  return query
    select c.id,
           c.nickname,
           public.consent_status(c.id, 'health_allergy'::public.consent_purpose),
           (h.id is not null),
           coalesce(h.allergens, '{}'::text[]),
           coalesce(h.has_allergy, false),
           (h.other_allergens is not null),
           (h.foods_to_avoid is not null),
           (h.care_notes is not null),
           h.updated_at,
           c.allergy_check_needed_at
      from public.bookings b
      join public.children c on c.id = b.child_id
      left join public.child_health h on h.child_id = c.id
     where b.session_id = p_session_id
       and b.status <> 'cancelled'::public.booking_status
     order by c.nickname;
end;
$$;

revoke execute on function public.get_child_health(uuid, boolean) from public, anon;
revoke execute on function public.upsert_child_health(uuid, text[], text, text, text) from public, anon;
revoke execute on function public.list_session_health_flags(uuid) from public, anon;
grant execute on function public.get_child_health(uuid, boolean) to authenticated, service_role;
grant execute on function public.upsert_child_health(uuid, text[], text, text, text) to authenticated, service_role;
grant execute on function public.list_session_health_flags(uuid) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 9b. record_family_print(p_family_id, p_include_health) — the print audit (decision 5, 14 Oct 2026; card P4-25).
--     Called FIRST by getPrintSheet (20 § 9.16), before any other read. Writes one audit_log row: action 'print_record',
--     table 'families', row id = the family id, details = { include_health } ONLY (never the content). Staff or server only.
--     Raises P0002 for a missing family, so nothing is printed for it. Applied with G4 · 0005 (Stage B).
--     Round two: the same p_include_health is then passed to get_child_health for each child (one choice per print).
-- -----------------------------------------------------------------------------

create or replace function public.record_family_print(p_family_id uuid, p_include_health boolean)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform public.require_staff_or_server();
  if p_include_health is null then
    raise exception 'includeHealth must be true or false' using errcode = '22004';
  end if;
  if not exists (select 1 from public.families f where f.id = p_family_id) then
    raise exception 'Family not found' using errcode = 'P0002';
  end if;
  perform public.log_audit_event('print_record', 'families', p_family_id::text,
                                 jsonb_build_object('include_health', p_include_health));
end;
$$;

revoke execute on function public.record_family_print(uuid, boolean) from public, anon;
grant execute on function public.record_family_print(uuid, boolean) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 10. media_assets + media_asset_children (D24). We store references and titles only — never files.
-- -----------------------------------------------------------------------------

create table if not exists public.media_assets (
  id                   uuid primary key default gen_random_uuid(),
  kind                 public.media_asset_kind not null,
  youtube_id           text check (youtube_id is null or youtube_id ~ '^[A-Za-z0-9_-]{11}$'),
  title                text not null check (char_length(btrim(title)) between 1 and 200),
  shows_children       boolean not null default true,
  shows_faces          boolean not null default true,
  legacy_consent_note  text check (legacy_consent_note is null or char_length(legacy_consent_note) <= 300),
  -- Review R-11: which channels the studio's PRE-SYSTEM confirmation covers (seed only; the admin never
  -- writes it, so a typed note can't make a new asset publishable). Empty = no legacy cover.
  legacy_consent_purposes  public.consent_purpose[] not null default '{}'::public.consent_purpose[]
                           check (not ('health_allergy'::public.consent_purpose = any (legacy_consent_purposes))),
  on_parents_group     boolean not null default false,
  on_website           boolean not null default false,
  on_social            boolean not null default false,
  on_youtube           boolean not null default false,
  on_print             boolean not null default false,   -- (decision 3) matches purpose media_print
  status               public.media_asset_status not null default 'active',
  taken_down_at        timestamptz,
  staff_note           text check (staff_note is null or char_length(staff_note) <= 500),
  created_by           uuid references auth.users (id) on delete set null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint media_assets_youtube_has_id check (kind <> 'youtube' or youtube_id is not null),
  constraint media_assets_taken_down_dated check (status <> 'taken_down' or taken_down_at is not null),
  constraint media_assets_youtube_id_key unique (youtube_id)
);

comment on table public.media_assets is
  'Clips/photos the studio publishes, by reference (YouTube id + title). Titles never contain children''s names.';
comment on column public.media_assets.shows_faces is 'TRUE unless staff confirmed no child''s face is recognisable. A face_hidden consent blocks assets that show faces.';

create or replace trigger media_assets_set_updated_at
  before update on public.media_assets for each row execute function public.set_updated_at();

create table if not exists public.media_asset_children (
  asset_id    uuid not null references public.media_assets (id) on delete cascade,
  child_id    uuid not null references public.children (id) on delete cascade,
  created_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now(),
  primary key (asset_id, child_id)
);

create index if not exists media_asset_children_child_idx on public.media_asset_children (child_id);

alter table public.media_assets enable row level security;
alter table public.media_asset_children enable row level security;
revoke all on table public.media_assets, public.media_asset_children from anon, authenticated;
grant select, insert, update, delete on table public.media_assets to authenticated;
grant select, insert, delete on table public.media_asset_children to authenticated;
grant all on table public.media_assets, public.media_asset_children to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_assets' and policyname = 'media_assets_staff_select') then
    create policy "media_assets_staff_select" on public.media_assets
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_assets' and policyname = 'media_assets_staff_insert') then
    create policy "media_assets_staff_insert" on public.media_assets
      for insert to authenticated with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_assets' and policyname = 'media_assets_staff_update') then
    create policy "media_assets_staff_update" on public.media_assets
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_assets' and policyname = 'media_assets_owner_delete') then
    create policy "media_assets_owner_delete" on public.media_assets
      for delete to authenticated using ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_asset_children' and policyname = 'media_asset_children_staff_select') then
    create policy "media_asset_children_staff_select" on public.media_asset_children
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_asset_children' and policyname = 'media_asset_children_staff_insert') then
    create policy "media_asset_children_staff_insert" on public.media_asset_children
      for insert to authenticated with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'media_asset_children' and policyname = 'media_asset_children_staff_delete') then
    create policy "media_asset_children_staff_delete" on public.media_asset_children
      for delete to authenticated using ((select public.is_staff()));
  end if;
end
$$;

-- can_publish_media(asset, purpose) — may this asset be used on that channel right now?
--  * asset missing or taken down                       → false
--  * shows no children                                 → true
--  * shows children but none linked yet                → true ONLY when a legacy_consent_note exists AND the
--                                                        purpose is in legacy_consent_purposes (pre-system clips;
--                                                        the admin shows "check manually" for other channels)
--  * otherwise every linked child must have consent_status = 'granted' for the purpose, and if the
--    asset shows faces the guardian's current media_level must be 'face_visible'.
--  * Review R-11: a YouTube asset shown on the WEBSITE is hosted on YouTube too, so media_website also needs
--    every linked child to pass the media_youtube check (50-security-privacy § 17.2).
create or replace function public.can_publish_media(p_asset_id uuid, p_purpose public.consent_purpose)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_status        public.media_asset_status;
  v_kind          public.media_asset_kind;
  v_shows_kids    boolean;
  v_shows_faces   boolean;
  v_legacy        text;
  v_legacy_for    public.consent_purpose[];
  v_child_id      uuid;
  v_level         public.media_level;
begin
  perform public.require_staff_or_server();
  -- Decision 3 (14 Oct 2026): media_print is a media purpose with the same rules as media_social.
  if p_purpose not in ('media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print') then
    raise exception 'can_publish_media needs a media_* purpose' using errcode = '22023';
  end if;

  select ma.status, ma.kind, ma.shows_children, ma.shows_faces, ma.legacy_consent_note, ma.legacy_consent_purposes
    into v_status, v_kind, v_shows_kids, v_shows_faces, v_legacy, v_legacy_for
    from public.media_assets ma
   where ma.id = p_asset_id;
  if v_status is null or v_status <> 'active'::public.media_asset_status then
    return false;
  end if;
  if not v_shows_kids then
    return true;
  end if;
  if not exists (select 1 from public.media_asset_children mac where mac.asset_id = p_asset_id) then
    return v_legacy is not null and p_purpose = any (coalesce(v_legacy_for, '{}'::public.consent_purpose[]));
  end if;

  for v_child_id in
    select mac.child_id from public.media_asset_children mac where mac.asset_id = p_asset_id
  loop
    if public.consent_status(v_child_id, p_purpose) <> 'granted' then
      return false;
    end if;
    if v_shows_faces then
      v_level := null;
      select cc.media_level into v_level
        from public.current_consents cc
       where cc.child_id = v_child_id
         and cc.purpose = p_purpose
         and cc.given_by = 'guardian'::public.consent_given_by;
      if v_level is distinct from 'face_visible'::public.media_level then
        return false;
      end if;
    end if;
  end loop;

  if v_kind = 'youtube'::public.media_asset_kind and p_purpose = 'media_website'::public.consent_purpose then
    return public.can_publish_media(p_asset_id, 'media_youtube'::public.consent_purpose);
  end if;
  return true;
end;
$$;

revoke execute on function public.can_publish_media(uuid, public.consent_purpose) from public, anon;
grant execute on function public.can_publish_media(uuid, public.consent_purpose) to authenticated, service_role;

-- Seed: the six clips already on the homepage (src/content/videos.ts, checked 2026-10-13).
-- Public YouTube ids and titles only (not personal data). shows_faces defaults to TRUE until staff check each clip.
-- Two founder clips: seeded now. Four class clips: owner-certified 14 Oct 2026 (G0 Q15 ticked). Their legacy cover is
-- all five child media channels (website, parents' LINE group, social, YouTube, print). They are seeded only when the
-- session setting cherrylee.legacy_clip_source_recorded = 'on' (see the block below): the builder sets it at G4 · 0005.
-- Legacy-only clips are never counted as "needs takedown"; the admin shows "check manually" for channels not covered.
-- The founder clips show no children: they are seeded at once.
insert into public.media_assets
  (kind, youtube_id, title, shows_children, shows_faces, legacy_consent_note, legacy_consent_purposes,
   on_website, on_youtube)
values
  ('youtube', '-kH75GL_o9A', 'What would you tell your childhood self? (founders)', false, true, null,
   '{}'::public.consent_purpose[], true, true),
  ('youtube', 'qAx7z_rhIPo', 'Uncle Lee on the Three Jars: saving, spending, giving', false, true, null,
   '{}'::public.consent_purpose[], true, true)
on conflict (youtube_id) do nothing;

-- The FOUR class clips show children. Owner certification 14 Oct 2026 (G0 Q15 ticked): parents agreed to all five
-- channels (website, parents' LINE group, social, YouTube, print). The block does nothing unless the session setting
-- cherrylee.legacy_clip_source_recorded is 'on'. The builder sets it (select set_config('cherrylee.legacy_clip_source_recorded',
-- 'on', false);) in the SAME SQL editor run at G4 · 0005, and never in this file. Legacy coverage = all five child media channels.
do $$
begin
  if coalesce(current_setting('cherrylee.legacy_clip_source_recorded', true), '') = 'on' then
    insert into public.media_assets
      (kind, youtube_id, title, shows_children, shows_faces, legacy_consent_note, legacy_consent_purposes,
       on_website, on_youtube)
    values
      ('youtube', 'qBoaW6tWiJc', 'Story Playlit: listen to a story, draw it, then act it out', true, true,
       'Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents'' LINE group, social, YouTube, print)',
       array['media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print']::public.consent_purpose[],
       true, true),
      ('youtube', 'e-WUF2wlGqY', 'In the kitchen with Uncle Lee', true, true,
       'Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents'' LINE group, social, YouTube, print)',
       array['media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print']::public.consent_purpose[],
       true, true),
      ('youtube', 'AvyI6OT88gQ', 'Shopping at Uncle Lee''s fruit stand', true, true,
       'Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents'' LINE group, social, YouTube, print)',
       array['media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print']::public.consent_purpose[],
       true, true),
      ('youtube', '9z7-0PwwiI4', 'A real shopping trip, with parents along', true, true,
       'Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents'' LINE group, social, YouTube, print)',
       array['media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print']::public.consent_purpose[],
       true, true)
    on conflict (youtube_id) do nothing;
  else
    raise notice 'SKIP the four class clips: the session setting cherrylee.legacy_clip_source_recorded is not on (G0 Q15 ticked 14 Oct 2026; the builder sets it at G4 · 0005)';
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 10b. One-call screen functions (review R-18: no per-row RPCs from a Worker) and one-transaction
--      writes (review R-15). All SECURITY DEFINER ones check require_staff_or_server() first.
-- -----------------------------------------------------------------------------

-- consent_matrix(child ids) — one row per child × CHILD purpose (6: health_allergy + 5 media channels) for the
-- family page, the roster and /my/$token. marketing_line is guardian scope and is never listed here.
-- status = consent_status() ('granted' | 'needs_child' | 'not_granted').
create or replace function public.consent_matrix(p_child_ids uuid[])
returns table (
  child_id              uuid,
  purpose               public.consent_purpose,
  guardian_decision     public.consent_decision,
  guardian_media_level  public.media_level,
  guardian_decided_at   timestamptz,
  child_decision        public.consent_decision,
  status                text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_staff_or_server();
  if coalesce(cardinality(p_child_ids), 0) > 200 then
    raise exception 'consent_matrix: at most 200 children per call' using errcode = '22023';
  end if;
  return query
    select c.id,
           pp.purpose,
           g.decision,
           g.media_level,
           g.created_at,
           k.decision,
           public.consent_status(c.id, pp.purpose)
      from public.children c
     cross join unnest(array['health_allergy', 'media_parents_group', 'media_website', 'media_social',
                             'media_youtube', 'media_print']::public.consent_purpose[]) as pp(purpose)
      left join public.current_consents g
             on g.child_id = c.id and g.purpose = pp.purpose and g.given_by = 'guardian'::public.consent_given_by
      left join public.current_consents k
             on k.child_id = c.id and k.purpose = pp.purpose and k.given_by = 'child'::public.consent_given_by
     where c.id = any (p_child_ids)
     order by c.created_at, c.id, pp.purpose;
end;
$$;

-- media_publishability() — every asset × the 5 media purposes (decision 3 adds media_print), for /admin/media and the dashboard.
create or replace function public.media_publishability()
returns table (
  asset_id     uuid,
  purpose      public.consent_purpose,
  publishable  boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_staff_or_server();
  return query
    select ma.id,
           pp.purpose,
           public.can_publish_media(ma.id, pp.purpose)
      from public.media_assets ma
     cross join unnest(array['media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print']
                       ::public.consent_purpose[]) as pp(purpose)
     order by ma.created_at desc, ma.id, pp.purpose;
end;
$$;

-- set_media_asset_children(asset, child ids) — replace the linked children in one transaction.
-- SECURITY INVOKER: media_asset_children RLS applies as the staff user.
create or replace function public.set_media_asset_children(p_asset_id uuid, p_child_ids uuid[])
returns void
language plpgsql
volatile
security invoker
set search_path = ''
as $$
begin
  perform public.require_staff_or_server();
  if coalesce(cardinality(p_child_ids), 0) > 40 then
    raise exception 'set_media_asset_children: at most 40 children' using errcode = '22023';
  end if;
  delete from public.media_asset_children mac
   where mac.asset_id = p_asset_id
     and not (mac.child_id = any (coalesce(p_child_ids, '{}'::uuid[])));
  insert into public.media_asset_children (asset_id, child_id, created_by)
  select p_asset_id, x.child_id, auth.uid()
    from unnest(coalesce(p_child_ids, '{}'::uuid[])) as x(child_id)
  on conflict (asset_id, child_id) do nothing;
end;
$$;

-- publish_consent_text(...) — owner publishes version N+1 in TH and EN and retires older versions of that
-- purpose, all in one transaction (no moment where TH vN sits next to EN vN-1). SECURITY INVOKER: the
-- consent_texts owner policies apply. Returns the new version number.
-- Review R-35 (G-HEALTH): it may publish a NEW VERSION of health_allergy but never the FIRST one. The first
-- health text arrives only through a reviewed SQL draft (0006 with G-HEALTH = system, after G9b), so an owner who
-- chose the paper form can't reopen health storage from the SQL editor by accident. Raises 23514.
-- While the publishing screen is parked (PK-03), the owner runs this in Cloud → SQL editor (00-overview § 8.0).
create or replace function public.publish_consent_text(
  p_purpose                          public.consent_purpose,
  p_title_th                         text,
  p_body_md_th                       text,
  p_title_en                         text,
  p_body_md_en                       text,
  p_is_explicit                      boolean,
  p_requires_child_consent_from_age  smallint
)
returns integer
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_version integer;
begin
  perform public.require_owner_or_server();
  perform pg_advisory_xact_lock(hashtextextended('consent_texts:' || p_purpose::text, 0));

  if p_purpose = 'health_allergy'::public.consent_purpose
     and not exists (select 1 from public.consent_texts ct
                      where ct.purpose = 'health_allergy'::public.consent_purpose) then
    raise exception 'The first health_allergy text comes only from a reviewed SQL draft (G-HEALTH, G9b)'
      using errcode = '23514';
  end if;

  select coalesce(max(ct.version), 0) + 1 into v_version
    from public.consent_texts ct
   where ct.purpose = p_purpose;

  insert into public.consent_texts
    (purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age, created_by)
  values
    (p_purpose, v_version, 'th'::public.site_lang, p_title_th, p_body_md_th, p_is_explicit,
     p_requires_child_consent_from_age, auth.uid()),
    (p_purpose, v_version, 'en'::public.site_lang, p_title_en, p_body_md_en, p_is_explicit,
     p_requires_child_consent_from_age, auth.uid());

  update public.consent_texts ct
     set retired_at = now()
   where ct.purpose = p_purpose
     and ct.version < v_version
     and ct.retired_at is null;

  return v_version;
end;
$$;

revoke execute on function public.consent_matrix(uuid[]) from public, anon;
revoke execute on function public.media_publishability() from public, anon;
revoke execute on function public.set_media_asset_children(uuid, uuid[]) from public, anon;
revoke execute on function public.publish_consent_text(public.consent_purpose, text, text, text, text, boolean, smallint) from public, anon;
grant execute on function public.consent_matrix(uuid[]) to authenticated, service_role;
grant execute on function public.media_publishability() to authenticated, service_role;
grant execute on function public.set_media_asset_children(uuid, uuid[]) to authenticated;
grant execute on function public.publish_consent_text(public.consent_purpose, text, text, text, text, boolean, smallint) to authenticated;


-- -----------------------------------------------------------------------------
-- 10c. submit_enrolment(p_link_id, p) — the whole /enrol/$token statement in ONE transaction (review R-15).
--      SERVER ONLY (service role). The TypeScript handler has already: zod-validated the payload, resolved the
--      token to p_link_id, and checked that every consent_text_id is a current text in the page language.
--      This function re-checks scope (every child belongs to the link's family) and locks the link row, so
--      two concurrent submits can't both succeed.
--
--      p = {
--        "guardian": {"full_name": text, "phone": text|null, "line_id": text|null, "email": text|null},
--        "children": [{
--            "child_id": uuid, "birth_month": "YYYY-MM",
--            "health": {"decision": "granted"|"refused"|"skipped", "consent_text_id": uuid|null,
--                       "allergens": [text], "other_allergens": text, "foods_to_avoid": text, "care_notes": text},
--            "media": [{"purpose": "media_website"|"media_parents_group"|"media_social"|"media_youtube"|"media_print",
--                       "on": true|false, "consent_text_id": uuid}, …],  -- ONLY
--                      the purposes whose text was shown (R-06); a missing purpose records nothing
--            "media_level": "face_visible"|"face_hidden"|null }],
--        "contacts": [{"id": uuid|null, "name": text, "phone": text, "relationship": text,
--                      "is_emergency_contact": bool, "is_authorised_pickup": bool}]
--      }
--      Rules:
--        * identity is NOT marked as checked (R-21): staff confirm in the family's LINE chat. Changed contact
--          fields are kept in guardians.pending_link_changes for staff to review.
--        * media switch ON records 'granted'. A switch that is OFF records 'refused' ONLY when this guardian has
--          no earlier decision for that child × purpose; otherwise it records NOTHING (R-33). The /enrol boxes
--          always start unticked, so "off" can't tell "untouched" from "switched off": a family re-sent an enrol
--          link (e.g. to add allergy info) must never lose its media consents by accident. Withdrawals go
--          through /my/$token or staff (D29 alerts still fire there).
--        * health "refused" (the explicit "I don't want to share this" button) records 'withdrawn' when the
--          latest guardian decision was 'granted', else 'refused' (R-05). "skipped" records nothing.
--        * health "granted" while the child's own latest health decision is refused/withdrawn raises 23514
--          (R-34): D11 says staff talk with the family first; the form hides the health box in that case.
--        * the trigger queue_consent_change_alert queues staff alerts; their ids are returned in alert_ids.
--        * contacts not in the list are soft-deleted (is_active = false), never hard-deleted (R-22).
--      Returns {"ok": true, "family_id": uuid, "alert_ids": [uuid…]} or {"ok": false, "code": "link_invalid" |
--      "link_expired" | "link_used"}. Bad scope raises 22023; a consent rule raises 23514 (TS → invalid_input).
-- -----------------------------------------------------------------------------

create or replace function public.submit_enrolment(p_link_id uuid, p jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_link         record;
  v_guardian     record;
  v_changes      jsonb := '{}'::jsonb;
  v_child        jsonb;
  v_child_id     uuid;
  v_health       jsonb;
  v_media        jsonb;
  v_purpose      public.consent_purpose;
  v_prev         public.consent_decision;
  v_decision     public.consent_decision;
  v_level        public.media_level;
  v_rec_id       uuid;
  v_record_ids   uuid[] := '{}'::uuid[];
  v_contact      jsonb;
  v_contact_id   uuid;
  v_keep_ids     uuid[] := '{}'::uuid[];
  v_alert_ids    uuid[];
  v_g            jsonb := coalesce(p -> 'guardian', '{}'::jsonb);
begin
  if coalesce(auth.role(), 'none') not in ('service_role', 'none') then
    raise exception 'Not allowed: server only' using errcode = '42501';
  end if;

  -- 1. Lock the link: a second, concurrent submit waits here and then sees used_at.
  select fl.id, fl.family_id, fl.purpose, fl.expires_at, fl.used_at, fl.revoked_at
    into v_link
    from public.family_links fl
   where fl.id = p_link_id
     for update;
  if not found or v_link.purpose <> 'enrol'::public.link_purpose or v_link.revoked_at is not null then
    return jsonb_build_object('ok', false, 'code', 'link_invalid');
  end if;
  if v_link.used_at is not null then
    return jsonb_build_object('ok', false, 'code', 'link_used');
  end if;
  if v_link.expires_at <= now() then
    return jsonb_build_object('ok', false, 'code', 'link_expired');
  end if;

  -- 2. Primary guardian of THIS family. Keep the old value of every changed contact field (R-21).
  select g.id, g.full_name, g.phone, g.line_id, g.email, g.pending_link_changes
    into v_guardian
    from public.guardians g
   where g.family_id = v_link.family_id
     and g.is_primary
     for update;
  if not found then
    raise exception 'invalid_input: family has no primary guardian' using errcode = '22023';
  end if;
  if (v_g ->> 'full_name') is distinct from v_guardian.full_name then
    v_changes := v_changes || jsonb_build_object('full_name', v_guardian.full_name);
  end if;
  if nullif(v_g ->> 'phone', '') is distinct from v_guardian.phone then
    v_changes := v_changes || jsonb_build_object('phone', v_guardian.phone);
  end if;
  if nullif(v_g ->> 'line_id', '') is distinct from v_guardian.line_id then
    v_changes := v_changes || jsonb_build_object('line_id', v_guardian.line_id);
  end if;
  if nullif(v_g ->> 'email', '') is distinct from v_guardian.email then
    v_changes := v_changes || jsonb_build_object('email', v_guardian.email);
  end if;

  update public.guardians g
     set full_name = v_g ->> 'full_name',
         phone = nullif(v_g ->> 'phone', ''),
         line_id = nullif(v_g ->> 'line_id', ''),
         email = nullif(v_g ->> 'email', ''),
         has_parental_responsibility = true,
         responsibility_attested_at = now(),
         pending_link_changes = case
           when v_changes = '{}'::jsonb then g.pending_link_changes
           -- earliest "before" values win, so staff see what was on file before ANY unconfirmed change
           else jsonb_build_object('at', now(),
                                   'before', v_changes || coalesce(g.pending_link_changes -> 'before', '{}'::jsonb))
         end
   where g.id = v_guardian.id;

  -- 3. Children: scope check, birth month, consent records, health.
  for v_child in select value from jsonb_array_elements(coalesce(p -> 'children', '[]'::jsonb)) loop
    v_child_id := (v_child ->> 'child_id')::uuid;
    if not exists (select 1 from public.children c
                    where c.id = v_child_id and c.family_id = v_link.family_id) then
      raise exception 'invalid_input: child is not in this family' using errcode = '22023';
    end if;
    update public.children c
       set birth_month = ((v_child ->> 'birth_month') || '-01')::date
     where c.id = v_child_id;

    -- 3a. Health (explicit consent, s.26). "skipped" (= "Not now") records nothing and deletes nothing.
    v_health := coalesce(v_child -> 'health', '{}'::jsonb);
    -- R-34: a 10+ child's own "no" (D11) blocks a new guardian grant until staff have talked with the family.
    -- Raised BEFORE any write so it surfaces as 23514 (TS → invalid_input), never as the 42501 of the
    -- child_health trigger (TS → server_error).
    if (v_health ->> 'decision') = 'granted' and (
         select cr.decision
           from public.consent_records cr
          where cr.child_id = v_child_id
            and cr.purpose = 'health_allergy'::public.consent_purpose
            and cr.given_by = 'child'::public.consent_given_by
          order by cr.created_at desc, cr.id desc
          limit 1
       ) in ('refused'::public.consent_decision, 'withdrawn'::public.consent_decision) then
      raise exception 'invalid_input: the child said no to sharing health information' using errcode = '23514';
    end if;
    if (v_health ->> 'decision') in ('granted', 'refused') then
      v_prev := null;
      select cr.decision into v_prev
        from public.consent_records cr
       where cr.child_id = v_child_id
         and cr.purpose = 'health_allergy'::public.consent_purpose
         and cr.given_by = 'guardian'::public.consent_given_by
       order by cr.created_at desc, cr.id desc
       limit 1;
      v_decision := case
        when v_health ->> 'decision' = 'granted' then 'granted'::public.consent_decision
        when v_prev is not distinct from 'granted'::public.consent_decision then 'withdrawn'::public.consent_decision
        else 'refused'::public.consent_decision
      end;
      insert into public.consent_records
        (family_id, guardian_id, child_id, purpose, consent_text_id, decision, given_by, channel, method,
         family_link_id)
      values
        (v_link.family_id, v_guardian.id, v_child_id, 'health_allergy'::public.consent_purpose,
         (v_health ->> 'consent_text_id')::uuid, v_decision, 'guardian'::public.consent_given_by,
         'web'::public.consent_channel, 'checkbox'::public.consent_method, v_link.id)
      returning id into v_rec_id;
      v_record_ids := v_record_ids || v_rec_id;
      if v_decision = 'granted'::public.consent_decision then
        -- after the consent row exists: the child_health trigger checks it (D10)
        perform public.upsert_child_health(
          v_child_id,
          coalesce(array(select jsonb_array_elements_text(coalesce(v_health -> 'allergens', '[]'::jsonb))),
                   '{}'::text[]),
          v_health ->> 'other_allergens',
          v_health ->> 'foods_to_avoid',
          v_health ->> 'care_notes');
      end if;
    end if;

    -- 3b. Media: one record per purpose that was SHOWN (R-06). ON = granted. OFF = refused only when this
    --     guardian never decided this purpose for this child; otherwise nothing is recorded (R-33).
    v_level := nullif(v_child ->> 'media_level', '')::public.media_level;
    for v_media in select value from jsonb_array_elements(coalesce(v_child -> 'media', '[]'::jsonb)) loop
      v_purpose := (v_media ->> 'purpose')::public.consent_purpose;
      -- Only the five child media purposes here (decision 3). Health has its own rules; marketing_line is
      -- guardian scope and is never part of the enrolment form.
      if v_purpose is null
         or v_purpose not in ('media_parents_group', 'media_website', 'media_social', 'media_youtube', 'media_print') then
        raise exception 'invalid_input: not a child media purpose' using errcode = '22023';
      end if;
      v_prev := null;
      select cr.decision into v_prev
        from public.consent_records cr
       where cr.child_id = v_child_id
         and cr.purpose = v_purpose
         and cr.given_by = 'guardian'::public.consent_given_by
       order by cr.created_at desc, cr.id desc
       limit 1;
      v_decision := case
        when (v_media ->> 'on')::boolean then 'granted'::public.consent_decision
        when v_prev is null then 'refused'::public.consent_decision
        else null   -- R-33: an unticked box never changes an earlier decision
      end;
      if v_decision is not null then
        insert into public.consent_records
          (family_id, guardian_id, child_id, purpose, consent_text_id, decision, given_by, media_level, channel,
           method, family_link_id)
        values
          (v_link.family_id, v_guardian.id, v_child_id, v_purpose, (v_media ->> 'consent_text_id')::uuid,
           v_decision, 'guardian'::public.consent_given_by,
           case when v_decision = 'granted'::public.consent_decision then v_level else null end,
           'web'::public.consent_channel, 'checkbox'::public.consent_method, v_link.id)
        returning id into v_rec_id;
        v_record_ids := v_record_ids || v_rec_id;
      end if;
    end loop;
  end loop;

  -- 4. Contacts: update the listed ones (must belong to this family), add new ones, soft-delete the rest.
  for v_contact in select value from jsonb_array_elements(coalesce(p -> 'contacts', '[]'::jsonb)) loop
    v_contact_id := null;
    if nullif(v_contact ->> 'id', '') is not null then
      update public.family_contacts fc
         set name = v_contact ->> 'name',
             phone = v_contact ->> 'phone',
             relationship = v_contact ->> 'relationship',
             is_emergency_contact = coalesce((v_contact ->> 'is_emergency_contact')::boolean, false),
             is_authorised_pickup = coalesce((v_contact ->> 'is_authorised_pickup')::boolean, false),
             guardian_attests_informed_at = now(),
             is_active = true
       where fc.id = (v_contact ->> 'id')::uuid
         and fc.family_id = v_link.family_id
      returning fc.id into v_contact_id;
      if v_contact_id is null then
        raise exception 'invalid_input: contact is not in this family' using errcode = '22023';
      end if;
    else
      insert into public.family_contacts
        (family_id, name, phone, relationship, is_emergency_contact, is_authorised_pickup,
         guardian_attests_informed_at)
      values
        (v_link.family_id, v_contact ->> 'name', v_contact ->> 'phone', v_contact ->> 'relationship',
         coalesce((v_contact ->> 'is_emergency_contact')::boolean, false),
         coalesce((v_contact ->> 'is_authorised_pickup')::boolean, false),
         now())
      returning id into v_contact_id;
    end if;
    v_keep_ids := v_keep_ids || v_contact_id;
  end loop;
  update public.family_contacts fc
     set is_active = false
   where fc.family_id = v_link.family_id
     and fc.is_active
     and not (fc.id = any (v_keep_ids));

  -- 5. Only now is the single-use link spent.
  update public.family_links fl set used_at = now() where fl.id = v_link.id;

  select coalesce(array_agg(sn.id), '{}'::uuid[]) into v_alert_ids
    from public.staff_notifications sn
   where sn.kind = 'consent_withdrawn'::public.notification_kind
     and sn.ref_id = any (v_record_ids);

  return jsonb_build_object('ok', true, 'family_id', v_link.family_id, 'alert_ids', to_jsonb(v_alert_ids));
end;
$$;

revoke execute on function public.submit_enrolment(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.submit_enrolment(uuid, jsonb) to service_role;


-- -----------------------------------------------------------------------------
-- 11. Private bucket consent-evidence (paper forms / signed sheets; ≤ 5 MB; jpeg/png/webp/pdf)
--     Path: <family_id>/<uuid>.<ext>. Staff upload/view (60-second signed URLs); owner deletes.
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('consent-evidence', 'consent-evidence', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'consent_evidence_staff_select') then
    create policy "consent_evidence_staff_select" on storage.objects
      for select to authenticated
      using (bucket_id = 'consent-evidence' and (select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'consent_evidence_staff_insert') then
    create policy "consent_evidence_staff_insert" on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'consent-evidence'
        and (select public.is_staff())
        and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
      );
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'consent_evidence_owner_delete') then
    create policy "consent_evidence_owner_delete" on storage.objects
      for delete to authenticated
      using (bucket_id = 'consent-evidence' and (select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 12. purge_expired_records() — v3 (full re-declaration). Adds child_health inactivity,
--     family_links, detached consent_records. Family deletion still arrives in v4 (0007).
-- -----------------------------------------------------------------------------

create or replace function public.purge_expired_records()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_counts jsonb := jsonb_build_object('version', 3);
  v_n      bigint;
begin
  perform set_config('cherrylee.allow_purge', 'on', true);

  delete from public.rate_limit_events where created_at < now() - interval '24 hours';
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('rate_limit_events', v_n);

  delete from public.staff_notifications where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('staff_notifications', v_n);

  delete from public.booking_requests where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('booking_requests', v_n);

  -- Health: delete 6 months after the child's last (or next) non-cancelled session; rows changed
  -- in the last 6 months are kept (e.g. a newly enrolled child who has not booked yet).
  -- Review R-07: mark those children so the roster says "info removed — check with the family".
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

  -- Review R-10: count the credits of expiring bookings before deleting them.
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

  -- Detached consent evidence (family erased) after its 3-year retention.
  delete from public.consent_records where family_id is null and retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('consent_records', v_n);

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

-- End of 0005_consent_health.sql
