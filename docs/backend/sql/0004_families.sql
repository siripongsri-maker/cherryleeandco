-- =============================================================================
-- 0004_families.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P3 (feature F3-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    the studio's day-to-day records: families, guardians, children (minimal),
--             emergency/pickup contacts, packages (1/4/8), manual payments, seat bookings +
--             attendance, package_balances view, private bucket payment-slips,
--             storage_cleanup_queue (files can't be deleted by SQL), session_seats_left v2,
--             get_sessions_with_seats v2, purge_expired_records v2, audit triggers.
--             Review fixes (00-overview § 15): sessions_used_purged (R-10), family_contacts.is_active (R-22),
--             guardians.pending_link_changes (R-21), children.allergy_check_needed_at (R-07),
--             create_family_from_request() in one transaction (R-15), cancelling a session cancels its
--             held/confirmed bookings (R-23); second review: set_primary_guardian() swaps the primary
--             guardian in one transaction (R-39). Behaviour checks: seed_dev.sql § 7b.
--             Decision 10 (14 Oct 2026): studio_settings.cancel_notice_hours (default 3, 0–72) decides on-time vs
--             late. (The round-one check_make_up_notice() is removed in round three.) Also queue_storage_cleanup()
--             covers guardian_consent_records (decision 2). Checks: seed_dev.sql § 7c.
--             Round two (14 Oct 2026, brief item 1): credit rule by notice. A cancellation with notice on or
--             before (session start − cancel_notice_hours) keeps its credit (status 'cancelled'). 'absent' and
--             'cancelled_late' use one credit. New: booking_status 'cancelled_late', bookings.cancel_notice_channel /
--             cancel_notice_at; validate_booking decides the cancellation status and writes cancelled_at.
--             Checks: seed_dev § 5, § 7d.
--             Round three (14 Oct 2026, the owner's third set of answers, briefs 1–8):
--             (1) studio cancels a session → status 'cancelled_studio': credit RETURNED (not used), no notice needed;
--                 the cherrylee.studio_cancel setting is removed (it used to keep the credit as 'cancelled').
--             (2) late → 'cancelled_late': seat kept, NOT an absence in attendance, ONE credit used.
--                 A family cancellation with NO notice is not a cancellation: cancel_booking() refuses it (22023),
--                 and validate_booking() turns a cancellation without notice into 'absent' (one credit, no log row).
--                 The D49 title says "cancels late or misses"; whether a miss means 'cancelled_late' is an open owner
--                 question (00 § 13B, 50 § 28), not decided here.
--                 Every cancellation writes one row to the NEW append-only booking_cancellation_log (section 8b),
--                 through cancel_booking() (section 19). Reports count cancellations from that log (0008).
--             Round three verifier fixes (14 Oct 2026, after review): cancel_booking() refuses a booking that is not
--                 held or confirmed (attended and absent cannot be cancelled); the no-notice path above; comments on
--                 recorded_by (staff user id) and on the retention of booking_cancellation_log (provisional).
--             (3) a cancelled_late booking counts as a booking for the 6-month child_health clock (child_has_recent_booking, 0005).
--             (5/6) notice_channel = 'line' | 'phone' | 'teacher' | 'in_person' (any of them counts as notice).
--             (7) check_make_up_notice() is removed: a rebooking uses the kept or returned credit; the make-up link
--                 (bookings.makeup_of_booking_id) only has to name a booking of the same child.
--             Helper booking_is_live(status) (section 1b) is the one rule for "holds a seat and uses a credit".
--             Checks: seed_dev § 5, § 7d, § 7e; tests/rls_smoke.sql A12, A16.
-- Depends on: 0001, 0002, 0003
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must contain "families", "bookings", "package_balances",
--   "create_family_from_request", "set_primary_guardian".
--   G11: the owner + accountant must confirm the 5-year payment retention used below.
-- Rules: additive only. Safe to run twice.
-- Not collected (D9, 00-overview § 6): national ID numbers, full birth dates, school, full legal
--   names of children, home address, bank account numbers, reasons for foods to avoid.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'family_status') then
    create type public.family_status as enum ('active', 'inactive');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'identity_check_method') then
    create type public.identity_check_method as enum ('in_person', 'line_account', 'phone_callback');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'package_purchase_status') then
    create type public.package_purchase_status as enum ('active', 'closed', 'void');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'payment_method') then
    create type public.payment_method as enum ('promptpay', 'bank_transfer', 'cash', 'other');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'payment_status') then
    create type public.payment_status as enum ('pending', 'paid', 'refunded', 'void');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'booking_status') then
    -- Round two: 'cancelled_late' = cancelled with late or no notice (uses one credit, like 'absent').
    -- Round three: 'cancelled_studio' = the studio cancelled the session (credit returned, not used).
    create type public.booking_status as enum ('held', 'confirmed', 'attended', 'absent', 'cancelled',
                                               'cancelled_late', 'cancelled_studio');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'notice_channel') then
    -- Round three (brief 6): any of the four channels counts as notice.
    create type public.notice_channel as enum ('line', 'phone', 'teacher', 'in_person');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'cancellation_outcome') then
    -- Round three (brief 2): one outcome per cancellation event, written to booking_cancellation_log.
    create type public.cancellation_outcome as enum ('family_on_time', 'family_late', 'studio');
  end if;
end
$$;

-- Round two/three: a type created by an earlier run may lack the newer labels. These steps add them when missing,
-- so re-runs are safe. Each is its own statement. PostgreSQL does not let a new enum label be used in the same
-- transaction that added it, so no DDL in this file (indexes, views, check constraints) uses 'cancelled_late' or
-- 'cancelled_studio' as a literal. Function bodies (plpgsql) use them at run time, which is fine.
alter type public.booking_status add value if not exists 'cancelled_late';
alter type public.booking_status add value if not exists 'cancelled_studio';
alter type public.notice_channel add value if not exists 'phone';
alter type public.notice_channel add value if not exists 'teacher';


-- -----------------------------------------------------------------------------
-- 1b. booking_is_live(status) — ONE rule for "this booking holds a seat and, with consumes_credit, uses a credit".
--     Live: held, confirmed, attended, absent, cancelled_late (the seat stays taken; a late cancel uses one credit).
--     Not live: cancelled (family on time, credit kept) and cancelled_studio (credit returned).
--     Used by the seat index, validate_booking, the views and reports, the purge (0005, 0007) and the health clock
--     (child_has_recent_booking, 0005). Written with TEXT labels so the function (and the index that uses it) does not
--     reference an enum label in DDL.
-- -----------------------------------------------------------------------------

create or replace function public.booking_is_live(p_status public.booking_status)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_status::text in ('held', 'confirmed', 'attended', 'absent', 'cancelled_late');
$$;

revoke execute on function public.booking_is_live(public.booking_status) from public, anon;
grant execute on function public.booking_is_live(public.booking_status) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 2. families
--    status / last_activity_at / retain_until are SYSTEM-MANAGED from P5
--    (mark_inactive_families() in 0007). Until then status stays 'active' and
--    retain_until stays NULL (no automatic family deletion before P5).
-- -----------------------------------------------------------------------------

