# 10 · Data model: CherryLee & Co.

Planning document, October 2026. **Nothing here is live.** The SQL files in [`sql/`](sql/) are drafts that a human
applies through Lovable chat (gate **G4**), one file per phase, in order. Names follow
[`00-overview.md`](00-overview.md) § 10. If this file and `00-overview.md` disagree, `00-overview.md` wins, except
for the documented deviations in § 14.

Not legal advice. Retention periods are proposals (00-overview § 12), and the children-10+ approach (D11) and the
consent wording need a Thai PDPA lawyer (G9b).

**October 2026 review:** the fixes listed in `00-overview.md` § 15 (R-xx) are applied here and in the SQL drafts. Where
an entry below says "(R-xx)", that resolution is the reason for the column or function.

---

## Contents

1. [Files and order](#1-files-and-order)
2. [How migrations get applied (G4) and rules for implementers](#2-how-migrations-get-applied-g4-and-rules-for-implementers)
3. [ER overview](#3-er-overview)
4. [Conventions used in every file](#4-conventions-used-in-every-file)
5. [Enums](#5-enums)
6. [Tables](#6-tables)
7. [Views](#7-views)
8. [Database functions](#8-database-functions)
9. [Triggers](#9-triggers)
10. [Storage buckets](#10-storage-buckets)
11. [RLS matrix (role × table × operation)](#11-rls-matrix)
12. [Data inventory (field → purpose → lawful basis → retention → access)](#12-data-inventory)
13. [Retention and the nightly purge](#13-retention-and-the-nightly-purge)
14. [Deviations from 00-overview and new names](#14-deviations-from-00-overview-and-new-names)
15. [TypeScript types](#15-typescript-types)
16. [Error codes raised by the database](#16-error-codes-raised-by-the-database)
17. [Testing the database](#17-testing-the-database)
18. [Open questions](#18-open-questions)

---

## 1. Files and order

Apply **in this order**, one file per G4 gate. Each file says at the top what it depends on.

| # | File | Phase · feature | Creates | Gate(s) |
|---|---|---|---|---|
| 1 | `sql/0001_foundation.sql` | P0 · F0-05 | enums `app_role`, `site_lang`; tables `user_roles`, `audit_log`, `studio_settings` (1 row); functions `has_role`, `is_staff`, `is_owner`, `current_app_role`, `require_staff_or_server`, `require_owner_or_server`, `set_updated_at`, `prevent_update_delete`, `log_audit_event`, `audit_row_change`, `prevent_last_owner_removal` | G1–G3 done → **G4** → G5 |
| 2 | `sql/0002_booking_requests.sql` | P1 · F1-01 | 6 enums; `booking_requests` (D26 contact rule), `rate_limit_events`, `staff_notifications`; `is_valid_request_children`, `check_rate_limit`, `purge_expired_records` v1; pg_cron jobs `purge-expired-records`, `cron-history-cleanup` (fallback route if refused, R-19) | **G4** |
| 3 | `sql/0003_sessions.sql` | P2 · F2-01 | `session_status`; `sessions`; `booking_requests.session_id`; `session_seats_left` v1 (staff/server only), `get_sessions_with_seats` v1, `get_open_sessions`, `generate_weekend_sessions` | **G4** |
| 4 | `sql/0004_families.sql` | P3 · F3-01 | 6 enums; `families`, `guardians` (+`pending_link_changes`), `children` (+`allergy_check_needed_at`), `family_contacts` (+`is_active`), `package_purchases` (+`sessions_used_purged`), `payments`, `bookings`, `storage_cleanup_queue`; view `package_balances`; `booking_requests.converted_family_id`; `session_seats_left` v2, `get_sessions_with_seats` v2, `create_family_from_request`, `set_primary_guardian`; triggers `guard_package_purge_counter`, `cancel_bookings_of_cancelled_session`; bucket `payment-slips`; `purge_expired_records` v2; `studio_settings.cancel_notice_hours` (decision 10, 14 Oct 2026); round two (14 Oct 2026): status `cancelled_late`, `bookings.cancel_notice_channel` / `cancel_notice_at`, the credit rule in `validate_booking` (brief item 1); round three (14 Oct 2026): status `cancelled_studio`, `notice_channel` = `line` / `phone` / `teacher` / `in_person`, enum `cancellation_outcome`, table `booking_cancellation_log` (§ 6.14a), `booking_is_live()` (§ 8), `cancel_booking()` (§ 8); `check_make_up_notice()` is **removed** (brief 7) | **G4**, G11 |
| 5 | `sql/0005_consent_health.sql` | P4 · F4-01 (the **whole file** is applied in **Stage B**, functions included; only the P4 screens wait, 00 § 8.0) | 9 enums; `consent_texts`, `consent_records`, `child_health`, `family_links`, `media_assets` (+`legacy_consent_purposes`), `media_asset_children`, `guardian_consent_records` (§ 6.17a, decision 2), `media_assets.on_print` (decision 3); views `current_consents`, `current_marketing_consents`; consent + health functions; `queue_consent_change_alert` trigger; `consent_matrix`, `media_publishability`, `set_media_asset_children`, `publish_consent_text`, `submit_enrolment`; bucket `consent-evidence`; seed of the 2 founder clips into `media_assets` (the 4 class clips only after the written source is recorded, G0 Q15, § 18); `purge_expired_records` v3; round three (14 Oct 2026): `get_child_health` returns `health_consent_status` and `has_health_record` (brief 4), `child_has_recent_booking()` = the 6-month health clock (brief 3) | **G4** |
| 6a | `sql/0006a_seed_marketing_text.sql` | P3 · card P3-20 (decision 2) | v1 `marketing_line` wording, TH + EN (guardian scope; separate opt-in; never pre-ticked) | **G9b first**, then **G4 · 0006a** (Stage B, before the family create screens go live) |
| 6 | `sql/0006_seed_consent_texts.sql` | P4 · F4-02 | v1 consent wording, TH + EN, 5 purposes (health, website, social, YouTube, print; data only; `media_print` added 14 Oct 2026) | **G9b first**, then **G4** |
| 6b | `sql/0006b_seed_media_parents_group.sql` | P4 · F4-02 (optional) | v1 wording for `media_parents_group`, only if G0 Q9 confirms the private parents' group | G0 Q9 = yes, **G9b**, **G4** |
| 7 | `sql/0007_privacy_ops.sql` | P5 · F5-01 (applied in **Stage B**, after 0005) | 4 enums; `dsr_requests`, `breach_incidents`; restriction columns + `set_family_restriction`, `guard_family_restriction_columns`, `block_restricted_family`; `mark_inactive_families`, `export_family_data`, `erase_family`; `purge_expired_records` v4 (complete); `guardian_consent_records` in the restriction guard, export, erase and purge; view `marketing_follow_up_list` (decision 2); round three (14 Oct 2026): `family_label()` (brief 5, every attending child), erase cancels future bookings as `cancelled_studio` and logs them (briefs 1, 2), purge v4 purges `booking_cancellation_log` | **G4** |
| 8 | `sql/0008_reporting.sql` | P6 · F6-01 | views `report_requests_weekly`, `report_session_fill` (+`cancelled_late`), `report_attendance_monthly` (+`cancelled_late`, `credit_bookings`), `report_revenue_monthly`; round three (14 Oct 2026): cancellation counts read from `booking_cancellation_log`, attendance rate leaves `cancelled_late` out | **G4** |
| — | `sql/tests/rls_smoke.sql` | after any file | read-only security check (BEGIN … ROLLBACK) | builder runs in **Cloud → SQL editor**, user OK |
| — | `sql/seed_dev.sql` | after 0007 + 0008 | **fake** data + behaviour checks, always ROLLBACK. Not a migration. | builder runs in **Cloud → SQL editor** (or local Supabase), user OK |

**Apply order:** 0001 → 0002 → 0003 → 0004 → 0005 → 0007 → 0006a (Stage B, after G9b) → 0006 (+0006b, Stage C) → 0008. 0007 comes before 0006a and 0006 because Stage B
(family records) needs retention, export, erasure and restriction, while 0006 waits for the lawyer (G9b).

`purge_expired_records()` is re-declared **in full** in 0002 (v1), 0004 (v2), 0005 (v3) and 0007 (v4). The returned
JSON has a `"version"` key, so you can see which one is live.

---

## 2. How migrations get applied (G4) and rules for implementers

### 2.1 Who does what

| Step | Who | What |
|---|---|---|
| Draft or fix SQL | Implementer (Haiku), **only if a task card says so** | Edit a file under `docs/backend/sql/` that has **not** been applied yet, or add a new numbered file. |
| Apply | Human builder (G4) | Lovable chat: paste one whole file and say *"Apply this SQL migration exactly as written. Do not change it."* Approve the SQL Lovable shows. |
| Sync | Human builder / main session | `git pull --ff-only`. Lovable adds its own migration file (folder `drizzle/` or `supabase/migrations/`, recorded in `40-integrations.md` § 2) and regenerates `src/integrations/supabase/types.ts`. |
| Verify | Main session | `grep -c "<new table name>" src/integrations/supabase/types.ts` is > 0, then the builder runs `sql/tests/rls_smoke.sql` (read-only) in **Cloud → SQL editor** (`40-integrations.md` § 3). Mark the gate done in `90-task-breakdown.md` § 2. |
| Build on it | Implementer | Only now start tasks whose card says `requires: G4 (000N)`. |

### 2.2 G4 checklist (one file at a time)

1. The previous file is applied and its gate is marked done.
2. Any extra gate for this file is done (0006 needs **G9b**; 0004 should have **G11** answered, or at least noted as pending).
3. Paste the **whole** file into Lovable chat with the exact sentence above. Do not split it, and do not let Lovable "improve" it.
   If Lovable wants to change anything, stop and ask the builder.
4. If Lovable reports an error, **do not retry with edits in chat.** Copy the error text (it contains no personal data), fix
   the draft file (if it was not applied at all) or write a new additive `00NN_fix_<what>.sql`, and go back to step 3.
5. `git pull --ff-only`; check `types.ts` grew; run the smoke check; record the result.
6. On the **first** G4 (0001) also record: which migration folder Lovable used, and whether the change reached the
   live database before Publish (`40-integrations.md` § 2 rows 4–5).

### 2.3 Rules for implementers (Haiku)

- **Never** apply SQL yourself: no Lovable `send_message`, no MCP `query_database` writes, no Supabase CLI. Those are human gates.
- **Never** edit a SQL file that has already been applied. Fix forward with a new numbered file.
- New SQL is **additive only**: `create … if not exists`, `create or replace function` (same signature and return type),
  `alter table … add column if not exists`, enums in `DO` blocks guarded by `pg_type`, policies in `DO` blocks guarded by
  `pg_policies`. No `DROP`, no `RENAME`, no type changes, no `NOT NULL` on an existing column without a default.
- Every new table: `enable row level security`, `revoke all … from anon, authenticated`, then grant to
  `authenticated` only what the policies need, plus `grant all … to service_role`.
- Every new SECURITY DEFINER function: `set search_path = ''`, schema-qualify everything (`public.`, `auth.`),
  `revoke execute … from public, anon`, grant explicitly.
- Never edit generated files (`src/integrations/supabase/*`, `supabase/config.toml`, `.env`, anything in `drizzle/` or
  `supabase/migrations/`).
- Never put real names, phones, LINE IDs or health details in SQL, tests or seeds. Use `ผู้ปกครองทดสอบ`, `Test Parent`,
  `น้องทดสอบ`, `0800000001`, `test.line.id`.
- Health data is read **only** through `get_child_health` / `list_session_health_flags` and written **only** through
  `upsert_child_health`. Staff have no table privileges on `child_health` at all.

---

## 3. ER overview

```
 auth.users (Lovable Cloud Auth: STAFF ONLY) ──1:n── user_roles (owner | staff)

 studio_settings (exactly 1 row)      audit_log      rate_limit_events      staff_notifications
 storage_cleanup_queue                breach_incidents                        (ref_id → request/family/consent)

 booking_requests ──session_id──────────────► sessions ◄──session_id── bookings
      │  ▲                                                                │ │ │ │
      │  └──── families.source_request_id                                 │ │ │ └─ picked_up_by_contact_id ─► family_contacts
      │ converted_family_id                                               │ │ └─── picked_up_by_guardian_id ► guardians
      ▼                                                                   │ └───── package_purchase_id ─────► package_purchases
 families ─┬─1:n─ guardians ◄───────────── consent_records.guardian_id    └─────── child_id, family_id
           ├─1:n─ children ─┬─1:1─ child_health   (explicit consent, audited reads)
           │                ├─1:n─ consent_records ──► consent_texts (versioned, immutable)
           │                └─n:m─ media_asset_children ──► media_assets
           ├─1:n─ family_contacts   (emergency / authorised pickup)
           ├─1:n─ family_links      (enrol / manage tokens, hash only)
           ├─1:n─ guardian_consent_records (marketing_line, guardian scope; holds no child data)
           ├─1:n─ package_purchases ◄─ payments (slip_path → bucket payment-slips)
           └─0:n─ dsr_requests (family_id nullable)

 Views:   package_balances (purchase − bookings) · current_consents (latest per child×purpose×given_by)
          report_requests_weekly · report_session_fill · report_attendance_monthly · report_revenue_monthly
 Buckets: payment-slips (payments.slip_path) · consent-evidence (consent_records.evidence_path)

 After erase_family(): consent_records, payments, package_purchases and bookings stay with family/child ids = NULL
 (anonymised), until their own retention date.
```

---

## 4. Conventions used in every file

- Tables `snake_case` plural; FKs `<entity>_id`; `id uuid primary key default gen_random_uuid()`, except log tables
  (`audit_log`, `rate_limit_events`, `storage_cleanup_queue`) which use `bigint generated always as identity`.
- `created_at timestamptz not null default now()`; `updated_at` + trigger `set_updated_at()` where rows change.
- Times: `*_at timestamptz`; dates `*_on date`. Exceptions: `sessions.session_date` (date), `children.birth_month`
  (date, always day 1), `sessions.starts_at` / `ends_at` (`time`, Bangkok wall-clock — named by the architect).
- Money: `*_thb integer` (whole baht).
- Retention: `retain_until timestamptz`. Values that depend on another column (deadlines, retention) are set by
  **BEFORE triggers**, never generated columns (`timestamptz + interval` is not immutable).
- "Today" in SQL = `(now() at time zone 'Asia/Bangkok')::date`. pg_cron schedules are UTC.
- Phones are stored **normalised**: digits only, local format, regex `^0[0-9]{8,9}$` (e.g. `0812345678`, `021234567`).
  `normaliseThaiPhone()` must output exactly this.
- LINE IDs: any non-blank string up to 50 chars without spaces (`^\S{1,50}$`); zod can be stricter.
- File paths in buckets: `<family_id>/<uuid>.<ext>`, ext lowercase `jpg|jpeg|png|webp|pdf`.
- Policies are named `"<table>_<role>_<action>"` (`role` = `staff`, `owner` or `self`); storage policies use the bucket
  name with `_` (`payment_slips_staff_select`). Staff policies call `(select public.is_staff())`, owner ones
  `(select public.is_owner())`. **`is_staff()` is true for owner too.**
- Views use `security_invoker = true`, so the caller's RLS applies.
- SECURITY DEFINER functions: `set search_path = ''`, fully qualified names, explicit grants.

### 4.1 Text and number limits shared with zod (R-16)

Zod schemas must never accept more than the database does. `src/lib/backend/limits.ts` (card P0-06) exports these
numbers as `DB_LIMITS`, and each schema card adds a boundary test (limit accepted, limit + 1 rejected). Zod may be
**stricter** (e.g. a 140-character public note), never looser.

| `DB_LIMITS` key | SQL column(s) | Max |
|---|---|---|
| `guardianName`, `personName` | `booking_requests.guardian_name`, `guardians.full_name`, `family_contacts.name`, `families.display_name`, `dsr_requests.requester_name` | 80 |
| `nickname` | `children.nickname`, request `children[].nickname` | 30 |
| `requestMessage` | `booking_requests.message` | 500 |
| `staffNoteLong` | `booking_requests.staff_note`, `sessions.staff_note`, `families.staff_note` | 1000 |
| `staffNoteShort` | `package_purchases.staff_note`, `payments.note`, `bookings.staff_note`, `media_assets.staff_note` | 500 |
| `publicNote` | `sessions.public_note_th/en` | 200 |
| `relationship` | `family_contacts.relationship` | 40 |
| `receiptNo` | `payments.receipt_no` | 40 |
| `email` | `guardians.email` | 254 |
| `otherAllergens` / `foodsToAvoid` / `careNotes` | `child_health.*` | 200 / 300 / 500 |
| `consentTitle` / `consentBody` | `consent_texts.title` / `body_md` | 200 / 10000 |
| `childConsentAgeMin` / `childConsentAgeMax` | `consent_texts.requires_child_consent_from_age` | 7 / 19 |
| `mediaTitle` / `legacyNote` | `media_assets.title` / `legacy_consent_note` | 200 / 300 |
| `dsrContact` / `dsrText` | `dsr_requests.requester_contact` / `details`, `outcome`, `refusal_reason` | 120 / 1000 |
| `breachTitle` / `breachText` | `breach_incidents.title` / `description`, `measures` | 200 / 4000 |
| `restrictionNote` | `families.restriction_note` | 200 |
| `sessionCapacityMax` (zod only) | `sessions.capacity` (SQL: > 0) | 60 |

---

## 5. Enums

Identical to `00-overview.md` § 10.

| Enum | Values | File |
|---|---|---|
| `app_role` | `owner`, `staff` | 0001 |
| `site_lang` | `th`, `en` | 0001 |
| `booking_request_status` | `new`, `contacted`, `waitlisted`, `converted`, `closed`, `spam` | 0002 |
| `contact_preference` | `line`, `phone` | 0002 |
| `package_code` | `single`, `four`, `eight` | 0002 |
| `preferred_day` | `sat`, `sun`, `either` | 0002 |
| `notification_kind` | `booking_request`, `enrolment_submitted`, `consent_withdrawn` | 0002 |
| `notify_status` | `pending`, `sent`, `failed`, `skipped` | 0002 |
| `session_status` | `draft`, `open`, `closed`, `cancelled` | 0003 |
| `family_status` | `active`, `inactive` | 0004 |
| `identity_check_method` | `in_person`, `line_account`, `phone_callback` | 0004 |
| `package_purchase_status` | `active`, `closed`, `void` | 0004 |
| `payment_method` | `promptpay`, `bank_transfer`, `cash`, `other` | 0004 |
| `payment_status` | `pending`, `paid`, `refunded`, `void` | 0004 |
| `booking_status` | `held`, `confirmed`, `attended`, `absent`, `cancelled` (family cancellation with notice on time: credit kept, no credit used), `cancelled_late` (late notice: seat kept, **not** an absence, one credit used; round two; a family cancellation with **no** notice is refused by `cancel_booking()` and recorded as `absent`, verifier fix round three), `cancelled_studio` (the studio cancelled the session or the seat: credit **returned**, not used, no notice; round three, 14 Oct 2026) | 0004 |
| `notice_channel` | `line`, `phone`, `teacher`, `in_person` (round three, 14 Oct 2026: **any** of the four counts as notice; `line` was the round-two channel with `in_person`) | 0004 |
| `cancellation_outcome` | `family_on_time` (the credit is kept), `family_late` (the seat is kept and one credit is used), `studio` (the credit is returned); one value per row of `booking_cancellation_log` (round three) | 0004 |
| `consent_purpose` | `health_allergy`, `media_parents_group`, `media_website`, `media_social`, `media_youtube`, `marketing_line` (guardian scope only, 14 Oct 2026: `consent_records` refuses it; `consent_status`, `consent_matrix` and `can_publish_media` never list it), `media_print` (decision 3; a child media purpose) | 0005 |
| `consent_decision` | `granted`, `refused`, `withdrawn` | 0005 |
| `consent_given_by` | `guardian`, `child` | 0005 |
| `consent_channel` | `web`, `line`, `paper`, `in_person` | 0005 |
| `consent_method` | `checkbox`, `signature`, `staff_recorded_verbal` | 0005 |
| `media_level` | `face_visible`, `face_hidden` | 0005 |
| `link_purpose` | `enrol`, `manage` | 0005 |
| `media_asset_kind` | `youtube`, `photo`, `other` | 0005 |
| `media_asset_status` | `active`, `taken_down` | 0005 |
| `dsr_right` | `access`, `portability`, `objection`, `erasure`, `restriction`, `rectification`, `withdraw_consent` | 0007 |
| `dsr_channel` | `in_person`, `registered_mail`, `line`, `email`, `web` | 0007 |
| `dsr_status` | `received`, `in_review`, `waiting_for_requester`, `extended`, `completed`, `refused` | 0007 |
| `breach_risk` | `unlikely`, `risk`, `high` | 0007 |

Allergen keys (`child_health.allergens`, CHECK-enforced, 10 keys): `peanut`, `tree_nut`, `milk`, `egg`, `wheat`, `flour`,
`soy`, `fish`, `shellfish`, `sesame`. Round two (owner, 14 Oct 2026, brief item 7): `flour` is new and covers all kinds of
flour and products made with flour (Thai label "แป้ง (ทุกชนิด และผลิตภัณฑ์จากแป้ง)", English "Flour (all kinds, and products made with flour)").
`wheat` keeps its own key ("แป้งสาลี / ข้าวสาลี"). Nuts: one group "ถั่ว" in the UI with two choices, `peanut` (ถั่วลิสง) and
`tree_nut` (ถั่วเปลือกแข็ง); both keys are kept. Anything else goes in `other_allergens`.

Status labels for the admin (from 00-overview "COPY KEYS"): `new` ใหม่ / New · `contacted` ติดต่อแล้ว / Contacted ·
`waitlisted` รอคิว / Waitlisted · `converted` จองแล้ว / Booked · `closed` ปิด / Closed · `spam` สแปม / Spam.

---

## 6. Tables

Legend: **N** = nullable. "Set by" = who normally writes the column (server = service role in a server function).
Every table has RLS enabled; § 11 has the full matrix.

### 6.1 `user_roles` (P0 · 0001)

Which Lovable Cloud auth users are staff. No row = no access. At least one `owner` must always exist (trigger).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | `gen_random_uuid()` | |
| `user_id` | uuid | | | → `auth.users(id)` **on delete cascade** (removing the Cloud user removes the role) |
| `role` | `app_role` | | | `owner` or `staff`; `unique (user_id, role)` |
| `created_at` | timestamptz | | `now()` | |
| `created_by` | uuid | ✓ | | → `auth.users`, set null |

RLS: self select own rows; owner select/insert/update/delete. Triggers: `user_roles_protect_last_owner`
(`prevent_last_owner_removal`), `user_roles_audit`. Bootstrap (G5) inserts the first owner as the database owner
(template in `40-integrations.md`):
`insert into public.user_roles (user_id, role) select u.id, 'owner' from auth.users u where lower(u.email) = lower('<OWNER_EMAIL>') on conflict (user_id, role) do nothing;`
— the email is typed only in **Cloud → SQL editor**, never in Lovable chat and never committed (R-19).

### 6.2 `audit_log` (P0 · 0001)

Who did what to which row. **Never field values.** Kept 12 months.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | bigint identity | | | |
| `at` | timestamptz | | `now()` | |
| `actor_user_id` | uuid | ✓ | | `auth.uid()`; NULL for server/cron. No FK (log survives user deletion). |
| `actor_kind` | text | | | `staff` or `system` |
| `action` | text | | | `insert`, `update`, `delete` (triggers); `read_health`, `export`, `erase` (functions) |
| `table_name` | text | | | |
| `row_id` | text | ✓ | | the row's `id` as text (for `list_session_health_flags`: the session id) |
| `details` | jsonb | | `'{}'` | `{"columns": [...changed column names...], "auth_role": "authenticated"|"service_role"|null, "function": "..."}` |
| `retain_until` | timestamptz | | `now() + 12 months` | |

RLS: owner select only. Nobody inserts directly; `audit_row_change()` and `log_audit_event()` do.

### 6.3 `studio_settings` (P0 · 0001)

Exactly one row (`id = true`), inserted by the migration.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | boolean | | `true` | `check (id)` → only one row possible |
| `booking_form_open` | boolean | | `true` | `submitBookingRequest` returns `form_closed` when false |
| `staff_alerts_enabled` | boolean | | `true` | `notifyStaff` records `skipped` when false |
| `default_session_capacity` | integer | ✓ | | > 0. NULL until the owner sets it (group size isn't published). |
| `cancel_notice_hours` | integer | | 3 | (decision 10, 14 Oct 2026; added by 0004) hours of notice before the session starts that keep the credit. 0–72 (CHECK). Owner sets it. Round three (brief 7): there is no separate make-up notice check any more; the same setting decides on time (`cancelled`, credit kept) or late (`cancelled_late`, one credit) for **every** family cancellation, any channel. Packages never expire. An absence, or a late cancellation, uses one credit. |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `updated_by` | uuid | ✓ | | server function sets `context.userId` |

RLS: staff select; owner update (columns `booking_form_open`, `staff_alerts_enabled`, `default_session_capacity`, `cancel_notice_hours`,
`updated_by`). Audited.

### 6.4 `booking_requests` (P1 · 0002; +`session_id` 0003; +`converted_family_id` 0004)

A structured request from `/book`. PDPA s.24(3) (pre-contract), no consent checkbox (D8). Inserted **only** by
`submitBookingRequest` via the service role.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `ref_code` | text | | | unique; `^CL-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$` (made by `makeRefCode`; retry once on unique conflict, SQLSTATE 23505) |
| `status` | `booking_request_status` | | `new` | |
| `guardian_name` | text | | | 1–80 chars after trim. What to call the parent. |
| `contact_phone` | text | ✓ | | normalised `^0[0-9]{8,9}$`; **required when `preferred_contact = 'phone'`** |
| `contact_line_id` | text | ✓ | | `^\S{1,50}$`; optional **matching hint** only (D26) |
| `preferred_contact` | `contact_preference` | | `line` | `line` = the parent sends the ref code to @cherryleeandco and staff reply there (nothing else required); `phone` = call-back (D26, R-03) |
| `children` | jsonb | | | array of 1–3 objects, exactly `{"age_years": 6..12, "nickname"?: string 1–30 \| null}`; no other keys (CHECK via `is_valid_request_children`) |
| `children_count` | smallint | | generated | number of items (read-only; not in Insert type) |
| `package_code` | `package_code` | ✓ | | NULL = "not sure yet" |
| `preferred_day` | `preferred_day` | ✓ | | |
| `preferred_date` | date | ✓ | | |
| `session_id` | uuid | ✓ | | → `sessions`, set null (P2) |
| `message` | text | ✓ | | ≤ 500. The form says: don't include health details. |
| `lang` | `site_lang` | | `th` | language of the page used |
| `privacy_notice_version` | text | | | 1–40 chars, `PRIVACY_NOTICE_VERSION` from `src/content/privacy.tsx` |
| `staff_note` | text | ✓ | | ≤ 1000; no health info |
| `handled_by` | uuid | ✓ | | → `auth.users`, set null |
| `contacted_at` | timestamptz | ✓ | | |
| `converted_family_id` | uuid | ✓ | | → `families`, set null (P3) |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | `now() + 6 months` | purge deletes after |

Constraint `booking_requests_phone_callback_has_phone`: `preferred_contact <> 'phone' or contact_phone is not null`. RLS: staff select + update (columns: `status`, `guardian_name`,
`contact_phone`, `contact_line_id`, `preferred_contact`, `children`, `package_code`, `preferred_day`, `preferred_date`,
`message`, `staff_note`, `handled_by`, `contacted_at`, `session_id`, `converted_family_id`); owner delete; no insert.

### 6.5 `rate_limit_events` (P1 · 0002)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | bigint identity | | | |
| `bucket` | text | | | e.g. `booking_request` |
| `key_hash` | text | | | 64 hex chars = `HMAC-SHA256(ip, IP_HASH_SECRET)`. **Raw IPs are never stored.** |
| `created_at` | timestamptz | | `now()` | purged after 24 h |

RLS on, **no policies, no grants** for anon/authenticated. Only `check_rate_limit()` touches it.

### 6.6 `staff_notifications` (P1 · 0002)

Outbox for PII-free LINE alerts (D7). The message text is never stored; it is rebuilt from the referenced row.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | also the LINE `X-Line-Retry-Key` |
| `kind` | `notification_kind` | | | |
| `ref_id` | uuid | | | `booking_request` → `booking_requests.id`; `enrolment_submitted` → `families.id`; `consent_withdrawn` → `consent_records.id`. No FK (polymorphic). |
| `status` | `notify_status` | | `pending` | |
| `attempts` | smallint | | 0 | |
| `last_error` | text | ✓ | | ≤ 200, an error **code** only (e.g. `line_http_401`, `timeout`) |
| `sent_at` | timestamptz | ✓ | | |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | `now() + 30 days` | |

RLS: staff select; staff update (`status`, `attempts`, `last_error`, `sent_at`). Inserts by the server (`notifyStaff`).

### 6.7 `sessions` (P2 · 0003)

One class day. Capacity is staff-set and **never public** (D14).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `session_date` | date | | | Bangkok date |
| `starts_at` | time | | `09:00` | `unique (session_date, starts_at)` |
| `ends_at` | time | | `15:00` | `> starts_at` |
| `capacity` | integer | ✓ | | > 0; NULL = not set → `seats_left` NULL → public shows "ask on LINE" |
| `seats_held_offline` | integer | | 0 | seats promised on LINE, not yet entered |
| `status` | `session_status` | | `draft` | only `open` is public; `generate_weekend_sessions` creates `open` |
| `public_note_th`, `public_note_en` | text | ✓ | | ≤ 200 each; no names, no unset policies |
| `staff_note` | text | ✓ | | ≤ 1000 |
| `created_by` | uuid | ✓ | | → `auth.users`, set null |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

RLS: staff select/insert/update; owner delete. Public read only via `get_open_sessions()`. No personal data, no retention.

### 6.8 `families` (P3 · 0004)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `display_name` | text | | | 1–80, a staff label. Never a child's nickname on any list (20 § 9.5a). OPEN (owner): the label rule for the follow-up list (card P3-19). |
| `processing_restricted_at` | timestamptz | ✓ | | (0007, D28/R-09) PDPA s.34 restriction in force; set only via `set_family_restriction()` (owner) |
| `restriction_note` | text | ✓ | | (0007) ≤ 200, short reason, never health details |
| `preferred_lang` | `site_lang` | | `th` | |
| `status` | `family_status` | | `active` | **system-managed** by `mark_inactive_families()` (P5); staff screens must not edit it |
| `staff_note` | text | ✓ | | ≤ 1000; never health/allergy/religion |
| `source_request_id` | uuid | ✓ | | → `booking_requests`, set null |
| `last_activity_at` | timestamptz | | `now()` | system-managed (P5) |
| `retain_until` | timestamptz | ✓ | | NULL while active; set to now()+30 days when inactive > 12 months (P5) |
| `created_by` | uuid | ✓ | | |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

RLS: staff select/insert/update; owner delete (from P4 on, a family that has consent records can only be removed with
`erase_family()`; a plain delete fails on the consent_records FK). Audited.

### 6.9 `guardians` (P3 · 0004)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | | | → `families`, cascade |
| `full_name` | text | | | 1–80 (name for receipts/consent evidence) |
| `phone` | text | ✓ | | `^0[0-9]{8,9}$` |
| `line_id` | text | ✓ | | `^\S{1,50}$` |
| `email` | text | ✓ | | optional, only for receipts by email |
| `is_primary` | boolean | | false | at most one per family (partial unique index): unset the old primary first |
| `has_parental_responsibility` | boolean | | false | PDPA s.20 statement; **required = true before this guardian can give a `granted` consent** |
| `responsibility_attested_at` | timestamptz | ✓ | | required when the flag is true |
| `identity_check_method` | `identity_check_method` | ✓ | | set together with `identity_checked_at` |
| `identity_checked_by` | uuid | ✓ | | staff user; NULL for `line_account` via private link |
| `identity_checked_at` | timestamptz | ✓ | | set only by **staff** (`saveGuardian markIdentityChecked`); using a private link never sets it (R-21) |
| `pending_link_changes` | jsonb | ✓ | | (R-21) `{"at": …, "before": {<field>: <old value>}}` for contact fields a parent changed through `/enrol`; staff compare in the LINE chat, then clear it (`saveGuardian confirmLinkChanges`) |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

At least one of phone / LINE ID / email. **No national ID numbers or ID card copies.** RLS: staff select/insert/update;
owner delete (blocked if the guardian has consent records). Audited.

### 6.10 `children` (P3 · 0004)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | | | → `families`, cascade |
| `nickname` | text | | | 1–30 |
| `birth_month` | date | ✓ | | day must be 1 (`YYYY-MM-01`). NULL = unknown → treated as needing the child's own consent (D11) |
| `reported_age_years` | smallint | ✓ | | 6–12, copied from the request until the birth month is known (**new**) |
| `reported_age_on` | date | ✓ | | when that age was reported (set together) (**new**) |
| `is_active` | boolean | | true | |
| `last_session_on` | date | ✓ | | latest **attended** session date; maintained by `sync_child_last_session()` |
| `allergy_check_needed_at` | timestamptz | ✓ | | (R-07) **not health data**: set when allergy info is removed (withdrawal, refusal, 6-month purge); cleared by `upsert_child_health`. Roster: "info removed on … — check with the family before cooking" |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

**Not stored:** full name, full birth date, school, gender, nationality, address. RLS: staff select/insert/update;
owner delete (blocked if the child has consent records). Audited.

### 6.11 `family_contacts` (P3 · 0004)

Emergency contacts and authorised pickup persons (third parties, PDPA s.25).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | | | → `families`, cascade |
| `name` | text | | | 1–80 |
| `phone` | text | | | `^0[0-9]{8,9}$` |
| `relationship` | text | | | 1–40, free text ("คุณยาย") |
| `is_emergency_contact` | boolean | | false | at least one of the two flags |
| `is_authorised_pickup` | boolean | | false | only these can be `bookings.picked_up_by_contact_id` |
| `guardian_attests_informed_at` | timestamptz | | | **required**: "I've told them and shared the privacy notice" |
| `is_active` | boolean | | true | (R-22) soft delete: `deleteFamilyContact` and `/enrol` set false; inactive contacts are hidden from pickup choices and forms but keep the "picked up by" history |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

RLS: staff select/insert/update/delete (the UI never hard-deletes; the family's erasure does). Audited.

### 6.12 `package_purchases` (P3 · 0004)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | ✓ | | → `families`, set null (NULL only after erasure) |
| `package_code` | `package_code` | | | |
| `sessions_total` | smallint | | | must match: single=1, four=4, eight=8 |
| `price_thb` | integer | | | ≥ 0; snapshot of `PRICES` in `src/content/business.ts` (staff may enter the agreed amount) |
| `purchased_on` | date | | today (Bangkok) | |
| `expires_on` | date | ✓ | | NULL unless the studio sets an expiry rule (G0 Q4) |
| `status` | `package_purchase_status` | | `active` | staff: active/closed; owner: void |
| `staff_note` | text | ✓ | | ≤ 500 |
| `sessions_used_purged` | smallint | | 0 | (R-10) credits used by bookings the purge already deleted; `0 ≤ x ≤ sessions_total`; written **only** by `purge_expired_records()` (trigger `guard_package_purge_counter`) |
| `created_by` | uuid | ✓ | | |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | trigger | 00:00 Bangkok on 1 Jan after 31 Dec of (purchase year + 5) — **accountant to confirm (G11)** |

RLS: staff select; staff insert/update only while status is `active`/`closed`; owner update (void) and delete. Audited.

### 6.13 `payments` (P3 · 0004)

Recorded manually by staff (D17). No card data, no bank account numbers.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | ✓ | | → `families`, set null |
| `package_purchase_id` | uuid | ✓ | | → `package_purchases`, set null |
| `amount_thb` | integer | | | > 0 |
| `method` | `payment_method` | | | |
| `status` | `payment_status` | | `pending` | staff: pending/paid; owner: refunded/void |
| `paid_at` | timestamptz | ✓ | | required when status = paid |
| `receipt_no` | text | ✓ | | unique, 1–40 |
| `slip_path` | text | ✓ | | object in bucket `payment-slips` |
| `note` | text | ✓ | | ≤ 500; never account numbers; NULLed on erase |
| `recorded_by`, `verified_by` | uuid | ✓ | | → `auth.users`, set null; `verified_by` needs `verified_at` |
| `verified_at` | timestamptz | ✓ | | |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | trigger | based on `paid_at` (or `created_at`) year + 5 — **G11** |

RLS: staff select; staff insert/update only with status `pending`/`paid`; owner update + delete. Replacing or deleting a
slip queues the old file in `storage_cleanup_queue`. Audited.

### 6.14 `bookings` (P3 · 0004)

A child's seat in a session, credit use and attendance.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `session_id` | uuid | | | → `sessions`, restrict |
| `child_id` | uuid | ✓ | | → `children`, set null. **Required on insert.** Can't change to another child later. |
| `family_id` | uuid | ✓ | | → `families`, set null. **Filled automatically from the child** if omitted. Can't change family. |
| `package_purchase_id` | uuid | ✓ | | → `package_purchases`, set null; required when `consumes_credit` |
| `consumes_credit` | boolean | | true | |
| `status` | `booking_status` | | `confirmed` | `absent` and `cancelled_late` use a credit; `cancelled` (notice on time) and `cancelled_studio` (credit returned) do not. Round three: a family cancellation goes through `cancel_booking()` (it writes `booking_cancellation_log`); `validate_booking()` makes it `cancelled_late` when the notice is late. A cancellation with no notice is refused by `cancel_booking()` (22023); `validate_booking()` would turn it into `absent` (verifier fix, round three). A direct edit that cancels a booking, or changes its notice, is refused (42501). Attendance (`attended`, `absent`) stays a plain staff update. |
| `checked_in_at`, `checked_out_at` | timestamptz | ✓ | | out ≥ in |
| `picked_up_by_guardian_id` | uuid | ✓ | | → `guardians` of the same family |
| `picked_up_by_contact_id` | uuid | ✓ | | → `family_contacts` of the same family **with `is_authorised_pickup`** (only one of the two pickup columns) |
| `cancel_notice_channel` | `notice_channel` | ✓ | | `line` (LINE OA chat), `phone` (phone call), `teacher` (told a teacher) or `in_person`. Any of them counts as notice (round three, brief 6). Set together with `cancel_notice_at` (CHECK `bookings_notice_pair`). NULL for a studio cancellation. |
| `cancel_notice_at` | timestamptz | ✓ | | The time the notice reached the studio: the phone call time, the LINE message time (not the time it was typed), or the time the teacher was told. Round two; round three: the same meaning for every channel. |
| `cancelled_at` | timestamptz | ✓ | | When the booking was cancelled (first time). Set by `validate_booking()`, never by the server. Round two. |
| `makeup_of_booking_id` | uuid | ✓ | | → `bookings`, set null. Optional link: the cancelled booking this rebooking replaces. **Round three (brief 7):** no status and no notice rule any more. A rebooking uses the kept or returned credit; `validate_booking()` only checks that the original is the same child, and the balance check decides the rest. One live rebooking per original: partial unique index `bookings_one_makeup_per_original`. **Verifier fix (round three):** the server does not send or read this column (20 § 9.7, P3-06 step 4); the column and index stay in the database as an optional reference with no screen that sets it (open question 20). |
| `staff_note` | text | ✓ | | ≤ 500 |
| `created_by` | uuid | ✓ | | |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | trigger | session date + 24 months |

Partial unique index `bookings_one_active_seat_per_child`: one live booking per child per session. Live means `booking_is_live(status)` (§ 8): held, confirmed, attended, absent and `cancelled_late` (which keeps the seat). `cancelled` and `cancelled_studio` free it. `validate_booking()` refuses a credit booking when
the package is not `active` or has no sessions left (row-locked). Seats are **not** enforced by the DB (staff may
overbook on purpose; the UI warns). RLS: staff select/insert/update; owner delete. Audited.

### 6.14a `booking_cancellation_log` (P3 · 0004) — **new, round three (14 Oct 2026, brief 2)**

One row per cancellation event, for the studio's cancellation statistics. The cancellation counts in the reports come from
this table, not from `bookings`. **Append-only**: UPDATE and DELETE raise 42501, except inside `purge_expired_records()` and
`erase_family()` (`cherrylee.allow_purge`). Holds **no names, phone numbers, LINE IDs or health data**.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | `gen_random_uuid()` | |
| `booking_id` | uuid | | | The cancelled booking. **No FK** (an FK action would UPDATE this append-only table). |
| `family_id` | uuid | ✓ | | **No FK.** NULL after the family is erased (`erase_family` detaches it). |
| `session_id` | uuid | | | The session of the booking. **No FK**, for the same reason. |
| `outcome` | `cancellation_outcome` | | | `family_on_time` (credit kept), `family_late` (seat kept, one credit used), `studio` (credit returned). |
| `notice_channel` | `notice_channel` | ✓ | | `line`, `phone`, `teacher` or `in_person`. NULL when no notice was given. |
| `notice_at` | timestamptz | ✓ | | The time the notice reached the studio. NULL when no notice. CHECK: channel and time are set together. |
| `recorded_by` | uuid | ✓ | | The staff user who recorded it (`auth.uid()`), for `cancel_booking()` and the studio path. NULL only when no staff user is in the session (no such path in round three). No FK. |
| `recorded_at` | timestamptz | | `clock_timestamp()` | Set by the database; cannot be back-dated. |
| `retain_until` | timestamptz | | set by the writer | **Session date + 24 months** (the same as `bookings`). The purge deletes rows past it. |

Written only by `cancel_booking()` (family or one-seat studio cancel), by `cancel_bookings_of_cancelled_session()` (a
studio cancel of a whole session, outcome `studio`, `recorded_by` = the staff user). `erase_family()` writes **no** row; it only detaches the family id from existing rows (verifier fix, round three).
**RLS:** on. Staff select only (`booking_cancellation_log_staff_select`). **Grants:** `anon` none; `authenticated` and
`service_role` select only. No insert, update or delete grant or policy for any app role. Audited (`audit_row_change`), no values.

### 6.15 `storage_cleanup_queue` (P3 · 0004) — **new**

SQL cannot delete files from Supabase Storage (deleting `storage.objects` rows orphans the file:
https://supabase.com/docs/guides/storage/management/delete-objects). Triggers queue paths here; an owner-only server
function removes them with `supabaseAdmin.storage.from(bucket_id).remove([object_path])` and sets `deleted_at`.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | bigint identity | | | |
| `bucket_id` | text | | | `payment-slips` or `consent-evidence` |
| `object_path` | text | | | unique per bucket |
| `reason` | text | | | `row_deleted` or `replaced` |
| `queued_at` | timestamptz | | `now()` | |
| `deleted_at` | timestamptz | ✓ | | set by the server function after a successful remove |
| `last_error` | text | ✓ | | ≤ 200, a code only |

RLS: owner select + update (`deleted_at`, `last_error`). Done rows purged after 30 days.

### 6.16 `consent_texts` (P4 · 0005)

Versioned consent wording. **Immutable after insert** (only `retired_at` can be set, once).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `purpose` | `consent_purpose` | | | |
| `version` | integer | | | > 0; `unique (purpose, version, lang)`; TH and EN share the number |
| `lang` | `site_lang` | | | |
| `title` | text | | | 1–200 |
| `body_md` | text | | | 1–10000, Markdown |
| `sha256` | text | | trigger | hex SHA-256 of UTF-8 `title || '\n' || body_md` (set by `consent_texts_guard`, see § 14) |
| `is_explicit` | boolean | | false | must be true for `health_allergy` |
| `requires_child_consent_from_age` | smallint | ✓ | | 7–19; seed uses 10 (D11) |
| `effective_from` | timestamptz | | `now()` | grants need `effective_from ≤ now()` |
| `retired_at` | timestamptz | ✓ | | a retired text can't be used for new grants (withdrawals may still cite it) |
| `created_by` | uuid | ✓ | | no FK (row is immutable) |
| `created_at` | timestamptz | | `now()` | |

RLS: staff select; owner insert (columns `purpose`, `version`, `lang`, `title`, `body_md`, `is_explicit`,
`requires_child_consent_from_age`, `effective_from`, `created_by`) and update (`retired_at` only). The `/enrol` and `/my`
pages read texts via the service role.

### 6.17 `consent_records` (P4 · 0005)

**Append-only** evidence (UPDATE/DELETE raise 42501, except inside `purge_expired_records()` / `erase_family()`).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | ✓* | | → `families` (no action). *Required on insert; NULL only after erase. |
| `guardian_id` | uuid | ✓ | | → `guardians` (no action). Required when `given_by = guardian`; forced NULL for child records |
| `child_id` | uuid | ✓* | | → `children` (no action). *Required on insert. |
| `purpose` | `consent_purpose` | | | must equal the text's purpose |
| `consent_text_id` | uuid | | | → `consent_texts` |
| `decision` | `consent_decision` | | | |
| `given_by` | `consent_given_by` | | | `child` needs `recorded_by` and channel `in_person`/`paper` |
| `child_age_years_at_decision` | smallint | ✓ | | filled from `birth_month` if not given |
| `media_level` | `media_level` | ✓ | | required for a guardian media **grant**; must be NULL for health |
| `channel` | `consent_channel` | | | `web` ⇒ method `checkbox` |
| `method` | `consent_method` | | | |
| `recorded_by` | uuid | ✓ | | staff user id; **staff inserts must use their own id**. No FK. |
| `evidence_path` | text | ✓ | | object in bucket `consent-evidence` |
| `family_link_id` | uuid | ✓ | | the link used (web). No FK (links get purged). |
| `guardian_name_snapshot` | text | ✓ | trigger | guardian's name at the time (**new**) |
| `child_nickname_snapshot` | text | ✓ | trigger | child's nickname at the time (**new**) |
| `created_at` | timestamptz | | trigger | `clock_timestamp()` so rows written in one transaction stay ordered |
| `retain_until` | timestamptz | ✓ | | NULL while the family exists; erase sets now() + 3 years |

Purpose `marketing_line` is refused here (check `consent_records_no_marketing`): that choice is guardian scope only (§ 6.17a). Insert rules (`validate_consent_record`): text exists and matches the purpose; a **grant** needs a text that is in effect,
not retired, and explicit for health; child and guardian belong to the family; a **guardian grant** needs
`has_parental_responsibility = true`. A health `refused`/`withdrawn` (guardian **or** child) deletes the `child_health`
row immediately (`apply_consent_withdrawal`). RLS: staff select; staff insert (column list in 0005) with
`recorded_by = auth.uid()`; the server writes web consents. Audited.

### 6.17a `guardian_consent_records` (P4 · 0005; used from Stage B by P3-04 and P3-11, and on `/my` in Stage C) — **new, 14 Oct 2026**

**Append-only** guardian-scope marketing choice (decision 2). Purpose `marketing_line` only. It is about the **parent**
who receives the messages, never the child: there is **no child column**, and no function, view or policy joins
children to this table. "Not now" = no row = not granted. Never pre-ticked. Giving consent = a `granted` row.
Withdrawing = a **new** `withdrawn` row (rows are never edited or deleted, so a withdrawal is as easy as giving).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | `gen_random_uuid()` | |
| `family_id` | uuid | ✓* | | → `families` (no action). *Required on insert; NULL only after erase |
| `guardian_id` | uuid | ✓* | | → `guardians` (no action). *Required on insert; NULL only after erase |
| `purpose` | `consent_purpose` | | `marketing_line` | must be `marketing_line` |
| `consent_text_id` | uuid | | | → `consent_texts`; the text must be `marketing_line` (seeded by 0006a) |
| `decision` | `consent_decision` | | | `granted` or `withdrawn` only (CHECK) |
| `given_at` | timestamptz | | trigger | set to `clock_timestamp()` when written; **cannot be back-dated**. For a paper or LINE choice, the signed form or the message is the evidence |
| `channel` | `consent_channel` | | | `web` (the parent on `/my`, via a private link) · `line` · `paper` · `in_person` (staff) |
| `method` | `consent_method` | | | `web` ⇒ `checkbox` |
| `recorded_by` | uuid | ✓ | | staff user id (no FK). **Required when channel ≠ web** |
| `evidence_path` | text | ✓ | | object in bucket `consent-evidence`, same path rule as `consent_records` |
| `family_link_id` | uuid | ✓ | | the private link used (web); no FK |
| `guardian_name_snapshot` | text | ✓ | trigger | the guardian's name when the row was written |
| `retain_until` | timestamptz | ✓ | | NULL while the family exists; erase sets `now() + 3 years` |

Constraints: `purpose = 'marketing_line'`; `decision in (granted, withdrawn)`; `web ⇒ checkbox`; non-web ⇒ `recorded_by`;
family and guardian both set, **or** `retain_until` set (detached after erase).

Insert rules (`validate_guardian_consent_record`): the text exists and is `marketing_line`; a **grant** needs a text in
effect and not retired; the guardian belongs to the family. There is **no** parental-responsibility rule here (PDPA s.20
is about consenting for a child; the parent is the data subject). **Restricted families** (0007, D28): a grant is refused
with 23514 `Family processing is restricted`; a withdrawal is always allowed.

Reads: the latest row per guardian is view `current_marketing_consents` (0005); the staff follow-up list is view
`marketing_follow_up_list` (0007, card P3-19): one row per guardian whose current choice is `granted`, for active,
non-restricted families, with `family_label_th` / `family_label_en` (round three, brief 5: `family_label(family_id)` names **every attending child**: a child with a non-cancelled booking (held, confirmed, attended or absent; not cancelled, cancelled_late or cancelled_studio) in the 6-month window (verifier fix, round three, D52); nicknames only; Thai `ครอบครัวน้องA` / `ครอบครัวน้องA และ น้องB` / `ครอบครัวน้องA, น้องB และ น้องC`; English `Family of A` / `Family of A and B` / `Family of A, B and C`; no attending child → no row), guardian name and consent date (no phone, no email, no LINE ID, no full name, age or health data). One row per granted guardian (brief item 5, round two, 14 Oct 2026: a family with two consenting guardians has two rows; 20 § 9.5a must match).

RLS: staff select; staff insert (column list above; `recorded_by = auth.uid()`; channel ≠ web). Web rows come from the
server (service role) through the private link. No update or delete policies: append-only (42501), except inside
`purge_expired_records()` and `erase_family()`. Audited. Triggers: `guardian_consent_records_validate`,
`_append_only`, `_queue_storage_cleanup` (delete), `_audit`, and `_block_restricted` (0007).

### 6.18 `child_health` (P4 · 0005)

Sensitive data (PDPA s.26). Exists only while the guardian's explicit consent stands and the child hasn't refused.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `child_id` | uuid | | | → `children`, cascade; unique |
| `allergens` | text[] | | `{}` | subset of the 10 allergen keys (round two adds `flour`) |
| `other_allergens` | text | ✓ | | ≤ 200 |
| `foods_to_avoid` | text | ✓ | | ≤ 300; **never ask the reason** (could reveal religion) |
| `care_notes` | text | ✓ | | ≤ 500 |
| `has_allergy` | boolean | | generated | chips or other allergens present |
| `updated_by` | uuid | ✓ | | staff id, or NULL (parent via link). No FK. |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

**No privileges for anon or authenticated.** Read: `get_child_health(child, includeHealth)` (audited; round three: returns one row per child with `health_consent_status` (`granted` / `refused` / `not_asked`, always, for the print sheet) and `has_health_record`; allergens always; `foods_to_avoid`, `care_notes` and `other_allergens` only when `includeHealth` is true (verifier fix); `includeHealth` is required, round two) and
`list_session_health_flags()` (chips + flags, audited). Write: `upsert_child_health()`. The trigger
`enforce_health_consent` raises 42501 unless `has_active_consent(child, 'health_allergy')`. Audited.

### 6.19 `family_links` (P4 · 0005)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | | | → `families`, cascade |
| `purpose` | `link_purpose` | | | `enrol` (14 days, single use) or `manage` (90 days, R-21) — lengths set by the server |
| `token_hash` | text | | | unique, 64 hex = sha256 of the raw 32-byte token. **The raw token is never stored.** |
| `expires_at` | timestamptz | | | > `created_at` |
| `used_at` | timestamptz | ✓ | | set by the server after a successful enrol write |
| `revoked_at` | timestamptz | ✓ | | staff can set it (`revokeFamilyLink`) |
| `created_by` | uuid | ✓ | | **must equal `auth.uid()` on staff insert** |
| `created_at`, `updated_at` | timestamptz | | `now()` | |

RLS: staff select, insert (`created_by = auth.uid()`), update (`revoked_at` only). Purged 30 days after expiry,
revocation, or enrol use. Audited.

### 6.20 `media_assets` and `media_asset_children` (P4 · 0005)

`media_assets` — clips/photos by reference only (D24). Titles never contain children's names.

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `kind` | `media_asset_kind` | | | `youtube` needs `youtube_id` |
| `youtube_id` | text | ✓ | | unique, `^[A-Za-z0-9_-]{11}$` |
| `title` | text | | | 1–200 |
| `shows_children` | boolean | | true | |
| `shows_faces` | boolean | | true | (**new**) TRUE until staff confirm no child's face is recognisable; a `face_hidden` consent blocks assets with faces |
| `legacy_consent_note` | text | ✓ | | pre-system confirmation (text) |
| `legacy_consent_purposes` | `consent_purpose[]` | | `{}` | (R-11) channels the pre-system confirmation covers; set by the 0005 seed from G0 Q15; **never written by the admin** |
| `on_parents_group` | boolean | | false | (**new**) matches purpose `media_parents_group` |
| `on_website`, `on_social`, `on_youtube`, `on_print` | boolean | | false | where it is published now (`on_print` added 14 Oct 2026, decision 3, matches purpose `media_print`) |
| `status` | `media_asset_status` | | `active` | `taken_down` needs `taken_down_at` |
| `taken_down_at` | timestamptz | ✓ | | |
| `staff_note` | text | ✓ | | ≤ 500 |
| `created_by`, `created_at`, `updated_at` | | | | |

0005 seeds the six homepage clips from `src/content/videos.ts` (YouTube ids and English titles). The **two founder clips**
are seeded at once. The **four class clips** are **gated** (decision 7, 14 Oct 2026): their legacy cover is all five child
media channels, with the note "Owner statement 14 Oct 2026; written source to be recorded before G4 (G0 Q15)", but the
written source is pending, so they are seeded only when the session setting `cherrylee.legacy_clip_source_recorded` is
`'on'` (see § 18, item 10). The builder never sets it in the file.

`media_asset_children` — `asset_id` → `media_assets` (cascade), `child_id` → `children` (cascade), `created_by`,
`created_at`, `primary key (asset_id, child_id)`.

RLS: staff select/insert/update (assets), owner delete (assets); staff select/insert/delete (links).

### 6.21 `dsr_requests` (P5 · 0007)

Rights requests. Owner only. **Column `requested_right` replaces the architect's `right`** (§ 14).

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `family_id` | uuid | ✓ | | → `families`, set null |
| `requester_name` | text | | | 1–80 |
| `requester_contact` | text | ✓ | | ≤ 120, how to reply (**new**) |
| `requested_right` | `dsr_right` | | | |
| `channel` | `dsr_channel` | | | |
| `details` | text | ✓ | | ≤ 1000, one sentence; no health details (**new**) |
| `received_at` | timestamptz | | `now()` | |
| `identity_verified_at` | timestamptz | ✓ | | |
| `identity_verified_by` | uuid | ✓ | | → `auth.users`, set null (**new**) |
| `review_due_at` | timestamptz | | trigger | `received_at + 15 days` |
| `due_at` | timestamptz | | trigger | `+ 30 days`; `+ 90 days` for `erasure` |
| `extended_until` | timestamptz | ✓ | | at most `due_at + 30 days` (trigger raises otherwise) |
| `status` | `dsr_status` | | `received` | `refused` needs `refusal_reason`; `completed`/`refused` need `responded_at` |
| `outcome`, `refusal_reason` | text | ✓ | | ≤ 1000 |
| `responded_at` | timestamptz | ✓ | | |
| `handled_by` | uuid | ✓ | | → `auth.users`, set null (**new**) |
| `created_at`, `updated_at` | timestamptz | | `now()` | |
| `retain_until` | timestamptz | | trigger | `(responded_at or received_at) + 3 years` |

RLS: owner select/insert/update. Audited.

### 6.22 `breach_incidents` (P5 · 0007)

| Column | Type | N | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | | | |
| `title` | text | | | 1–200 |
| `description` | text | ✓ | | ≤ 4000; describe, never paste leaked data |
| `aware_at` | timestamptz | | | |
| `pdpc_deadline` | timestamptz | | trigger | `aware_at + 72 hours` (PDPA s.37(4)) |
| `risk_level` | `breach_risk` | | | `high` ⇒ notify parents without delay |
| `data_categories` | text[] | | `{}` | e.g. `{child_health, contacts}` |
| `affected_count` | integer | ✓ | | ≥ 0 |
| `measures` | text | ✓ | | ≤ 4000 |
| `pdpc_notified_at`, `subjects_notified_at`, `closed_at` | timestamptz | ✓ | | |
| `created_by`, `created_at`, `updated_at` | | | | |
| `retain_until` | timestamptz | | trigger | `(closed_at or aware_at) + 5 years` |

RLS: owner select/insert/update. Audited.

---

## 7. Views

All `security_invoker = true`; anon has no grant; `authenticated` and `service_role` may select (RLS of the
underlying tables decides what comes back).

| View | File | Columns | Who sees rows |
|---|---|---|---|
| `package_balances` | 0004 | `package_purchase_id, family_id, package_code, status, purchased_on, expires_on, sessions_total, sessions_used, sessions_left` (used = `sessions_used_purged` + live credit bookings, `booking_is_live`: held, confirmed, attended, absent, cancelled_late; R-10; round three) | staff |
| `current_consents` | 0005 | `consent_record_id, family_id, child_id, purpose, given_by, decision, media_level, consent_text_id, channel, method, created_at` (latest per child × purpose × given_by) | staff |
| `current_marketing_consents` | 0005 | `guardian_consent_record_id, family_id, guardian_id, purpose, decision, given_at, channel, consent_text_id` (latest per guardian; § 6.17a) | staff |
| `marketing_follow_up_list` | 0007 | `family_id, guardian_id, guardian_name, family_label_th, family_label_en, consented_at` (one row per guardian whose current choice is `granted`; label from `family_label()`: every attending child, `ครอบครัวน้อง…` / `Family of …` (round three, brief 5); nickname only; active, non-restricted families with at least one attending child; decision 2; card P3-19) | staff |
| `report_requests_weekly` | 0008 | `week_start (Monday, Bangkok), status, requests, children` | staff |
| `report_session_fill` | 0008 | `session_id, session_date, status, capacity, seats_held_offline, seats_booked, attended, absent, cancelled, seats_left, cancelled_late, cancelled_studio` (round three: `cancelled`, `cancelled_late` and `cancelled_studio` count `booking_cancellation_log` outcomes `family_on_time`, `family_late` and `studio`) | staff |
| `report_attendance_monthly` | 0008 | `month, sessions, bookings, attended, absent, cancelled, attendance_rate_pct, cancelled_late, credit_bookings, cancelled_studio` (round three: `attendance_rate_pct` = attended / (attended + absent), so `cancelled_late` is **not** an absence and is left out; the three cancellation columns come from `booking_cancellation_log`) | staff |
| `report_revenue_monthly` | 0008 | `month, method, payments_paid, paid_thb, payments_refunded, refunded_thb` | **owner only** (zero rows for staff) |

`sessions_used` counts credit-using bookings: `consumes_credit` and `booking_is_live` (§ 8), so `absent` and `cancelled_late` count as used, while a cancellation on time (`cancelled`) and a studio cancellation (`cancelled_studio`, credit returned) do not (rounds two and three).

---

## 8. Database functions

"Caller" = who is meant to call it. Call from TypeScript with `.rpc("<name>", { p_…: … })`. Grants: **anon never**.

| Function | Returns | Security | Caller | Notes |
|---|---|---|---|---|
| `has_role(_user_id uuid, _role app_role)` | boolean | definer | RLS / functions | |
| `is_staff()` | boolean | definer | RLS policies | owner **or** staff |
| `is_owner()` | boolean | definer | RLS policies | |
| `current_app_role()` | `app_role` \| NULL | definer | `requireStaff` / `requireOwner` via `context.supabase.rpc("current_app_role")` | |
| `require_staff_or_server()` | void | definer | other functions | passes for staff, `service_role`, or no API role (cron); else 42501 (**new**) |
| `require_owner_or_server()` | void | definer | other functions | same for owner (**new**) |
| `log_audit_event(p_action, p_table, p_row_id, p_details)` | void | definer | other definer functions only | (**new**) |
| `record_family_print(p_family_id, p_include_health)` | void | definer | `getPrintSheet` (P4-25), first call | (**new**, 0005 § 9b) staff or server. One `audit_log` row: action `print_record`, table `families`, row id = family id, details `{include_health}` only. Raises P0002 for a missing family. |
| `set_updated_at()`, `audit_row_change()`, `prevent_update_delete()` | trigger | — | triggers | bypass for append-only: `set_config('cherrylee.allow_purge','on',true)` inside purge/erase only |
| `prevent_last_owner_removal()` | trigger | definer | trigger on `user_roles` | (**new**) |
| `is_valid_request_children(p jsonb)` | boolean | immutable | CHECK on `booking_requests.children` | (**new**) |
| `check_rate_limit(p_bucket text, p_key_hash text, p_max_per_hour int, p_max_per_day int)` | boolean | definer | **service role only** (`checkRateLimit`) | TRUE = allowed (and recorded); FALSE = limited. Advisory-locked per key. |
| `purge_expired_records()` | jsonb | definer | pg_cron (service role may call) | counts per table + `"version"` |
| `session_seats_left(p_session_id uuid)` | integer \| NULL | definer (plpgsql) | staff, server, views | NULL when capacity unset; never below 0; refuses no-role users (R-20) |
| `get_sessions_with_seats(p_from date, p_to date)` | table `(session_id, session_date, starts_at, ends_at, capacity, seats_held_offline, status, public_note_th, public_note_en, staff_note, seats_left, booked)` | **invoker** | staff (`listSessions`) | one call per month list (R-18); `booked` = held/confirmed/attended/absent bookings (0 before 0004) |
| `create_family_from_request(p_request_id uuid, p_display_name text, p_guardian jsonb, p_children jsonb)` | uuid | **invoker** | staff (`createFamilyFromRequest`) | one transaction (R-15): family + primary guardian + children (`age_years` per child → `reported_age_years`) + request `converted`; `23514` if already converted, `P0002` if missing |
| `set_primary_guardian(p_guardian_id uuid)` | void | **invoker** | staff (`saveGuardian`) | (0004, R-39) clears the family's other primary and sets this guardian, one transaction; never leaves a family without a primary; `P0002` if missing; restricted family → `23514` |
| `get_open_sessions(p_from date, p_to date)` | table `(session_id uuid, session_date date, starts_at time, ends_at time, seats_left int, public_note_th text, public_note_en text)` | definer | **service role only** (`getOpenSessions`) | open sessions from max(p_from, today) to min(p_to, today + 70 days); **never capacity** |
| `generate_weekend_sessions(p_from date, p_weeks int, p_capacity int)` | integer (created) | **invoker** | staff (`generateWeekendSessions`) | Sat + Sun, 09:00–15:00, status `open`, from the first Saturday on/after `p_from`; `p_weeks` 1–26; NULL capacity → studio default; skips existing dates |
| `booking_is_live(p_status booking_status)` | boolean | immutable, SQL | authenticated, service_role (views, triggers) | **Round three (brief 1, 2, 3).** The one rule for "holds a seat and, with `consumes_credit`, uses a credit": true for `held`, `confirmed`, `attended`, `absent`, `cancelled_late`; false for `cancelled` and `cancelled_studio`. Used by the seat index, `validate_booking`, `package_balances`, the seats functions, the roster, the purge, `mark_inactive_families` and the reports. Text labels inside, so no DDL uses a new enum label. |
| `cancel_booking(p_booking_id uuid, p_notice_channel notice_channel, p_notice_at timestamptz, p_studio boolean)` | `cancellation_outcome` | definer, volatile | staff, server (the booking-cancel server function in 20-server-api must call this, not write `status` directly) | **Round three (brief 1, 2, 6).** The only way staff cancel a seat. Family cancel (`p_studio` false): the notice (`line`, `phone`, `teacher` or `in_person`, with its time) decides: at or before (session start − `cancel_notice_hours`) → `cancelled` (credit kept), outcome `family_on_time`; later or no notice → `cancelled_late` (seat kept, one credit), outcome `family_late`. Studio cancel of one seat (`p_studio` true): `cancelled_studio` (credit returned), outcome `studio`, and NO notice allowed (22023). Writes one `booking_cancellation_log` row in the same transaction. Refused: a booking already cancelled (23514), an unknown booking (P0002), `p_studio` NULL (22004). Returns the outcome. Not granted to anon. |
| `child_has_recent_booking(p_child_id uuid)` | boolean | definer, stable, SQL | service_role only (purge, tests) | **Round three (brief 3): the 6-month child_health clock.** True when a live booking (`booking_is_live`, so a `cancelled_late` booking COUNTS) falls on or after (today in Bangkok − 6 months), past or next. `cancelled` and `cancelled_studio` do not count. Used by `purge_expired_records` (v3 and v4). |
| `family_label(p_family_id uuid)` | table `(label_th text, label_en text)` | definer, stable, plpgsql | staff, server (through the view `marketing_follow_up_list`) | **Round three (brief 5).** The follow-up label, written once. Children counted: the family's children with a non-cancelled booking (held, confirmed, attended, absent) in the 6-month window; cancelled_late does not count here (it still counts for the health clock). `child_has_recent_booking` is not used. Nicknames only, in creation order. One child: `ครอบครัวน้อง` + A / `Family of A`. Two: `ครอบครัว` + `น้องA และ น้องB` / `Family of A and B`. Three or more: `ครอบครัว` + `น้องA, น้องB และ น้องC` / `Family of A, B and C`. No attending child → no row. Not granted to anon. |
| `check_make_up_notice(...)` | — | — | — | **Removed in round three (brief 7).** It was the round-one make-up notice check (the original had to be `cancelled` with notice). A rebooking now uses the kept or returned credit, and `validate_booking()` checks the balance. The file drops the function (`drop function if exists`). |
| `child_age_years(p_birth_month date, p_on date)` | integer | immutable | anyone signed in, server | during the birth month the child counts as the new age (errs towards asking the child) |
| `has_active_consent(p_child_id uuid, p_purpose consent_purpose)` | boolean | definer | trigger, server (**not** `authenticated`, R-20) | latest guardian = granted AND child hasn't refused/withdrawn. No age rule. |
| `consent_status(p_child_id uuid, p_purpose consent_purpose)` | text: `granted` \| `needs_child` \| `not_granted` | definer | staff, server | D11: media needs the child's own grant when age ≥ text threshold (default 10) or age unknown; health needs the guardian only |
| `can_publish_media(p_asset_id uuid, p_purpose consent_purpose)` | boolean | definer | staff, server | media purposes only; rules in 0005: legacy note counts only for `legacy_consent_purposes`; `face_hidden` blocks assets with faces; a `youtube` asset on `media_website` also needs `media_youtube` (R-11) |
| `consent_matrix(p_child_ids uuid[])` | table `(child_id, purpose, guardian_decision, guardian_media_level, guardian_decided_at, child_decision, status)` | definer | staff, server | 6 rows per child (health + 5 media channels; marketing_line is never listed; ≤ 200 children); `status` = `consent_status()` (R-18) |
| `media_publishability()` | table `(asset_id, purpose, publishable)` | definer | staff, server | every asset × 5 media purposes (R-18; media_print added 14 Oct 2026) |
| `set_media_asset_children(p_asset_id uuid, p_child_ids uuid[])` | void | **invoker** | staff | replace links in one transaction (≤ 40) (R-15) |
| `publish_consent_text(p_purpose, p_title_th, p_body_md_th, p_title_en, p_body_md_en, p_is_explicit boolean, p_requires_child_consent_from_age smallint)` | integer (new version) | **invoker** | owner (UI parked; SQL editor) | TH + EN of version N+1 and retire older versions, one transaction (R-15) |
| `submit_enrolment(p_link_id uuid, p jsonb)` | jsonb | definer | **service role only** (`submitEnrolment`) | whole `/enrol` statement in one transaction, locks the link row; payload and rules in the 0005 comment (R-15, R-05, R-06, R-21, R-22) |
| `get_child_health(p_child_id uuid, p_include_health boolean)` | table `(child_id, health_consent_status text, has_health_record boolean, allergens text[], other_allergens, foods_to_avoid, care_notes, has_allergy, updated_at)` | definer, volatile | staff (`getChildHealth`, and the print sheet), and the owner export with `true` | **one audit row per call**, with `include_health` in the details. Round three (brief 4): one row per child, even with no health record; `health_consent_status` is `granted`, `refused` (a guardian refusal or withdrawal) or `not_asked` (no guardian choice yet), and is returned **always** (the status line on every sheet). `foods_to_avoid` and `care_notes` are NULL unless `p_include_health` is true. NULL is refused (22004). Round two, 14 Oct 2026 |
| `upsert_child_health(p_child_id uuid, p_allergens text[], p_other_allergens text, p_foods_to_avoid text, p_care_notes text)` | void | definer | staff (`saveChildHealth`), server (`submit_enrolment`) | 42501 without consent; '' → NULL; chips de-duplicated; clears `children.allergy_check_needed_at` |
| `list_session_health_flags(p_session_id uuid)` | table `(child_id uuid, nickname text, health_consent text, has_health_record bool, allergens text[], has_allergy bool, has_other_allergens bool, has_foods_to_avoid bool, has_care_notes bool, health_updated_at timestamptz, allergy_check_needed_at timestamptz)` | definer, volatile | staff (`getSessionHealthFlags`) | **one audit row per call**; booked (non-cancelled) children only; feeds the three roster states (R-07) |
| `mark_inactive_families()` | integer | definer | purge (daily), owner | sets `status`, `last_activity_at`, `retain_until`; skips restricted families |
| `set_family_restriction(p_family_id uuid, p_restricted boolean, p_note text)` | void | definer | owner (`setFamilyRestriction`) | the only way to change the restriction columns; restricting also revokes unused **enrol** links (manage links stay for withdrawals) (D28) |
| `export_family_data(p_family_id uuid, p_include_health boolean)` | jsonb | definer | owner (`exportFamilyData`) | one family only; no token hashes; audit `export` with `include_health`; health only through `get_child_health(child, p_include_health)`, and none when false (round two, decision 3; no default, NULL refused with 22004) |
| `erase_family(p_family_id uuid)` | jsonb counts | definer | owner (`eraseFamily`), purge | see § 13; audit `erase`; cannot be undone. Round three, verifier fix: the round-two behaviour is kept. Future bookings keep their status and credit, and no `studio` log row is written; the family id is detached from the log (`cancellation_log_detached`). |

Trigger-only functions added by this design (all **new**): `set_accounting_retain_until`, `validate_booking`,
`sync_child_last_session`, `queue_storage_cleanup`, `consent_texts_guard`, `validate_consent_record`,
`apply_consent_withdrawal`, `enforce_health_consent`, `set_dsr_deadlines`, `set_breach_deadlines`; from the review:
`guard_package_purge_counter` (R-10), `cancel_bookings_of_cancelled_session` (R-23), `queue_consent_change_alert` (D29),
`guard_family_restriction_columns` and `block_restricted_family` (D28); decision 2 (14 Oct 2026): `validate_guardian_consent_record` (0005), and `block_restricted_family` also guards `guardian_consent_records` (0007).

pg_cron jobs (0002): `purge-expired-records` at `15 19 * * *` UTC (02:15 Bangkok) → `select public.purge_expired_records();`
and `cron-history-cleanup` at `0 20 * * *` → deletes `cron.job_run_details` older than 7 days.

---

## 9. Triggers

| Table | BEFORE | AFTER |
|---|---|---|
| `user_roles` | `prevent_last_owner_removal` (update/delete) | audit |
| `studio_settings` | `set_updated_at` | audit (update) |
| `booking_requests`, `staff_notifications`, `media_assets` | `set_updated_at` | — |
| `sessions` | `set_updated_at` | `cancel_bookings_of_cancelled_session` (update of status; round three: held and confirmed seats become `cancelled_studio`, one `studio` log row each) |
| `families` | `set_updated_at`; `guard_family_restriction_columns` (0007); `block_restricted_family` (0007, update: only system columns may change while restricted, R-36) | audit |
| `guardians`, `children`, `family_contacts` | `set_updated_at`; `block_restricted_family` (0007) | audit |
| `package_purchases` | `set_updated_at`; `set_accounting_retain_until` (insert, update of `purchased_on`); `guard_package_purge_counter` | audit |
| `payments` | `set_updated_at`; `set_accounting_retain_until` (insert, update of `paid_at`) | audit; `queue_storage_cleanup` (update of `slip_path`, delete) |
| `bookings` | `set_updated_at`; `validate_booking` (insert/update); `block_restricted_family` (0007, insert only in effect) | audit; `sync_child_last_session` (insert, update of status/session/child, delete) |
| `consent_texts` | `consent_texts_guard` (insert: sha256; update: only `retired_at`; delete: refused) | — |
| `consent_records` | `validate_consent_record` (insert); `prevent_update_delete` (update/delete); `block_restricted_family` (0007, grants only) | audit; `apply_consent_withdrawal` (insert); `queue_consent_change_alert` (insert, D29); `queue_storage_cleanup` (delete) |
| `guardian_consent_records` | `validate_guardian_consent_record` (insert); `prevent_update_delete` (update/delete); `block_restricted_family` (0007, insert; grants only) | audit; `queue_storage_cleanup` (delete) |
| `child_health` | `enforce_health_consent` (insert/update); `set_updated_at` | audit |
| `family_links` | `set_updated_at`; `block_restricted_family` (0007, insert) | audit |
| `dsr_requests` | `set_dsr_deadlines`; `set_updated_at` | audit |
| `breach_incidents` | `set_breach_deadlines`; `set_updated_at` | audit |

Audit rows contain changed column **names** only; an update that changes nothing but `updated_at` is not logged.

---

## 10. Storage buckets

| Bucket | File | Private | Limit | Types | Policies on `storage.objects` |
|---|---|---|---|---|---|
| `payment-slips` | 0004 | yes | 5 MB | `image/jpeg`, `image/png`, `image/webp`, `application/pdf` | `payment_slips_staff_select`, `payment_slips_staff_insert` (first folder must look like a uuid), `payment_slips_owner_delete`. No update. |
| `consent-evidence` | 0005 | yes | 5 MB | same | `consent_evidence_staff_select`, `consent_evidence_staff_insert`, `consent_evidence_owner_delete`. No update. |

Path `<family_id>/<uuid>.<ext>`. Staff view through 60-second signed URLs. Never overwrite: upload a new object, then
update the row (the old path is queued for deletion).

---

## 11. RLS matrix

S = select, I = insert, U = update, D = delete. "cols" = column-level grant (see the table section). "fn" = only through
the named functions. `service_role` bypasses RLS and has all privileges on every table (server code only).
"no-role" = signed in to Cloud Auth but no `user_roles` row: they see **nothing** anywhere.

| Table / view | anon | no-role | staff | owner | Notes |
|---|---|---|---|---|---|
| `user_roles` | — | S own (none) | S own | S I U D | last owner can't be removed |
| `audit_log` | — | — | — | S | writes by triggers/functions |
| `studio_settings` | — | — | S | S U(cols) | |
| `booking_requests` | — | — | S U(cols) | S U(cols) D | inserts by server only |
| `rate_limit_events` | — | — | — | — | fn `check_rate_limit` (server) |
| `staff_notifications` | — | — | S U(cols) | S U(cols) | inserts by server |
| `sessions` | — | — | S I U | S I U D | public: fn `get_open_sessions` (server) |
| `families` | — | — | S I U | S I U D | D blocked by consent FK from P4 → `erase_family` |
| `guardians` | — | — | S I U | S I U D | |
| `children` | — | — | S I U | S I U D | |
| `family_contacts` | — | — | S I U | S I U D | staff remove = U `is_active = false` (R-22); hard delete owner only (R-39) |
| `package_purchases` | — | — | S; I U while active/closed | S I U D | void = owner |
| `payments` | — | — | S; I U while pending/paid | S I U D | refund/void = owner |
| `bookings` | — | — | S I U | S I U D | cancel = `cancel_booking()` (round three); a direct edit that cancels is refused (42501); attendance is a plain U |
| `booking_cancellation_log` | — | — | S (staff) | — | append-only; written only by `cancel_booking`, the studio path and `erase_family` (§ 6.14a) |
| `storage_cleanup_queue` | — | — | — | S U(cols) | |
| `consent_texts` | — | — | S | S I(cols) U(retired_at) | immutable |
| `consent_records` | — | — | S I(cols, own `recorded_by`) | same | append-only |
| `guardian_consent_records` | — | — | S I(cols; own `recorded_by`; channel ≠ web) | same | append-only; guardian scope (`marketing_line`) only; no child data (§ 6.17a) |
| `child_health` | — | — | fn | fn | `get_child_health`, `list_session_health_flags`, `upsert_child_health` |
| `family_links` | — | — | S I(own `created_by`) U(revoked_at) | same | token functions use the server |
| `media_assets` | — | — | S I U | S I U D | |
| `media_asset_children` | — | — | S I D | S I D | |
| `dsr_requests` | — | — | — | S I U | |
| `breach_incidents` | — | — | — | S I U | |
| views `current_marketing_consents`, `marketing_follow_up_list` | — | 0 rows | S | S | staff only through the base tables' RLS (decision 2) |
| views (`package_balances`, `current_consents`, `report_*`) | — | 0 rows | S | S | `report_revenue_monthly`: owner only |
| bucket `payment-slips` | — | — | S I | S I D | |
| bucket `consent-evidence` | — | — | S I | S I D | |

Parents never touch the database directly: `/book`, `/enrol/$token` and `/my/$token` run server functions that use the
service role and must filter every query by the request or the family resolved from the token (D4).

---

## 12. Data inventory

Lawful bases refer to the Thai PDPA B.E. 2562. Retention = proposals (owner to confirm, lawyer to review). "Staff"
includes the owner. Fields marked ⚠ are sensitive (s.26).

| Table · field(s) | Purpose | Lawful basis | Retention | Who can access |
|---|---|---|---|---|
| `booking_requests` · `guardian_name`, `contact_phone`, `contact_line_id`, `preferred_contact` | Call or message the parent back | s.24(3) steps before a contract, at the parent's request | 6 months after creation | Staff; server inserts |
| `booking_requests` · `children` (nickname optional, age) | Suggest the right session/group | s.24(3) | 6 months | Staff |
| `booking_requests` · `package_code`, `preferred_day`, `preferred_date`, `session_id`, `message` | Understand the request | s.24(3) | 6 months | Staff |
| `booking_requests` · `lang`, `privacy_notice_version` | Reply language; proof of which notice was shown | s.24(3); accountability (s.23) | 6 months | Staff |
| `booking_requests` · `staff_note`, `handled_by`, `contacted_at`, `status` | Follow-up | s.24(5) legitimate interest (running the studio) | 6 months | Staff |
| `rate_limit_events` · `key_hash` | Stop spam on `/book` | s.24(5) | 24 hours | Nobody (server function only) |
| `staff_notifications` · all | Deliver PII-free alerts | s.24(5) | 30 days | Staff |
| `audit_log` · actor, action, table, row id, column names | Security audit trail (PDPC security notification) | s.24(6) legal obligation (s.37) | 12 months | Owner |
| `auth.users` email + `user_roles` | Staff sign-in and access | s.24(3) (staff work) | Until offboarding (same day) | Owner |
| `families` · `display_name`, `preferred_lang`, `staff_note` | Customer record | s.24(3) contract | 12 months after last activity (+30-day notice), then erased | Staff |
| `guardians` · `full_name`, `phone`, `line_id`, `email` | Contact, receipts, consent evidence | s.24(3) | With the family | Staff |
| `guardians` · `has_parental_responsibility`, `responsibility_attested_at` | Who may consent for the child | s.24(6) / s.20 | With the family | Staff |
| `guardians` · `identity_check_*` | Verify the parent (PDPC consent guideline) | s.24(5) | With the family | Staff |
| `children` · `nickname`, `birth_month`, `reported_age_*` | Know the child; age group; the age-10 rule | s.24(3); s.20 | With the family | Staff |
| `children` · `is_active`, `last_session_on` | Operations; health retention | s.24(5) | With the family | Staff |
| `family_contacts` · `name`, `phone`, `relationship`, flags | Emergencies and safe handover | s.24(5) child safety (+ s.24(2) in an emergency); s.25 | With the family | Staff |
| `family_contacts` · `guardian_attests_informed_at` | Show the contact was told (s.25 transparency) | s.24(5) | With the family | Staff |
| `package_purchases` · all | Contract and accounting | s.24(3), s.24(6) Accounting Act | to end of (purchase year + 5) — G11; anonymised on erase | Staff (void: owner) |
| `payments` · `amount_thb`, `method`, `status`, `paid_at`, `receipt_no` | Accounting | s.24(3), s.24(6) | to end of (payment year + 5) — G11; anonymised on erase | Staff (refund/void: owner) |
| `payments` · `slip_path` (file) | Proof of payment | s.24(3), s.24(6) | Same as the payment; file kept on erase (accounting) — G11 | Staff view; owner delete |
| `payments` · `note` | Staff note | s.24(3) | Same; NULLed on erase | Staff |
| `bookings` · session, child, status, check-in/out, pickup person | Seats, attendance, safe handover | s.24(3), s.24(5) | 24 months after the session; anonymised on erase | Staff |
| `booking_cancellation_log` · booking, session, outcome, notice channel and time, recorded by | Cancellation statistics (no names, no health data) | s.24(5) legitimate interest (running the studio) | 24 months after the session (the same as bookings; PROVISIONAL, not yet decided: § 18 open 23); family id removed on erase | Staff |
| `consent_texts` · all | Prove the exact wording (s.19) | accountability | Indefinite (no personal data) | Staff read; owner publish/retire |
| `consent_records` · decision, purpose, who, when, channel, method, snapshots, evidence file | Evidence of consent and withdrawal (s.19, s.20) | s.24(6); legal claims (s.78: 3 years) | While the family exists; after erase + 3 years | Staff read/append |
| ⚠ `child_health` · `allergens`, `other_allergens`, `foods_to_avoid`, `care_notes` | Safe cooking activities | **s.26 explicit consent** (guardian; child's agreement at 10+) | Until withdrawal/refusal (deleted at once), or 6 months after the last session | Staff through audited functions; server for `/enrol` |
| `family_links` · `token_hash`, dates | Private parent links | s.24(3) | 30 days after expiry/revocation/use | Staff |
| `media_assets` · `youtube_id`, `title`, channel flags | Know what is published where | not personal data (titles carry no names) | Until removed | Staff |
| `media_asset_children` | Who appears in which asset | s.19/s.20 consent (publication) | Until the child/family is deleted; yearly review | Staff |
| `dsr_requests` · `requester_name`, `requester_contact`, `details`, outcome | Handle rights requests on time | s.24(6) (PDPC access rules: keep ≥ 2 years) | 3 years after the response | Owner |
| `breach_incidents` · all (no leaked data) | PDPC notification | s.24(6) (s.37(4)) | 5 years | Owner |
| `guardian_consent_records` · `decision`, `given_at`, `channel`, `method`, `guardian_name_snapshot`, evidence file | Marketing choice: follow-up messages about classes from the studio by LINE (separate opt-in, withdrawable at any time; decision 2) | s.19 consent (opt-in) | While the family exists; then erase + 3 years as evidence | Staff read/append; the parent on `/my` (server) |
| `media_assets` · `on_print`; `consent_records` with purpose `media_print` | Print use of photos or videos that show children (posters, leaflets; decision 3) | s.19 consent (guardian; the child's own at 10+, D11) | Until withdrawn or removed; consent evidence as for the other media channels | Staff |
| `marketing_follow_up_list` (view, nothing stored) · family label, guardian name, consent date (no LINE ID) | Staff contact by hand from the studio's LINE OA chat, one family at a time | s.19 consent (opt-in) | Only while the choice is `granted`, the family is active and not restricted | Staff |
| `storage_cleanup_queue` · paths (uuids only) | Delete files SQL can't | s.24(6) (s.37(3)) | 30 days after done | Owner |

**Not collected** (00-overview § 6): national ID or passport numbers, ID card copies, children's full names, full birth
dates, schools, gender, nationality, home address, reasons for foods to avoid, medical histories, diagnoses, medication
lists, raw IPs, cookies, LINE chat content, payer bank account numbers, photos/videos of children. (The marketing choice IS collected since 14 Oct 2026, decision 2, as in § 12 and § 12b; photos for print use are collected by reference only, decision 3.)

---

### 12b. ROPA entry: family follow-up and print use (decisions 2 and 3, 14 Oct 2026)

Draft for the record of processing (ROPA). The lawyer (G9b) reviews the wording and the lawful basis. Not legal advice.

| Item | Entry |
|---|---|
| Activity | Follow-up for families by LINE (by hand), and print use of approved media |
| Controller | CherryLee & Co. (the studio owner) |
| Purposes | (a) Send follow-up messages about classes, class times and class-package offers, only to parents who opted in. (b) Use photos or videos that show children in printed materials, only where the consents on the record allow it |
| Lawful basis | Consent (PDPA s.19), a separate choice for each purpose and each channel. For print use of children's photos: the guardian's consent, and the child's own consent at 10 and over (D11) |
| Data subjects | Parents and guardians (follow-up). Children and their parents (print use) |
| Categories | Follow-up: guardian name, LINE ID hint, decision, channel, time, text version, evidence file. The follow-up label uses the child's nickname only (round two, brief item 4). Print use: media reference, title, face-visibility level. No child names in copy, captions or file names |
| Sensitive data | None in the follow-up choice. Health data is never used for either activity (§ 12, `child_health`) |
| Recipients | Parents only, through the studio's LINE OA chat. No bulk sends (decision 2). No third-party marketing platform |
| Processors and transfer | Database and backend on Lovable Cloud (Supabase), Asia Pacific region, outside Thailand (as in § 12 and 40-integrations). LINE Official Account (the studio's own) |
| Retention | Follow-up choice: while the family exists, then erase + 3 years as evidence. Follow-up list: no separate storage. Print consent: as for the other media channels, until withdrawn; evidence 3 years after erase |
| Security | RLS (staff only, no anon grant); append-only evidence; audit rows without values; the follow-up list shows no phone, no email and no child name, age or health data (nickname label only); restricted families are excluded (PDPA s.34) |
| Rights | Access and portability through `export_family_data` (it includes both records). Withdrawal at any time, on `/my`, on LINE, or through staff |
| Review | Lawyer (G9b) for the 0006 and 0006a texts. Owner for the list of printed materials |

## 13. Retention and the nightly purge

`purge_expired_records()` v4 (0007) runs daily at 02:15 Bangkok, in this order:

1. `mark_inactive_families()` (restricted families skipped): last activity = latest of family created, live
   booking session date (`booking_is_live`: a late cancellation counts; a cancellation on time or by the studio does not), payment, package purchase, consent record, link use (profile edits don't count, R-25).
   No activity for 12 months → `status = inactive`,
   `retain_until = now() + 30 days` (a notice window the admin can show as "scheduled for deletion"). New activity
   → back to `active`, `retain_until = NULL`.
2. `erase_family()` for every family whose `retain_until` has passed (never a restricted family).
3. `rate_limit_events` > 24 h; `staff_notifications`, `booking_requests` past `retain_until`.
4. `child_health` not updated for 6 months **and** no live booking in the last 6 months or in the future (`child_has_recent_booking`; round three, brief 3: a `cancelled_late` booking COUNTS, because its seat was kept and a credit used; a cancellation on time or by the studio does not);
   the child gets `allergy_check_needed_at = now()` (R-07).
5. `family_links` 30 days after expiry / revocation / enrol use.
6. `bookings` past `retain_until` (session + 24 months) — their credits are first added to
   `package_purchases.sessions_used_purged` (R-10) — then `booking_cancellation_log` past `retain_until` (round three),
   then `payments`, then `package_purchases` (year + 5).
7. Detached `consent_records` and `guardian_consent_records` past `retain_until` (erase + 3 years).
8. `dsr_requests` (response + 3 years), `breach_incidents` (+ 5 years).
9. `storage_cleanup_queue` rows done > 30 days ago; `audit_log` past `retain_until` (12 months).

What `erase_family(id)` does (owner erasure request, or retention):

| Data | Result |
|---|---|
| Future held/confirmed bookings | Unchanged status and credit (round-two behaviour kept, verifier fix round three); anonymised (family and child ids NULL). No `booking_cancellation_log` row is written. |
| `booking_cancellation_log` | family id → NULL (counts kept until session + 24 months; round three) |
| `consent_records` | detached (ids → NULL), name/nickname snapshots kept, `retain_until = now() + 3 years` (**lawyer to confirm**) |
| `guardian_consent_records` (marketing choices) | Detached: ids → NULL, `retain_until = now() + 3 years`, rows kept as evidence (decision 2) |
| `bookings` | child/family/pickup → NULL, note → NULL; kept as counts until session + 24 months |
| `payments`, `package_purchases` | family → NULL, notes → NULL; amounts, dates, receipt numbers and slip files kept (accounting, **G11**) |
| `booking_requests` of the family | deleted |
| `families` → `guardians`, `children` (→ `child_health`, media links), `family_contacts`, `family_links` | deleted (cascade) |
| `dsr_requests` | kept (family → NULL) |
| Files in `consent-evidence` | kept with the detached evidence; queued for deletion when it is purged |
| Published clips/photos | **not** automatic: follow the takedown runbook in `50-security-privacy.md` |

Files are deleted through the Storage API from `storage_cleanup_queue` by the owner-only server function
`runStorageCleanup` (see § 14). An **orphan** file is one whose path is not referenced by any `payments.slip_path` or
`consent_records.evidence_path` (rows of erased families still reference their slips and evidence, so those are never
orphans, R-08). Orphan checks are a manual runbook step after a restore (`50-security-privacy.md` § 19.4), not code.

---

## 14. Deviations from 00-overview and new names

Everything below is a deliberate change or addition; other files must use these exact names.

**Deviations**

| Architect said | This file does | Why |
|---|---|---|
| `dsr_requests.right` | `dsr_requests.requested_right` | `RIGHT` is a reserved SQL keyword; a bare column named `right` breaks plain SQL |
| `consent_texts.sha256` "generated always as …" | plain column set by the BEFORE INSERT trigger `consent_texts_guard()` with the same formula | `convert_to()` is STABLE, and generated columns require IMMUTABLE expressions |
| `consent_records.recorded_by`, `family_link_id` (implied FKs) | plain uuid columns | an `ON DELETE SET NULL` would UPDATE the append-only table and be blocked |
| Seeding the six clips "in F4-07" | seeded by 0005 (public ids and titles only) | deterministic; no UI work needed to start |
| `storage.objects` cleanup by purge | queue table + owner server function | SQL can't delete Storage files |

**New names** (not in 00-overview § 10)

- Table: `storage_cleanup_queue` (bucket_id, object_path, reason `row_deleted|replaced`, queued_at, deleted_at, last_error).
  Needs owner server functions — suggested `listStorageCleanup` and `runStorageCleanup` in
  `src/lib/backend/privacy.functions.ts` (the second calls `supabaseAdmin.storage.from(bucket_id).remove([object_path])`
  and sets `deleted_at` or `last_error`).
- Functions: `require_staff_or_server`, `require_owner_or_server`, `log_audit_event`, `prevent_last_owner_removal`,
  `is_valid_request_children`, `set_accounting_retain_until`, `validate_booking`, `sync_child_last_session`,
  `queue_storage_cleanup`, `consent_texts_guard`, `validate_consent_record`, `apply_consent_withdrawal`,
  `enforce_health_consent`, `set_dsr_deadlines`, `set_breach_deadlines`; second review: `set_primary_guardian`
  (0004, R-39); decision 10: `check_make_up_notice` (0004, **removed in round three**); decision 2: `validate_guardian_consent_record` (0005). Policy renamed: `family_contacts_owner_delete` (was `family_contacts_staff_delete`, R-39).
- Columns: `children.reported_age_years`, `children.reported_age_on`; `consent_records.guardian_name_snapshot`,
  `consent_records.child_nickname_snapshot`; `media_assets.shows_faces`, `media_assets.on_parents_group`;
  `dsr_requests.requester_contact`, `dsr_requests.details`, `dsr_requests.identity_verified_by`,
  `dsr_requests.handled_by`; `created_by` on `families`, `sessions`, `package_purchases`, `bookings`, `media_assets`,
  `media_asset_children`, `breach_incidents`; `staff_note` on `package_purchases`, `bookings`, `media_assets`;
  `payments.note`; `family_links.updated_at`; `breach_incidents.description`.
- Return columns: `list_session_health_flags` (`health_consent`, `has_health_record`, `has_other_allergens`,
  `has_foods_to_avoid`, `has_care_notes`); `current_consents.consent_record_id`.
- Tables, views and columns added 14 Oct 2026 (decisions 2, 3, 10): table `guardian_consent_records` (§ 6.17a); views `current_marketing_consents` (0005) and `marketing_follow_up_list` (0007); column `studio_settings.cancel_notice_hours` (0004); column `media_assets.on_print` (0005); purposes `marketing_line` (guardian scope only) and `media_print` (child media); function `check_make_up_notice` (0004).
- Round three names (14 Oct 2026, the owner's third set of answers, briefs 1–8). **Keep as written; other files use these exact names.**
  - Booking statuses: `cancelled` (family on time, credit kept), `cancelled_late` (seat kept, not an absence, one credit), `cancelled_studio` (credit returned, not used), `absent` (one credit).
  - Table `booking_cancellation_log` (append-only, § 6.14a); enum `cancellation_outcome` = `family_on_time` | `family_late` | `studio`.
  - Enum `notice_channel` = `line` | `phone` | `teacher` | `in_person`. Any counts as notice.
  - Functions: `cancel_booking(booking, notice channel, notice time, studio)` (the only cancel path); `booking_is_live(status)`; `child_has_recent_booking(child)` (the 6-month health clock); `family_label(family)` (the follow-up label). `get_child_health` returns `health_consent_status` (`granted` | `refused` | `not_asked`) and `has_health_record`.
  - Removed: `check_make_up_notice`; the transaction flag `cherrylee.studio_cancel`. The rebooking link `bookings.makeup_of_booking_id` stays, with no notice or status rule.
  - The session-level studio cancel keeps the name `cancel_bookings_of_cancelled_session`.
- Round two names (14 Oct 2026): booking status `cancelled_late`; enum `notice_channel` (round two: `line`, `in_person`; round three extends it, see above); columns `bookings.cancel_notice_channel` and `bookings.cancel_notice_at`; allergen key `flour`; `get_child_health(p_child_id, p_include_health)`; follow-up view columns `family_label_th` and `family_label_en` (replacing `family_display_name`); report columns `cancelled_late` and `credit_bookings`.
- Transaction flags: `cherrylee.allow_purge` (as in 00-overview), used only inside `purge_expired_records` / `erase_family`; `cherrylee.allow_cancel_log` (round three), set only inside `cancel_booking` and `cancel_bookings_of_cancelled_session` (verifier fix: `erase_family` no longer sets it), so that a cancellation can be written only together with its log row. `cherrylee.studio_cancel` (round two) is **removed** in round three: a studio or system cancellation now sets `cancelled_studio` directly, and the credit comes back for that reason.

**Rules the server code must follow because of the database**

- `bookings`: `child_id` required on insert; `family_id` may be omitted (filled from the child); family/child can't be changed.
- `consent_records` staff inserts: `recorded_by = context.userId`. `family_links` staff inserts: `created_by = context.userId`.
- A guardian needs `has_parental_responsibility = true` (+ `responsibility_attested_at`) **before** their `granted` consent.
- Enrolment: `submitEnrolment` makes **one** call, `supabaseAdmin.rpc("submit_enrolment", { p_link_id, p })` (R-15). The SQL
  function does the guardian update (no identity marking, `pending_link_changes` for changed fields), birth months,
  consent records (media: ticked = `granted`; unticked = `refused` only when there is no earlier guardian decision,
  otherwise nothing, R-33; health decline after a grant = `withdrawn`; health grant refused with `23514` when the
  child's own latest health decision is a "no", R-34), health via `upsert_child_health`, contacts
  (soft delete), `used_at`, and returns the queued alert ids. Then the server pushes those alerts and calls
  `notifyStaff('enrolment_submitted', familyId)`.
- Restricted families (0007): writes listed in D28 fail with `23514` "Family processing is restricted" → staff error
  `family_restricted`; public `/enrol` → `invalid_input`.
- `ageFromBirthMonth()` in `src/lib/backend/age.ts` must match `child_age_years()` (the birth month counts as reached).
- `families.status`, `last_activity_at`, `retain_until` are system-managed: `saveFamily` must not write them.
  `processing_restricted_at` / `restriction_note` change only through `set_family_restriction()`.
- `package_purchases.sessions_used_purged` is never sent from TypeScript.
- `family_contacts`: never `.delete()` from the UI; set `is_active = false`. Pickup choices and the enrol form list
  only `is_active = true` contacts.
- **Marketing choice (decision 2, 14 Oct 2026).** `/my` writes through the server with `channel = 'web'`, `method = 'checkbox'` and the link id. A tick after no grant inserts `granted`. An untick after a grant inserts `withdrawn`. An untick with no grant inserts nothing (no `refused` row for marketing). Staff screens (P3-04, P3-11) insert with `recorded_by = context.userId` and channel `line` or `in_person` only (no `paper`; `web` is /my only). `/enrol` never writes a marketing row. Every marketing row carries the `consent_text_id` of the current `marketing_line` text.
- **Cancellations (round three, briefs 1, 2, 6; replaces the round-two send rule).** A family cancellation is sent to **`cancel_booking(booking_id, notice_channel, notice_at, false)`** only, never as a plain status update. The staff booking screen passes the notice channel (`line`, `phone`, `teacher` or `in_person`: any of them counts) and the notice time (the time it reached the studio). The notice is required: with no notice the call is refused (22023), and staff record the missed class as `absent` instead (verifier fix, round three). A studio cancel of one seat → `cancel_booking(booking_id, NULL, NULL, true)` (`cancelled_studio`, credit returned). A studio cancel of a whole session → set `sessions.status` to `cancelled`; the database does the rest. The function returns the outcome (`family_on_time`, `family_late` or `studio`); map it to the copy. Map the errors: 23514 already cancelled, or not held/confirmed (attended and absent cannot be cancelled); 22023 a studio cancel with a notice, or a family cancel with no notice; P0002 not found; 42501 not staff. Round-two text follows.
- **Cancellations (round two, brief item 1; kept for history, see round three above).** The staff booking screen sends status `cancelled` (with notice) or `absent`, plus `cancel_notice_channel` and `cancel_notice_at`. For LINE, `cancel_notice_at` is the time the message arrived in the OA chat. The database decides the final status: `cancelled` with notice at or before (session start − `cancel_notice_hours`) keeps the credit; late or missing notice becomes `cancelled_late` (one credit, and the seat stays taken). `absent` uses one credit. `validate_booking()` recomputes the status and may change what the server sent (for example to `cancelled_late`); the server never writes `cancelled_at`, and the database does. A studio cancellation of a whole session is `cancelled` with no notice channel and no notice time, and keeps the credit.
- **Health reads (round two, brief item 3; round three, brief 4).** Health is read only through `get_child_health(child, includeHealth)`, with the boolean chosen by staff for that print (`record_family_print` is called first). **Round three:** the print sheet shows the health consent status line on EVERY sheet (`health_consent_status`: `granted`, `refused` or `not_asked`); allergen checklist always shows; `foods_to_avoid`, `care_notes` and the free-text `other_allergens` show only when true (verifier fix, round three: other allergies are health content; the owner has not ruled on the free text, open question). The export passes the staff choice too (`export_family_data(family, includeHealth)`); with false the file has no health data. The print sheet calls `get_child_health` for every child (allergens always show; `foods_to_avoid`, `care_notes` and `other_allergens` only when true). There is no other route.
- **Follow-up list (round two, brief items 4 and 5; round three, brief 5).** `marketing_follow_up_list` has one row per granted guardian. The label names every child who attends (a non-cancelled booking in the 6-month window; verifier fix, round three), nicknames only: `family_label_th` / `family_label_en`. The screen shows them with `guardian_name`; wrap the Thai label in `<Nobr>` (`<Nobr>` rule in `AGENTS.md`). Never a full name, age or health data, and only to staff.
- **Rebooking (decision 10; round three, brief 7).** `check_make_up_notice` is **removed**: there is no make-up notice check. A rebooking is an ordinary booking insert, and it uses the kept or returned credit. The server does **not** send or read `makeup_of_booking_id` (verifier fix, round three; 20 § 9.7 and P3-06 step 4 say the same). The column and its index stay in the database as an optional reference. `validate_booking()` refuses the insert (23514) when the family has no session left.
- **Media (decision 3).** `/enrol` and `/my` accept the five child media purposes. `media_print` follows the same publishability and face-level rules as `media_social`.

---

## 15. TypeScript types

Types are **generated by Lovable**, never written by hand. After every G4, Lovable regenerates
`src/integrations/supabase/types.ts` (pulled with `git pull --ff-only`). Never edit that file. Until a migration is
applied, its tables don't exist in the types, so code that uses them can't compile; that is why tasks wait for the gate.

```ts
import type { Database } from "@/integrations/supabase/types";

type Tables = Database["public"]["Tables"];
export type BookingRequestRow = Tables["booking_requests"]["Row"];
export type BookingRequestInsert = Tables["booking_requests"]["Insert"]; // children_count is generated: don't send it
export type BookingRequestStatus = Database["public"]["Enums"]["booking_request_status"];
export type OpenSession = Database["public"]["Functions"]["get_open_sessions"]["Returns"][number];
export type PackageBalance = Database["public"]["Views"]["package_balances"]["Row"];
export type HealthFlag = Database["public"]["Functions"]["list_session_health_flags"]["Returns"][number];
```

Notes:
- `jsonb` columns (`booking_requests.children`, function results like `export_family_data`) are typed `Json`. Parse them
  with zod (`BookingRequestInput` children schema) before use; never cast.
- View columns are typed as nullable even when they never are; handle `null` (strict TS).
- RPC argument names are the SQL parameter names: `supabase.rpc("check_rate_limit", { p_bucket, p_key_hash,
  p_max_per_hour: 5, p_max_per_day: 20 })`.
- Don't run the Supabase CLI type generator: Lovable Cloud owns the project and the file is generated for us.
- If a needed name is missing from `types.ts` after G4, stop and report "types not regenerated" — do not add it by hand.

---

## 16. Error codes raised by the database

supabase-js returns them as `error.code` (SQLSTATE). Server functions map them to `PublicErrorCode` (public) or a
friendly thrown error (staff). Never show the raw message to parents; never log personal data with it.

| SQLSTATE | Raised when (message starts with) | Suggested handling |
|---|---|---|
| `42501` | not staff/owner (`Not allowed`), health without consent (`Health information needs…`), append-only write (also `booking_cancellation_log`), editing a consent text, removing the last owner, round three: `A cancellation must be recorded with cancel_booking()` (a direct edit that cancels a booking or changes its notice) | staff: show "ไม่มีสิทธิ์ / Not allowed" or the specific hint; public: `server_error` |
| `23514` | business rule: `No sessions left on this package`, `Package is not active`, `Child does not belong…`, `Pickup contact is not an authorised…`, retired/ineffective consent text, parental-responsibility statement missing, `Request already converted`, `Family processing is restricted` (→ `family_restricted`), round three: `A rebooking must replace a booking of the same child`, `Booking is already cancelled` and `Only a held or confirmed booking can be cancelled` (`cancel_booking`; verifier fix); the old `Make-up needs notice…` is removed (brief 7); CHECK constraints (incl. `consent_records_no_marketing`, `bookings_notice_pair`, `booking_cancellation_log_notice_pair`) | staff: show the rule in TH/EN; public: `invalid_input` |
| `23505` | unique: `ref_code` (retry once with a new code), `receipt_no`, one booking per child per session, one primary guardian | staff: "ซ้ำ / Already exists" |
| `23502` | required value missing (`child_id is required…`, `family_id and child_id are required`) | bug in the caller |
| `23503` | referenced row missing (`Session not found`, `Consent text not found`, FK) | staff: "ไม่พบข้อมูล / Not found" |
| `22023` | bad arguments (round three: `A studio cancellation has no notice` and `A family cancellation needs a notice channel and time` from `cancel_booking` (verifier fix); `check_rate_limit: invalid arguments`, `p_weeks must be between 1 and 26`, `invalid_input: …` from `submit_enrolment`, `invalid_input: not a child media purpose`, `marketing_line is a guardian purpose` from `consent_status`) | bug in the caller; public: `invalid_input` |
| `22004` | `includeHealth must be true or false` (`get_child_health`, round two, brief item 3); `studio must be true or false` (`cancel_booking`, round three) | bug in the caller |
| `P0002` | `Family not found`, `Child not found`, round three: `Booking not found` (`cancel_booking`) | staff: "ไม่พบข้อมูล / Not found" |

---

## 17. Testing the database

- **Unit tests (implementers):** mock supabase-js; never hit a real database; no secrets locally.
- **`sql/tests/rls_smoke.sql`** (builder, read-only, `BEGIN … ROLLBACK`): returns one result table with `part`/`line`.
  Part A checks the catalogue (RLS on, anon has nothing, service-only functions closed, buckets private, definer
  functions pin `search_path`, views are invoker); B and C try every table and protected function as `anon` and as a
  signed-in user with no role; D checks the cron jobs. Any `FAIL` line = stop.
- **`sql/seed_dev.sql`** (builder, ends in `ROLLBACK`): fake family/guardian/children, sessions at 07:00 so they never
  clash with real ones, and ~40 behaviour checks: children JSON validation, rate limit, seats/credits, pickup rules,
  consent immutability, health needs consent, audited reads, withdrawal deletes health, 10+ child consent, face level,
  DSR/breach deadlines, export scope, erase, purge; plus § 7b for the review SQL (R-05 alert queue, R-07 marker, R-11
  legacy/YouTube rule, R-15 `create_family_from_request` / `set_media_asset_children` / `publish_consent_text` /
  `submit_enrolment`, R-21/R-22/R-33/R-34 enrolment rules, R-35, R-36/R-37 restriction, R-39 primary guardian). § 7c (14 Oct 2026 decisions): marketing_line (guardian scope, follow-up list, restriction, append-only), media_print (media_social rules), `cancel_notice_hours` (the make-up check is gone in round three). § 7e (round three): `cancel_booking` and the cancellation log (on time, late, studio, phone and teacher notices), the guards, the rebooking rule, the follow-up label for one, two and three children, the print status line (`granted` / `refused` / `not_asked`), the 6-month clock, and the reports read from the log. § 7d (round two, 14 Oct 2026): the credit rule by notice (exactly on time, one second late, no notice, absent, studio cancellation, notice pair), the report columns, the follow-up two-row rule and nickname-only label, the allergen key `flour`, and `get_child_health` with `includeHealth`.
  The row lock in `submit_enrolment` needs two sessions and is checked by reading the SQL. Prefer a local Supabase; on the Lovable database only with the
  owner's OK, never as a migration, and never without the final `ROLLBACK`.
- These SQL files were **not executed** while planning (no database is enabled yet). The first G4 is also the first
  real syntax check: if Lovable reports an error, fix the draft before anything else (§ 2.2 step 4).

---

## 18. Open questions

1. **G11** — accounting retention: is 5 years after the year-end right, and is the studio a juristic person? (`set_accounting_retain_until`)
2. **Lawyer** — keeping guardian name / child nickname snapshots on detached consent evidence for 3 years after erasure; keeping slip files after erasure.
3. **Lawyer (D11)** — health: guardian explicit consent + child's agreement at the first session for ages 10+; media: both consents for 10+.
4. **Owner** — is a 30-day notice window before deleting inactive families useful, or should deletion happen exactly at 12 months?
5. **Owner (G0 Q4)** — may siblings share one package? The DB currently allows any child of the same family to use a family's package.
6. **Technical (after G2)** — does Lovable's migration tool accept `create extension if not exists pg_cron` and `cron.schedule` in a chat-applied migration, or must Jobs be created another way? (`40-integrations.md` § 7)
7. **Technical** — does Lovable apply SQL statements on `storage.buckets` / `storage.objects` from chat migrations? If not, create the buckets and the six storage policies through Lovable's Storage UI with the same names and rules.
8. **Resolved (round two, owner, 14 Oct 2026, brief item 1: option a).** A cancellation with notice on time (at or before the session start minus `cancel_notice_hours`) keeps its credit (`cancelled`). An absence, or a cancellation with late or no notice, uses one credit (`absent` or `cancelled_late`). Implemented in `validate_booking` (0004), `package_balances`, the seat functions, `purge_expired_records` (0007) and the reports (0008). Make-up uses the same notice rule. Open detail for the owner: `cancelled_late` keeps the seat and counts as not attended in the reports.
9. **Owner and implementer — make-up flow (decision 10), superseded in round three.** Round three (brief 7): there is no make-up notice check and `check_make_up_notice` is removed; see question 16 and § 6.14. The rest of this item is history. Notice is given by LINE (staff record channel `line`, with the time the LINE message arrived) or in person (`in_person`). Round two (owner): no web notice form in this scope. (History, round two: the make-up booking function was specified in 20-server-api § 9.7, and `check_make_up_notice` received the ORIGINAL booking's `cancel_notice_at`. Both are superseded in round three.)
10. **Builder — class clips (decision 7, G0 Q15): CERTIFIED by the owner on 14 Oct 2026.** The legacy note reads "Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents' LINE group, social, YouTube, print)". G0 Q15 is ticked. The four class clips are still seeded only when `cherrylee.legacy_clip_source_recorded` = `'on'` in the same SQL editor run at G4 · 0005 (the builder's step, never in the file). `src/content/videos.ts` needs no change for this decision.
11. **Owner (decision 2).** Should the marketing question also appear on `/enrol`? Decision 2 names only P3-04, P3-11 and `/my`, so this draft does not ask it on `/enrol`.
12. **Owner (decision 3).** Which printed materials the studio really uses. The 0006 `media_print` text names posters, leaflets and promotional handouts as OWNER-APPROVE items; remove any the studio does not use.
13. **Lawyer (decisions 2 and 3, and brief item 4, G9b).** The `marketing_line` text (0006a): the separate opt-in, the withdrawal promise, the 3-year evidence sentence, and (round two, brief item 4) the child-nickname sentence: the staff list uses the nickname only, for the studio's own follow-up, and is never shown publicly. The `media_print` text (0006) is not changed by this round.
14. **Resolved (round two, owner, 14 Oct 2026, brief item 5).** The follow-up list has one row per consenting guardian (`marketing_follow_up_list`). A family with two consenting guardians has two rows, each with the same family label; `guardian_name` tells them apart.
15. **Owner (round two, brief item 4).** A family with no active child is left off the follow-up list (the label needs a nickname). Should such a family get a fallback label instead? (Round three: "no active child" is now "no attending child", i.e. no non-cancelled booking in the 6-month window; see brief 5.)
16. **Resolved (round three, owner, 14 Oct 2026, briefs 1–8).** The studio's cancellation returns the credit (`cancelled_studio`) and the family rebooks with it. A late cancellation keeps the seat, is not an absence and uses one credit (`cancelled_late`), and is counted in `booking_cancellation_log`. Any notice channel (`line`, `phone`, `teacher`, `in_person`) counts. A `cancelled_late` booking counts for the 6-month health clock and for the follow-up label. The print sheet always shows the health consent status. Identifiers in the docs are kept (the owner's answer 7: no removal; nothing is deleted).
17. **Lawyer sign-off (decision 8, round three).** The lawyer's sign-off for the changed wording (`คุณผู้ปกครอง` in 0006a; the nickname line in 0006a; notice §§ 3.6, 3.10 and 3.11) is **done**, per the owner's report on 14 Oct 2026. The written sign-off is kept with the decision record. This section records the owner's report; it is not the sign-off itself.
18. **Owner (round three, brief 2).** Can a cancellation be **undone** (for example a wrong notice time or a mis-keyed cancel)? The round-three rule refuses any direct edit that leaves or changes a cancellation (42501), and `cancel_booking` refuses a second cancel. Until it is decided, no screen undoes a cancellation, and the log keeps the record of the first cancellation.
19. **Owner (round three, brief 5).** The follow-up label counts every child with a non-cancelled booking in the 6-month window (verifier fix: cancelled, cancelled_late and cancelled_studio do not count), even a child the studio has deactivated (`children.is_active` is not checked, as the brief says). Should a deactivated child drop off the label?
20. **Owner (round three, brief 7).** A rebooking uses the kept or returned credit, with no notice rule. Should a rebooking that is made for a seat cancelled **late** also be limited (for example, one rebooking per cancellation)? The database enforces one live rebooking per original (`bookings_one_makeup_per_original`) only.
21. **Owner (verifier, round three; 00 § 13B c).** Does a `cancelled_studio` booking count for the 6-month `child_health` clock? The SQL says no (`child_has_recent_booking`), as a provisional reading. The decisions are silent.
22. **Owner (verifier, round three; 00 § 13B g).** Does a `cancelled_late` booking sit in the attendance-rate denominator? The SQL leaves it out of both the numerator and the denominator, as a provisional reading (`report_attendance_monthly`).
23. **Owner (verifier, round three; 00 § 12 and 50 § 19.1).** Retention of `booking_cancellation_log`: the SQL uses 24 months after the session date, as a provisional reading. Not decided.
24. **Owner (verifier, round three; D52 and the notice § 3.10).** The follow-up label window: the SQL counts a non-cancelled booking from 6 months back with no upper bound (future bookings count too). The notice says "last 6 months". Which window applies?
25. **Owner (verifier, round three; D49 title "misses").** Is a missed class (no notice) an absence (as the decisions body and 20 § 9.7 say, implemented) or a `cancelled_late`? The D49 title reads "cancels late or misses".
26. **Owner (verifier, round three).** The free-text `other_allergens`: does it print on every sheet, or only with the includeHealth tick? The SQL now gates it with includeHealth (the decisions only fix the allergen checklist as always-on).
27. **Owner (verifier, round three; open question a).** A child with no nickname: the enrolment and booking forms say the nickname is optional, but `children.nickname` is NOT NULL and `create_family_from_request` now refuses it with a clear error. Required on intake, or a fallback label?
