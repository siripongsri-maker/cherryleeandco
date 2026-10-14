# 50 · Security and privacy (PDPA operations)

Planning document, October 2026. **This is not legal advice.** It is a working plan based on the PDPA text
(PDPC unofficial English translation) and published guidance. A Thai PDPA lawyer must review the privacy notice, the
consent texts, the children-10+ approach (D11), the cross-border position and the retention schedule before the related
phases go live (gates G9a, G9b).

Names (tables, functions, enums, gates G0–G13 + G-MVP/G-HEALTH/G-PARK, decisions D1–D30, secrets) come from
[`00-overview.md`](00-overview.md); its § 15 lists the October 2026 review resolutions (R-xx) applied here.
If this file disagrees with `00-overview.md`, `10-data-model.md` or `20-server-api.md`, those files win; fix this one.
Setup steps for vendors are in [`40-integrations.md`](40-integrations.md).

Markers: 🧑 **HUMAN** = owner/builder/lawyer step; 🤖 **AGENT** = can be a task card; ⚖️ **LEGAL REVIEW** = wording or
position a lawyer must confirm; ⚠️ **UNVERIFIED** = not confirmed, check before relying on it.

---

## Contents

Part A · Security
1. [Threat model](#1-threat-model)
2. [Secrets inventory](#2-secrets-inventory)
3. [Auth and RLS strategy](#3-auth-and-rls-strategy)
4. [Rate limiting and spam](#4-rate-limiting-and-spam)
5. [Audit log](#5-audit-log)
6. [Logging rules](#6-logging-rules)
7. [Backups and restore](#7-backups-and-restore)
8. [Staff and builder access: onboarding and offboarding](#8-staff-and-builder-access-onboarding-and-offboarding)
9. [Security checklist (every phase)](#9-security-checklist-every-phase)

Part B · PDPA operations

10. [PDPA mapping](#10-pdpa-mapping)
11. [Privacy notice: outline, versions and full draft (TH + EN)](#11-privacy-notice-outline-versions-and-full-draft-th--en)
12. [Consent texts v1 (TH + EN)](#12-consent-texts-v1-th--en)
13. [Consent mechanics checklist (for UI reviewers)](#13-consent-mechanics-checklist-for-ui-reviewers)
14. [Children's data rules](#14-childrens-data-rules)
15. [Health data rules](#15-health-data-rules)
16. [Consent withdrawal flow](#16-consent-withdrawal-flow)
17. [Media consent, `videos.ts` and the takedown runbook](#17-media-consent-videosts-and-the-takedown-runbook)
18. [Data-subject requests (DSR): process and templates](#18-data-subject-requests-dsr-process-and-templates)
19. [Retention schedule and the cleanup job](#19-retention-schedule-and-the-cleanup-job)
20. [Breach response runbook (72 hours)](#20-breach-response-runbook-72-hours)
21. [Cross-border transfer note](#21-cross-border-transfer-note)
22. [Cookies and analytics statement](#22-cookies-and-analytics-statement)
23. [LINE data rules](#23-line-data-rules)
24. [Processors and recipients](#24-processors-and-recipients)
25. [ROPA (record of processing activities)](#25-ropa-record-of-processing-activities)
26. [Staff privacy notice](#26-staff-privacy-notice)
27. [Annual review checklist](#27-annual-review-checklist)
28. [Open legal questions](#28-open-legal-questions)
29. [Sources](#29-sources)

---

# Part A · Security

## 1. Threat model

The studio is small (one owner, one or two staff), the data is about **children**, and the most sensitive item is
allergy/health information. The biggest risks are ordinary ones: a phone left signed in, a link sent to the wrong chat,
a misconfigured table, personal data copied into a log or an AI chat.

| # | Threat | What could happen | Main controls (where) | Residual risk / human action |
|---|---|---|---|---|
| T1 | Database exposed to the public | Anyone reads families or health data through the Supabase API | `anon` has no table grants; RLS on every table, deny by default (D3); service role only in `src/server/supabase-admin.server.ts` (D4); Lovable publish security scan (G10); `sql/tests/rls_smoke.sql` | Fix every critical scan finding before Publish |
| T2 | Service-role key reaches the browser | Full read/write bypassing RLS | Server-only code lives in `src/server/*.server.ts` with the `server-only` marker (the build blocks it by **folder**, not by file name); ESLint rule against importing `@/integrations/supabase/client.server` outside `src/server/**` (F0-03); leak grep after every build | Leak grep must print nothing (README) |
| T3 | Staff account taken over (phished password, shared or lost phone) | Someone reads families, contacts, allergy notes | Email + password, sign-up disabled, leaked-password check (D5); long passwords; owner MFA if Cloud supports it (F5-06); role re-checked on every server call; health reads audited (D20); no bulk health export | Same-day offboarding (§ 8); sign out on shared devices; lost phone = breach runbook § 20 |
| T4 | Private parent link leaked or forwarded (`/enrol/$token`, `/my/$token`) | Another person sees or changes a family's details or consents | 32-byte random tokens, only the sha256 stored (D13); enrol links single-use, 14 days; manage links 90 days and revocable; using a link never marks identity as checked and changed contact details wait for staff (R-21); pages are `noindex` + `referrer: no-referrer`; pages never show stored health notes back; Umami (if used) never tracks these paths | Staff paste links only into that family's own LINE chat; revoke on any doubt |
| T5 | Allergy information missing, stale or not seen at cooking time | A child is exposed to an allergen | Roster shows allergen chips (`list_session_health_flags`) and **never "no allergies" by default**: no record = "no allergy info — check with the family before cooking", removed info shows its date (R-07); enrolment link before the first session; paper form if G-HEALTH = paper (D10, D11) | Teachers check the roster before cooking; the studio decides its own in-class procedure (not set by this plan) |
| T6 | Child handed to the wrong adult | Physical safety | Roster lists authorised pickup contacts (`family_contacts.is_authorised_pickup`) and records who picked up (F3-06) | The studio's own handover habit (e.g. asking for the person's name against the roster). No ID numbers are stored |
| T7 | Children's images published without valid consent, or not removed after withdrawal | Harm to the child, PDPA s.19/20 breach | Per-channel consent, default off; child consent for 10+ (D11); `can_publish_media`; withdrawal creates a staff alert; takedown runbook (§ 17) | Manual steps on YouTube/Facebook/TikTok/LINE groups; copies shared by others can't be fully recalled |
| T8 | Insider over-access | Staff browse health notes or contacts without need | Health reads only via audited SECURITY DEFINER functions; owner reviews `audit_log` monthly (§ 5) | Staff confidentiality briefing (§ 8) |
| T9 | Personal data leaking into side channels | Names/phones/allergies in server logs, LINE alerts, analytics, git, Lovable or Claude chats | Logging rules (§ 6); PII-free alert text with a unit test (`40-integrations.md` § 5.7); fake test data only; never paste personal data into Lovable chat (its AI runs outside the Cloud region) | Check Cloud → Logs after each phase |
| T10 | Spam or bots flood `/book` | Junk data, LINE quota used up, staff time wasted | Honeypot, 3-second minimum, Turnstile, HMAC-IP rate limit 5/h and 20/day (D18); `booking_form_open` switch | Owner can close the form in `/admin/settings` |
| T11 | Data kept too long | PDPA s.33/s.37(3) breach; bigger impact if leaked | `retain_until` + daily `purge_expired_records()` (D19); `mark_inactive_families()`; `storage_cleanup_queue` + owner file cleanup via the Storage API (§ 19.4) | Jobs stop if Cloud is paused (credits); check Jobs monthly |
| T12 | Restore brings back deleted data | A withdrawn health record or an erased family reappears | Restore procedure re-applies withdrawals and erasures (§ 7.3) | Only the owner restores |
| T13 | Lovable project access too wide | Anyone with edit access to the Lovable project can open Cloud → Database, export a table as CSV, read secrets' names and **restore backups** | Keep the Lovable workspace/project to the owner and one named builder (§ 8.3); builder signs a confidentiality note | Review project members every quarter |
| T14 | Script injection (XSS) through text parents type | A parent's message runs code in a staff browser and steals the session (stored in localStorage) | React escapes text by default; **never** use `dangerouslySetInnerHTML` for user text (the only allowed use is the server-generated PromptPay SVG); zod length limits; no new third-party scripts on `/admin` | Code review rule in every UI card |
| T15 | Cross-site request forgery on server functions | A malicious page triggers staff actions | `csrfMiddleware` stays in `src/start.ts` (G3 check); staff calls need a Bearer token, which other sites can't read | Keep both middlewares (F0-06) |
| T16 | Backend unavailable (Cloud paused, outage) | Lost booking requests | Public pages never wait on the DB (D15); every failure offers "send on LINE"; LINE stays the main channel | Owner tops up credits; § 14 of `40-integrations.md` |
| T17 | Owner locked out or unavailable | Nobody can handle a rights request or a breach in time | Owner password in a password manager; builder knows the runbooks; the Lovable workspace owner can reset users in Cloud → Users | Name a backup person for the 72-hour breach clock (G0) |

---

## 2. Secrets inventory

Values are never written down in this repo, in chat or in screenshots. "Where stored" is the only place the value lives.

| Name | Kind | Set by | Where stored | Who can read the value | Used by | If leaked | Rotation |
|---|---|---|---|---|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | DB admin key (bypasses RLS) | Lovable (auto) | Lovable Cloud | server code only | `supabaseAdmin` via `src/server/supabase-admin.server.ts` | **Critical**: full database access → breach runbook | ⚠️ UNVERIFIED; ask Lovable support |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_ANON_KEY`, `SUPABASE_DB_URL`, `LOVABLE_API_KEY` | platform | Lovable (auto) | Lovable Cloud | server code | generated clients | `SUPABASE_DB_URL` includes DB credentials (critical); the others are low-risk (`anon` has no grants) | Lovable support |
| `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` | **public** build-time | Lovable (auto) | committed `.env` | everyone (in the browser bundle by design) | generated browser client | none by itself: RLS + no `anon` grants protect data | — |
| `IP_HASH_SECRET` | HMAC key (64 hex) | Owner | Cloud → Secrets | server code | `hash.server.ts` (`hashIp`) | IP hashes in `rate_limit_events` (kept 24 h) could be brute-forced back to IPs | `40-integrations.md` § 4 |
| `TURNSTILE_SECRET_KEY` | API secret | Owner | Cloud → Secrets | server code | `turnstile.server.ts` | Bots could validate tokens; low impact | Cloudflare → Rotate secret key |
| `LINE_ALERT_CHANNEL_ID` | identifier | Owner | Cloud → Secrets | server code | `line-alert.server.ts` | low alone | — |
| `LINE_ALERT_CHANNEL_SECRET` | API secret | Owner | Cloud → Secrets | server code | `line-alert.server.ts`, `line-signature.server.ts` | Someone could push messages as the alert OA to its friends/group | LINE console → reissue |
| `LINE_ALERT_TO` | user/group ID | Owner | Cloud → Secrets | server code | `staff-notify.server.ts` | low (only useful with the channel secret) | — |
| `PUBLIC_SITE_URL` | config | Owner | Cloud → Secrets | server code | admin links in alerts | none | — |
| `PROMPTPAY_ID` (P6, optional) | business payment ID | Owner | Cloud → Secrets | server code | `/pay/$token` | low (it is shown inside every QR anyway); kept server-side to stay out of the public bundle | — |
| `RESEND_API_KEY` (P6, optional) | API secret | Owner | Cloud → Secrets | server code | backup email alert | spam sent from the account | Resend → delete key |
| `STAFF_NOTIFY_EMAIL` (P6, optional) | owner's inbox | Owner | Cloud → Secrets | server code | backup email alert | low | — |
| `TURNSTILE_SITE_KEY`, `TURNSTILE_TEST_SITE_KEY`, `UMAMI_WEBSITE_ID` | **public** constants | Builder | `src/lib/backend/public-config.ts` | everyone | browser | none | — |
| Staff passwords | credentials | each staff member | password manager | the person only | `/admin/login` | account takeover (T3) | change in Cloud → Users or by the user |
| Owner accounts for Lovable, GitHub, Cloudflare, LINE, Resend, Umami | account logins | Owner/builder | password manager, with 2-step verification wherever offered | the account holder | vendor dashboards | Lovable or GitHub takeover = full system takeover | turn on 2-step verification; review members quarterly |

`LOVABLE_CRON_SECRET` is not used (our cron is SQL-only, D19). If Lovable creates it, leave it alone.

---

## 3. Auth and RLS strategy

Summary of D3, D4 and D5 (details in `10-data-model.md` and `20-server-api.md`).

**Who signs in:** staff only. Lovable Cloud Auth, email + password, public sign-up **disabled**, leaked-password
protection **on**. Parents never get passwords (P0–P6); they use single-use or revocable private links (D13).

**Roles:** `user_roles(user_id, role app_role)` with `owner` and `staff`. SQL helpers: `has_role(_user_id, _role)`,
`is_staff()` (owner or staff), `is_owner()`, `current_app_role()`. All are SECURITY DEFINER with `set search_path = ''`.

**Three ways code reaches the database:**

| Caller | Client | Protection |
|---|---|---|
| Staff page → staff server function | `context.supabase` from the generated `requireSupabaseAuth`, acting as the staff user | `requireStaff` / `requireOwner` middleware (role checked on **every** call) **and** RLS policies using `(select public.is_staff())` / `public.is_owner()`; audit triggers see `auth.uid()` |
| Public form (`submitBookingRequest`, `getOpenSessions`) | service role (`supabaseAdmin`) | zod + spam checks in code; inserts only; `get_open_sessions` returns aggregates only |
| Private link (`/enrol/$token`, `/my/$token`) | service role (`supabaseAdmin`) | `resolveLinkToken(token, purpose)` checks hash, expiry, revoked, used; **every query is filtered by the resolved `family_id`**; health writes go through `upsert_child_health`, which checks consent in the DB |

**Rules that never bend**

- `anon` has **no** grants on any table; `authenticated` gets only what policies need. RLS on every table.
- Admin routes are `ssr: false` and `noindex`. The route guard is only for UX; security lives in the server functions and RLS.
- Removing a staff member's role takes effect on their next server call even if their login token is still valid.
- Health data is **never** read with a plain `select`; only `get_child_health` (audited) or `list_session_health_flags` (chips only, audited).
- Owner-only areas: staff roles, settings changes, DSR, breach log, audit log, consent-text versions, voiding payments, deleting families.

---

## 4. Rate limiting and spam

From D18, applied in this order inside `submitBookingRequest`:

| Step | Check | Failure result | Data kept |
|---|---|---|---|
| 1 | zod schema (`BookingRequestInput`) | `invalid_input` | none |
| 2 | honeypot field `company_website` empty (`isHoneypotFilled`) | **fake success** with a fake ref code; nothing stored, no alert | none |
| 3 | form open ≥ 3 s (`isTooFast`, `MIN_FILL_MS = 3000`) | `too_fast` | none |
| 4 | Turnstile `success` and `action = booking_request` (`verifyTurnstile`) | `bot_check_failed` | none |
| 5 | `check_rate_limit('booking_request', hashIp(ip), 5, 20)` | `rate_limited` | one `rate_limit_events` row (HMAC of IP), deleted after 24 h |
| 6 | `studio_settings.booking_form_open` | `form_closed` | none |

- Raw IP addresses are never stored or logged. `hashIp` = HMAC-SHA-256(ip, `IP_HASH_SECRET`), not a plain hash
  (a plain SHA-256 of an IPv4 address can be reversed by trying all 4 billion addresses).
- Shared mobile IPs (CGNAT) mean limits stay generous. If real parents hit `rate_limited`, the owner can raise the limits
  (new SQL draft, G4). Every failure message offers LINE.
- ⚠️ UNVERIFIED that `cf-connecting-ip` gives the real visitor IP on Lovable hosting (`40-integrations.md` § 2 row 10).
  When no IP is available the server **skips** the rate limit and logs `[booking] no_client_ip` (one shared "unknown"
  bucket would block every parent after five requests, R-25); Turnstile, the honeypot and the 3-second check still run.
- Staff login: Supabase Auth applies its own sign-in rate limits (⚠️ UNVERIFIED values; see Cloud → Users → Auth
  settings). We add nothing on top.

---

## 5. Audit log

Decision D20. Table `audit_log` (append-only, kept 12 months via `retain_until`).

**What is recorded**

| Event | How | Fields |
|---|---|---|
| Insert/update/delete on `families`, `guardians`, `children`, `family_contacts`, `package_purchases`, `payments`, `bookings`, `child_health`, `consent_records`, `user_roles`, `family_links`, `dsr_requests`, `breach_incidents` | trigger `audit_row_change()` | `at`, `actor_user_id` (`auth.uid()`), `actor_kind` (`staff` or `system`), `action` (`insert`/`update`/`delete`), `table_name`, `row_id`, `details` = changed **column names only** |
| Every health read | inside `get_child_health` and `list_session_health_flags` | action `read_health`, child or session id |

Never any field values: an audit log full of names and allergies would be a second copy of the data we protect.

**Who reads it:** owner only. The audit-log viewer screen is **parked** (D27); until it is un-parked the owner opens
**More → Cloud → Database → `audit_log`** (read-only table view; the log holds no field values) for the monthly review.

**Monthly 10-minute review (🧑 owner)**
1. `read_health` count per staff member: does it roughly match the cooking sessions they taught?
2. Any `delete` on `families`, `children`, `consent_records`, `payments`? Expected ones only (owner actions, purge).
3. Any change on `user_roles`? Should match staff changes you made.
4. Activity at odd hours or from someone who has left.
5. If something looks wrong: talk to the person first; if data may have been misused, start § 20.

Suggestion for `10-data-model.md` (not a decided name): have `purge_expired_records()` write one `audit_log` row per run
(`actor_kind = 'system'`, action `purge`, `details` = the jsonb of counts per table, which is not personal data), so the
owner can see purges happening without reading `cron.job_run_details`.

---

## 6. Logging rules

Anything printed with `console.*` in server code lands in **Cloud → Logs → Server logs** (searchable for about 5 days,
downloadable). Rules for every implementer:

- Log **only** an error code and a row id, e.g. `console.error("notify_failed", { id, code })`.
- Never log: request bodies, names, nicknames, phone numbers, LINE IDs, emails, ages, health or allergy fields, IP
  addresses, link tokens, Turnstile tokens, LINE access tokens, secrets, `process.env`.
- Never log raw zod issues or `error.message` from validation on public endpoints: zod messages can echo the value
  that failed (for example an invalid enum "received '…'"). Public functions map validation errors to `invalid_input`.
- Never throw an `Error` whose message contains personal data. `src/start.ts` `errorMiddleware` prints thrown errors
  with `console.error(error)`.
- Don't store third-party response bodies (LINE, Turnstile, Resend) in logs or the database; store short codes.
- 🧑 After each phase's first preview test: search Cloud → Logs for the fake test values (`0800000001`,
  `ผู้ปกครองทดสอบ`, `test.line.id`). Expect zero results.

---

## 7. Backups and restore

### 7.1 What exists (Lovable Cloud)

From https://docs.lovable.dev/features/database.md (checked 13 Oct 2026):
- "Lovable takes a daily backup of your project's database." "Up to roughly 14 days of backups are retained."
- Backups cover the database (schema and data) only. **Storage files (slips, consent evidence) are not backed up.**
- Restore: **More → Cloud → Database → Backups → Restore to this backup**. The database is down for a few minutes.
  "Restoring is permanent. Any data created or changed after the chosen backup is lost." No point-in-time recovery.
- "Restoring is available to anyone with edit access to the project." → keep project access minimal (§ 8.3).
- Export: per-table **Export CSV** from the Database view. Don't make routine exports: each CSV is a new uncontrolled
  copy of families' data. If one is ever needed, keep it encrypted and delete it within 30 days.

What else is "backed up": code = git + Lovable history; secrets = not backed up (the owner can regenerate every custom
secret from the vendor dashboards, `40-integrations.md` § 4).

### 7.2 Erasure and backups (PDPA)

Erased or purged rows stay in daily backups for up to about 14 days and then disappear. That is inside the 90-day
erasure deadline (PDPC 2024 notification). Say so in erasure replies (§ 18.6).

### 7.3 Restore runbook (🧑 owner only)

Restore only for a real emergency (data corruption, a destructive mistake). Before you press Restore:
1. Write down the backup's timestamp (UTC) = **T**.
2. List everything done **after T** that the restore will undo:
   - booking requests, bookings, payments recorded (staff re-enter from LINE/bank app);
   - **consent withdrawals and refusals** (`/admin/families` and the LINE chats) → must be re-recorded, so health rows
     are deleted again and media stays unpublishable;
   - **erasures and rights requests handled** (the owner's LINE/email threads) → re-run `eraseFamily` for each;
   - staff role changes (re-apply in `/admin/settings`).
3. Restore. Then re-apply the list from step 2 the same day, starting with withdrawals and erasures.
4. Storage files are not restored (and `storage_cleanup_queue` rows after T are lost). Files uploaded after T may now
   have no row, and files deleted after T stay deleted while their rows come back: run "files to delete" and the manual
   orphan check in § 19.4 (an orphan = a file **no row references**; never "a family that no longer exists"), and tell
   staff which slips/evidence files are missing.
5. Log the restore in `breach_incidents` if it was caused by an incident; otherwise note it in `90-task-breakdown.md`.

---

## 8. Staff and builder access: onboarding and offboarding

### 8.1 Onboarding a staff member (🧑 owner)

1. Confirm the person needs admin access (teachers who only teach may not).
2. Short briefing (15 minutes), then the person confirms on LINE that they've read the staff privacy notice (§ 26):
   - health notes: open only for the children you teach that day; every opening is logged;
   - never send health information, names with photos, or private links anywhere except the family's own chat;
   - never forward a private link; never screenshot rosters into groups;
   - sign out of `/admin` on shared devices; lock your phone with a PIN/biometrics;
   - tell the owner immediately if a phone is lost or something goes to the wrong chat (§ 20).
3. **Cloud → Users → Add user** with their own email. They set a long password themselves (in person or by phone).
4. `/admin/settings` → give the `staff` role (`setStaffRole`).
5. If they will be in the staff alert LINE group, add them (`40-integrations.md` § 5.6; costs quota per member).

### 8.2 Offboarding (🧑 owner, the same day the person leaves)

1. `/admin/settings` → remove role (`removeStaffRole`). Access stops on their next server call.
2. **Cloud → Users → delete the user** (cannot be undone).
3. Remove them from the staff alert LINE group, the parents' groups they managed, and any shared studio phones.
4. Revoke any private links they created that are still open (family page → revoke).
5. Remove them from Lovable, GitHub, Cloudflare, LINE OA Manager roles, if they had any.
6. Look at their last month in the audit log (§ 5).

### 8.3 Builder and vendor dashboards

- People with **edit access to the Lovable project** can see all tables in Cloud → Database, export CSVs, restore backups
  and see secret names. Keep this to the owner and one named builder. The builder signs a short confidentiality note
  (they are acting for the studio).
- Never ask Lovable's chat to "show rows" from personal tables, and never paste personal data into Lovable, Claude or
  any AI chat. Use fake data for tests (README golden rules).
- The GitHub repo must be **private** (`40-integrations.md` § 2 row 15). Poster images and old commits stay in git history,
  and Lovable sync means history is never rewritten.
- Quarterly: review Lovable workspace members, GitHub collaborators, Cloudflare members, LINE OA admins.

---

## 9. Security checklist (every phase)

🤖 Agents check the code items in their card; 🧑 the builder ticks the rest before G10.

- [ ] RLS enabled on every new table; `anon` revoked; policies named `"<table>_<role>_<action>"`.
- [ ] No new grants to `anon`; SECURITY DEFINER functions use `set search_path = ''` and check `is_staff()`/`is_owner()`
      or are executable only by `service_role`.
- [ ] Server-only code under `src/server/` with the `server-only` first line; no `src/server/index.ts`.
- [ ] Service role imported only from `@/server/supabase-admin.server`.
- [ ] Leak grep on `.output/public` prints nothing.
- [ ] Every staff server function has `requireStaff` or `requireOwner`; every public function returns `PublicResult`.
- [ ] No `dangerouslySetInnerHTML` with user text; no new third-party scripts; no cookies.
- [ ] No PII in logs, LINE alerts, analytics events, test fixtures, commit messages.
- [ ] Storage buckets private; signed URLs 60 s; uploads ≤ 5 MB, `image/jpeg|png|webp`, `application/pdf`.
- [ ] Private-link pages `noindex` + `referrer: no-referrer`; robots.txt disallows `/admin`, `/enrol/`, `/my/`, `/pay/`.
- [ ] Privacy notice covers any new data before collection starts; `PRIVACY_NOTICE_VERSION` bumped (§ 11.1).
- [ ] No consent checkbox pre-ticked; one purpose per checkbox.
- [ ] Lovable publish security scan: no critical findings.
- [ ] Cloud → Users → Auth settings: public sign-up **disabled** (R-20); `rls_smoke.sql` in the SQL editor: no `FAIL`.
- [ ] Cloud → Logs searched for test values: zero hits.

---

# Part B · PDPA operations

## 10. PDPA mapping

Section numbers refer to the Personal Data Protection Act B.E. 2562 (2019).

| PDPA | Requirement (short) | Our measure | Where in the system |
|---|---|---|---|
| s.19 | Consent: before/at collection, explicit, separate, plain language, freely given, withdrawable as easily as given | Versioned TH/EN `consent_texts` (sha256, immutable); append-only `consent_records`; one unticked box per purpose; one-click withdrawal on `/my/$token` | D12, F4-01, F4-04, F5-03; § 12, § 13, § 16 |
| s.20 | Minors: under 10 → parent consents; 10–19 → minor consents, plus parent where the act isn't one the minor can do alone | Guardian consent for every child; child's own consent for media at 10+ (staff, in person); child agreement on health at the first session | D11, `consent_status()`, `child_age_years()`; § 14 |
| s.21 | Use only for the stated purpose | Purposes per table in the ROPA; no reuse for marketing | § 25 |
| s.22 | Collect only what is necessary | Stage-based collection; birth month not birth date; no ID numbers, school, address, reasons for diets | `00-overview.md` § 6; D9 |
| s.23 | Privacy notice before/at collection | `/privacy` (TH/EN), linked next to every form; `privacy_notice_version` stored on each request | F1-02, F3-08, F4-10 (cards P1-02, P3-16, P4-20); § 11 |
| s.24 | Lawful basis for non-consent processing | Booking request = s.24(3) (no checkbox, D8); records = contract; payments = legal obligation; safety = legitimate interest | § 25 |
| s.25 | Data collected from someone else | Emergency/pickup contacts come from the guardian, who attests they told them (`guardian_attests_informed_at`) | P3/P4; § 11 |
| s.26 | Sensitive data (health, religion) needs explicit consent | Separate `child_health` table; DB trigger requires current `health_allergy` consent; dietary reasons never asked; audited reads | D10; § 15 |
| s.27 | No use/disclosure beyond the basis | Recipient list (§ 24); PII-free LINE alerts | § 23, § 24 |
| s.28/29 | Cross-border transfers | Asia Pacific region; DPA kept; disclosed in notice and health text | D2; § 21 |
| s.30 | Access and copy within 30 days | `dsr_requests` (review +15 d, due +30 d); `export_family_data()` / `exportFamilyData` | P5; § 18 |
| s.31 | Portability | JSON export | § 18 |
| s.32 | Objection (incl. direct marketing) | No marketing in scope; objection handled as DSR | § 18 |
| s.33 | Erasure | `erase_family()` / `eraseFamily` within 90 days incl. backups | § 18, § 19 |
| s.34 | Restriction | `families.processing_restricted_at` set by the owner through `set_family_restriction()` (D28); the database refuses new processing while it is set; see § 18.4 | § 18.4 |
| s.35/36 | Accuracy, rectification | Staff edit records; parents correct via enrol link or LINE | P3, P4 |
| s.37(1) | Security measures | RLS, roles, audit log, private buckets, MFA if available, logging rules | Part A |
| s.37(3) | System to delete at end of retention or on request | `purge_expired_records()` daily via pg_cron | D19; § 19 |
| s.37(4) | Breach: PDPC within 72 h; individuals without delay if high risk | `breach_incidents` (`pdpc_deadline` = aware + 72 h); runbook | P5; § 20 |
| s.39 | ROPA | § 25 (required: the studio processes s.26 data regularly, so the small-business exemption doesn't apply) | § 25 |
| s.40 | Processor agreements | Lovable DPA saved (G2); other vendors' terms listed | § 24 |
| s.41 | DPO | Very likely **not** required (health data is not the core activity; far below 100,000 people). Name a privacy contact instead | § 11; ⚖️ |
| s.73 | Complaint to the PDPC | Listed in the notice | § 11 |

---

## 11. Privacy notice: outline, versions and full draft (TH + EN)

⚖️ **LEGAL REVIEW** required (G9a for `…-v1`, again for every later version). Owner fills the `{{…}}` placeholders.

### 11.1 Versions and the "collect only after you've told them" rule

PDPA s.23 says the notice must be given **before or at** collection, so every stage publishes its sections **before**
it starts collecting (`00-overview.md` § 8.0, R-02). **This section (11.3 TH, 11.4 EN) is the only source of the
wording**; `30-ui.md` § 3.4 only shows how `src/content/privacy.tsx` is coded. Version format: **`YYYY-MM-vN`** only
(YYYY-MM = the month it goes live; N goes up by one each time the meaning changes).

| `PRIVACY_NOTICE_VERSION` | Ships with | Adds sections (tags below) | Gate |
|---|---|---|---|
| `YYYY-MM-v1` | Stage A (card P1-02), before `/book` goes live | all `[P1]` sections, including 3.9 and its two retention rows (the owner's runbook log of rights requests and incidents exists from Stage A, R-28) | G9a |
| `YYYY-MM-v2` | Stage B (card P3-16), before family records go live | `[P3]`: family records, payments, attendance, contacts, their retention rows | G9a |
| `YYYY-MM-v3` | Stage C (card P4-20), before `/enrol` and `/my` go live | `[P4]`: health (only if G-HEALTH = system), media, enrolment link, children 10+; the `/my` part of `[P5]` | G9a, G9b |
| `YYYY-MM-v4` | only if a parked item that sends data somewhere new is switched on (Umami, Resend, PromptPay page) | `[P6]` rows | G9a |

`PRIVACY_NOTICE_VERSION` is exported from `src/content/privacy.tsx` and saved on each booking request. The page shows
the version and the effective date at the top. Remove the `[Pn]` tags and the HTML comments when building the page,
but keep each section's stage in code (`PrivacySection.phase`). Wrap Thai compound words and names in `<Nobr>` and
English inside Thai in `<En>` (AGENTS.md).

### 11.2 Outline (both languages, same order)

1. About this notice `[P1]`
2. Who looks after your data (controller, contact) `[P1]`
3. What we collect and why
   3.1 Visiting the website `[P1]` · 3.2 Booking request form `[P1]` · 3.3 Chatting with us `[P1]` ·
   3.4 Family records `[P3]` · 3.5 Emergency and pickup contacts `[P3]` · 3.6 Allergy and care information `[P4]` ·
   3.7 Photos and videos `[P4]` · 3.8 Private family links `[P4]` (`/my` part `[P5]`) · 3.9 Rights requests and incident records `[P1]` (R-28)
4. Children's information `[P1]` (10+ paragraph `[P4]`)
5. Who we share data with `[P1]` (+ rows per phase)
6. Data stored outside Thailand `[P1]`
7. How long we keep data `[P1]` (+ rows per phase)
8. How we keep data safe `[P1]`
9. Your rights and how to use them `[P1]`
10. Cookies and similar technologies `[P1]`
11. Changes to this notice `[P1]`
12. Contact us `[P1]`

### 11.3 Full draft — Thai (ภาษาไทย)

```markdown
# ประกาศความเป็นส่วนตัว CherryLee & Co.

ฉบับที่ {PRIVACY_NOTICE_VERSION} · มีผลตั้งแต่วันที่ {{EFFECTIVE_DATE_TH}}

## 1. ประกาศนี้คืออะไร [P1]

CherryLee & Co. (เชอร์รี่ลีแอนด์โค) ดูแลข้อมูลของทุกครอบครัวด้วยความใส่ใจ เหมือนที่เราดูแลเด็กๆ ในห้องเรียนค่ะ
ประกาศนี้อธิบายว่าเราเก็บข้อมูลส่วนบุคคลอะไร ใช้ทำอะไร ส่งต่อให้ใคร เก็บไว้นานแค่ไหน และคุณมีสิทธิอะไรบ้าง
ตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562
หลักของเราคือ เก็บเท่าที่จำเป็นในแต่ละขั้นตอน ไม่ขายข้อมูล และไม่ใช้ข้อมูลเพื่อการโฆษณาค่ะ

## 2. ใครดูแลข้อมูลของคุณ [P1]

- ผู้ควบคุมข้อมูลส่วนบุคคล: {{CONTROLLER_NAME_TH}}
- ที่อยู่: {{FULL_ADDRESS_TH}}
- ติดต่อเรื่องข้อมูลส่วนบุคคล: LINE @cherryleeandco · อีเมล cherryleeandco@gmail.com ·
  มาพบเราที่สตูดิโอ หรือส่งไปรษณีย์ลงทะเบียนมาตามที่อยู่ข้างต้น
- ผู้ประสานงานด้านความเป็นส่วนตัว: {{PRIVACY_CONTACT_TH}}

## 3. ข้อมูลที่เราเก็บ และเหตุผล

### 3.1 เมื่อคุณเข้าชมเว็บไซต์ [P1]

- เราไม่ใช้คุกกี้เพื่อติดตามหรือโฆษณา และไม่ติดตั้งเครื่องมือโฆษณาใดๆ
- ภาษาที่คุณเลือก (ไทยหรืออังกฤษ) บันทึกไว้ในเบราว์เซอร์ของคุณเองเท่านั้น
- ผู้ให้บริการโฮสต์เว็บไซต์ (Lovable ซึ่งทำงานบนเครือข่ายของ Cloudflare) บันทึกข้อมูลทางเทคนิคตามปกติ
  เช่น ที่อยู่ IP เวลา และหน้าที่เปิด เพื่อให้เว็บไซต์ทำงานได้อย่างปลอดภัย และเพื่อนับจำนวนผู้เข้าชมแบบภาพรวม
  (ฐานประโยชน์โดยชอบด้วยกฎหมาย มาตรา 24(5))
- ฟอนต์ของเว็บไซต์โหลดจาก Google Fonts และหน้าแรกมีแผนที่ Google Maps ซึ่ง Google จะได้รับที่อยู่ IP ของอุปกรณ์คุณ
- วิดีโอ YouTube จะโหลดเมื่อคุณกดเล่นเท่านั้น

### 3.2 แบบฟอร์ม "ฝากข้อมูลให้ติดต่อกลับ" [P1]

- **ข้อมูลที่เราขอ:** ชื่อที่สะดวกให้เราเรียก ช่องทางที่อยากคุย (LINE หรือให้โทรกลับ) เบอร์โทรศัพท์ (จำเป็นเฉพาะถ้าอยากให้โทรกลับ)
  LINE ID (ไม่บังคับ ใช้ช่วยหาแชตของคุณเท่านั้น) ชื่อเล่นของน้อง (ไม่บังคับ) และอายุ แพ็กเกจและวันที่สนใจ
  ข้อความถึงเรา (ไม่บังคับ) ภาษาที่ใช้ และฉบับของประกาศนี้ที่คุณเห็นตอนส่ง ระบบจะสร้างรหัสคำขอให้ด้วยค่ะ
- **ถ้าเลือกคุยทาง LINE:** กรุณาส่งรหัสคำขอมาที่ LINE @cherryleeandco บัญชี LINE ทางการของสตูดิโอทักหาใครก่อนไม่ได้
  เราจึงตอบในแชตที่คุณทักมาค่ะ
- **ใช้เพื่อ:** ติดต่อกลับเรื่องการจองและตอบคำถามของคุณ
- **ฐานทางกฎหมาย:** เป็นขั้นตอนก่อนเข้าทำสัญญาตามที่คุณขอ (มาตรา 24(3)) จึงไม่ต้องติ๊กให้ความยินยอม
- **ถ้าไม่ให้ข้อมูล:** เราจะติดต่อกลับไม่ได้ แต่คุณทักเราทาง LINE @cherryleeandco ได้เสมอค่ะ
- **การป้องกันสแปม:** เราใช้ Cloudflare Turnstile ตรวจว่าผู้ส่งเป็นคนจริง และเก็บค่าที่แปลงมาจากที่อยู่ IP
  แบบย้อนกลับไม่ได้ไว้ 24 ชั่วโมงเพื่อจำกัดจำนวนครั้งที่ส่ง เราไม่เก็บที่อยู่ IP จริง
- **การแจ้งเตือนทีมงาน:** ระบบส่งข้อความ LINE ถึงทีมงาน ซึ่งมีเพียงรหัสคำขอ วันที่ และจำนวนเด็ก ไม่มีชื่อหรือเบอร์โทร
- **ระยะเวลาเก็บ:** 6 เดือนนับจากวันที่ส่ง หากยังไม่ได้ลงเรียน

กรุณาอย่าใส่ข้อมูลสุขภาพในช่องข้อความนะคะ ถ้าน้องมีเรื่องที่ต้องดูแลเป็นพิเศษ เราจะสอบถามแยกต่างหากค่ะ

### 3.3 เมื่อคุยกับเราทาง LINE, Messenger หรืออีเมล [P1]

เราใช้ข้อความที่คุณส่งมาเพื่อตอบคำถามและนัดหมายการเรียน (มาตรา 24(3) และ 24(5))
ข้อความแชตเก็บอยู่ในระบบของผู้ให้บริการแต่ละราย (LINE โดย LY Corporation, Messenger โดย Meta, อีเมลโดย Google)
ตามนโยบายของผู้ให้บริการนั้น เว็บไซต์ของเราไม่ได้เชื่อมต่อกับแชตของคุณ
กรุณาอย่าส่งข้อมูลสุขภาพหรือการแพ้อาหารทางแชต เราจะส่งลิงก์แบบฟอร์มส่วนตัวให้แทนค่ะ
<!-- owner to decide: how long staff keep old chats / photos sent in chat -->

### 3.4 ข้อมูลครอบครัวเมื่อเริ่มเรียน [P3]

- **ข้อมูล:** ชื่อ เบอร์โทร LINE ID ของผู้ปกครอง (และอีเมล ถ้าต้องการรับใบเสร็จทางอีเมล) ภาษาที่สะดวก
  ชื่อเล่นและเดือนปีเกิดของน้อง แพ็กเกจที่ซื้อ การชำระเงิน (จำนวนเงิน วิธี วันที่ เลขที่ใบเสร็จ
  และรูปสลิปหากทีมงานเลือกเก็บ) การจองที่นั่ง เวลามาถึงและกลับในวันเรียน และผู้ที่มารับน้อง
- **ใช้เพื่อ:** จัดการเรียนการสอน ดูแลแพ็กเกจและการชำระเงิน และส่งน้องกลับบ้านอย่างปลอดภัย
- **ฐานทางกฎหมาย:** การปฏิบัติตามสัญญา (มาตรา 24(3)) การเก็บบันทึกการเงินตามกฎหมายบัญชีและภาษี (มาตรา 24(6))
  และประโยชน์โดยชอบด้วยกฎหมายในการดูแลความปลอดภัยของเด็ก (มาตรา 24(5))
- **เราไม่เก็บ:** เลขบัตรประชาชน วันเกิดแบบเต็ม ชื่อโรงเรียน ที่อยู่บ้าน หรือเลขบัญชีธนาคาร

### 3.5 ผู้ติดต่อฉุกเฉินและผู้มีสิทธิ์รับน้อง [P3]

- **ข้อมูล:** ชื่อ เบอร์โทร และความเกี่ยวข้องกับน้อง ซึ่งผู้ปกครองเป็นผู้ให้
- **ใช้เพื่อ:** ติดต่อเมื่อมีเหตุจำเป็น และตรวจสอบว่าใครรับน้องกลับบ้านได้
- **ฐานทางกฎหมาย:** ประโยชน์โดยชอบด้วยกฎหมายในการดูแลความปลอดภัยของเด็ก (มาตรา 24(5))
  และการป้องกันอันตรายต่อชีวิตหรือสุขภาพในกรณีฉุกเฉิน (มาตรา 24(2))

รบกวนผู้ปกครองแจ้งบุคคลเหล่านี้ และส่งลิงก์ประกาศนี้ให้ด้วยนะคะ

### 3.6 ข้อมูลการแพ้อาหารและการดูแลสุขภาพ [P4]

ข้อมูลนี้เป็นข้อมูลอ่อนไหว เราจึงเก็บ **เฉพาะเมื่อผู้ปกครองให้ความยินยอมโดยชัดแจ้ง**
ในช่องแยกต่างหากที่ไม่ได้ติ๊กไว้ล่วงหน้า (มาตรา 26)

- **ข้อมูล:** ชนิดอาหารที่แพ้ อาหารที่ต้องหลีกเลี่ยง (ไม่ต้องบอกเหตุผล) และวิธีดูแลเบื้องต้น
- **ใช้เพื่อ:** ให้คุณครูและอังเคิลลีวางแผนกิจกรรมทำอาหารและของว่างให้ปลอดภัยสำหรับน้อง
- **ใครเห็นได้:** เฉพาะคุณครูและทีมงานของสตูดิโอ รายชื่อในวันเรียนแสดงเพียงป้ายชนิดอาหารที่แพ้
  การเปิดดูรายละเอียดทุกครั้งมีการบันทึกไว้ และเราไม่ส่งข้อมูลนี้ทาง LINE
- **ไม่บังคับ:** ถ้าไม่ให้ข้อมูล ไม่เป็นไรเลยค่ะ ถ้าน้องแพ้อาหารอะไร บอกคุณครูได้ทุกเมื่อก่อนคลาสทำอาหาร
  <!-- OWNER-APPROVE (R-24) -->
- **ถอนได้ทุกเมื่อ:** เมื่อถอน เราจะลบข้อมูลนี้ออกจากระบบ
- **ระยะเวลาเก็บ:** จนกว่าจะถอนความยินยอม หรือ 6 เดือนหลังวันเรียนครั้งล่าสุดของน้อง

ในเหตุฉุกเฉินที่น้องต้องได้รับการดูแลทันที เราอาจแจ้งข้อมูลที่จำเป็นแก่บุคลากรทางการแพทย์ (มาตรา 26(1))

### 3.7 รูปภาพและวิดีโอ [P4]

เราขอความยินยอม **แยกตามช่องทาง** ได้แก่ กลุ่มผู้ปกครองแบบปิด เว็บไซต์นี้ Facebook / Instagram / TikTok และ YouTube
และให้คุณเลือกว่าเห็นหน้าน้องได้หรือไม่ ทุกช่องทางตั้งต้นเป็น "ไม่ยินยอม" (มาตรา 19 และ 20)

- เราไม่ใส่ชื่อจริงหรือชื่อเล่นของน้องในคำบรรยาย ชื่อไฟล์ หรือข้อความแทนภาพ
- ระบบหลังบ้านของเว็บไซต์ไม่เก็บไฟล์รูปหรือวิดีโอของเด็ก เก็บเพียงรายการอ้างอิง (เช่น รหัสวิดีโอ YouTube) และสถานะความยินยอม
- เมื่อถอนความยินยอม เราจะหยุดใช้ใหม่ทันที และนำออกจากช่องทางของเราโดยเร็ว
  สำเนาที่ผู้อื่นบันทึกหรือแชร์ไปแล้วอาจอยู่นอกการควบคุมของเรา แต่เราจะช่วยติดตามให้เท่าที่ทำได้ค่ะ

### 3.8 ลิงก์ส่วนตัวสำหรับครอบครัว [P4]

ทีมงานจะส่งลิงก์ส่วนตัวให้ในแชต LINE ของครอบครัว เพื่อกรอกข้อมูลก่อนเรียน (ใช้ได้ครั้งเดียว ภายใน 14 วัน)
[P5] และเพื่อดูหรือเปลี่ยนความยินยอม (ใช้ได้ 90 วัน ขอลิงก์ใหม่ได้เสมอ)
กรุณาอย่าส่งต่อลิงก์นี้ให้ผู้อื่น เราเก็บรหัสของลิงก์ในรูปแบบที่ย้อนกลับไม่ได้เท่านั้น และยกเลิกลิงก์ให้ได้ทันทีถ้าคุณขอ

### 3.9 คำขอใช้สิทธิและบันทึกเหตุการณ์ [P1]

เราบันทึกคำขอใช้สิทธิและการตอบกลับ (เก็บ 3 ปี) และบันทึกเหตุการณ์ละเมิดข้อมูลส่วนบุคคล (เก็บ 5 ปี)
เพื่อปฏิบัติตามกฎหมาย (มาตรา 24(6))

## 4. ข้อมูลของเด็ก [P1]

ผู้ปกครองหรือผู้ใช้อำนาจปกครองเป็นผู้ให้ข้อมูลและให้ความยินยอมแทนน้องค่ะ เราไม่ขอข้อมูลจากเด็กโดยตรงทางออนไลน์

[P4] สำหรับน้องอายุ 10 ปีขึ้นไป คุณครูจะอธิบายด้วยภาษาที่เข้าใจง่าย และถามความเห็นของน้องเองด้วย
ทั้งเรื่องรูปและวิดีโอ และเรื่องข้อมูลการแพ้อาหาร ถ้าน้องไม่สบายใจ เราจะเคารพการตัดสินใจของน้องและพูดคุยกับครอบครัวค่ะ

## 5. เราส่งต่อข้อมูลให้ใคร [P1]

เราไม่ขายข้อมูลและไม่ส่งต่อเพื่อการโฆษณา เราใช้ผู้ให้บริการต่อไปนี้เท่าที่จำเป็น

| ผู้รับข้อมูล | ข้อมูล | เพื่อ |
|---|---|---|
| Lovable (ระบบเว็บไซต์และฐานข้อมูล Lovable Cloud ซึ่งใช้เทคโนโลยีของ Supabase) | ข้อมูลที่ส่งผ่านเว็บไซต์ | โฮสต์เว็บไซต์และจัดเก็บข้อมูล |
| Cloudflare | ที่อยู่ IP และข้อมูลทางเทคนิคของเบราว์เซอร์ | ส่งหน้าเว็บ และตรวจสอบบอทบนหน้าแบบฟอร์ม (Turnstile) |
| LY Corporation (LINE) | ข้อความที่คุยกับเรา และข้อความแจ้งเตือนทีมงาน (ไม่มีชื่อ) | การสื่อสาร |
| Google | ที่อยู่ IP (ฟอนต์ แผนที่ และ YouTube เมื่อกดเล่น) และอีเมลที่ส่งถึงเรา | แสดงผลเว็บไซต์และการสื่อสาร |
| Meta (Messenger) | ข้อความที่คุยกับเรา | การสื่อสาร |
| [P3] ธนาคาร | ข้อมูลการโอนเงิน | รับชำระเงิน |
| [P3] บุคลากรทางการแพทย์ | ข้อมูลที่จำเป็นในเหตุฉุกเฉิน | ดูแลน้อง |
| [P4] Meta (Facebook, Instagram), TikTok, YouTube (Google) | รูปหรือวิดีโอที่ได้รับความยินยอมในช่องทางนั้น | เผยแพร่กิจกรรมของสตูดิโอ |
| หน่วยงานของรัฐ | เมื่อกฎหมายกำหนด | ปฏิบัติตามกฎหมาย |
| [P6] Umami (ถ้าเปิดใช้) | สถิติการเข้าชมแบบไม่ใช้คุกกี้และไม่ระบุตัวบุคคล | ปรับปรุงเว็บไซต์ |

## 6. การเก็บข้อมูลนอกประเทศไทย [P1]

ฐานข้อมูลของเราอยู่ใน Lovable Cloud ภูมิภาค "Asia Pacific" ซึ่งอยู่นอกประเทศไทย {{REGION_CITY_TH_IF_KNOWN}}
ระบบเว็บไซต์และ Cloudflare ทำงานบนเครือข่ายทั่วโลก ส่วน LINE ให้บริการโดย LY Corporation ประเทศญี่ปุ่น
เราเลือกผู้ให้บริการที่มีข้อตกลงการประมวลผลข้อมูลและมาตรการรักษาความปลอดภัย
และส่งข้อมูลเท่าที่จำเป็นต่อการให้บริการตามที่คุณขอค่ะ
<!-- LEGAL REVIEW: s.28/s.29 basis wording -->

## 7. ระยะเวลาเก็บข้อมูล [P1]

| ข้อมูล | ระยะเวลา |
|---|---|
| คำขอจองที่ยังไม่ได้ลงเรียน | 6 เดือนนับจากวันที่ส่ง |
| ค่าที่แปลงจากที่อยู่ IP เพื่อกันสแปม | 24 ชั่วโมง |
| บันทึกการแจ้งเตือนทีมงาน | 30 วัน |
| [P3] ข้อมูลครอบครัว ข้อมูลน้อง และผู้ติดต่อ | 12 เดือนหลังการเรียน การชำระเงิน การซื้อแพ็กเกจ การให้หรือถอนความยินยอม หรือการใช้ลิงก์ส่วนตัวครั้งล่าสุด (ถ้าคุณขอระงับการใช้ข้อมูล เราจะเก็บไว้โดยไม่ใช้จนกว่าจะยกเลิกการระงับ) |
| [P3] บันทึกการเข้าเรียน | 24 เดือนหลังวันเรียน |
| [P3] บันทึกการชำระเงินและแพ็กเกจ | 5 ปีหลังสิ้นปีบัญชี ตามกฎหมายบัญชี |
| [P4] ข้อมูลการแพ้อาหาร | จนกว่าจะถอนความยินยอม หรือ 6 เดือนหลังวันเรียนครั้งล่าสุด |
| [P4] หลักฐานความยินยอม | ตลอดอายุความยินยอม และอีก 3 ปี |
| [P4] ลิงก์ส่วนตัว | 30 วันหลังลิงก์หมดอายุ |
| คำขอใช้สิทธิ | 3 ปีหลังตอบกลับ |
| บันทึกเหตุละเมิดข้อมูล | 5 ปี |
| บันทึกการเข้าถึงระบบของทีมงาน | 12 เดือน |

เมื่อครบกำหนด ระบบจะลบข้อมูลให้อัตโนมัติทุกวัน ข้อมูลสำรองของระบบจะหมดไปเองภายในประมาณ 14 วันหลังจากนั้นค่ะ

## 8. การดูแลความปลอดภัย [P1]

- เฉพาะทีมงานที่ต้องใช้ข้อมูลเท่านั้นที่เข้าถึงได้ ด้วยบัญชีส่วนตัวและรหัสผ่านที่แข็งแรง
- ฐานข้อมูลควบคุมสิทธิการเข้าถึงทุกตาราง หน้าเว็บสาธารณะอ่านข้อมูลส่วนบุคคลไม่ได้
- เราบันทึกว่าใครแก้ไขหรือเปิดดูข้อมูลสำคัญ
- ไฟล์ส่วนตัวเก็บในพื้นที่ที่ไม่เปิดเป็นสาธารณะ
- ระบบลบข้อมูลที่ครบกำหนดให้อัตโนมัติทุกวัน
- หากเกิดเหตุละเมิดข้อมูลส่วนบุคคล เราจะแจ้งสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคลภายใน 72 ชั่วโมงตามที่กฎหมายกำหนด
  และแจ้งครอบครัวที่ได้รับผลกระทบโดยไม่ชักช้าเมื่อมีความเสี่ยงสูง

## 9. สิทธิของคุณ [P1]

คุณ (และผู้ปกครองในนามของน้อง) มีสิทธิ

- ถอนความยินยอมได้ทุกเมื่อ ง่ายเหมือนตอนให้
- ขอเข้าถึงและขอรับสำเนาข้อมูล
- ขอรับข้อมูลในรูปแบบที่อ่านได้ด้วยเครื่องมือทั่วไป หรือขอให้ส่งต่อให้ผู้อื่น
- คัดค้านการเก็บ ใช้ หรือเปิดเผยข้อมูล
- ขอให้ลบ ทำลาย หรือทำให้ข้อมูลไม่สามารถระบุตัวตนได้
- ขอให้ระงับการใช้ข้อมูล
- ขอให้แก้ไขข้อมูลให้ถูกต้องและเป็นปัจจุบัน
- ร้องเรียนต่อสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคล (สคส.)

**วิธียื่นคำขอ:** ทาง LINE @cherryleeandco อีเมล cherryleeandco@gmail.com มาพบเราที่สตูดิโอ
หรือส่งไปรษณีย์ลงทะเบียนมาที่ {{FULL_ADDRESS_TH}}

**ระยะเวลา:** เราจะตรวจสอบคำขอภายใน 15 วัน และตอบกลับภายใน 30 วัน (หากเรื่องซับซ้อน อาจขยายได้อีก 30 วัน
โดยจะแจ้งให้ทราบ) คำขอลบข้อมูลจะดำเนินการให้เสร็จภายใน 90 วัน รวมถึงข้อมูลสำรอง

เราอาจขอยืนยันตัวตนก่อน เช่น ตอบในแชต LINE เดิมของครอบครัว หรือโทรกลับเบอร์ที่ให้ไว้ โดยเราจะไม่เก็บสำเนาบัตรประชาชน
การยื่นคำขอไม่มีค่าใช้จ่ายค่ะ <!-- owner to confirm -->
บางกรณีเราอาจต้องเก็บข้อมูลบางส่วนไว้ตามกฎหมาย เช่น บันทึกการเงิน ถ้าเป็นเช่นนั้นเราจะแจ้งเหตุผลเป็นลายลักษณ์อักษร

**ร้องเรียน:** สำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคล https://www.pdpc.or.th (ช่องทางร้องเรียน https://complaint.pdpc.or.th/)

## 10. คุกกี้และเทคโนโลยีที่คล้ายกัน [P1]

- เว็บไซต์นี้ไม่มีคุกกี้ติดตามหรือคุกกี้โฆษณา จึงไม่มีแบนเนอร์ขอความยินยอมคุกกี้
- เบราว์เซอร์ของคุณจำภาษาที่เลือกไว้ (localStorage) เพื่อให้แสดงภาษาเดิมเมื่อกลับมา
- หน้าแบบฟอร์มใช้ Cloudflare Turnstile ซึ่ง Cloudflare ระบุว่าใช้สัญญาณทางเทคนิคเพื่อตรวจสอบบอทเท่านั้น
- วิดีโอ YouTube โหลดจาก youtube-nocookie.com เมื่อคุณกดเล่น หลังจากนั้นเป็นไปตามนโยบายของ Google
- ฟอนต์จาก Google Fonts และแผนที่ Google Maps ตามข้อ 3.1
- [P6] หากเปิดใช้ Umami เป็นสถิติแบบไม่ใช้คุกกี้และไม่ระบุตัวบุคคล

## 11. การเปลี่ยนแปลงประกาศนี้ [P1]

เราอาจปรับปรุงประกาศนี้เมื่อเพิ่มบริการใหม่หรือเมื่อกฎหมายเปลี่ยนแปลง ฉบับที่และวันที่มีผลอยู่ด้านบนของหน้านี้
หากการเปลี่ยนแปลงต้องขอความยินยอมใหม่ เราจะขอก่อนเสมอค่ะ

## 12. ติดต่อเรา [P1]

LINE @cherryleeandco · อีเมล cherryleeandco@gmail.com · {{FULL_ADDRESS_TH}}
```

### 11.4 Full draft — English

```markdown
# CherryLee & Co. Privacy Notice

Version {PRIVACY_NOTICE_VERSION} · Effective {{EFFECTIVE_DATE_EN}}

## 1. About this notice [P1]

CherryLee & Co. looks after every family's information with the same care we give the children in our classes.
This notice explains what personal data we collect, why, who we share it with, how long we keep it and what your
rights are under Thailand's Personal Data Protection Act B.E. 2562 (2019).
Our approach: collect only what each step needs, never sell data, and never use it for advertising.

## 2. Who looks after your data [P1]

- Data controller: {{CONTROLLER_NAME_EN}}
- Address: {{FULL_ADDRESS_EN}}
- Privacy questions: LINE @cherryleeandco · email cherryleeandco@gmail.com · in person at the studio, or by
  registered mail to the address above
- Privacy contact: {{PRIVACY_CONTACT_EN}}

## 3. What we collect and why

### 3.1 Visiting the website [P1]

- We don't use tracking or advertising cookies, and we don't run any advertising tools.
- Your language choice (Thai or English) is saved only in your own browser.
- Our website host (Lovable, running on Cloudflare's network) keeps standard technical records such as IP address,
  time and the page opened, so the site works safely and we can see overall visitor numbers
  (legitimate interests, section 24(5)).
- The site's fonts come from Google Fonts and the home page shows a Google Maps map, so Google receives your device's
  IP address.
- YouTube videos load only when you press play.

### 3.2 The "Leave your details" booking form [P1]

- **What we ask for:** the name you'd like us to use, how you'd like to talk (LINE, or a call back), a phone number
  (only needed for a call back), a LINE ID (optional, only to help us find your chat), each child's nickname
  (optional) and age, the package and dates you're interested in, an optional message, the page language, and which
  version of this notice you saw. The system also creates a reference code.
- **If you choose LINE:** please send your reference code to LINE @cherryleeandco. The studio's official LINE account
  can't message anyone first, so we reply in the chat you start.
- **Why:** to get back to you about booking and answer your questions.
- **Legal basis:** steps you asked us to take before a contract (section 24(3)), so there's no consent box to tick.
- **If you'd rather not:** we can't call you back, but you can always message us on LINE @cherryleeandco.
- **Spam protection:** Cloudflare Turnstile checks that a person is sending the form. We keep a one-way, keyed
  fingerprint of your IP address for 24 hours to limit repeat submissions. We never store your actual IP address.
- **Team alert:** our team gets a LINE message with only the reference code, date and number of children. No names
  or phone numbers.
- **How long:** 6 months from the day you send it, if you don't go ahead with classes.

Please don't include health details in the message box. If your child needs special care, we'll ask separately.

### 3.3 Chatting with us on LINE, Messenger or email [P1]

We use your messages to answer questions and arrange classes (sections 24(3) and 24(5)). Chats are stored by each
provider (LINE by LY Corporation, Messenger by Meta, email by Google) under that provider's own policy. Our website is
not connected to your chats. Please don't send health or allergy details in chat; we'll send you a private form instead.

### 3.4 Family records once classes start [P3]

- **What:** the parent's or guardian's name, phone, LINE ID (and email, if you'd like receipts by email), preferred
  language; each child's nickname and birth month and year; packages bought; payments (amount, method, date, receipt
  number, and a slip image if our team chooses to keep one); seat bookings; arrival and departure times on class days;
  and who collected your child.
- **Why:** to run classes, manage packages and payments, and make sure every child goes home safely.
- **Legal basis:** performing our contract (section 24(3)); keeping financial records required by accounting and tax law
  (section 24(6)); our legitimate interest in children's safety (section 24(5)).
- **We don't collect:** national ID numbers, full dates of birth, school names, home addresses or bank account numbers.

### 3.5 Emergency contacts and people allowed to collect your child [P3]

- **What:** name, phone and relationship to the child, given to us by the parent or guardian.
- **Why:** to reach someone when needed and to check who may take your child home.
- **Legal basis:** our legitimate interest in children's safety (section 24(5)), and protecting life or health in an
  emergency (section 24(2)).

Please let these people know, and share this notice with them.

### 3.6 Allergy and care information [P4]

This is sensitive data, so we keep it **only with a parent's or guardian's explicit consent**, given in its own
checkbox that is never ticked in advance (section 26).

- **What:** foods your child is allergic to, foods to avoid (no need to tell us why), and first-aid notes.
- **Why:** so the teachers and Uncle Lee can plan cooking activities and snacks safely for your child.
- **Who can see it:** only the studio's teachers and staff. Class lists show allergy labels only; every time someone
  opens the full notes it is logged. We never send this information over LINE.
- **Optional:** if you'd rather not share it, that's fine. If your child has a food allergy, you can tell a teacher
  any time before a cooking session. <!-- OWNER-APPROVE (R-24) -->
- **You can withdraw at any time:** we then delete it from our system.
- **How long:** until you withdraw, or 6 months after your child's last session.

In an emergency where your child needs care right away, we may tell medical staff what they need to know
(section 26(1)).

### 3.7 Photos and videos [P4]

We ask **separately for each channel**: a private parents' group, this website, Facebook / Instagram / TikTok, and
YouTube, and whether your child's face may be shown. Every channel starts as "no" (sections 19 and 20).

- We never put children's names or nicknames in captions, file names or image descriptions.
- Our website's back office doesn't store children's photos or videos, only a reference (such as a YouTube video ID)
  and the consent status.
- If you withdraw, we stop any new use straight away and remove the content from our channels as soon as we can.
  Copies other people have already saved or shared may be outside our control, but we'll help follow up where we can.

### 3.8 Private family links [P4]

Our team sends private links in your family's LINE chat: one to fill in details before classes (works once, within
14 days) [P5] and one to see or change your consents (works for 90 days; ask us any time for a new one). Please don't forward these links. We only
store a one-way code of each link, and we can cancel a link straight away if you ask.

### 3.9 Rights requests and incident records [P1]

We record rights requests and our replies (kept 3 years) and personal data breach records (kept 5 years) because the
law requires it (section 24(6)).

## 4. Children's information [P1]

Parents or guardians with parental responsibility give information and consent for their children. We don't collect
information from children directly online.

[P4] For children aged 10 and over, a teacher also explains things in child-friendly words and asks the child's own
view about photos and videos and about allergy information. If a child isn't comfortable, we respect that and talk it
through with the family.

## 5. Who we share data with [P1]

We don't sell data or share it for advertising. We use these providers only as far as needed:

| Recipient | Data | Why |
|---|---|---|
| Lovable (website and the Lovable Cloud database, built on Supabase technology) | data sent through the website | hosting the website and storing data |
| Cloudflare | IP address and browser technical data | delivering pages and checking for bots on the form (Turnstile) |
| LY Corporation (LINE) | your chats with us; team alerts (no names) | communication |
| Google | IP address (fonts, map, YouTube when you press play) and emails you send us | showing the website; communication |
| Meta (Messenger) | your chats with us | communication |
| [P3] Banks | transfer details | receiving payments |
| [P3] Medical staff | what's needed in an emergency | caring for your child |
| [P4] Meta (Facebook, Instagram), TikTok, YouTube (Google) | photos or videos you agreed to for that channel | sharing the studio's activities |
| Government authorities | when the law requires | legal compliance |
| [P6] Umami (if switched on) | cookieless, non-identifying visit statistics | improving the website |

## 6. Data stored outside Thailand [P1]

Our database is in Lovable Cloud's "Asia Pacific" region, which is outside Thailand {{REGION_CITY_EN_IF_KNOWN}}.
The website and Cloudflare run on global networks, and LINE is provided by LY Corporation in Japan. We choose providers
with data processing agreements and security measures, and we only transfer what's needed to provide the service you
asked for.

## 7. How long we keep data [P1]

| Data | How long |
|---|---|
| Booking requests that don't go ahead | 6 months from the day sent |
| Spam-protection IP fingerprints | 24 hours |
| Team alert records | 30 days |
| [P3] Family, child and contact details | 12 months after the last class, payment, package purchase, consent decision or use of a private link (if you ask us to restrict use, we keep it unused until the restriction ends) |
| [P3] Attendance records | 24 months after the class date |
| [P3] Payment and package records | 5 years after the end of the accounting year, as accounting law requires |
| [P4] Allergy information | until you withdraw, or 6 months after your child's last session |
| [P4] Consent records | for as long as the consent applies, plus 3 years |
| [P4] Private links | 30 days after the link expires |
| Rights requests | 3 years after our reply |
| Data breach records | 5 years |
| Team access logs | 12 months |

When the time is up, the system deletes data automatically every day. System backups then expire within about 14 days.

## 8. How we keep data safe [P1]

- Only team members who need the data can access it, with personal accounts and strong passwords.
- Every database table has access controls; public pages can't read personal data.
- We log who changes or opens important records.
- Private files are kept in storage that isn't public.
- Data past its retention date is deleted automatically every day.
- If a personal data breach happens, we report it to the Office of the Personal Data Protection Committee within
  72 hours as the law requires, and tell affected families without delay when the risk is high.

## 9. Your rights [P1]

You (and parents on behalf of their children) can:

- withdraw consent at any time, as easily as you gave it;
- ask to see and get a copy of your data;
- receive your data in a commonly used machine-readable format, or ask us to send it to someone else;
- object to us collecting, using or disclosing your data;
- ask us to delete, destroy or anonymise your data;
- ask us to restrict use of your data;
- ask us to correct your data or bring it up to date;
- complain to the Office of the Personal Data Protection Committee (PDPC).

**How to ask:** LINE @cherryleeandco, email cherryleeandco@gmail.com, in person at the studio, or registered mail to
{{FULL_ADDRESS_EN}}.

**Timing:** we check requests within 15 days and reply within 30 days (complex requests may take up to 30 more days;
we'll tell you if so). Deletion requests are completed within 90 days, including backups.

We may first confirm it's you, for example by replying in your family's usual LINE chat or calling back the number you
gave us. We won't keep copies of ID cards. Making a request is free. <!-- owner to confirm -->
Sometimes the law requires us to keep some data, such as financial records. If so, we'll explain why in writing.

**Complaints:** Office of the Personal Data Protection Committee, https://www.pdpc.or.th (complaints:
https://complaint.pdpc.or.th/)

## 10. Cookies and similar technologies [P1]

- This website has no tracking or advertising cookies, so there's no cookie banner.
- Your browser remembers your language choice (localStorage) so the site opens in the same language next time.
- The booking form uses Cloudflare Turnstile, which Cloudflare says uses technical signals only to detect bots.
- YouTube videos load from youtube-nocookie.com when you press play; after that, Google's policies apply.
- Google Fonts and Google Maps as described in 3.1.
- [P6] If we switch on Umami, it gives cookieless, non-identifying statistics.

## 11. Changes to this notice [P1]

We may update this notice when we add services or the law changes. The version and effective date are at the top of
this page. If a change needs new consent, we'll always ask first.

## 12. Contact us [P1]

LINE @cherryleeandco · email cherryleeandco@gmail.com · {{FULL_ADDRESS_EN}}
```

### 11.5 Short notice next to the `/book` submit button (no checkbox, D8)

Recommended wording; `src/content/booking.tsx` (`30-ui.md`) is authoritative.

- TH: "เราจะใช้ข้อมูลนี้เพื่อติดต่อกลับเรื่องการจองเท่านั้นค่ะ และเก็บไว้ไม่เกิน 6 เดือนหากยังไม่ได้ลงเรียน อ่านเพิ่มเติมได้ที่ นโยบายความเป็นส่วนตัว"
- EN: "We'll use these details only to get back to you about booking, and keep them for up to 6 months if you don't go ahead. Read our privacy notice."

### 11.6 Placeholders the owner fills (G0, G9a)

| Placeholder | What | Source |
|---|---|---|
| `{{CONTROLLER_NAME_TH/EN}}` | legal name of the person or company running CherryLee & Co. | G0 Q1 |
| `{{FULL_ADDRESS_TH/EN}}` | full postal address at Soi Nawamin 117 (house number, sub-district, district, postcode) | owner |
| `{{PRIVACY_CONTACT_TH/EN}}` | the owner's name or role ("เจ้าของสตูดิโอ / Studio owner") | owner |
| `{{REGION_CITY_*_IF_KNOWN}}` | e.g. "(สิงคโปร์)" / "(Singapore)" if Lovable confirms; otherwise delete | `40-integrations.md` § 2 row 2 |
| `{{EFFECTIVE_DATE_*}}` | publish date; Thai uses the Buddhist year | G10 |

---

## 12. Consent texts v1 (TH + EN)

⚖️ **LEGAL REVIEW** (G9b) before the seed is applied.

### 12.0 Where the wording lives (single source)

The **canonical v1 wording** (title + body, Thai and English, all five purposes) is in
[`sql/0006_seed_consent_texts.sql`](sql/0006_seed_consent_texts.sql). That file ranks above this one (README order of
authority), so this section does **not** repeat the full texts. It gives the version ids, a content checklist for the
lawyer, the review deltas we recommend adding to 0006 **before** it is applied, and the UI-only copy that lives in
`src/content/*.tsx` rather than in the database. After 0006 is applied, any wording change is a **new version**, never an
edit (D12): a new reviewed SQL draft (G9b + G4), or the owner runs `publish_consent_text()` in Cloud → SQL editor
(`00-overview.md` § 8.0). The `/admin/settings` publishing screen (`publishConsentText`) is parked (card PK-03). The
first `health_allergy` text can only come from a reviewed SQL draft (R-35), so the G-HEALTH = paper choice holds.

**Version id format** (used here, in review notes and in `/admin/settings`): `<consent_purpose>.v<version>.<lang>`,
e.g. `health_allergy.v1.th`. In the database that is the row `consent_texts(purpose, version, lang)`.

| Version id | Title in 0006 (TH / EN) | `is_explicit` | `requires_child_consent_from_age` | Where asked |
|---|---|---|---|---|
| `health_allergy.v1.th` / `.en` | ข้อมูลการแพ้อาหารและการดูแลของน้อง (ขอความยินยอมโดยชัดแจ้ง) / Your child's food allergies and care notes (explicit consent) | `true` | `10` | `/enrol/$token` health section; staff (paper/in person) |
| `media_parents_group.v1.th` / `.en` | รูปและวิดีโอในกลุ่มแชตส่วนตัวของผู้ปกครอง / Photos and videos in the private parents' chat group | `false` | `10` | `/enrol/$token` media section; `/my/$token` |
| `media_website.v1.th` / `.en` | รูปและวิดีโอบนเว็บไซต์ของสตูดิโอ / Photos and videos on the studio's website | `false` | `10` | same |
| `media_social.v1.th` / `.en` | รูปและวิดีโอบน Facebook, Instagram และ TikTok ของสตูดิโอ / … Facebook, Instagram and TikTok | `false` | `10` | same |
| `media_youtube.v1.th` / `.en` | วิดีโอบนช่อง YouTube ของสตูดิโอ / Videos on the studio's YouTube channel | `false` | `10` | same |

The task brief's "internal / social / website" media purposes map to `media_parents_group` (internal: the private
parents' group), `media_social` and `media_website`; YouTube is its own purpose, `media_youtube`.

Purposes **not** used, on purpose:
- **Booking contact consent:** not needed. A booking request relies on PDPA s.24(3) (D8); a consent box there would
  bundle consent where another basis fits (PDPC consent guideline). Use the short notice in § 11.5 instead.
- **Marketing opt-in:** out of scope for P0–P6 (no marketing channel; `00-overview.md` § 1 non-goals). Parked draft in § 12.5.

**Rendering rule (for `30-ui.md`):** show `title` as the heading and the whole `body_md` directly above an **unticked**
checkbox (never behind a "read more" link); 0006 bodies end with the affirmative statement for the box. The checkbox
label itself is short UI copy from `src/content/enrol.tsx` (e.g. "ยินยอม / I agree"). Store the `consent_text_id` of the
exact language version shown; its `sha256` covers title + body.

### 12.1 Content checklist (lawyer and reviewer)

Each text must say, in plain words, in both languages. ✓ = present in the 0006 draft as of 14 Oct 2026.

| Element | health_allergy | media_* (each) |
|---|---|---|
| What data / what media | ✓ | ✓ |
| Purpose (safe cooking with Uncle Lee / which channel) | ✓ | ✓ |
| Who can see it (studio teachers and staff; access logged / public or group audience) | ✓ | ✓ |
| Never sent on LINE | ✓ | n/a |
| Where stored, incl. outside Thailand (s.28/29 disclosure) | ✓ | platforms "outside Thailand" ✓ (social, YouTube) |
| How long | ✓ | ✓ (consent record + 3 years) |
| Optional; what happens if no (warm, no fear) | ✓ | ✓ |
| Children 10+ asked too (D11) | ✓ | ✓ |
| How to withdraw; as easy as giving; what happens | ✓ | ✓ |
| Copies shared by others may not be recoverable (honest) | n/a | ✓ |
| Face shown / not shown choice | n/a | ✓ |
| Emergency disclosure to medical staff (s.26(1)) | **missing → delta R-1** | n/a |
| Withdrawal doesn't affect earlier lawful use (s.19) | **missing → delta R-2** | **missing → delta R-2** |
| Website clips are hosted on YouTube, so both consents are needed | n/a | **missing in `media_website` → delta R-3** |

### 12.2 Recommended review deltas for 0006 (add before G4, after G9b approval)

Each delta is a sentence (TH + EN) the lawyer approves; the builder then edits 0006 **before** it is applied.

**R-1 · `health_allergy`: emergency disclosure** (insert before the final consent paragraph)
- TH: "ในเหตุฉุกเฉินที่น้องต้องได้รับการดูแลทันที เราอาจแจ้งข้อมูลที่จำเป็นแก่บุคลากรทางการแพทย์ค่ะ"
- EN: "In an emergency where your child needs care right away, we may tell medical staff what they need to know."

**R-2 · all five: effect of withdrawal** (append to the "withdraw at any time" sentence)
- TH: "การถอนความยินยอมไม่กระทบสิ่งที่ทำไปแล้วก่อนหน้านั้นค่ะ"
- EN: "Withdrawing doesn't affect anything done before."

**R-3 · `media_website`: YouTube hosting** (add as a bullet)
- TH: "วิดีโอบนเว็บไซต์ฝากไว้บน YouTube ด้วย เราจะใช้วิดีโอที่มีน้องบนเว็บไซต์ก็ต่อเมื่อคุณพ่อคุณแม่อนุญาตทั้งข้อเว็บไซต์และข้อ YouTube ค่ะ"
- EN: "Videos on the website are hosted on YouTube, so we only use a video of your child on the website if you agree to both the website and YouTube."

If the lawyer rejects a delta, record why in the G9b notes in `90-task-breakdown.md`.

### 12.3 UI-only copy (lives in `src/content/enrol.tsx` / `my-consents.tsx`, not in the database)

Suggested wording; `30-ui.md` is authoritative for keys and placement.

**Health buttons** (R-07; `30-ui.md` § 3.5 is authoritative): "ไม่ใช่ตอนนี้ / Not now" records nothing; "ไม่ต้องการ
ให้ข้อมูลนี้ / I don't want to share this" records a refusal (or a withdrawal if the family agreed before, which deletes
earlier info). Notes (OWNER-APPROVE, R-24: an invitation, not a promise of a studio process):
- Not now — TH: "ไม่เป็นไรเลยค่ะ น้องยังเรียนได้ตามปกติ ถ้าน้องแพ้อาหารอะไร บอกคุณครูได้ทุกเมื่อก่อนคลาสทำอาหารนะคะ"
  · EN: "That's completely fine. If your child has any food allergy, please tell a teacher before a cooking class."
- Decline — TH: "รับทราบค่ะ เราจะไม่เก็บข้อมูลการแพ้อาหารของน้อง ถ้าเคยให้ไว้ก่อนหน้านี้ ระบบจะลบออกให้ค่ะ"
  · EN: "Understood. We won't keep allergy information for your child, and anything shared before will be deleted."

**Face-level choice** (stored per media consent row as `media_level`; 0006 asks it within each media purpose, so the UI
shows it per ticked purpose and may offer "ใช้แบบเดียวกันทุกช่องทาง / Same for all channels" as a shortcut; no default
selection once a box is ticked):
- Question TH: "ถ้าน้องอยู่ในรูปหรือวิดีโอ เห็นหน้าน้องได้ไหมคะ" · EN: "If your child appears, may their face be shown?"
- `face_visible`: TH "เห็นหน้าได้" · EN "Yes, face can be shown"
- `face_hidden`: TH "ไม่ให้เห็นหน้า (เช่น ถ่ายจากด้านหลัง เห็นแค่มือ หรือเบลอหน้า)" · EN "No face (e.g. from behind, hands only, or blurred)"

Withdrawal copy and confirmation messages: § 16.3 and § 16.4.

### 12.4 Children's own consent (10+)

Recorded by staff in person (D11); the kid-friendly TH/EN script is in `30-ui.md`. Principles in § 14.

### 12.5 Parked (not in P0–P6): marketing on LINE

Requires a new `consent_purpose` value (proposal `marketing_line`, not in `00-overview.md`), an owner decision, a
broadcast plan within the `@cherryleeandco` quota and a privacy-notice update. Objection to direct marketing must be
honoured at any time (s.32). Never pre-ticked, never bundled with enrolment.

- TH title: "รับข่าวสารกิจกรรมและรอบเรียนใหม่ทาง LINE (ไม่บังคับ)"
- TH body: "เราจะส่งข่าวสารเป็นครั้งคราว เฉพาะเรื่องกิจกรรมและรอบเรียนของสตูดิโอ และจะไม่ส่งข้อมูลของคุณให้ผู้อื่นเพื่อการตลาดค่ะ ยกเลิกได้ทุกเมื่อโดยบอกเราทาง LINE หรือผ่านลิงก์ \"ความยินยอมของฉัน\" เมื่อติ๊กช่องนี้ คุณยินยอมให้ CherryLee & Co. ส่งข่าวสารดังกล่าวทาง LINE ค่ะ"
- EN title: "News about activities and new sessions on LINE (optional)"
- EN body: "We'll write now and then, only about the studio's activities and sessions, and we never pass your details to anyone for marketing. Stop any time by telling us on LINE or through your \"My consents\" link. By ticking this box, you agree that CherryLee & Co. may send you this news on LINE."

---

## 13. Consent mechanics checklist (for UI reviewers)

Based on PDPA s.19 and the PDPC Consent Guideline (7 Sep 2022, https://www.pdpc.or.th/1356/). Every form that asks for
consent must pass all of these:

- [ ] **Separate:** one checkbox per purpose (`health_allergy`, `media_parents_group`, `media_website`, `media_social`,
      `media_youtube`). Never one box for several purposes; never inside terms and conditions.
- [ ] **Unticked:** no checkbox or toggle is on by default. Media toggles default off.
- [ ] **Specific and visible:** the purpose `title` and the **full** text (`body_md`) are shown right above its own
      checkbox, in the page language, never behind a link, a "read more" or a collapsible (R-04). The checkbox label is
      short UI copy ("ยินยอมตามข้อความด้านบน / I agree to the text above"). A UI test checks the text is visible.
- [ ] **Only what was shown is recorded:** a purpose whose text isn't published is not shown and nothing is recorded
      for it (R-06).
- [ ] **Freely given:** booking and classes never depend on giving consent. Each "no" path is calm and explained.
- [ ] **Clear affirmative act:** ticking the box and pressing submit. A pre-filled or implied "yes" doesn't count.
- [ ] **Exact wording stored:** the record saves `consent_text_id` of the exact TH or EN version shown.
- [ ] **Who and how:** `given_by` (`guardian`/`child`), `channel` (`web`/`line`/`paper`/`in_person`), `method`
      (`checkbox`/`signature`/`staff_recorded_verbal`), `recorded_by` for staff entries, `family_link_id` for web.
- [ ] **Withdrawal as easy as giving:** web consent can be withdrawn on the web (`/my/$token`) with one click;
      never "call us in office hours".
- [ ] **Effect of withdrawal explained** next to the withdraw button (§ 16.3).
- [ ] **Children 10+:** the UI shows when a child's own consent is still needed (`consent_status` = `needs_child`).
- [ ] **Tone:** warm, no fear-based wording; Thai ends with ค่ะ where natural; both languages say the same thing.
- [ ] **Accessibility:** each checkbox has a real `<label>`; touch target ≥ 44 px; focus visible; errors announced.

---

## 14. Children's data rules

PDPA s.20 (PDPC translation): for a minor aged 10–19 the consent request goes to the minor, and the holder of parental
responsibility must also consent where the act is not one the minor may do alone (Civil and Commercial Code ss.22–24);
under 10, only the holder of parental responsibility can consent. The same rules apply to withdrawal and to exercising
rights.

Our rules (D11, ⚖️ lawyer to confirm):

1. **Every child:** a guardian who states they hold parental responsibility (`guardians.has_parental_responsibility`,
   `responsibility_attested_at`) gives consent. Identity is checked by the family's LINE chat (`line_account`), in person
   or by phone callback; never by ID copies.
2. **Media, child aged 10+ at the time of the decision:** publication needs **both** the guardian's and the child's own
   consent. `consent_status()` returns `needs_child` until the child's consent is recorded. Unknown `birth_month` counts
   as "needs child consent".
3. **Health, child aged 10+:** the guardian's explicit consent allows storage before the first session (safety comes
   first). At the first session a teacher explains it to the child. If the child says no, staff record the child's
   `refused` decision; the trigger deletes the `child_health` row, and staff talk with the family.
4. **Under 10:** the child's assent is good practice, not a legal requirement. Teachers still explain photos kindly and
   respect a child who doesn't want to be filmed on the day.
5. **How child consent is taken** (script text in `30-ui.md`):
   - in person, by a teacher, using the kid-friendly TH/EN script, with a parent nearby where possible;
   - one question per channel, yes/no, no pressure, no rewards for saying yes;
   - not in front of the whole group;
   - recorded the same day: `given_by = 'child'`, `channel = 'in_person'`, `method = 'staff_recorded_verbal'`,
     `recorded_by` = the staff member, `child_age_years_at_decision`;
   - the child can change their mind at any time; tell them so.
6. **Never** ask children for information online, never show children's names publicly, never put names in alt text,
   captions or file names (the existing rule in `src/content/videos.ts`).

---

## 15. Health data rules

1. Health and allergy data lives **only** in `child_health` (D10): `allergens` (chips: `peanut`, `tree_nut`, `milk`,
   `egg`, `wheat`, `soy`, `fish`, `shellfish`, `sesame`), `other_allergens` (≤ 200), `foods_to_avoid` (≤ 300, **no reason
   asked**: a reason such as halal or vegetarian-for-faith could reveal religion, also s.26 data), `care_notes` (≤ 500).
2. A database trigger blocks any insert/update unless the child has a current granted guardian `health_allergy` consent.
3. A refusal or withdrawal record deletes the row (AFTER INSERT trigger on `consent_records`).
4. Reads only through `get_child_health` (full notes, one `audit_log` row per call) and `list_session_health_flags`
   (allergen chips for a roster, audited). No plain `select`. No CSV/report export of health fields.
5. The admin shows full notes behind a "ดูข้อมูลสุขภาพ / View health info" button that says the view is logged.
6. **Never** on LINE: not in alerts, not in chats, not in screenshots of rosters. Parents who start typing allergies in
   LINE get a kind reply with their enrolment link instead (template in § 23).
7. Not collected: diagnoses, medication lists, free-text medical histories, reasons for diets.
8. Emergency: staff may tell medical responders what they need (s.26(1)); afterwards log it as a note on the family
   (no health details in the note) and tell the guardian.
9. Retention: deleted on withdrawal/refusal, or 6 months after the child's last session (§ 19).

---

## 16. Consent withdrawal flow

### 16.1 Channels

| Channel | Phase | Who records | Record |
|---|---|---|---|
| `/my/$token` one-click withdraw | P5 | the guardian (`updateMyConsent`) | `decision='withdrawn'`, `given_by='guardian'`, `channel='web'`, `method='checkbox'`, `family_link_id` |
| LINE chat ("please stop using photos") | P4+ | staff (`recordStaffConsent`), **same day** | `channel='line'`, `method='staff_recorded_verbal'`, `recorded_by` |
| In person / by phone | P4+ | staff, same day | `channel='in_person'`, `method='staff_recorded_verbal'` |
| Paper / letter | P4+ | staff, same day; scan to `consent-evidence` if signed | `channel='paper'`, `method='signature'`, `evidence_path` |
| Child (10+) changes their mind | P4+ | staff | `given_by='child'`, `channel='in_person'` |

`/my/$token` now ships **with** `/enrol` in Stage C (D27), so consent given on the web can be withdrawn on the web from
day one; there is no gap. `/enrol` itself withdraws only through the explicit health button "I don't want to share
this"; an unticked media box on a re-sent enrol link keeps the earlier decision (R-33), so withdrawing media consent
is `/my` or staff.

### 16.2 What happens next

```
consent_records insert (decision = withdrawn | refused), any channel, guardian or child
  ├─ trigger queue_consent_change_alert (D29): if the decision moved AWAY from 'granted' (or a 10+ child said no
  │   while the guardian's consent is granted) → one staff_notifications row 'consent_withdrawn' (pending)
  │   → server pushes it (deliverConsentAlert / deliverAlertIds); unsent rows show in the admin with "resend"
  ├─ purpose = health_allergy → trigger deletes child_health row (immediately) and sets
  │                              children.allergy_check_needed_at → roster: "check with the family before cooking"
  └─ purpose = media_*        → consent_status() no longer 'granted' → can_publish_media() = false
                               → takedown runbook § 17.3
current_consents view shows the new state at once; older rows stay as evidence (append-only, D12)
```

Targets (owner to confirm): record a LINE/in-person withdrawal the **same day**; finish media takedown on our own
channels within **7 days**; reply to the guardian when done.

### 16.3 Copy shown next to "withdraw" (suggested for `src/content/my-consents.tsx`)

- TH: "เมื่อถอนความยินยอม เราจะหยุดใช้ข้อมูลส่วนนี้ทันที สิ่งที่ทำไปก่อนหน้านี้ยังถูกต้องตามกฎหมาย ถ้าเป็นข้อมูลการแพ้อาหาร ระบบจะลบออก ถ้าน้องแพ้อาหารอะไร บอกคุณครูก่อนคลาสทำอาหารได้เสมอนะคะ ถ้าเป็นรูปหรือวิดีโอ เราจะนำออกจากช่องทางของเราโดยเร็วค่ะ" (OWNER-APPROVE)
- EN: "When you withdraw, we stop using this straight away; anything done before stays lawful. Allergy information is deleted; you can always tell a teacher about allergies before a cooking class. Photos or videos are removed from our channels as soon as we can." (OWNER-APPROVE)

### 16.4 Confirmation message to the guardian (LINE, by staff; no health details)

- TH: "สวัสดีค่ะ เราบันทึกการถอนความยินยอมเรื่อง {หัวข้อ} เรียบร้อยแล้วค่ะ {ถ้าเป็นสื่อ: เราจะนำออกจากช่องทางของเราภายใน 7 วัน และจะแจ้งอีกครั้งเมื่อเสร็จนะคะ} ขอบคุณที่บอกเราค่ะ"
- EN: "Hello! We've recorded that you've withdrawn consent for {topic}. {If media: we'll remove it from our channels within 7 days and let you know when it's done.} Thank you for letting us know."

---

## 17. Media consent, `videos.ts` and the takedown runbook

### 17.1 How the pieces connect (D24)

- `src/content/videos.ts` stays the **static** list of clips on the homepage. The homepage never reads the database.
- Today 4 class clips (`storyPlaylit`, `cookingClass`, `fruitStand`, `shoppingTrip`) carry
  `consent: { confirmedOn: "2026-10-13", note: "Studio confirmed parents' permission…" }`; `canShow()` hides any clip
  with `showsChildren: true` and no `consent`. Two clips (`founders`, `threeJars`) show no children.
- F4-07 seeds `media_assets` with all 6 clips (`kind='youtube'`, `youtube_id`, `shows_children`); the 4 class clips get
  `legacy_consent_note` = "Studio confirmed parents' permission on 2026-10-13, before this system". Staff then link the
  children who appear (`media_asset_children`), where known.
- F4-08 adds an optional `mediaAssetId` to the `Video` type so each clip can be matched to its `media_assets` row.
- **Truth about consent** = `consent_records` → `can_publish_media(asset_id, purpose)` shown as a matrix in `/admin/media`.

### 17.2 Rules before publishing a clip that shows children

1. Create or find the `media_assets` row and link **every** child who can be identified (`setMediaAssetChildren`).
2. Check the matrix in `/admin/media` for the channel:
   - Website clip (YouTube embed on the site) → needs **both** `media_website` **and** `media_youtube` = publishable for
     every linked child (the clip lives on YouTube too). `can_publish_media(asset, 'media_website')` enforces this for
     `kind = 'youtube'` assets (R-11).
   - Pre-system clips with no linked children count only for the channels in `legacy_consent_purposes` (set from the
     owner's G0 Q15 answer); other channels show "check manually" in `/admin/media`.
   - YouTube only → `media_youtube`. Facebook/Instagram/TikTok → `media_social`. Parents' group → `media_parents_group`.
   - Children aged 10+ need their own consent too (`needs_child` = not publishable).
   - If any child chose `face_hidden`, their face must not be recognisable in that clip.
3. Only then: add the clip to `videos.ts` with `consent` and `mediaAssetId`, commit, Publish (G10).
4. Never put names in titles, alt text, poster file names or captions.

Legacy clips (consent before this system): at the yearly review (§ 27), ask those families to confirm through the
normal consent flow, or retire the clips.

### 17.3 Takedown runbook (consent withdrawn, or a parent asks)

Trigger: a `consent_withdrawn` LINE alert for a media purpose, or any request from a parent or child.

| Step | Who | What |
|---|---|---|
| 1 | Staff/owner | Open `/admin/media`; filter by the family's child; list every asset linked to that child and the channels it is on. If the child isn't linked to any asset, check the channels by eye for clips from that period. |
| 2 | Builder (website) | For each affected clip in `src/content/videos.ts`: remove the clip's entry from `CLASS_VIDEOS` (or delete its `consent` field so `canShow()` hides it). **Also delete its poster files** in `public/images/videos/<poster>*`: a hidden clip's poster image is still reachable by URL until deleted. Run the README acceptance commands, commit, push (never force-push), then **Publish** (G10). |
| 3 | Owner (YouTube) | YouTube Studio → the video → Visibility **Private**, or delete. Removing it from the website does not remove it from YouTube. |
| 4 | Owner (social) | Delete or archive the posts/reels on Facebook, Instagram and TikTok (all accounts listed in `business.ts`). |
| 5 | Owner (parents' group) | Delete the photos/videos the studio posted, where the app allows (LINE "unsend" works only for a limited time; otherwise delete from albums/notes). Kindly ask group members not to keep or re-share. |
| 6 | Staff | `markMediaTakenDown` → `media_assets.status = 'taken_down'`, `taken_down_at`; note which channels were cleaned. |
| 7 | Staff | Tell the guardian (and the child, if 10+) what was removed, using § 16.4. Explain kindly that copies others already saved or shared can't all be recalled, and offer to help with specific ones. |
| 8 | Owner | If the clip was published **without** valid consent (not just withdrawn later), open a `breach_incidents` row and follow § 20. |

Target: steps 2–7 within 7 days (owner to confirm). Note: old poster images remain in **git history**; the GitHub repo
must be private (§ 8.3). Do not rewrite history (Lovable sync).

---

## 18. Data-subject requests (DSR): process and templates

Owner-only. The DSR tracker screen is **parked** (D27): track requests in a **private spreadsheet** with the same
fields as `dsr_requests` (received, requester, right, channel, identity verified, review due +15 days, due +30/+90
days, status, outcome, refusal reason, responded) — no health details, kept 3 years. The export, erase and restriction
**actions** exist from Stage B on the family page (owner card).

### 18.1 Deadlines

| Right (`dsr_right`) | PDPA | Review (`review_due_at`) | Respond (`due_at`) | Notes |
|---|---|---|---|---|
| `access` | s.30 | received + 15 days | received + 30 days; one extension of 30 days if complex, telling the requester (`extended_until`) | PDPC access-request notification (Gazette 16 Jul 2026, in force about mid-Sep 2026) |
| `portability` | s.31 | + 15 days | + 30 days (internal target) | JSON export |
| `objection` | s.32 | + 15 days | + 30 days (internal target) | no direct marketing in scope |
| `erasure` | s.33 | + 15 days | **+ 90 days**, including backups | PDPC 2024 erasure notification; restrict use meanwhile if it can't finish in time |
| `restriction` | s.34 | + 15 days | + 30 days (internal target) | owner sets it with `set_family_restriction()` (D28), see § 18.4 |
| `rectification` | s.35/36 | + 15 days | + 30 days (internal target; usually same day) | |
| `withdraw_consent` | s.19 | — | same day (§ 16) | tracked here only if it arrives as a formal request |

The `dsr_requests` BEFORE trigger sets `review_due_at` (+15 d) and `due_at` (+30 d, or +90 d for `erasure`).
The admin shows a countdown; keep every request and reply for 3 years (`retain_until`).

### 18.2 Process

1. **Receive** through any channel (`dsr_channel`): `in_person` at the studio (Soi Nawamin 117), `registered_mail`,
   `line`, `email`, `web`. Create the `dsr_requests` row the same day (`received_at` = when it arrived).
   Store the requester's name and what they ask for; no ID copies.
2. **Acknowledge** within 2 days (template § 18.6 A).
3. **Verify identity** (proportionate), set `identity_verified_at`:

   | Channel | How to verify |
   |---|---|
   | the family's existing LINE chat | the chat itself is the check (same account as at enrolment) |
   | in person | staff recognise the guardian or check the name against the family record; look at ID if needed, **never copy it** |
   | email / registered mail / new LINE account | call back the phone number on file, or ask them to confirm in the family's existing LINE chat |
   | someone acting for the guardian | written authorisation from the guardian + check both people as above |

   If the request is incomplete, ask for what's missing (status `waiting_for_requester`); the requester gets at least
   15 days to reply.
4. **Find the data:** `/admin/families` (by name, phone, nickname), `booking_requests` (inbox), consent records, LINE
   chats and paper forms.
5. **Do it** (§ 18.3), set `status`, `outcome`, `responded_at`.
6. **Refusals** only with a legal reason (e.g. accounting duty, legal claims), always **in writing** with the reason in
   `refusal_reason`, and the requester's right to complain to the PDPC. Refusals also go in the ROPA (§ 25, item 7).
7. **Reply** with template § 18.6. Never send health details over LINE; see § 18.5 for delivering copies.

### 18.3 How each right is done in the system

| Right | Steps |
|---|---|
| Access / copy / portability | `exportFamilyData` (owner) → one family's JSON (guardians, children, contacts, bookings, packages, payments, consents, health). Check it contains only that family. Deliver per § 18.5. |
| Rectification | Staff edit via `saveGuardian`, `saveChild`, `saveFamilyContact`; health via `saveChildHealth` (consent still required). |
| Erasure | Owner: family page → owner card → erase with typed confirmation → `eraseFamily` → `erase_family()`: personal data removed; payment amounts, dates, receipt numbers **and slip files** kept with the anonymised payment rows (accounting, G11); consent evidence rows and their files kept for 3 years without contact details (legal claims, ⚖️). Erasure itself queues no slip file (R-08). If G11 or the lawyer decides slips must go on erasure, a new SQL file makes `erase_family` set `slip_path = null` (the trigger then queues each file) and the owner runs "files to delete" the same day. Revoke the family's links (erasure deletes them). Delete or archive the LINE chat if they ask. Backups expire within ~14 days. |
| Objection | Stop the processing objected to unless there's a compelling legal reason; record the outcome. |
| Restriction | See § 18.4. |
| Withdraw consent | § 16. |

### 18.4 Restriction (D28, R-09)

Restriction is real data, not a status trick (`families.status` is recomputed every night). The owner opens the
family page → owner card → **"ระงับการใช้ข้อมูล / Restrict data use"**, types a short reason (e.g. "ระงับตามคำขอ
2026-11-02", no other detail) → `setFamilyRestriction` → SQL `set_family_restriction()`. While restricted:
1. the database refuses new bookings, new enrol links, new **granted** consents and edits to the family's own name,
   language and staff note (R-36), guardians, children and contacts (`family_restricted` in the admin); check-in/out of
   existing bookings, removing a contact, withdrawals and refusals still work;
2. unused enrol links are revoked automatically; the manage link stays so the parent can still withdraw;
3. the family is never marked inactive and never auto-erased; the owner can still export or erase on request;
4. record the request and the outcome in the private DSR spreadsheet (§ 18).
Lift it with the same button ("ยกเลิกการระงับ / Lift restriction").

**Correcting data while a family is restricted (R-37).** Restriction is often asked for while the parent disputes
whether data is accurate (s.34 together with s.36), and the fix is to correct the data. The database refuses every edit while
the restriction is set (including the family's own name, language and staff note), so the owner corrects in one
sitting, in this order:
1. owner lifts the restriction (same button; reason not needed);
2. owner (or staff, with the owner present) makes **only** the correction the parent asked for (`saveGuardian`,
   `saveChild`, `saveFamilyContact`, `saveFamily`);
3. owner restricts again if the parent still wants it, with the same short reason (e.g. "ระงับตามคำขอ 2026-11-02
   (หลังแก้ไข)");
4. one line in the private DSR spreadsheet: date, "lifted → corrected → restricted again", which field group changed
   (never the old or new value).
The audit log already records each step (`families` update × 2 by the owner, then the guardian/child/contact update,
actor and time, no values; D20), so the sequence can be shown later. Nothing else may be changed during step 2.

### 18.5 Delivering a copy safely

- Default: in person (on screen or printed) at the studio, or by email to the address the guardian confirms in their
  LINE chat, as an encrypted ZIP; send the password separately on LINE (a password is not health data).
- Never send the export file itself over LINE if it contains health information.
- Electronic copies are free (PDPC 2026 access notification: fees, if any, must not exceed actual cost).

### 18.6 Templates (TH + EN)

**A. Acknowledgement**
- TH: "สวัสดีค่ะ เราได้รับคำขอของคุณเรื่อง {สิทธิ} เมื่อวันที่ {วันที่} แล้วค่ะ เราจะตรวจสอบภายใน 15 วัน และตอบกลับภายในวันที่ {due_at} หากต้องการข้อมูลเพิ่มเพื่อยืนยันตัวตน เราจะติดต่อกลับนะคะ"
- EN: "Hello! We received your request about {right} on {date}. We'll review it within 15 days and reply by {due_at}. If we need anything to confirm it's you, we'll get in touch."

**B. Identity check**
- TH: "เพื่อความปลอดภัยของข้อมูลครอบครัว รบกวนยืนยันคำขอนี้ผ่านแชต LINE เดิมของครอบครัว หรือรับสายจากเราที่เบอร์ที่ให้ไว้กับสตูดิโอนะคะ เราไม่ต้องการสำเนาบัตรประชาชนค่ะ"
- EN: "To keep your family's information safe, please confirm this request in your family's usual LINE chat, or take our call on the number you gave the studio. We don't need a copy of your ID."

**C. Access done**
- TH: "เราเตรียมสำเนาข้อมูลของครอบครัวคุณเรียบร้อยแล้วค่ะ {วิธีส่งมอบ} หากมีข้อมูลใดไม่ถูกต้อง บอกเราได้เลยนะคะ"
- EN: "Your family's data copy is ready. {delivery method}. If anything is wrong, just let us know."

**D. Erasure done**
- TH: "เราลบข้อมูลของครอบครัวคุณออกจากระบบแล้วค่ะ ข้อมูลสำรองของระบบจะหมดไปเองภายในประมาณ 14 วัน ข้อมูลบางส่วนที่กฎหมายกำหนดให้เก็บ ได้แก่ {บันทึกการชำระเงินแบบไม่ระบุชื่อ / หลักฐานความยินยอม} จะเก็บต่อจนถึง {วันที่} เพื่อ {เหตุผล} แล้วจึงลบค่ะ"
- EN: "We've deleted your family's data from our system. System backups expire on their own within about 14 days. Some records the law requires us to keep ({anonymised payment records / consent evidence}) stay until {date} for {reason}, and are then deleted."

**E. Extension (access only, once)**
- TH: "คำขอนี้ต้องใช้เวลาตรวจสอบเพิ่มเติม เราขอขยายเวลาตอบกลับถึงวันที่ {extended_until} เนื่องจาก {เหตุผล} ขออภัยที่ต้องรอนะคะ"
- EN: "This request needs a little more time. We'll reply by {extended_until} because {reason}. Sorry for the wait."

**F. Refusal (in writing)**
- TH: "เราพิจารณาคำขอของคุณแล้ว แต่ไม่สามารถดำเนินการ {ส่วนใด} ได้ เนื่องจาก {เหตุผลตามกฎหมาย} คุณมีสิทธิร้องเรียนต่อสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคลได้ที่ https://complaint.pdpc.or.th/ ค่ะ"
- EN: "We've considered your request, but we can't {part} because {legal reason}. You have the right to complain to the Office of the Personal Data Protection Committee at https://complaint.pdpc.or.th/."

---

## 19. Retention schedule and the cleanup job

### 19.1 Schedule (proposal; owner to confirm at G0, lawyer at G9a/G9b, accountant at G11)

Copied from `00-overview.md` § 12, with reasons.

| Data | Period | Why | Mechanism | Purge version |
|---|---|---|---|---|
| `rate_limit_events` (HMAC of IP) | 24 hours | only needed for the hourly/daily limit | purge by `created_at` | v1 (0002) |
| `staff_notifications` | 30 days | resend window, debugging | `retain_until` | v1 |
| `booking_requests` | 6 months after creation | follow-up window for an unconverted enquiry | `retain_until` | v1 |
| Families, guardians, children, contacts | 12 months after last activity | re-enrolment within a year | `mark_inactive_families()` sets `retain_until` | v4 (0007) |
| `child_health` | deleted on withdrawal/refusal; else 6 months after the child's last session | s.26 minimisation | trigger + purge | v3 (0005) |
| `bookings` (attendance) | 24 months after the session date | attendance questions, safety history | `retain_until` (trigger) | v2 (0004) |
| `package_purchases`, `payments`, slips | 5 years after the end of the accounting year | Accounting Act (if a juristic person; G11) | `retain_until`; anonymised on erase | v2 |
| `consent_records`, consent evidence files | life of the consent + 3 years | s.78 civil claim period (evidence) | `retain_until` | v3 |
| `family_links` | 30 days after expiry | troubleshooting | purge | v3 |
| `dsr_requests` | 3 years after response | PDPC 2026 rule needs ≥ 2 years; 3 chosen | `retain_until` | v4 |
| `breach_incidents` | 5 years | accountability | `retain_until` | v4 |
| `audit_log` | 12 months | security review | `retain_until` | v4 |
| `media_assets` ↔ children | until withdrawal; yearly review | consent-based | manual (§ 17) | — |

### 19.2 Jobs

| Job | Schedule (UTC) | Bangkok | Does |
|---|---|---|---|
| `purge-expired-records` | `15 19 * * *` | 02:15 | `select public.purge_expired_records();` |
| `cron-history-cleanup` | `0 20 * * *` | 03:00 | `delete from cron.job_run_details where end_time < now() - interval '7 days';` |

Created by `sql/0002_booking_requests.sql`, visible in **More → Cloud → Jobs** (`40-integrations.md` § 7).

### 19.3 Design of `purge_expired_records()` (summary; `10-data-model.md` and the SQL drafts are authoritative)

- `SECURITY DEFINER`, `set search_path = ''`, `execute` revoked from `public`, `anon`, `authenticated` (only cron, and the
  builder in **Cloud → SQL editor** with the owner's OK, run it; never through Lovable chat, R-19).
- Inside: `set_config('cherrylee.allow_purge', 'on', true)` so append-only tables (`consent_records`) can be purged,
  switched off again at the end.
- Deletes children before parents (FK-safe order), each statement `where retain_until < now()` (or the rule in § 19.1).
  FK references from kept rows to purged ones are `on delete set null` (e.g. `families.source_request_id`,
  `booking_requests.converted_family_id`).
- Returns `jsonb` counts per table. Idempotent: running twice deletes nothing the second time.
- Re-declared in full in 0002 (v1), 0004 (v2), 0005 (v3), 0007 (v4); v4 calls `mark_inactive_families()` first.
- Also clears processed rows from `storage_cleanup_queue` (`deleted_at` older than 30 days, from v3).

### 19.4 Storage files (slips, consent evidence)

SQL cannot delete files: Supabase says deleting from `storage.objects` with SQL "will not remove the object from the
bucket and will result in the object being orphaned"
(https://supabase.com/docs/guides/storage/management/delete-objects). The data model therefore uses a queue:

1. Triggers on `payments` (`slip_path` changed or row deleted) and `consent_records` (row deleted) insert the old path
   into **`storage_cleanup_queue`** (`bucket_id`, `object_path`, `reason` = `row_deleted` | `replaced`, `queued_at`,
   `deleted_at`, `last_error`). This happens for staff edits, owner slip deletion (`deletePaymentSlip`) and the nightly
   purge. **Erasure does not queue slips or evidence**: the anonymised payment rows and detached consent records still
   reference them (R-08).
2. The owner-only server function **`runStorageCleanup`** (`privacy.functions.ts`, behind `requireOwner`; listing:
   `listStorageCleanup`) reads pending rows (`deleted_at is null`), calls
   `supabaseAdmin.storage.from(bucket_id).remove([object_path])`, and sets `deleted_at = now()` or a short `last_error`
   code. It never logs paths together with names (paths contain only uuids).
3. 🧑 The owner runs it from `/admin/privacy` → "ไฟล์รอลบ / Files to delete" ("ลบไฟล์ที่รออยู่ / Delete queued files"):
   the same day as any slip deletion, and monthly otherwise. The first payment slips reach their 5-year limit around
   2031, so routine volume is tiny.
4. **Orphan check (manual, only after a restore, § 7.3).** An orphan is a file whose path is **not referenced by any
   `payments.slip_path` or `consent_records.evidence_path`**. Never treat "the family no longer exists" as orphaned:
   erased families' slips and evidence are still referenced by kept rows. The builder lists bucket objects in Cloud →
   Storage, compares with those two columns in the SQL editor (read-only), and the owner deletes true orphans by hand.
   No code does this automatically.
5. Consent-evidence files are only queued when their `consent_records` row is deleted, i.e. after the consent's
   retention (life + 3 years), so evidence survives an erasure request (legal claims, ⚖️).

### 19.5 Checking that it works (🧑 builder/owner)

1. Weekly in the first month, then monthly: Jobs view shows **Succeeded** for both jobs.
2. Stage B acceptance test with fake data only: staff create an obviously fake family in the admin
   (`ครอบครัวทดสอบ`) **with no bookings, payments, packages, consents or link use**, and the builder runs once in
   **Cloud → SQL editor**
   `update public.families set created_at = now() - interval '13 months', retain_until = now() - interval '1 day' where display_name = 'ครอบครัวทดสอบ';`
   then `select public.purge_expired_records();` and checks the count and that the family is gone. Backdating
   `created_at` matters (R-31): purge v4 first runs `mark_inactive_families()`, which treats a family with any activity in
   the last 12 months as active and clears its `retain_until`, so only changing `retain_until` would leave it in place.
3. If Cloud was paused (credits), run the purge once manually after waking it.

---

## 20. Breach response runbook (72 hours)

A **personal data breach** is any accidental or unlawful loss, access, use, change or disclosure of personal data
(PDPA s.37(4)). Small everyday examples count: a private link pasted into the wrong family's chat; a roster screenshot
posted in a group; a staff phone lost while signed in; a misconfigured table; a clip published without consent.

### 20.1 Roles

- **Owner** = decision maker and PDPC contact. **Backup person** (named at G0) if the owner can't be reached within 12 hours.
- **Builder** = technical containment and investigation.
- Processors (Lovable/Supabase, Cloudflare, LINE) must tell us about their incidents; the same runbook applies.

### 20.2 Timeline (clock starts at `aware_at` = when the studio became aware)

| When | Step |
|---|---|
| **0 h** | Whoever notices tells the owner **immediately** (call, not just a message). Owner opens a `breach_incidents` row (`title`, `aware_at`); `pdpc_deadline` is set to `aware_at + 72 h` by trigger. Before P5: a private note with the same fields. |
| **0–4 h · Contain** | Pick what fits: revoke the wrong link (family page → revoke); remove the staff role (`removeStaffRole`) and delete/sign out the user; close the form (`studio_settings.booking_form_open = false`); rotate the affected secret (`40-integrations.md` § 4); ask Lovable support to rotate platform keys if `SUPABASE_SERVICE_ROLE_KEY`/`SUPABASE_DB_URL` may have leaked; delete wrongly posted content (§ 17.3); ask the wrong recipient to delete it and confirm. |
| **by 24 h · Assess** | What data (`data_categories`)? How many people (`affected_count`)? Children? Health? Who has it now? Is it still exposed? Set `risk_level`. |
| **by 72 h · Notify PDPC** | Unless the risk is `unlikely`, report to the PDPC through the e-service https://www.pdpc.or.th/17259/ (set `pdpc_notified_at`). If not all facts are known, report what you know and add the rest later. If you decide not to report, write why in `measures`. |
| **without delay, if `high`** | Tell affected families (template § 20.5), set `subjects_notified_at`. |
| **within 14 days · Review** | Root cause, what changes (code, habit, training), `closed_at`. Update this runbook if needed. |

### 20.3 Risk levels (`breach_risk`)

| Level | Examples | PDPC? | Families? |
|---|---|---|---|
| `unlikely` | an enrol link sent to the wrong chat, revoked within minutes, never opened (audit/`used_at` shows no use); a staff member's encrypted, locked phone lost and the role removed at once | no (record the reasoning) | optional courtesy note |
| `risk` | a few families' names and phone numbers seen by the wrong person | **yes, within 72 h** | consider |
| `high` | any **children's health/allergy** data exposed; children's photos published without consent; database tables exposed to the internet; many families affected | **yes, within 72 h** | **yes, without delay** |

### 20.4 PDPC report contents (have these ready)

1. What happened, when, and when we became aware.
2. Categories of data and of people (parents, children), approximate numbers.
3. Name and contact of the person handling it (owner / privacy contact).
4. Likely consequences for the people affected.
5. Measures taken and planned (containment, help for affected families, prevention).
Penalties for failing s.37 duties go up to ฿3M (s.83), ฿5M where s.26 data is involved (s.84), so report on time.

### 20.5 Message to affected families (warm, factual, no blame, no alarm)

**TH**

```
เรียนครอบครัว{ชื่อ}

CherryLee & Co. ขอแจ้งให้ทราบอย่างตรงไปตรงมาว่า เมื่อวันที่ {วันที่} มีเหตุการณ์ที่ทำให้ข้อมูลบางส่วนของครอบครัวคุณ
คือ {ข้อมูลอะไร} {เกิดอะไรขึ้น เช่น ถูกส่งไปผิดแชต / ถูกเข้าถึงโดยผู้ที่ไม่เกี่ยวข้อง}

สิ่งที่เราทำแล้ว: {การแก้ไข เช่น ยกเลิกลิงก์ ลบข้อความ เปลี่ยนรหัส}
สิ่งที่อาจเกิดขึ้น: {ผลที่อาจเกิดขึ้นตามจริง}
สิ่งที่คุณทำได้: {คำแนะนำที่ทำได้จริง เช่น ระวังข้อความแปลกๆ ที่อ้างชื่อสตูดิโอ}

เราได้แจ้งสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคลแล้ว {ถ้าแจ้ง}
เราขออภัยอย่างจริงใจค่ะ หากมีคำถามหรืออยากคุยกัน ติดต่อ {ชื่อผู้ประสานงาน} ได้ที่ LINE @cherryleeandco หรือ cherryleeandco@gmail.com
```

**EN**

```
Dear {family name} family,

We want to tell you openly that on {date}, something happened that affected some of your family's information:
{which data} {what happened, e.g. was sent to the wrong chat / was accessed by someone who shouldn't have seen it}.

What we've done: {actions, e.g. cancelled the link, deleted the message, changed passwords}
What this could mean: {honest, likely consequences}
What you can do: {practical steps, e.g. be careful with unexpected messages that use the studio's name}

We have reported this to Thailand's Office of the Personal Data Protection Committee. {if reported}
We're truly sorry. If you have questions or would like to talk, please contact {privacy contact} on LINE
@cherryleeandco or at cherryleeandco@gmail.com.
```

Send it individually (LINE chat of that family, or email), never in a group. If individual contact is impossible, a
public notice is allowed (PDPC breach notification).

---

## 21. Cross-border transfer note

⚖️ **LEGAL REVIEW.** Position for the privacy notice and the ROPA:

- **Where data is:** Lovable Cloud, region **Asia Pacific** (chosen at G2, permanent; city not documented by Lovable,
  ⚠️ UNVERIFIED; the Supabase APAC general region is Singapore). Hosting on Cloudflare's global network. LINE by LY
  Corporation (Japan; storage location of OA chats not confirmed). Google (Fonts, Maps, YouTube, Gmail) global.
  Optional: Umami (US/EU), Resend (US account data).
- **Law:** PDPA s.28 (destination with adequate standards, or an exception such as contract necessity or consent that
  names the risk) and s.29 (appropriate safeguards). PDPC notifications in force 24 Mar 2024 accept the Thai model
  clauses or "overseas" models (EU SCCs, ASEAN Model Contractual Clauses), BCRs or certification. As of April 2026 the
  PDPC has published **no** adequacy list (Baker McKenzie). The same notifications exclude data "in transit or stored"
  (e.g. cloud) where no third party other than the sender's controller/processor can access it. Whether that covers a
  managed database operator is unsettled.
- **What we do:** choose the closest region; keep Lovable's DPA (G2); disclose the transfer in the notice (§ 11) and in
  the health consent text (`health_allergy.v1`, `sql/0006_seed_consent_texts.sql`); minimise health data; send only booking communications through LINE (contract
  necessity, s.28(3)) and never health data.
- **Open:** whether to rely on the storage exclusion or on SCCs/ASEAN MCCs; whether Lovable's DPA includes SCCs; whether
  SCCs must be filed with the PDPC (sources disagree). See § 28.

---

## 22. Cookies and analytics statement

- No tracking or advertising cookies; no cookie banner needed while this stays true (D22). No GA4, no Meta Pixel.
- `localStorage`: `cherrylee-lang` (public site language) and `cherrylee-admin-lang` (staff admin language).
  Lovable Cloud Auth keeps the **staff** session in `localStorage` (admin only; parents never sign in).
- Turnstile only on `/book` (bot detection, described by Cloudflare as strictly necessary).
- YouTube click-to-load via `youtube-nocookie.com` (`src/components/YouTubeVideo.tsx`).
- Google Fonts (every page) and the Google Maps iframe (homepage) contact Google; disclosed. Options for later: self-host
  fonts; click-to-load map (parked card PK-06).
- Lovable built-in analytics: verify no cookies/identifiers (G12, `40-integrations.md` § 10.1).
- Optional Umami: cookieless, `data-do-not-track`, auto-track off, never on `/admin`, `/enrol/*`, `/my/*`, `/pay/*`.
- If anything ever sets a non-essential cookie or identifier: stop and add an opt-in banner with equal-weight
  "Accept"/"Reject" and logged choices **before** it goes live.

---

## 23. LINE data rules

1. `@cherryleeandco` stays unconnected to our server (D6). LINE chat content is never stored in our database.
2. Staff alerts (separate OA) carry only ref code, date, child count, purpose label and an admin link (`40-integrations.md` § 5.7).
3. Never send or ask for health/allergy details on LINE. Kind reply when a parent starts to:
   - TH: "ขอบคุณที่บอกเรานะคะ เพื่อความปลอดภัยของข้อมูลน้อง รบกวนกรอกเรื่องนี้ในลิงก์ส่วนตัวที่เราส่งให้แทนนะคะ ทีมงานจะอ่านก่อนคลาสทำอาหารค่ะ"
   - EN: "Thank you for telling us. To keep your child's information safe, please add this in the private link we sent you. Our team will read it before cooking sessions."
4. Private links are pasted **only** into that family's own LINE chat; never into groups; check the chat name before sending.
5. Put the privacy-notice link (`{PUBLIC_SITE_URL}/privacy`) in the `@cherryleeandco` greeting message (🧑 owner,
   LINE OA Manager → Greeting message).
6. Staff group chats: no parent names with photos, no roster screenshots, no health info.
7. Staff phones: screen lock on; LINE backups to personal cloud are the staff member's own choice; delete studio photos of
   children from personal phones once posted or no longer needed (owner to set a habit).
8. LY Corporation is a separate platform operator; LINE user IDs of parents are not stored before P7.

---

## 24. Processors and recipients

For the privacy notice (§ 11, section 5) and PDPA s.40. "DPA" = data processing agreement.

| Organisation | Role | Data | Agreement / status | Phase |
|---|---|---|---|---|
| Lovable | processor (hosting, database, auth, storage, logs) | everything submitted to the site | Lovable DPA https://lovable.dev/th/data-processing-agreement, saved at G2 | P0 |
| Supabase | Lovable's sub-processor (database technology) | same | covered by Lovable's DPA (Supabase DPA https://supabase.com/legal/customer-resources/data-processing-addendum) | P0 |
| Cloudflare | processor (network under Lovable hosting; Turnstile) | IP, browser signals, Turnstile tokens | Cloudflare terms + Turnstile privacy https://www.cloudflare.com/turnstile-privacy-policy/ (studio's own Cloudflare account for Turnstile) | P1 |
| LY Corporation (LINE) | platform operator; processor for alert pushes | chats with parents; PII-free alerts | LINE OA terms (https://www.lycorp.co.jp/en/privacy-security/privacy/transparency/guideline02_th/) | P1 |
| Google | provider (Fonts, Maps, YouTube, Gmail) | IP; emails; consented videos | Google terms | P1/P4 |
| Meta | provider (Messenger; Facebook/Instagram posts) | chats; consented media | Meta terms | P1/P4 |
| TikTok | provider (posts) | consented media | TikTok terms | P4 |
| Banks (studio's and parents') | independent controllers | transfer details | — | P3 |
| Emergency medical services | independent recipients | what's needed in an emergency | s.24(2)/s.26(1) | P3 |
| Umami (optional) | processor | cookieless analytics | Umami terms; add to notice before use | P6 |
| Resend (optional) | processor | owner's own email only (P6) | Resend terms; US account data | P6 |
| The builder (person) | acts for the studio | admin/DB access during work | short confidentiality note (§ 8.3) | P0 |
| Accountant / lawyer | independent advisers | as needed | professional confidentiality | as needed |

---

## 25. ROPA (record of processing activities)

PDPA s.39 requires the eight items below. The small-organisation exemption does **not** apply because the studio
regularly processes children's data and s.26 health data. Keep this table current; review yearly (§ 27). It is the
single source for the privacy notice and the retention job.

**Common to all activities**
- (3) Controller: `{{CONTROLLER_NAME_EN}}`, `{{FULL_ADDRESS_EN}}`, contact LINE @cherryleeandco / cherryleeandco@gmail.com;
  privacy contact `{{PRIVACY_CONTACT_EN}}`; no DPO appointed (s.41, likely not required, ⚖️).
- (7) Rejected requests and objections: recorded in `dsr_requests` (`status = 'refused'`, `refusal_reason`); summary
  copied here at each yearly review.
- (8) Security measures: Part A of this document (RLS, roles, audit log, private buckets, logging rules, backups,
  offboarding).

**Activities**

| # | Activity | Data subjects | (1) Data | (2) Purpose | Lawful basis | (4) Retention | (5) Who can access | (6) Disclosures / recipients | Cross-border |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Booking request (`/book`) | parents; children | guardian_name, phone/LINE ID, preferred contact, child nickname (opt.) + age, package, preferred day/date/session, message, lang, notice version; HMAC of IP (24 h) | reply about booking | s.24(3) | 6 months; IP hash 24 h | staff, owner | Lovable/Supabase; Cloudflare (Turnstile); LINE (PII-free alert) | APAC region; Cloudflare global |
| 2 | Family and child profile | parents; children | guardian name, phone, LINE ID, email (opt.), lang, parental-responsibility statement, identity-check method; child nickname, birth month | run classes | s.24(3); s.24(5) | 12 months after last activity | staff, owner | Lovable/Supabase | APAC |
| 3 | Allergy and care info | children (via parents) | allergen chips, other allergens, foods to avoid (no reason), care notes | safe cooking activities | **s.26 explicit consent**; emergency s.26(1) | until withdrawal; 6 months after last session | staff and owner, only via audited functions (`get_child_health`, `list_session_health_flags`) | Lovable/Supabase; medical staff in emergency | APAC |
| 4 | Emergency and pickup contacts | third parties named by parents | name, phone, relationship, flags, "informed" attestation | emergency contact; safe handover | s.24(5); s.24(2) | with the family profile | staff, owner | Lovable/Supabase | APAC |
| 5 | Attendance | children | session, check-in/out times, picked up by (guardian/contact), status | safety; package use | s.24(3); s.24(5) | 24 months after session | staff, owner | Lovable/Supabase | APAC |
| 6 | Packages and payments | parents | package, price snapshot, amount, method, paid_at, receipt no., slip image (opt.) | billing; accounting | s.24(3); s.24(6) | 5 years after accounting year end (G11) | staff (record), owner (void/refund) | Lovable/Supabase; banks; accountant | APAC |
| 7 | Media consent and media register | parents; children | consent records (purpose, decision, given_by, text version, channel, method, media level, staff id, evidence file), media_assets ↔ children links | lawful publication of class media | s.19/s.20 consent; evidence: s.24(6) / legal claims | consent life + 3 years | staff, owner | Lovable/Supabase; YouTube, Meta, TikTok, parents' group (only consented media) | APAC; platforms global |
| 8 | Staff alerts via LINE | (no personal data in text) | ref code, date, child count, purpose label, admin link; notification status | tell staff about new requests | s.24(5) | 30 days (`staff_notifications`) | owner/staff in LINE | LY Corporation | Japan (unconfirmed) |
| 9 | Staff accounts and audit log | staff | email, role, sign-in data (Auth), audit rows (actor, action, table, row id) | access control; security | s.24(3) (staff arrangement); s.24(5); s.37 | audit 12 months; account until offboarding | owner | Lovable/Supabase | APAC |
| 10 | Rights requests | parents/requesters | requester name, right, channel, dates, identity-verified date, outcome, refusal reason | comply with PDPA rights | s.24(6) | 3 years after response | owner | Lovable/Supabase; PDPC if complained | APAC |
| 11 | Breach log | anyone affected | incident facts, categories, counts, risk, notifications, measures | s.37(4) accountability | s.24(6) | 5 years | owner | PDPC; affected families | APAC |
| 12 | Chats with the studio (LINE/Messenger/email) | parents | message content, account names | answer questions; arrange classes | s.24(3); s.24(5) | per platform; studio habit (owner to set) | staff on studio accounts | LY Corp, Meta, Google | platforms' locations |

**Template row for a new activity**

```
| # | <activity> | <who> | <data fields> | <purpose> | <s.24(x) / s.26 / consent> | <period + mechanism> | <roles> | <recipients> | <locations> |
```

Add a row **before** the activity starts, update the privacy notice the same week, and add its rule to
`purge_expired_records()`.

---

## 26. Staff privacy notice

Short notice for staff accounts (shown at `/admin/login` as a link and given at onboarding). ⚖️ review with the main notice.

**TH**

```
ประกาศความเป็นส่วนตัวสำหรับทีมงาน CherryLee & Co.

เมื่อคุณใช้หลังบ้านของเว็บไซต์ เราเก็บอีเมล บทบาท (owner/staff) ข้อมูลการเข้าสู่ระบบ และบันทึกการใช้งาน
(ใครทำอะไรกับข้อมูลส่วนใด เมื่อไร โดยไม่บันทึกเนื้อหาของข้อมูล) เพื่อควบคุมสิทธิการเข้าถึงและดูแลความปลอดภัยของข้อมูลเด็กและครอบครัว
(ฐานการปฏิบัติตามข้อตกลงการทำงาน และประโยชน์โดยชอบด้วยกฎหมาย)
บันทึกการใช้งานเก็บ 12 เดือน บัญชีจะถูกลบในวันที่คุณหยุดทำงานกับสตูดิโอ เจ้าของสตูดิโอเป็นผู้เดียวที่ดูบันทึกการใช้งานได้
คุณใช้สิทธิตาม PDPA ได้เช่นเดียวกับผู้ปกครอง ติดต่อ {{PRIVACY_CONTACT_TH}}

ขอบคุณที่ช่วยกันดูแลข้อมูลของเด็กๆ นะคะ: เปิดดูข้อมูลสุขภาพเฉพาะเด็กที่คุณสอนในวันนั้น ไม่ส่งข้อมูลสุขภาพหรือลิงก์ส่วนตัวทาง LINE
นอกจากแชตของครอบครัวนั้นเอง และแจ้งเจ้าของสตูดิโอทันทีถ้าโทรศัพท์หายหรือส่งข้อความผิดแชต
```

**EN**

```
Privacy notice for CherryLee & Co. staff

When you use the admin area, we keep your email, role (owner/staff), sign-in data and an activity log (who did what to
which record and when, without the record's contents), to control access and protect children's and families' data
(legal basis: our working arrangement and legitimate interests).
The activity log is kept for 12 months. Your account is deleted on the day you stop working with the studio. Only the
studio owner can view the activity log. You have the same PDPA rights as parents; contact {{PRIVACY_CONTACT_EN}}.

Thank you for helping keep children's data safe: open health information only for children you teach that day, never
send health information or private links on LINE except in that family's own chat, and tell the owner straight away if
a phone is lost or a message goes to the wrong chat.
```

---

## 27. Annual review checklist

🧑 Owner, once a year (suggested: every October), plus whenever a new phase goes live.

- [ ] ROPA (§ 25) still matches what we actually do; new activities added.
- [ ] Privacy notice version matches the system; recipients list current (§ 24); contacts and address correct.
- [ ] Retention periods still right (§ 19.1); Jobs ran successfully all year; storage file purge done.
- [ ] Consent texts: any wording to improve → publish a new version (never edit, D12); retire old ones.
- [ ] Media register: legacy clips re-confirmed or retired; takedowns completed; children who turned 10 since their
      consent: ask for their own consent before new media use.
- [ ] Staff list and roles; Lovable/GitHub/Cloudflare/LINE members; 2-step verification on owner accounts.
- [ ] Audit log spot check; rights requests and incidents of the year reviewed (lessons learned).
- [ ] Vendors: Lovable region/DPA changes, LINE plan/quota, Cloudflare Turnstile hostnames, Umami/Resend if used.
- [ ] Law changes: PDPA amendment bill (consultation July–August 2026; would make consent one of seven equal bases),
      new PDPC notifications (ROPA guidance, cross-border lists).
- [ ] Lawyer check if anything material changed.

---

## 28. Open legal questions

For the Thai PDPA lawyer (G9a/G9b):

1. **Controller identity:** sole proprietor, partnership or company? Who is named in the notice? (G0 Q1)
2. **Children 10+ (D11):** is guardian + child consent for media, and guardian explicit consent + child agreement at
   first session for health, the right reading of s.20(1) and CCC ss.22–24?
3. **Health data:** is the explicit-consent text (`health_allergy.v1` in `sql/0006_seed_consent_texts.sql`, plus the
   deltas in § 12.2) sufficient, including the cross-border mention? Is the emergency disclosure wording right (s.26(1))?
4. **Cross-border:** does the PDPC 2024 storage exclusion cover a managed database (Lovable/Supabase)? If not, which s.29
   safeguard (EU SCCs / ASEAN MCCs) and is filing with the PDPC needed? Does Lovable's DPA include SCCs?
5. **LINE:** is LY Corporation a separate controller or our processor for OA chats and pushes? Is s.28(3) contract
   necessity the right basis for booking messages through LINE?
6. **Retention:** are the periods in § 19.1 defensible? Payment records: 5 years (Accounting Act) if a juristic person;
   what if a sole proprietor (Revenue Code)? (G11 with the accountant)
7. **Erasure vs evidence:** may we keep consent evidence (without contact details) for 3 years after an erasure request
   (legal-claims exception)? Keep or delete slip images on erasure?
8. **Withdrawal gap:** web consents from `/enrol` (P4) before `/my` exists (P5): is "tell us on LINE" acceptable meanwhile?
9. **Restriction (s.34):** is the database restriction (D28, § 18.4: new bookings, links, granted consents and profile
   edits refused; withdrawals and check-out still work) enough, and is "lift → correct → restrict again" (§ 18.4) the right
   way to fix data whose accuracy is disputed?
10. **DPO (s.41):** confirm not required.
11. **Staff notice and audit log:** sufficient for staff data (s.23, s.24)?
12. **Pending PDPA amendment:** anything to prepare now?

---

## 29. Sources

- PDPA (PDPC unofficial English translation): https://www.pdpc.or.th/wp-content/uploads/2023/12/2_Personal-Data-Protection-Act-2019.pdf
- PDPC consent guideline (7 Sep 2022): https://www.pdpc.or.th/1356/ · notice guideline: https://www.pdpc.or.th/1365/ ·
  breach e-service: https://www.pdpc.or.th/17259/ · complaints: https://complaint.pdpc.or.th/
- Consent/notice guideline summary: https://www.tilleke.com/insights/thailand-issues-guidelines-on-pdpa-consent-and-notification-requirements
- Access-request rules (2026): https://www.tilleke.com/insights/thailand-issues-new-rules-on-data-subject-access-requests/
- Erasure rules (2024): https://www.tilleke.com/insights/thailand-issues-criteria-for-deletion-destruction-and-de-identification-of-personal-data/
- Breach notification: https://www.tilleke.com/insights/thailand-pdpc-notification-on-data-breaches/
- Cross-border: https://www.tilleke.com/insights/thailand-unveils-regulations-for-cross-border-personal-data-transfer ·
  https://www.bakermckenzie.com/en/insight/publications/2026/04/thailand-pdpc-approved-bcrs-for-cross-border-transfers
- ROPA exemptions and guidance: https://www.tilleke.com/insights/first-set-of-subordinate-regulations-enacted-for-thailands-pdpa/ ·
  https://www.tilleke.com/insights/thailands-draft-compliance-guidelines-position-ropa-as-core-accountability-tool/
- DPO notification: https://www.tilleke.com/insights/thailand-releases-notification-on-data-protection-officer-appointment/
- PDPA amendment bill: https://www.tilleke.com/insights/thailand-proposes-significant-amendments-to-the-personal-data-protection-act/
- Children's images: https://tdri.or.th/en/2022/11/protecting-children-on-social-media/
- Lovable: database and backups https://docs.lovable.dev/features/database.md · auth https://docs.lovable.dev/features/authentication.md ·
  logs https://docs.lovable.dev/features/logs.md · cloud/regions https://docs.lovable.dev/features/cloud.md ·
  DPA https://lovable.dev/th/data-processing-agreement
- Supabase: storage deletes https://supabase.com/docs/guides/storage/management/delete-objects · RBAC
  https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac
- LINE privacy (LY Corporation): https://www.lycorp.co.jp/en/privacy-security/privacy/transparency/guideline02_th/
- Cloudflare Turnstile privacy: https://www.cloudflare.com/turnstile-privacy-policy/