create table if not exists public.families (
  id                 uuid primary key default gen_random_uuid(),
  display_name       text not null check (char_length(btrim(display_name)) between 1 and 80),
  preferred_lang     public.site_lang not null default 'th',
  status             public.family_status not null default 'active',
  staff_note         text check (staff_note is null or char_length(staff_note) <= 1000),
  source_request_id  uuid references public.booking_requests (id) on delete set null,
  last_activity_at   timestamptz not null default now(),
  retain_until       timestamptz,
  created_by         uuid references auth.users (id) on delete set null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

comment on table public.families is
  'Customer household. Lawful basis s.24(3) contract. Deleted (via erase_family, P5) 12 months after last activity.';
comment on column public.families.staff_note is 'Practical notes only. NEVER health, allergy or religious information.';
comment on column public.families.display_name is 'Staff label. Not used on the follow-up list: that list uses family_label() (0007), which names every attending child (round three, D52). No surnames needed.';

create index if not exists families_status_idx on public.families (status);
create index if not exists families_retain_until_idx on public.families (retain_until) where retain_until is not null;
create index if not exists families_source_request_idx on public.families (source_request_id);


-- -----------------------------------------------------------------------------
-- 3. guardians — parents/guardians who act for the child (PDPA s.20)
-- -----------------------------------------------------------------------------

create table if not exists public.guardians (
  id                            uuid primary key default gen_random_uuid(),
  family_id                     uuid not null references public.families (id) on delete cascade,
  full_name                     text not null check (char_length(btrim(full_name)) between 1 and 80),
  phone                         text check (phone is null or phone ~ '^0[0-9]{8,9}$'),
  line_id                       text check (line_id is null or line_id ~ '^\S{1,50}$'),
  email                         text check (email is null or (char_length(email) <= 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')),
  is_primary                    boolean not null default false,
  has_parental_responsibility   boolean not null default false,
  responsibility_attested_at    timestamptz,
  identity_check_method         public.identity_check_method,
  identity_checked_by           uuid references auth.users (id) on delete set null,
  identity_checked_at           timestamptz,
  -- Review R-21: contact fields a parent changed through the private enrol link, waiting for staff to confirm
  -- in the family's LINE chat. {"at": <timestamptz>, "before": {"phone": "...", ...}} (old values of the
  -- changed fields only). Written by submit_enrolment (0005); cleared by staff (saveGuardian confirm).
  pending_link_changes          jsonb
                                  check (pending_link_changes is null or jsonb_typeof(pending_link_changes) = 'object'),
  created_at                    timestamptz not null default now(),
  updated_at                    timestamptz not null default now(),
  constraint guardians_contact_present
    check (phone is not null or line_id is not null or email is not null),
  constraint guardians_responsibility_attested
    check (not has_parental_responsibility or responsibility_attested_at is not null),
  constraint guardians_identity_check_complete
    check ((identity_check_method is null) = (identity_checked_at is null))
);

comment on table public.guardians is
  'Parent/guardian. No national ID numbers or ID card copies (D13: the LINE chat is the identity check).';
comment on column public.guardians.email is 'Optional (enrolment), only for families who want receipts by email.';
comment on column public.guardians.identity_checked_by is 'Staff user who checked identity; NULL when checked through the private link (line_account).';

create index if not exists guardians_family_idx on public.guardians (family_id);
create unique index if not exists guardians_one_primary_per_family on public.guardians (family_id) where is_primary;
create index if not exists guardians_phone_idx on public.guardians (phone) where phone is not null;


-- -----------------------------------------------------------------------------
-- 4. children — minimal profile (nickname + birth month)
-- -----------------------------------------------------------------------------

create table if not exists public.children (
  id                  uuid primary key default gen_random_uuid(),
  family_id           uuid not null references public.families (id) on delete cascade,
  nickname            text not null check (char_length(btrim(nickname)) between 1 and 30),
  birth_month         date check (birth_month is null or extract(day from birth_month) = 1),
  reported_age_years  smallint check (reported_age_years is null or reported_age_years between 6 and 12),
  reported_age_on     date,
  is_active           boolean not null default true,
  last_session_on     date,
  -- Review R-07: NOT health data. Set when allergy info is removed (withdrawal, refusal, retention purge) so
  -- the roster can say "info removed on <date> — check with the family before cooking". Cleared when new
  -- allergy info is saved (upsert_child_health, 0005).
  allergy_check_needed_at  timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint children_reported_age_dated
    check ((reported_age_years is null) = (reported_age_on is null))
);

comment on table public.children is
  'Child profile: nickname + birth month (YYYY-MM-01) only. No full name, full birth date, school, gender or nationality.';
comment on column public.children.birth_month is 'First day of the birth month (day must be 1). NULL = unknown → treated as needing the child''s own consent (D11).';
comment on column public.children.reported_age_years is 'Age the parent gave on the booking request, until the birth month is known.';
comment on column public.children.last_session_on is 'Latest session date with status attended. Maintained by trigger sync_child_last_session().';

create index if not exists children_family_idx on public.children (family_id);
create index if not exists children_nickname_idx on public.children (lower(nickname));


-- -----------------------------------------------------------------------------
-- 5. family_contacts — emergency contacts and authorised pickup persons
-- -----------------------------------------------------------------------------

create table if not exists public.family_contacts (
  id                            uuid primary key default gen_random_uuid(),
  family_id                     uuid not null references public.families (id) on delete cascade,
  name                          text not null check (char_length(btrim(name)) between 1 and 80),
  phone                         text not null check (phone ~ '^0[0-9]{8,9}$'),
  relationship                  text not null check (char_length(btrim(relationship)) between 1 and 40),
  is_emergency_contact          boolean not null default false,
  is_authorised_pickup          boolean not null default false,
  guardian_attests_informed_at  timestamptz not null,
  -- Review R-22: soft delete. Removing a contact sets is_active = false so bookings.picked_up_by_contact_id keeps
  -- the record of who collected a child. Inactive contacts are hidden from pickup choices and the enrol form,
  -- and are deleted with the family (erase_family / retention).
  is_active                     boolean not null default true,
  created_at                    timestamptz not null default now(),
  updated_at                    timestamptz not null default now(),
  constraint family_contacts_has_role check (is_emergency_contact or is_authorised_pickup)
);

comment on table public.family_contacts is
  'Third parties given by the guardian (PDPA s.25). guardian_attests_informed_at = guardian confirmed "I have told them and shared the privacy notice". No ID numbers. Removed contacts are soft-deleted (is_active = false).';

create index if not exists family_contacts_family_idx on public.family_contacts (family_id, is_active);


-- -----------------------------------------------------------------------------
-- 6. package_purchases — 1/4/8-session packages with a price snapshot (D16)
--    retain_until = 31 Dec of (purchase year + 5), set by trigger. ACCOUNTANT TO CONFIRM (G11).
--    family_id becomes NULL when a family is erased (amounts/dates kept, anonymised).
-- -----------------------------------------------------------------------------

create table if not exists public.package_purchases (
  id              uuid primary key default gen_random_uuid(),
  family_id       uuid references public.families (id) on delete set null,
  package_code    public.package_code not null,
  sessions_total  smallint not null,
  price_thb       integer not null check (price_thb >= 0),
  purchased_on    date not null default ((now() at time zone 'Asia/Bangkok')::date),
  expires_on      date,
  status          public.package_purchase_status not null default 'active',
  staff_note      text check (staff_note is null or char_length(staff_note) <= 500),
  -- Review R-10: credit-consuming bookings deleted by the retention purge (24 months after the session) are
  -- counted here first, so used credits never "come back". Maintained ONLY by purge_expired_records()
  -- (guard_package_purge_counter blocks every other write).
  sessions_used_purged  smallint not null default 0,
  created_by      uuid references auth.users (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  retain_until    timestamptz not null default (now() + interval '6 years'),  -- overwritten by trigger
  constraint package_purchases_sessions_match_code check (
       (package_code = 'single' and sessions_total = 1)
    or (package_code = 'four'   and sessions_total = 4)
    or (package_code = 'eight'  and sessions_total = 8)
  ),
  constraint package_purchases_expiry_after_purchase check (expires_on is null or expires_on >= purchased_on),
  constraint package_purchases_purged_in_range check (sessions_used_purged between 0 and sessions_total)
);

comment on table public.package_purchases is
  'Package bought by a family. price_thb is a snapshot of PRICES in src/content/business.ts at purchase time (staff may enter a different agreed amount). expires_on is NULL unless the studio sets an expiry rule. Used = live credit-using bookings (booking_is_live: held, confirmed, attended, absent, cancelled_late; cancelled on time and cancelled_studio are not used) + sessions_used_purged (rounds two and three).';

create index if not exists package_purchases_family_idx on public.package_purchases (family_id);
create index if not exists package_purchases_status_idx on public.package_purchases (status);
create index if not exists package_purchases_retain_until_idx on public.package_purchases (retain_until);


-- -----------------------------------------------------------------------------
-- 7. payments — recorded manually by staff (D17). No card data, no bank account numbers.
-- -----------------------------------------------------------------------------

create table if not exists public.payments (
  id                    uuid primary key default gen_random_uuid(),
  family_id             uuid references public.families (id) on delete set null,
  package_purchase_id   uuid references public.package_purchases (id) on delete set null,
  amount_thb            integer not null check (amount_thb > 0),
  method                public.payment_method not null,
  status                public.payment_status not null default 'pending',
  paid_at               timestamptz,
  receipt_no            text check (receipt_no is null or char_length(btrim(receipt_no)) between 1 and 40),
  slip_path             text check (slip_path is null or slip_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|pdf)$'),
  note                  text check (note is null or char_length(note) <= 500),
  recorded_by           uuid references auth.users (id) on delete set null,
  verified_by           uuid references auth.users (id) on delete set null,
  verified_at           timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  retain_until          timestamptz not null default (now() + interval '6 years'),  -- overwritten by trigger
  constraint payments_receipt_no_key unique (receipt_no),
  constraint payments_paid_has_date check (status <> 'paid' or paid_at is not null),
  -- verified_by may later become NULL (staff user deleted), so only require: by → at.
  constraint payments_verified_has_date check (verified_by is null or verified_at is not null)
);

comment on table public.payments is
  'Payment recorded by staff. Lawful basis s.24(3) + s.24(6) accounting. Kept to 31 Dec of (payment year + 5) — accountant to confirm (G11). Anonymised (family_id NULL, note NULL) on erase.';
comment on column public.payments.slip_path is 'Optional object path in the private bucket payment-slips: <family_id>/<uuid>.<ext>.';
comment on column public.payments.note is 'Short staff note. Never bank account numbers.';

create index if not exists payments_family_idx on public.payments (family_id);
create index if not exists payments_status_idx on public.payments (status, created_at desc);
create index if not exists payments_paid_at_idx on public.payments (paid_at);
create index if not exists payments_package_purchase_idx on public.payments (package_purchase_id);
create index if not exists payments_retain_until_idx on public.payments (retain_until);


-- -----------------------------------------------------------------------------
-- 8. bookings — child × session seat, credit use and attendance
--    child_id / family_id become NULL when a family is erased (attendance stays as counts).
-- -----------------------------------------------------------------------------

create table if not exists public.bookings (
  id                         uuid primary key default gen_random_uuid(),
  session_id                 uuid not null references public.sessions (id) on delete restrict,
  child_id                   uuid references public.children (id) on delete set null,
  family_id                  uuid references public.families (id) on delete set null,
  package_purchase_id        uuid references public.package_purchases (id) on delete set null,
  consumes_credit            boolean not null default true,
  status                     public.booking_status not null default 'confirmed',
  checked_in_at              timestamptz,
  checked_out_at             timestamptz,
  picked_up_by_guardian_id   uuid references public.guardians (id) on delete set null,
  picked_up_by_contact_id    uuid references public.family_contacts (id) on delete set null,
  -- Round three (brief 6): the notice for a cancellation, recorded by staff through cancel_booking().
  -- channel: 'line' (LINE message), 'phone' (phone call), 'teacher' (told a teacher), 'in_person' (at the studio).
  -- cancel_notice_at = the time the notice reached the studio (the call time, the LINE message time, the time the
  -- teacher was told). Any channel counts. validate_booking() sets the status from it: on time -> 'cancelled';
  -- late -> 'cancelled_late'. No notice: cancel_booking() refuses a family cancellation, and validate_booking() turns
  -- a cancellation without notice into 'absent'. A studio cancellation has no notice ('cancelled_studio').
  cancel_notice_channel      public.notice_channel,
  cancel_notice_at           timestamptz,
  -- Round two: when the booking was cancelled (first time). Set by validate_booking(), never written by the server.
  cancelled_at               timestamptz,
  -- Round three (brief 7): optional link to the cancelled booking this rebooking replaces (same child). It is NOT a
  -- notice or status rule: the rebooking simply uses the kept or returned credit (validate_booking checks the balance).
  makeup_of_booking_id       uuid references public.bookings (id) on delete set null,
  staff_note                 text check (staff_note is null or char_length(staff_note) <= 500),
  created_by                 uuid references auth.users (id) on delete set null,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now(),
  retain_until               timestamptz not null default (now() + interval '24 months'),  -- overwritten by trigger
  constraint bookings_checkout_after_checkin
    check (checked_out_at is null or (checked_in_at is not null and checked_out_at >= checked_in_at)),
  constraint bookings_one_pickup_person
    check (picked_up_by_guardian_id is null or picked_up_by_contact_id is null),
  constraint bookings_notice_pair
    check ((cancel_notice_channel is null) = (cancel_notice_at is null))
);

comment on table public.bookings is
  'A child''s seat in a session. Live bookings (held, confirmed, attended, absent, cancelled_late; see booking_is_live) hold the seat and, with consumes_credit, count against package_purchases.sessions_total. cancelled (on time, credit kept) and cancelled_studio (credit returned) free the seat and use no credit. Kept 24 months after the session date.';

-- cancelled_late keeps its seat: it is a late cancellation, so the seat is not free for someone else.
-- Round three: the predicate is booking_is_live(status) (section 1b), so cancelled and cancelled_studio free the seat.
create unique index if not exists bookings_one_active_seat_per_child
  on public.bookings (session_id, child_id) where public.booking_is_live(status);
-- Round two (decision 10): one live rebooking per original booking. A second one gives 23505 (the server maps it to conflict).
create unique index if not exists bookings_one_makeup_per_original
  on public.bookings (makeup_of_booking_id) where makeup_of_booking_id is not null and public.booking_is_live(status);
create index if not exists bookings_session_idx on public.bookings (session_id);
create index if not exists bookings_child_idx on public.bookings (child_id);
create index if not exists bookings_family_idx on public.bookings (family_id);
create index if not exists bookings_package_purchase_idx on public.bookings (package_purchase_id);
create index if not exists bookings_retain_until_idx on public.bookings (retain_until);


-- -----------------------------------------------------------------------------
-- 8b. booking_cancellation_log — APPEND-ONLY, one row per cancellation event (round three, brief 2)
--     * Written only by cancel_booking() (section 19) and cancel_bookings_of_cancelled_session() (section 11), inside
--       the same transaction as the booking change. No insert grant for anyone else. erase_family (0007) writes no
--       cancellation row (verifier fix); it only detaches family_id from existing rows.
--     * outcome: 'family_on_time' (notice in time, credit kept), 'family_late' (late notice, seat kept, one
--       credit used), 'studio' (the studio cancelled the session, credit returned). No notice = absent, not a row.
--     * Reports count cancellations from THIS table, not from bookings (0008).
--     * No foreign keys on purpose: an FK action would UPDATE an append-only table. The ids stay as plain uuids.
--       family_id is NULL after the family is erased (erase_family). Rows are removed only by the purge (retain_until).
--     * Retention = 24 months after the session date, the same as bookings (set when the row is written).
--       PROVISIONAL: the owner has not yet ruled on this retention (00 § 12 and 50 § 19.1 list it as open).
-- -----------------------------------------------------------------------------

create table if not exists public.booking_cancellation_log (
  id              uuid primary key default gen_random_uuid(),
  booking_id      uuid not null,
  family_id       uuid,
  session_id      uuid not null,
  outcome         public.cancellation_outcome not null,
  notice_channel  public.notice_channel,
  notice_at       timestamptz,
  recorded_by     uuid,                                  -- staff user id (auth.uid()) for cancel_booking() and the studio path; NULL only if no staff user is in the session (not written by round three: erase writes no log row)
  recorded_at     timestamptz not null default clock_timestamp(),
  retain_until    timestamptz not null,
  constraint booking_cancellation_log_notice_pair
    check ((notice_channel is null) = (notice_at is null))
);

comment on table public.booking_cancellation_log is
  'Append-only cancellation statistics: one row per cancellation (family on time, family late, studio). UPDATE/DELETE blocked except inside purge/erase. Holds no names, phone numbers or health data.';
comment on column public.booking_cancellation_log.notice_at is
  'The time the notice reached the studio (phone call time, LINE message time, time the teacher was told). NULL when none was given.';

create index if not exists booking_cancellation_log_session_idx on public.booking_cancellation_log (session_id, outcome);
create index if not exists booking_cancellation_log_family_idx on public.booking_cancellation_log (family_id);
create index if not exists booking_cancellation_log_retain_until_idx on public.booking_cancellation_log (retain_until);


-- -----------------------------------------------------------------------------
-- 9. booking_requests.converted_family_id
-- -----------------------------------------------------------------------------

alter table public.booking_requests
  add column if not exists converted_family_id uuid references public.families (id) on delete set null;

create index if not exists booking_requests_converted_family_idx on public.booking_requests (converted_family_id);

grant update (converted_family_id) on table public.booking_requests to authenticated;


-- -----------------------------------------------------------------------------
-- 10. storage_cleanup_queue — files to delete through the Storage API
--     Supabase: deleting storage.objects rows with SQL orphans the file
--     (https://supabase.com/docs/guides/storage/management/delete-objects).
--     Triggers queue paths here; an owner-only server function removes the files with
--     supabaseAdmin.storage.from(bucket_id).remove([object_path]) and sets deleted_at.
-- -----------------------------------------------------------------------------

create table if not exists public.storage_cleanup_queue (
  id           bigint generated always as identity primary key,
  bucket_id    text not null check (bucket_id in ('payment-slips', 'consent-evidence')),
  object_path  text not null check (char_length(object_path) between 1 and 300),
  reason       text not null check (reason in ('row_deleted', 'replaced')),
  queued_at    timestamptz not null default now(),
  deleted_at   timestamptz,
  last_error   text check (last_error is null or char_length(last_error) <= 200),
  constraint storage_cleanup_queue_object_key unique (bucket_id, object_path)
);

comment on table public.storage_cleanup_queue is
  'Private files waiting to be deleted through the Storage API (SQL cannot delete storage files). Paths contain only uuids.';

create index if not exists storage_cleanup_queue_pending_idx on public.storage_cleanup_queue (queued_at) where deleted_at is null;

alter table public.storage_cleanup_queue enable row level security;
revoke all on table public.storage_cleanup_queue from anon, authenticated;
grant select on table public.storage_cleanup_queue to authenticated;
grant update (deleted_at, last_error) on table public.storage_cleanup_queue to authenticated;
grant all on table public.storage_cleanup_queue to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'storage_cleanup_queue' and policyname = 'storage_cleanup_queue_owner_select') then
    create policy "storage_cleanup_queue_owner_select" on public.storage_cleanup_queue
      for select to authenticated
      using ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'storage_cleanup_queue' and policyname = 'storage_cleanup_queue_owner_update') then
    create policy "storage_cleanup_queue_owner_update" on public.storage_cleanup_queue
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 11. Trigger functions for this phase
-- -----------------------------------------------------------------------------

-- BEFORE INSERT/UPDATE on package_purchases and payments:
-- retain_until = start of 1 Jan (Bangkok) after 31 Dec of (year + 5). Accountant to confirm (G11).
create or replace function public.set_accounting_retain_until()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_basis date;
begin
  if tg_table_name = 'package_purchases' then
    v_basis := new.purchased_on;
  else
    v_basis := (coalesce(new.paid_at, new.created_at, now()) at time zone 'Asia/Bangkok')::date;
  end if;
  new.retain_until :=
    ((make_date(extract(year from v_basis)::integer + 5, 12, 31) + 1)::timestamp at time zone 'Asia/Bangkok');
  return new;
end;
$$;

-- BEFORE INSERT/UPDATE on bookings: consistency checks + retain_until (session date + 24 months).
-- * child, package purchase and pickup person must belong to the booking's family
-- * a pickup contact must be an authorised pickup person
-- * a credit-consuming booking needs an ACTIVE package with sessions left (row-locked)
-- * family_id / child_id cannot be switched to ANOTHER family/child (cancel and book again);
--   they may only become NULL (family erased / FK ON DELETE SET NULL).
-- * round two (14 Oct 2026): the status of a cancellation comes from its notice. Notice at or before
--   (session start − studio_settings.cancel_notice_hours, default 3) -> 'cancelled' (credit kept). Later notice
--   -> 'cancelled_late' (one credit used). No notice at all -> 'absent' (one credit, not a cancellation; verifier fix,
--   round three). Any notice channel counts (round three).
-- * round three (14 Oct 2026): a cancellation is written only through cancel_booking(), the studio path
--   (cancel_bookings_of_cancelled_session), which set cherrylee.allow_cancel_log = 'on'. Any other
--   write that puts a booking into a cancelled status, or changes its notice, is refused (42501), so the
--   booking_cancellation_log can never miss a cancellation.
-- * round three: a rebooking (makeup_of_booking_id) needs only a booking of the same child; the balance check does the rest.
-- References are checked only on INSERT or when that column changes to a non-NULL value, so the
-- cascaded SET NULL updates Postgres makes while a family is being deleted never trip a check.
create or replace function public.validate_booking()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_date      date;
  v_session_start     timestamptz;
  v_notice_hours      integer;
  v_recompute         boolean := false;
  v_cancel_now        boolean := false;
  v_log_guard         boolean := false;
  v_total             smallint;
  v_purged            smallint;
  v_pp_status         public.package_purchase_status;
  v_used              integer;
  v_check_credit      boolean := false;
  v_check_package     boolean := false;
  v_check_guardian    boolean := false;
  v_check_contact     boolean := false;
begin
  select s.session_date, (s.session_date + s.starts_at) at time zone 'Asia/Bangkok'
    into v_session_date, v_session_start
    from public.sessions s where s.id = new.session_id;
  if v_session_date is null then
    raise exception 'Session not found' using errcode = '23503';
  end if;
  new.retain_until := ((v_session_date + interval '24 months') at time zone 'Asia/Bangkok');

  -- Round two (14 Oct 2026, brief item 1): the notice decides a cancellation. It is decided again only when the
  -- status or the notice changes, so an unrelated later edit (a staff note, the family-erase anonymising update)
  -- never flips a studio cancellation into a late one. Runs before the credit checks below.
  if tg_op = 'INSERT' then
    v_recompute := true;
  else
    v_recompute := new.status is distinct from old.status
                   or new.cancel_notice_at is distinct from old.cancel_notice_at
                   or new.cancel_notice_channel is distinct from old.cancel_notice_channel;
  end if;
  -- Round three: the log guard. A cancellation (or a change to a cancelled booking's notice) is allowed only while
  -- cancel_booking() or the studio path sets cherrylee.allow_cancel_log = 'on' (see the header).
  v_cancel_now := new.status in ('cancelled'::public.booking_status, 'cancelled_late'::public.booking_status,
                                 'cancelled_studio'::public.booking_status);
  if tg_op = 'INSERT' then
    v_log_guard := v_cancel_now;
  else
    v_log_guard := (v_cancel_now or old.status in ('cancelled'::public.booking_status,
                                                    'cancelled_late'::public.booking_status,
                                                    'cancelled_studio'::public.booking_status))
                   and (new.status is distinct from old.status
                        or new.cancel_notice_at is distinct from old.cancel_notice_at
                        or new.cancel_notice_channel is distinct from old.cancel_notice_channel);
  end if;
  if v_log_guard and coalesce(current_setting('cherrylee.allow_cancel_log', true), '') <> 'on' then
    raise exception 'A cancellation must be recorded with cancel_booking() (booking_cancellation_log)'
      using errcode = '42501';
  end if;

  -- Round three (brief 1, 2): the notice decides on-time (cancelled, credit kept) or late (cancelled_late, one credit).
  -- A studio cancellation (cancelled_studio) is never changed here.
  if v_recompute
     and new.status in ('cancelled'::public.booking_status, 'cancelled_late'::public.booking_status) then
    if new.cancel_notice_at is null then
      -- Verifier fix (14 Oct 2026): no notice is not a cancellation. It is the absent path: one credit used,
      -- no cancellation log row. cancel_booking() refuses a family cancellation without notice before this point.
      new.status := 'absent'::public.booking_status;
      new.cancel_notice_channel := null;
    else
      select st.cancel_notice_hours into v_notice_hours from public.studio_settings st where st.id;
      if new.cancel_notice_at <= v_session_start - make_interval(hours => coalesce(v_notice_hours, 3)) then
        new.status := 'cancelled'::public.booking_status;        -- notice on time (any channel): credit kept
      else
        new.status := 'cancelled_late'::public.booking_status;   -- late notice: one credit used
      end if;
    end if;
    -- Recompute the cancellation flag from the final status (the no-notice path ends as 'absent').
    v_cancel_now := new.status in ('cancelled'::public.booking_status, 'cancelled_late'::public.booking_status,
                                   'cancelled_studio'::public.booking_status);
  end if;

  -- Round two: cancelled_at is written here, so the server never sets it. Kept at the first cancellation.
  -- Round three: cancelled_studio counts too.
  if v_cancel_now then
    new.cancelled_at := coalesce(
      case when tg_op = 'UPDATE' and old.status in ('cancelled'::public.booking_status, 'cancelled_late'::public.booking_status,
                                                    'cancelled_studio'::public.booking_status)
           then old.cancelled_at end,
      new.cancelled_at,
      now());
  else
    new.cancelled_at := null;
  end if;

  -- Round three (brief 7): a rebooking uses the kept or returned credit. There is no notice check and no status
  -- check on the original (the round-two refusal that needed status 'cancelled' is removed). The link must name a
  -- booking of the same child; the credit check further down decides whether the family has a session left.
  if tg_op = 'INSERT' and new.makeup_of_booking_id is not null then
    if not exists (select 1 from public.bookings ob
                    where ob.id = new.makeup_of_booking_id
                      and ob.child_id = new.child_id) then
      raise exception 'A rebooking must replace a booking of the same child' using errcode = '23514';
    end if;
  end if;

  if tg_op = 'INSERT' then
    if new.child_id is null then
      raise exception 'child_id is required for a new booking' using errcode = '23502';
    end if;
    if new.family_id is null then
      select c.family_id into new.family_id from public.children c where c.id = new.child_id;
    end if;
    if not exists (select 1 from public.children c where c.id = new.child_id and c.family_id = new.family_id) then
      raise exception 'Child does not belong to this family' using errcode = '23514';
    end if;
    if new.consumes_credit and new.package_purchase_id is null then
      raise exception 'A credit-consuming booking needs package_purchase_id' using errcode = '23514';
    end if;
    v_check_package  := new.package_purchase_id is not null;
    v_check_guardian := new.picked_up_by_guardian_id is not null;
    v_check_contact  := new.picked_up_by_contact_id is not null;
    v_check_credit   := new.consumes_credit and public.booking_is_live(new.status) and new.package_purchase_id is not null;
  else
    if new.family_id is not null and new.family_id is distinct from old.family_id then
      raise exception 'A booking cannot move to another family' using errcode = '23514';
    end if;
    if new.child_id is not null and new.child_id is distinct from old.child_id then
      raise exception 'A booking cannot move to another child: cancel it and book again' using errcode = '23514';
    end if;
    v_check_package  := new.package_purchase_id is not null
                        and new.package_purchase_id is distinct from old.package_purchase_id;
    v_check_guardian := new.picked_up_by_guardian_id is not null
                        and new.picked_up_by_guardian_id is distinct from old.picked_up_by_guardian_id;
    v_check_contact  := new.picked_up_by_contact_id is not null
                        and new.picked_up_by_contact_id is distinct from old.picked_up_by_contact_id;
    -- Credit check only when a booking starts (or restarts) using a credit: it was not using one before
    -- (cancelled on time, cancelled_studio, or no credit), or it moves to another package.
    v_check_credit   := new.consumes_credit and public.booking_is_live(new.status) and new.package_purchase_id is not null
                        and (not (old.consumes_credit and public.booking_is_live(old.status))
                             or old.package_purchase_id is distinct from new.package_purchase_id);
  end if;

  if v_check_package
     and not exists (select 1 from public.package_purchases pp
                     where pp.id = new.package_purchase_id and pp.family_id = new.family_id) then
    raise exception 'Package does not belong to this family' using errcode = '23514';
  end if;

  if v_check_guardian
     and not exists (select 1 from public.guardians g
                     where g.id = new.picked_up_by_guardian_id and g.family_id = new.family_id) then
    raise exception 'Pickup guardian does not belong to this family' using errcode = '23514';
  end if;

  if v_check_contact
     and not exists (select 1 from public.family_contacts fc
                     where fc.id = new.picked_up_by_contact_id
                       and fc.family_id = new.family_id
                       and fc.is_authorised_pickup
                       and fc.is_active) then
    raise exception 'Pickup contact is not an authorised pickup person of this family' using errcode = '23514';
  end if;

  if v_check_credit then
    select pp.sessions_total, pp.sessions_used_purged, pp.status
      into v_total, v_purged, v_pp_status
      from public.package_purchases pp
     where pp.id = new.package_purchase_id
       for update;
    if v_pp_status is distinct from 'active'::public.package_purchase_status then
      raise exception 'Package is not active' using errcode = '23514';
    end if;
    select count(*) into v_used
      from public.bookings b
     where b.package_purchase_id = new.package_purchase_id
       and b.consumes_credit
       and public.booking_is_live(b.status)
       and b.id <> new.id;
    -- Review R-10: credits used by bookings the retention purge already deleted still count.
    if v_used + coalesce(v_purged, 0) >= v_total then
      raise exception 'No sessions left on this package' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

-- AFTER INSERT/UPDATE/DELETE on bookings: children.last_session_on = latest attended session date.
create or replace function public.sync_child_last_session()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_child_ids uuid[];
begin
  if tg_op = 'INSERT' then
    v_child_ids := array[new.child_id];
  elsif tg_op = 'UPDATE' then
    v_child_ids := array[new.child_id, old.child_id];
  else
    v_child_ids := array[old.child_id];
  end if;

  update public.children c
     set last_session_on = (
       select max(s.session_date)
         from public.bookings b
         join public.sessions s on s.id = b.session_id
        where b.child_id = c.id
          and b.status = 'attended'::public.booking_status
     )
   where c.id = any (v_child_ids)
     and c.last_session_on is distinct from (
       select max(s.session_date)
         from public.bookings b
         join public.sessions s on s.id = b.session_id
        where b.child_id = c.id
          and b.status = 'attended'::public.booking_status
     );
  return null;
end;
$$;

-- AFTER UPDATE OF slip_path / AFTER DELETE on payments (and AFTER DELETE on consent_records, 0005):
-- queue the old file for deletion through the Storage API.
create or replace function public.queue_storage_cleanup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bucket text;
  v_path   text;
  v_reason text;
begin
  if tg_table_name = 'payments' then
    v_bucket := 'payment-slips';
    if tg_op = 'DELETE' then
      v_path := old.slip_path;
      v_reason := 'row_deleted';
    elsif tg_op = 'UPDATE' then
      if old.slip_path is not null and old.slip_path is distinct from new.slip_path then
        v_path := old.slip_path;
        v_reason := 'replaced';
      end if;
    end if;
  elsif tg_table_name in ('consent_records', 'guardian_consent_records') then
    v_bucket := 'consent-evidence';
    if tg_op = 'DELETE' then
      v_path := old.evidence_path;
      v_reason := 'row_deleted';
    end if;
  end if;

  if v_path is not null then
    insert into public.storage_cleanup_queue (bucket_id, object_path, reason)
    values (v_bucket, v_path, v_reason)
    on conflict (bucket_id, object_path) do nothing;
  end if;
  return null;
end;
$$;

-- BEFORE INSERT OR UPDATE on package_purchases: sessions_used_purged belongs to the nightly purge only
-- (review R-10). Staff can't create a package with "already used" credits or change the counter.
create or replace function public.guard_package_purge_counter()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('cherrylee.allow_purge', true), '') = 'on' then
    return new;
  end if;
  if tg_op = 'INSERT' and new.sessions_used_purged <> 0 then
    raise exception 'sessions_used_purged is maintained by the nightly purge only' using errcode = '42501';
  end if;
  if tg_op = 'UPDATE' and new.sessions_used_purged is distinct from old.sessions_used_purged then
    raise exception 'sessions_used_purged is maintained by the nightly purge only' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- AFTER UPDATE OF status on sessions: cancelling a class day cancels its held/confirmed bookings, so
-- their credits return and nobody stays "booked" on a cancelled day (review R-23). The admin warns first.
create or replace function public.cancel_bookings_of_cancelled_session()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'cancelled'::public.session_status
     and old.status is distinct from 'cancelled'::public.session_status then
    -- Round three (brief 1, 2): a studio cancellation returns the credit ('cancelled_studio': not used, no notice).
    -- Each affected seat gets one booking_cancellation_log row, outcome 'studio'. The log row is written first, from
    -- the same rows the update is about to change, in this transaction.
    perform set_config('cherrylee.allow_cancel_log', 'on', true);
    insert into public.booking_cancellation_log
      (booking_id, family_id, session_id, outcome, recorded_by, retain_until)
    select b.id, b.family_id, b.session_id, 'studio'::public.cancellation_outcome, auth.uid(),
           ((new.session_date + interval '24 months') at time zone 'Asia/Bangkok')
      from public.bookings b
     where b.session_id = new.id
       and b.status in ('held'::public.booking_status, 'confirmed'::public.booking_status);
    update public.bookings b
       set status = 'cancelled_studio'::public.booking_status
     where b.session_id = new.id
       and b.status in ('held'::public.booking_status, 'confirmed'::public.booking_status);
    perform set_config('cherrylee.allow_cancel_log', 'off', true);
  end if;
  return null;
end;
$$;

revoke execute on function public.set_accounting_retain_until() from public, anon, authenticated;
revoke execute on function public.validate_booking() from public, anon, authenticated;
revoke execute on function public.sync_child_last_session() from public, anon, authenticated;
revoke execute on function public.queue_storage_cleanup() from public, anon, authenticated;
revoke execute on function public.guard_package_purge_counter() from public, anon, authenticated;
revoke execute on function public.cancel_bookings_of_cancelled_session() from public, anon, authenticated;


-- -----------------------------------------------------------------------------
-- 12. Triggers
-- -----------------------------------------------------------------------------

create or replace trigger families_set_updated_at
  before update on public.families for each row execute function public.set_updated_at();
create or replace trigger guardians_set_updated_at
  before update on public.guardians for each row execute function public.set_updated_at();
create or replace trigger children_set_updated_at
  before update on public.children for each row execute function public.set_updated_at();
create or replace trigger family_contacts_set_updated_at
  before update on public.family_contacts for each row execute function public.set_updated_at();
create or replace trigger package_purchases_set_updated_at
  before update on public.package_purchases for each row execute function public.set_updated_at();
create or replace trigger payments_set_updated_at
  before update on public.payments for each row execute function public.set_updated_at();
create or replace trigger bookings_set_updated_at
  before update on public.bookings for each row execute function public.set_updated_at();

create or replace trigger package_purchases_retain_until
  before insert or update of purchased_on on public.package_purchases
  for each row execute function public.set_accounting_retain_until();
create or replace trigger package_purchases_guard_purge_counter
  before insert or update on public.package_purchases
  for each row execute function public.guard_package_purge_counter();
create or replace trigger sessions_cancel_bookings
  after update of status on public.sessions
  for each row execute function public.cancel_bookings_of_cancelled_session();
create or replace trigger payments_retain_until
  before insert or update of paid_at on public.payments
  for each row execute function public.set_accounting_retain_until();

create or replace trigger bookings_validate
  before insert or update on public.bookings
  for each row execute function public.validate_booking();
create or replace trigger bookings_sync_child_last_session
  after insert or update of status, session_id, child_id or delete on public.bookings
  for each row execute function public.sync_child_last_session();

create or replace trigger payments_queue_storage_cleanup
  after update of slip_path or delete on public.payments
  for each row execute function public.queue_storage_cleanup();

create or replace trigger families_audit
  after insert or update or delete on public.families for each row execute function public.audit_row_change();
create or replace trigger guardians_audit
  after insert or update or delete on public.guardians for each row execute function public.audit_row_change();
create or replace trigger children_audit
  after insert or update or delete on public.children for each row execute function public.audit_row_change();
create or replace trigger family_contacts_audit
  after insert or update or delete on public.family_contacts for each row execute function public.audit_row_change();
create or replace trigger package_purchases_audit
  after insert or update or delete on public.package_purchases for each row execute function public.audit_row_change();
create or replace trigger payments_audit
  after insert or update or delete on public.payments for each row execute function public.audit_row_change();
create or replace trigger bookings_audit
  after insert or update or delete on public.bookings for each row execute function public.audit_row_change();


-- -----------------------------------------------------------------------------
-- 13. package_balances view (security_invoker: RLS of the caller applies)
-- -----------------------------------------------------------------------------

create or replace view public.package_balances
with (security_invoker = true)
as
select
  pp.id                                                                                   as package_purchase_id,
  pp.family_id,
  pp.package_code,
  pp.status,
  pp.purchased_on,
  pp.expires_on,
  pp.sessions_total::integer                                                              as sessions_total,
  (pp.sessions_used_purged
   + count(b.id) filter (where b.consumes_credit and public.booking_is_live(b.status)))::integer   as sessions_used,
  (pp.sessions_total - pp.sessions_used_purged
   - count(b.id) filter (where b.consumes_credit and public.booking_is_live(b.status)))::integer   as sessions_left
from public.package_purchases pp
left join public.bookings b on b.package_purchase_id = pp.id
group by pp.id;

comment on view public.package_balances is
  'Sessions left per package purchase = sessions_total − sessions_used_purged − live credit-consuming bookings (booking_is_live: held, confirmed, attended, absent, cancelled_late). cancelled (on time) and cancelled_studio (credit returned) do not use a credit.';

revoke all on table public.package_balances from anon, authenticated;
grant select on table public.package_balances to authenticated;
grant select on table public.package_balances to service_role;


-- -----------------------------------------------------------------------------
-- 14. session_seats_left v2 — also subtracts bookings that hold a seat
-- -----------------------------------------------------------------------------

create or replace function public.session_seats_left(p_session_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_left integer;
begin
  perform public.require_staff_or_server();
  select case
           when s.capacity is null then null
           else greatest(
             s.capacity
             - s.seats_held_offline
             - (select count(*)::integer
                  from public.bookings b
                 where b.session_id = s.id
                   and public.booking_is_live(b.status)),
             0)
         end
    into v_left
    from public.sessions s
   where s.id = p_session_id;
  return v_left;
end;
$$;

-- get_sessions_with_seats v2 — same signature as 0003, now with the real booked count.
create or replace function public.get_sessions_with_seats(p_from date, p_to date)
returns table (
  session_id          uuid,
  session_date        date,
  starts_at           time,
  ends_at             time,
  capacity            integer,
  seats_held_offline  integer,
  status              public.session_status,
  public_note_th      text,
  public_note_en      text,
  staff_note          text,
  seats_left          integer,
  booked              integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  select s.id, s.session_date, s.starts_at, s.ends_at, s.capacity, s.seats_held_offline, s.status,
         s.public_note_th, s.public_note_en, s.staff_note,
         public.session_seats_left(s.id),
         (select count(*)::integer
            from public.bookings b
           where b.session_id = s.id
             and public.booking_is_live(b.status))
    from public.sessions s
   where s.session_date between p_from and p_to
   order by s.session_date, s.starts_at;
$$;


-- -----------------------------------------------------------------------------
-- 14b. create_family_from_request(...) — "convert to family" in ONE transaction (review R-15).
--      SECURITY INVOKER: runs as the staff user, so RLS and the audit triggers apply as usual.
--      p_guardian = {"full_name": text, "phone": text|null, "line_id": text|null}
--      p_children = [{"nickname": text, "age_years": 6..12|null}, …] (1–6 items; age comes from the
--                   request row the staff member is looking at, passed per child — never matched by index)
--      Returns the new family id. Raises 23514 'Request already converted' or P0002 'Request not found'.
-- -----------------------------------------------------------------------------

create or replace function public.create_family_from_request(
  p_request_id    uuid,
  p_display_name  text,
  p_guardian      jsonb,
  p_children      jsonb
)
returns uuid
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_req        record;
  v_family_id  uuid;
  v_child      jsonb;
  v_today      date := (now() at time zone 'Asia/Bangkok')::date;
  v_age        smallint;
begin
  perform public.require_staff_or_server();
  if p_children is null or jsonb_typeof(p_children) <> 'array'
     or jsonb_array_length(p_children) not between 1 and 6 then
    raise exception 'p_children must be an array of 1–6 children' using errcode = '22023';
  end if;

  select br.id, br.status, br.lang
    into v_req
    from public.booking_requests br
   where br.id = p_request_id
     for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if v_req.status = 'converted'::public.booking_request_status then
    raise exception 'Request already converted' using errcode = '23514';
  end if;

  insert into public.families (display_name, preferred_lang, source_request_id, created_by)
  values (p_display_name, v_req.lang, p_request_id, auth.uid())
  returning id into v_family_id;

  insert into public.guardians (family_id, full_name, phone, line_id, is_primary)
  values (v_family_id,
          p_guardian ->> 'full_name',
          nullif(p_guardian ->> 'phone', ''),
          nullif(p_guardian ->> 'line_id', ''),
          true);

  for v_child in select value from jsonb_array_elements(p_children) loop
    v_age := nullif(v_child ->> 'age_years', '')::smallint;
    -- Verifier fix (14 Oct 2026): children.nickname is NOT NULL. A child with no nickname is refused here with a
    -- clear error, not a raw not-null error. The enrolment and booking forms still say the nickname is optional, so
    -- a family can reach this error. Whether the nickname is required on intake or a fallback applies is OPEN
    -- (owner question a; 00 § 13B). The owner must decide before G4 · 0004; the forms, zod and this check then agree.
    if nullif(btrim(v_child ->> 'nickname'), '') is null then
      raise exception 'Each child needs a nickname before the family can be created' using errcode = '22023';
    end if;
    insert into public.children (family_id, nickname, reported_age_years, reported_age_on)
    values (v_family_id,
            v_child ->> 'nickname',
            v_age,
            case when v_age is null then null else v_today end);
  end loop;

  update public.booking_requests br
     set status = 'converted'::public.booking_request_status,
         converted_family_id = v_family_id,
         handled_by = auth.uid()
   where br.id = p_request_id;

  return v_family_id;
end;
$$;

revoke execute on function public.create_family_from_request(uuid, text, jsonb, jsonb) from public, anon;
grant execute on function public.create_family_from_request(uuid, text, jsonb, jsonb) to authenticated;


-- -----------------------------------------------------------------------------
-- 14c. set_primary_guardian(p_guardian_id) — make one guardian the family's primary in ONE transaction (R-39).
--      saveGuardian first writes the guardian's plain fields (a new guardian with is_primary = false), then calls
--      this. If this call fails, the old primary stays, so a family is never left without a primary guardian
--      (submit_enrolment in 0005 needs one). Two UPDATE statements, because the partial unique index
--      guardians_one_primary_per_family is checked row by row. SECURITY INVOKER: RLS, the audit trigger and the
--      restriction guard (0007) apply as for any staff write. Raises P0002 'Guardian not found'.
-- -----------------------------------------------------------------------------

create or replace function public.set_primary_guardian(p_guardian_id uuid)
returns void
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_family_id uuid;
begin
  perform public.require_staff_or_server();
  select g.family_id into v_family_id
    from public.guardians g
   where g.id = p_guardian_id;
  if v_family_id is null then
    raise exception 'Guardian not found' using errcode = 'P0002';
  end if;
  update public.guardians g
     set is_primary = false
   where g.family_id = v_family_id
     and g.is_primary
     and g.id <> p_guardian_id;
  update public.guardians g
     set is_primary = true
   where g.id = p_guardian_id
     and not g.is_primary;
end;
$$;

revoke execute on function public.set_primary_guardian(uuid) from public, anon;
grant execute on function public.set_primary_guardian(uuid) to authenticated;


-- -----------------------------------------------------------------------------
-- 15. RLS: families, guardians, children, family_contacts, package_purchases, payments, bookings
-- -----------------------------------------------------------------------------

alter table public.families enable row level security;
alter table public.guardians enable row level security;
alter table public.children enable row level security;
alter table public.family_contacts enable row level security;
alter table public.package_purchases enable row level security;
alter table public.payments enable row level security;
alter table public.bookings enable row level security;

revoke all on table public.families, public.guardians, public.children, public.family_contacts,
                    public.package_purchases, public.payments, public.bookings
  from anon, authenticated;
grant select, insert, update, delete on table public.families, public.guardians, public.children,
                    public.family_contacts, public.package_purchases, public.payments, public.bookings
  to authenticated;
grant all on table public.families, public.guardians, public.children, public.family_contacts,
                   public.package_purchases, public.payments, public.bookings
  to service_role;

do $$
declare
  v_table text;
begin
  -- Same pattern for the four profile tables: staff select/insert/update, owner delete.
  -- (family_contacts: staff may also delete — deleteFamilyContact.)
  foreach v_table in array array['families', 'guardians', 'children', 'family_contacts'] loop
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_staff_select') then
      execute format('create policy %I on public.%I for select to authenticated using ((select public.is_staff()))',
                     v_table || '_staff_select', v_table);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_staff_insert') then
      execute format('create policy %I on public.%I for insert to authenticated with check ((select public.is_staff()))',
                     v_table || '_staff_insert', v_table);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = v_table and policyname = v_table || '_staff_update') then
      execute format('create policy %I on public.%I for update to authenticated using ((select public.is_staff())) with check ((select public.is_staff()))',
                     v_table || '_staff_update', v_table);
    end if;
  end loop;

  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'families' and policyname = 'families_owner_delete') then
    create policy "families_owner_delete" on public.families
      for delete to authenticated using ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'guardians' and policyname = 'guardians_owner_delete') then
    create policy "guardians_owner_delete" on public.guardians
      for delete to authenticated using ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'children' and policyname = 'children_owner_delete') then
    create policy "children_owner_delete" on public.children
      for delete to authenticated using ((select public.is_owner()));
  end if;
  -- R-39: staff never hard-delete a contact (soft delete keeps who collected a child, R-22); like the other
  -- family tables only the owner may delete, and erase_family runs as SECURITY DEFINER anyway.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'family_contacts' and policyname = 'family_contacts_owner_delete') then
    create policy "family_contacts_owner_delete" on public.family_contacts
      for delete to authenticated using ((select public.is_owner()));
  end if;

  -- package_purchases: staff work with active/closed; only the owner can void or delete.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'package_purchases' and policyname = 'package_purchases_staff_select') then
    create policy "package_purchases_staff_select" on public.package_purchases
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'package_purchases' and policyname = 'package_purchases_staff_insert') then
    create policy "package_purchases_staff_insert" on public.package_purchases
      for insert to authenticated
      with check ((select public.is_staff()) and status in ('active'::public.package_purchase_status, 'closed'::public.package_purchase_status));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'package_purchases' and policyname = 'package_purchases_staff_update') then
    create policy "package_purchases_staff_update" on public.package_purchases
      for update to authenticated
      using ((select public.is_staff()) and status in ('active'::public.package_purchase_status, 'closed'::public.package_purchase_status))
      with check ((select public.is_staff()) and status in ('active'::public.package_purchase_status, 'closed'::public.package_purchase_status));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'package_purchases' and policyname = 'package_purchases_owner_update') then
    create policy "package_purchases_owner_update" on public.package_purchases
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'package_purchases' and policyname = 'package_purchases_owner_delete') then
    create policy "package_purchases_owner_delete" on public.package_purchases
      for delete to authenticated using ((select public.is_owner()));
  end if;

  -- payments: staff create and mark pending/paid; only the owner can refund, void or delete.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'payments' and policyname = 'payments_staff_select') then
    create policy "payments_staff_select" on public.payments
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'payments' and policyname = 'payments_staff_insert') then
    create policy "payments_staff_insert" on public.payments
      for insert to authenticated
      with check ((select public.is_staff()) and status in ('pending'::public.payment_status, 'paid'::public.payment_status));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'payments' and policyname = 'payments_staff_update') then
    create policy "payments_staff_update" on public.payments
      for update to authenticated
      using ((select public.is_staff()) and status in ('pending'::public.payment_status, 'paid'::public.payment_status))
      with check ((select public.is_staff()) and status in ('pending'::public.payment_status, 'paid'::public.payment_status));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'payments' and policyname = 'payments_owner_update') then
    create policy "payments_owner_update" on public.payments
      for update to authenticated
      using ((select public.is_owner()))
      with check ((select public.is_owner()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'payments' and policyname = 'payments_owner_delete') then
    create policy "payments_owner_delete" on public.payments
      for delete to authenticated using ((select public.is_owner()));
  end if;

  -- bookings: staff select/insert/update. Round three: a cancellation goes through cancel_booking() (section 19), which
  -- also writes booking_cancellation_log; a direct edit that cancels a booking is refused by validate_booking (42501).
  -- Attendance (attended / absent / check-in / check-out) stays a plain staff update. Owner delete.
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bookings' and policyname = 'bookings_staff_select') then
    create policy "bookings_staff_select" on public.bookings
      for select to authenticated using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bookings' and policyname = 'bookings_staff_insert') then
    create policy "bookings_staff_insert" on public.bookings
      for insert to authenticated with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bookings' and policyname = 'bookings_staff_update') then
    create policy "bookings_staff_update" on public.bookings
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bookings' and policyname = 'bookings_owner_delete') then
    create policy "bookings_owner_delete" on public.bookings
      for delete to authenticated using ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 16. Private bucket payment-slips (≤ 5 MB; jpeg/png/webp/pdf) + storage.objects policies
--     Path: <family_id>/<uuid>.<ext>. Staff upload and view (60-second signed URLs);
--     only the owner deletes. No update (never overwrite a slip; upload a new object).
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('payment-slips', 'payment-slips', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'payment_slips_staff_select') then
    create policy "payment_slips_staff_select" on storage.objects
      for select to authenticated
      using (bucket_id = 'payment-slips' and (select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'payment_slips_staff_insert') then
    create policy "payment_slips_staff_insert" on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'payment-slips'
        and (select public.is_staff())
        and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
      );
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'payment_slips_owner_delete') then
    create policy "payment_slips_owner_delete" on storage.objects
      for delete to authenticated
      using (bucket_id = 'payment-slips' and (select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 17. purge_expired_records() — v2 (full re-declaration; adds bookings, payments,
--     package_purchases, storage_cleanup_queue). Family deletion arrives in v4 (0007).
-- -----------------------------------------------------------------------------

create or replace function public.purge_expired_records()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_counts jsonb := jsonb_build_object('version', 2);
  v_n      bigint;
begin
  -- The flag lets this function maintain package_purchases.sessions_used_purged (guard trigger).
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

  -- Attendance before money: bookings (24 months) are always younger than packages (5 years).
  -- Review R-10: first remember how many credits the expiring bookings used, so balances stay right.
  update public.package_purchases pp
     set sessions_used_purged = least(pp.sessions_total, pp.sessions_used_purged + x.n)
    from (select b.package_purchase_id, count(*)::smallint as n
            from public.bookings b
           where b.retain_until < now()
             and b.consumes_credit
             and public.booking_is_live(b.status)
             and b.package_purchase_id is not null
           group by b.package_purchase_id) as x
   where pp.id = x.package_purchase_id;

  delete from public.bookings where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('bookings', v_n);

  delete from public.payments where retain_until < now();          -- slips get queued by trigger
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('payments', v_n);

  delete from public.package_purchases where retain_until < now();
  get diagnostics v_n = row_count;
  v_counts := v_counts || jsonb_build_object('package_purchases', v_n);

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
-- 18. Decision 10 (14 Oct 2026) and round three: cancel_notice_hours. Round three (brief 7): the separate make-up
--     notice check is REMOVED. A rebooking uses the kept or returned credit, so there is no notice check for it.
--     Packages never expire; siblings may share a package (owner Q4, still open). Credit rule: see validate_booking()
--     and the booking_is_live helper (section 1b). cancel_notice_hours (default 3) decides on-time vs late for every
--     family cancellation (validate_booking). The studio_settings table is the single-row settings table from 0001:
--     the key is a column here, so it is additive (no edit to 0001).
-- -----------------------------------------------------------------------------

alter table public.studio_settings
  add column if not exists cancel_notice_hours integer not null default 3;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'studio_settings_cancel_notice_hours_range') then
    alter table public.studio_settings
      add constraint studio_settings_cancel_notice_hours_range
      check (cancel_notice_hours between 0 and 72);
  end if;
end
$$;

comment on column public.studio_settings.cancel_notice_hours is
  'Hours of notice before the session starts that keep the credit: a family cancellation at or before (start − this many hours) is on time (status cancelled); later or no notice is cancelled_late (one credit used). Owner sets it; default 3; 0–72. Round three: applies to every family cancellation, any channel.';

-- Only the owner changes it (the existing owner update policy applies; column grant added here).
grant update (cancel_notice_hours) on table public.studio_settings to authenticated;

-- Round three (brief 7): check_make_up_notice(session, notice time) is REMOVED. It existed only for the round-one
-- make-up rule (the original had to be 'cancelled' with notice). A rebooking now uses the kept or returned credit,
-- and validate_booking() checks the balance. The drop keeps a re-run from leaving the old function behind.
drop function if exists public.check_make_up_notice(uuid, timestamptz);


-- -----------------------------------------------------------------------------
-- 19. Cancellations (round three, 14 Oct 2026; brief items 1, 2, 6, 7).
--     cancel_booking() is how staff cancel one seat. It is the only path for a family cancellation, so every one is
--     logged (booking_cancellation_log, section 8b). The studio path (cancel_bookings_of_cancelled_session, section 11)
--     writes its own log rows. erase_family (0007) writes none.
--     * p_studio = false (family): the notice (p_notice_channel + p_notice_at, any of the four channels) is REQUIRED.
--         at or before (session start − cancel_notice_hours) → 'cancelled' (credit kept)  → outcome family_on_time
--         later                                               → 'cancelled_late' (seat kept, one credit) → outcome family_late
--         no notice                                           → refused (22023). Record a missed class as 'absent'
--                                                              (one credit, no log row). Verifier fix, 14 Oct 2026.
--       validate_booking() makes the on-time / late decision; this function reads the final status and writes the log row.
--     * p_studio = true (studio, one seat): 'cancelled_studio' (credit returned). No notice allowed → outcome studio.
--     * Only a held or confirmed booking can be cancelled (attended and absent cannot: 23514).
--     * A booking can be cancelled once. To rebook, insert a NEW booking (the kept or returned credit pays for it).
--     * Returns the outcome. Staff or server only (require_staff_or_server); the log row is written in the same transaction.
-- -----------------------------------------------------------------------------

create or replace function public.cancel_booking(
  p_booking_id      uuid,
  p_notice_channel  public.notice_channel,
  p_notice_at       timestamptz,
  p_studio          boolean
)
returns public.cancellation_outcome
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_booking       public.bookings%rowtype;
  v_session_date  date;
  v_outcome       public.cancellation_outcome;
begin
  perform public.require_staff_or_server();
  if p_studio is null then
    raise exception 'studio must be true or false' using errcode = '22004';
  end if;
  if p_studio and (p_notice_channel is not null or p_notice_at is not null) then
    raise exception 'A studio cancellation has no notice' using errcode = '22023';
  end if;

  select b.* into v_booking from public.bookings b where b.id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found' using errcode = 'P0002';
  end if;
  if v_booking.status in ('cancelled'::public.booking_status, 'cancelled_late'::public.booking_status,
                          'cancelled_studio'::public.booking_status) then
    raise exception 'Booking is already cancelled' using errcode = '23514';
  end if;
  -- Verifier fix (14 Oct 2026): only a held or confirmed seat can be cancelled. An attended or absent booking
  -- would otherwise turn into a cancellation (credit returned, cancellation counted).
  if v_booking.status not in ('held'::public.booking_status, 'confirmed'::public.booking_status) then
    raise exception 'Only a held or confirmed booking can be cancelled (attended and absent cannot)' using errcode = '23514';
  end if;
  -- Verifier fix (14 Oct 2026): a family cancellation needs notice. Without it the booking is not cancelled:
  -- staff record it as absent (one credit, no log row).
  if not p_studio and (p_notice_channel is null or p_notice_at is null) then
    raise exception 'A family cancellation needs a notice channel and time. Record a missed class as absent.' using errcode = '22023';
  end if;

  select s.session_date into v_session_date from public.sessions s where s.id = v_booking.session_id;

  perform set_config('cherrylee.allow_cancel_log', 'on', true);
  update public.bookings b
     set status = case when p_studio then 'cancelled_studio'::public.booking_status
                       else 'cancelled'::public.booking_status end,
         cancel_notice_channel = case when p_studio then null else p_notice_channel end,
         cancel_notice_at      = case when p_studio then null else p_notice_at end
   where b.id = p_booking_id
  returning b.* into v_booking;
  perform set_config('cherrylee.allow_cancel_log', 'off', true);

  -- The status is final here (validate_booking may have made a 'cancelled' into 'cancelled_late').
  v_outcome := case
    when v_booking.status = 'cancelled_studio'::public.booking_status then 'studio'::public.cancellation_outcome
    when v_booking.status = 'cancelled'::public.booking_status then 'family_on_time'::public.cancellation_outcome
    else 'family_late'::public.cancellation_outcome
  end;

  insert into public.booking_cancellation_log
    (booking_id, family_id, session_id, outcome, notice_channel, notice_at, recorded_by, retain_until)
  values
    (v_booking.id, v_booking.family_id, v_booking.session_id, v_outcome,
     v_booking.cancel_notice_channel, v_booking.cancel_notice_at, auth.uid(),
     ((v_session_date + interval '24 months') at time zone 'Asia/Bangkok'));

  return v_outcome;
end;
$$;

-- Append-only guards and audit for the cancellation log (the only bypass is the purge / erase flag).
create or replace trigger booking_cancellation_log_append_only
  before update or delete on public.booking_cancellation_log
  for each row execute function public.prevent_update_delete();
create or replace trigger booking_cancellation_log_audit
  after insert or update or delete on public.booking_cancellation_log
  for each row execute function public.audit_row_change();

-- RLS: staff read; nobody inserts directly (the cancel functions do, as owner); no update, no delete, anon nothing.
alter table public.booking_cancellation_log enable row level security;
revoke all on table public.booking_cancellation_log from anon, authenticated, service_role;
grant select on table public.booking_cancellation_log to authenticated, service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
                 and tablename = 'booking_cancellation_log' and policyname = 'booking_cancellation_log_staff_select') then
    create policy "booking_cancellation_log_staff_select" on public.booking_cancellation_log
      for select to authenticated using ((select public.is_staff()));
  end if;
end
$$;
-- No INSERT, UPDATE or DELETE policy and no such grant: append-only, written by cancel_booking() and the studio path.

revoke execute on function public.cancel_booking(uuid, public.notice_channel, timestamptz, boolean) from public, anon;
grant execute on function public.cancel_booking(uuid, public.notice_channel, timestamptz, boolean) to authenticated, service_role;

-- End of 0004_families.sql
