# 40 · Integrations and setup runbooks

Planning document, October 2026. Names (gates G0–G13 + G-MVP/G-HEALTH/G-PARK, decisions D1–D55, secrets, tables, functions, files) come from
[`00-overview.md`](00-overview.md) §§ 5, 9, 10, 11. If this file disagrees with `00-overview.md`, `10-data-model.md` or
`20-server-api.md`, those files win; fix this one.

**How to read the markers**

| Marker | Meaning |
|---|---|
| 🧑 **HUMAN** | A person does this (owner or builder). Implementing agents (Claude Haiku) never do it, and stop with "blocked by G…" if it is not done. |
| 🤖 **AGENT** | An implementing agent can do this inside a task card from `90-task-breakdown.md`. |
| ⚠️ **UNVERIFIED** | We could not confirm it in official docs or in the installed code. Check it and write the result in § 2. |

Menu paths in Lovable, LINE and Cloudflare change from time to time. If a menu name differs, look for the closest
match and write the real path into § 2 so the next person has it.

**One source per artifact (review R-14).** This file holds setup runbooks and HTTP facts only. TypeScript lives in
`20-server-api.md` (server code) and `30-ui.md` (UI code); alert wording lives in `buildStaffAlertText`
(`20-server-api.md` § 8.6); privacy-notice wording lives in `50-security-privacy.md` § 11. Where this file used to
repeat code, it now links there. **SQL that is not a migration** (the RLS smoke check, `seed_dev.sql`, the G5 owner
role, one-off checks) runs in **More → Cloud → SQL editor**, never through Lovable chat, so the agent can't save it as a
migration (https://docs.lovable.dev/features/database.md, R-19). Lovable chat is only for applying DDL migrations (G4).

---

## Contents

1. [Lovable Cloud setup (G1–G5)](#1-lovable-cloud-setup-g1g5)
2. [Observed after enabling Cloud (fill in)](#2-observed-after-enabling-cloud-fill-in)
3. [Migration workflow (G4)](#3-migration-workflow-g4)
4. [Secrets (G6) and rotation](#4-secrets-g6-and-rotation)
5. [Staff notifications via LINE (G8, P1)](#5-staff-notifications-via-line-g8-p1)
6. [Cloudflare Turnstile (G7, P1)](#6-cloudflare-turnstile-g7-p1)
7. [Scheduled jobs (pg_cron)](#7-scheduled-jobs-pg_cron)
8. [Payments: PromptPay and transfer slips](#8-payments-promptpay-and-transfer-slips)
9. [Transactional email (optional)](#9-transactional-email-optional)
10. [Analytics (cookieless)](#10-analytics-cookieless)
11. [LINE Login / LIFF (optional P7)](#11-line-login--liff-optional-p7)
12. [Custom domain follow-ups (G13)](#12-custom-domain-follow-ups-g13)
13. [Publish checklist (G10)](#13-publish-checklist-g10)
14. [Troubleshooting](#14-troubleshooting)
15. [Sources](#15-sources)

---

## 1. Lovable Cloud setup (G1–G5)

Lovable Cloud is Supabase underneath (Postgres, Auth, Storage, Jobs/pg_cron, Logs, Secrets). Decision D1 makes it the
only backend. Everything in this section is 🧑 **HUMAN**.

### G1 · Cloud permissions (owner, before anything else)

Why: by default Lovable's agent may switch Cloud on by itself ("Enable Cloud = Always allow"), and the region can never
be changed afterwards.

1. Lovable → workspace **Settings** → **Cloud permissions** (search the settings for "Cloud permissions" if the menu moved).
2. Set:

   | Permission | Value |
   |---|---|
   | Enable Cloud | **Ask each time** |
   | Modify database | **Ask each time** |
   | Configure auth | **Ask each time** |
   | Execute backward incompatible database migrations | **Never allow** (default; keep it) |

3. Open the project → **More → Cloud → Advanced settings** (visible before or right after enabling) and note the
   **Estimated monthly cost** for the smallest instance. Write it in § 2.
4. Cost background: Cloud usage is billed as Run credits. Pro has a 20-credit monthly Cloud grant that Lovable calls a
   "temporary offering"; top-ups are $15 per 50 credits on Pro. When credits run out the published site stays up, but the
   database, auth and storage pause until credits are added (then **More → Cloud → Overview → Wake up**).
   Source: https://docs.lovable.dev/introduction/credits-and-usage.md

### G2 · Enable Cloud (owner)

1. Open the project on the **main version** (not a draft; Cloud cannot be enabled from a draft).
2. **More → Cloud → Enable** (or accept Lovable's prompt to enable Cloud).
3. Region: choose **Asia Pacific**. **This is permanent.** Lovable does not say which city Asia Pacific is (⚠️ UNVERIFIED;
   ask Lovable support and write the answer in § 2 and in `50-security-privacy.md` § 21).
4. Read Lovable's Data Processing Agreement and save a PDF copy in the studio's records:
   https://lovable.dev/th/data-processing-agreement (needed for PDPA s.40; see `50-security-privacy.md` § 24).
5. Write the date, region and estimated cost in § 2.

### G3 · Bootstrap auth (builder)

1. In the Lovable project chat, send exactly:

   > Set up staff login with email and password only. Disable public sign-up. Turn on leaked-password protection. Do not create any tables. Keep errorMiddleware and csrfMiddleware in src/start.ts.

2. Approve only what matches the request. If Lovable proposes tables or a sign-up page, reply "No tables and no sign-up page, please."
3. In **More → Cloud → Users → Auth settings** check: sign-up **disabled**; email/password **on**; leaked-password
   protection **on**; minimum password length **12** if the setting exists (Lovable's minimum is 6; we want more).
4. On the builder's computer, from the repo root:

   ```sh
   git pull --ff-only
   npm install --no-package-lock     # only to fetch @supabase/supabase-js that Lovable added; never creates package-lock.json
   ```

5. Run the **post-pull verification** below (this is task F0-06; an 🤖 AGENT may do steps a–f read-only and report).

#### Post-pull verification (F0-06)

```sh
# a. generated Supabase files exist (do NOT edit any of them)
ls src/integrations/supabase/
#    expect: client.ts  client.server.ts  auth-middleware.ts  auth-attacher.ts  types.ts
#    (may also include cron-auth.ts, previewAuthStorage.ts)

# b. public build-time config exists (do not print its contents into chat or logs)
test -f .env && echo ".env present"
grep -c "VITE_SUPABASE_URL\|VITE_SUPABASE_PUBLISHABLE_KEY" .env    # expect 2

# c. project config
test -f supabase/config.toml && echo "config.toml present"

# d. dependency added by Lovable
grep -n '"@supabase/supabase-js"' package.json

# e. start.ts kept our middlewares AND gained the auth attacher
grep -n "functionMiddleware\|requestMiddleware\|attachSupabaseAuth\|errorMiddleware\|csrfMiddleware" src/start.ts
#    expect: functionMiddleware: [attachSupabaseAuth]
#            requestMiddleware: [errorMiddleware, csrfMiddleware]

# f. which migration folder exists (record it in § 2)
ls drizzle/migrations supabase/migrations 2>/dev/null
```

If (e) shows that `errorMiddleware` or `csrfMiddleware` disappeared: **stop**. The builder asks Lovable in chat to
"restore errorMiddleware and csrfMiddleware in src/start.ts exactly as before, next to attachSupabaseAuth", then pulls again.
Do not hand-edit `src/start.ts` in a way that removes `attachSupabaseAuth`.

Then run the README acceptance commands (`npx vite build`, `npx tsc --noEmit`, `npx vitest run`) to prove the
generated code builds, and record the results in § 2.

### G5 · Owner account and role (owner)

1. **More → Cloud → Users → Add user → Create new user**: the owner's own email and a strong password
   (a long passphrase; store it in a password manager). New users added here are confirmed automatically.
2. G4 must have applied `0001_foundation.sql` first (it creates `user_roles`).
3. Give the owner role. Pick **one** option.

   **Option A (recommended, no email needed).** Use it only when **Cloud → Users lists exactly one user** (the owner).
   Paste it into **More → Cloud → SQL editor** and run it once (not in Lovable chat: R-19):

   ```sql
   -- G5 · bootstrap the single owner. Safe to run twice: inserts nothing if an owner already exists.
   insert into public.user_roles (user_id, role)
   select u.id, 'owner'::public.app_role
   from auth.users as u
   where not exists (select 1 from public.user_roles where role = 'owner')
     and (select count(*) from auth.users) = 1
   order by u.created_at
   limit 1;
   ```

   **Option B (template with an email).** Use it when more than one user exists. Type the email **only in the SQL
   editor**. Never save this file with a real email, and never commit it filled in.

   ```sql
   -- G5 · give the owner role to one existing Cloud user. Replace <OWNER_EMAIL> in the SQL editor only.
   insert into public.user_roles (user_id, role)
   select u.id, 'owner'::public.app_role
   from auth.users as u
   where lower(u.email) = lower('<OWNER_EMAIL>')
   on conflict (user_id, role) do nothing;
   ```

4. The SQL editor does not create migration files. If Option B was ever run through Lovable chat by mistake, check
   after `git pull --ff-only`: `grep -rIl "@" drizzle supabase/migrations 2>/dev/null | xargs grep -l "user_roles" 2>/dev/null`.
   A hit is only the owner's own email; note it in § 2 and do not rewrite git history.
5. Sign in at `/admin/login` on the preview. The dashboard should show the owner role (P0 acceptance).

### Staff accounts (after F1-09)

- 🧑 Owner: **More → Cloud → Users → Add user** for each staff member (their own email; they choose the password on a
  call or in person, never sent in LINE). Then `/admin/settings` → "เพิ่มสิทธิ์ทีมงาน / Give staff access" (`setStaffRole`).
- Offboarding (same day): `/admin/settings` → remove role (`removeStaffRole`, takes effect on the next server call
  because every staff function re-checks the role), then **Cloud → Users → delete user**. Full checklist:
  `50-security-privacy.md` § 8.

---

## 2. Observed after enabling Cloud (fill in)

🧑 The builder fills this table after G2–G5 and the first G4. Implementing agents read it; they never guess these values.

| # | Question | Answer | Checked on (date) / by |
|---|---|---|---|
| 1 | Date Cloud was enabled; region shown in Cloud → Overview | | |
| 2 | City or data centre behind "Asia Pacific" (Lovable support answer) | | |
| 3 | Estimated monthly cost (Advanced settings), instance size | | |
| 4 | Migration folder Lovable wrote for `0001` (`drizzle/migrations/` or `supabase/migrations/`) | | |
| 5 | Did `0001` reach the **live** database before Publish? (check: tables visible in Cloud → Database while the published site is unchanged) | | |
| 6 | `src/start.ts` after G3: `functionMiddleware: [attachSupabaseAuth]` and `requestMiddleware: [errorMiddleware, csrfMiddleware]` both present? | | |
| 7 | Generated files present (list from § 1 step a) | | |
| 8 | Is `LOVABLE_CRON_SECRET` listed in Cloud → Secrets? (We don't use it; just record.) | | |
| 9 | Do custom secrets added in Cloud → Secrets reach server functions via `process.env["NAME"]`? (F1-10: a staff-only test function that returns only `true`/`false` per name, never the value) | | |
| 10 | Does `cf-connecting-ip` / `getRequestIP()` give the real visitor IP on the preview and on the published site? (F1-10: compare with the IP shown by a "what is my IP" site; never log or store the raw IP) | | |
| 11 | Cloud auto-pause window (Lovable support) and whether a visitor request wakes it | | |
| 12 | Does Cloud → Users → Auth settings offer MFA / TOTP? (F5-06) | | |
| 13 | Minimum password length setting available? Value set | | |
| 14 | Did the G5 data statement create a migration file? | | |
| 15 | Is the GitHub repo `siripongsri-maker/github-seed` **private**? (It must be: poster images and history stay in git.) | | |
| 16 | Does pg_cron appear in Cloud → Jobs after `0002`? First run status | | |
| 17 | Does Lovable's built-in analytics set cookies or localStorage on the published site? (G12, § 10.1) | | |
| 18 | Import lines of the generated `src/integrations/supabase/auth-middleware.ts` (card P0-15: `grep -n "^import" …`; module names only). Must NOT include `client.server`, `@tanstack/react-start/server-only` or anything reading `SUPABASE_SERVICE_ROLE_KEY` (our `auth.middleware.ts` imports it from browser-bundled code, `20-server-api.md` § 6). Exported name of the middleware (`requireSupabaseAuth`?) and its context members (`supabase`, `userId`, `claims`?) | | |

---

## 3. Migration workflow (G4)

Decision D21. SQL is written by agents as **draft files only** in `docs/backend/sql/NNNN_*.sql` and applied by a human.

1. 🧑 Builder checks the task card says the SQL file is ready and reviewed (header comment lists phase, gate, depends-on).
2. 🧑 Builder runs `git pull --ff-only` (so Lovable and git agree).
3. 🧑 In Lovable chat, paste:

   > Apply this SQL migration exactly as written. Do not change it.
   >
   > *(paste the whole content of `docs/backend/sql/NNNN_name.sql`)*

4. 🧑 Lovable shows the SQL for approval ("Modify database = Ask each time"). Compare the first and last 10 lines and the
   number of `create` statements with the file. If Lovable rewrote anything, reject and ask it again to apply the file
   unchanged. If it refuses something as "backward incompatible", stop and report; our files are additive only, so this
   means a mistake in the file.
5. 🧑 If Lovable says an extension is missing (for example `pg_cron` in `0002`), reply: "Please enable the pg_cron
   extension (it is on Lovable's allowed list), then apply the migration exactly as written."
6. 🧑 After success: `git pull --ff-only`. Check:
   - a new migration file appeared (folder from § 2 row 4);
   - `src/integrations/supabase/types.ts` changed and now contains the new table names
     (`grep -c "booking_requests" src/integrations/supabase/types.ts`).
7. 🧑 Mark the gate done for that file in `90-task-breakdown.md` (date, folder, types regenerated yes/no).
8. 🧑 Run the read-only RLS smoke check (`docs/backend/sql/tests/rls_smoke.sql`) in **More → Cloud → SQL editor**
   (it is wrapped in `BEGIN … ROLLBACK`). Any `FAIL` line = stop. Never insert test data with SQL outside
   `seed_dev.sql` (which also ends in `ROLLBACK`): drafts and the live site share one database.

Never:
- apply SQL with the Lovable MCP `query_database` tool (it bypasses Lovable's migration history and type generation);
- run non-migration SQL (smoke check, seed, G5) through Lovable chat (use the SQL editor);
- edit files under `drizzle/` or `supabase/migrations/`, or `src/integrations/supabase/*`;
- paste personal data (names, phones, health) into Lovable chat. Lovable's AI processes chat text outside the Cloud region.

---

## 4. Secrets (G6) and rotation

All 🧑 **HUMAN** (owner). Where: **More → Cloud → Secrets → Add secret**. Values are write-only (Lovable never shows them
again). **Never** paste a value into chat (Lovable, LINE, Claude), a file, a commit or a screenshot.

| Secret | Where the value comes from | Format check | Phase |
|---|---|---|---|
| `IP_HASH_SECRET` | Owner's own computer, Terminal: `openssl rand -hex 32`. Copy the output straight into Lovable; don't save it anywhere. | 64 hex characters | P1 |
| `TURNSTILE_SECRET_KEY` | Cloudflare → Turnstile → the widget → **Secret key** (§ 6) | starts with `0x` | P1 |
| `LINE_ALERT_CHANNEL_ID` | LINE Developers → provider "CherryLee & Co." → channel "CherryLee Staff Alerts" → **Basic settings → Channel ID** (§ 5) | digits only | P1 |
| `LINE_ALERT_CHANNEL_SECRET` | same page → **Channel secret** | 32 hex characters | P1 |
| `LINE_ALERT_TO` | owner's user ID (**Basic settings → Your user ID**) or a staff group ID (§ 5.6) | `U` or `C` + 32 hex characters | P1 |
| `PUBLIC_SITE_URL` | the live site address: `https://cherryleeandco.com` (D37; the domain is live and G13 is done) | starts with `https://`, **no trailing slash** | P1 |
| `PROMPTPAY_ID` (optional) | the studio's business PromptPay ID (§ 8) | 10, 13 or 15 digits | P6 |
| `RESEND_API_KEY` (optional) | Resend → API Keys → Create (permission "Sending access") (§ 9) | starts with `re_` | P6 |
| `STAFF_NOTIFY_EMAIL` (optional) | the owner's own inbox used to sign up for Resend | an email address | P6 |

After adding or changing a secret, press **Publish** again (G10). ⚠️ UNVERIFIED whether a republish is required for the
published site to see a new secret; republishing is harmless.

Public values that are safe to publish are **not** secrets and go in `src/lib/backend/public-config.ts`
(`TURNSTILE_SITE_KEY`, `TURNSTILE_TEST_SITE_KEY`, `UMAMI_WEBSITE_ID`). Never add lines to `.env` (Lovable generates it).

### Rotation (what to do if a value may have leaked)

| Secret | How to rotate | Side effects |
|---|---|---|
| `IP_HASH_SECRET` | generate a new one, replace, Publish | rate-limit counters restart (harmless) |
| `TURNSTILE_SECRET_KEY` | Cloudflare → Turnstile → widget → **Rotate secret key**, replace, Publish | none if done together |
| `LINE_ALERT_CHANNEL_SECRET` | LINE Developers → channel → Basic settings → Channel secret → **Issue** (reissue), replace, Publish | alerts fail until replaced; stateless tokens issued with the old secret expire within 15 minutes |
| `SUPABASE_SERVICE_ROLE_KEY` and other Lovable-managed keys | ⚠️ UNVERIFIED whether Lovable lets you rotate them; contact Lovable support | — |
| `RESEND_API_KEY` | Resend → API Keys → delete key, create a new one | email backup alert fails until replaced |

---

## 5. Staff notifications via LINE (G8, P1)

### 5.1 Decision summary

- LINE Notify was shut down on 31 March 2025 (https://notify-bot.line.me/closing-announce). The replacement is a LINE
  Official Account (OA) that sends **push messages** through the Messaging API.
- **D6:** we do **not** connect `@cherryleeandco` (the parents' chat account) to the Messaging API or a webhook in P0–P6.
  Linking an OA to a provider is permanent, the free message quota would be shared with the studio's broadcasts, and every
  parent message would be forwarded to our server.
- **D7:** a **separate**, notification-only OA "CherryLee Staff Alerts" on the **Free** plan pushes PII-free alerts to the
  owner (or a staff group). The database row in `staff_notifications` is the source of truth. A failed alert never fails a
  parent's submission; it shows in the admin inbox with a resend button.
- Parents keep using `@cherryleeandco` exactly as today. After submitting `/book`, the thank-you screen offers
  "ส่งรหัสทาง LINE / Send your code on LINE" built with the existing `lineMessageUrl()` in `src/content/business.ts`
  (zero cost; the parent sends the ref code into the chat staff already watch).

### 5.2 One-time setup (G8) 🧑 HUMAN (owner)

Do this with the **studio's own LINE account** (the one that owns `@cherryleeandco`), not a freelancer's or the builder's.

1. Go to https://developers.line.biz/console/ and log in with the studio's LINE account.
2. **Create a provider** named `CherryLee & Co.`. ⚠️ A LINE Official Account linked to a provider can never be moved or
   unlinked (https://developers.line.biz/en/docs/messaging-api/getting-started/). Reuse this provider for every future
   LINE channel (the alert OA now; LINE Login and `@cherryleeandco` only if P7 is ever approved).
3. Create a new LINE Official Account named **CherryLee Staff Alerts** (LINE Official Account Manager,
   https://manager.line.biz/ → Create). Plan: **Free** (Thailand: 300 messages/month, no extra messages).
4. In LINE Official Account Manager → the new OA → **Settings → Messaging API → Enable Messaging API** → choose the
   provider `CherryLee & Co.`.
5. **Settings → Response settings** for the alert OA:
   - Greeting message: **Off**
   - Auto-response messages: **Off**
   - Webhooks: **Off** (turn on only for § 5.6, then off again)
   - Chat: **Off** if LINE allows it. ⚠️ UNVERIFIED: LINE may refuse to have Chat and Webhooks both off. If it refuses,
     leave **Chat On**. Only staff will ever see this OA, so it does no harm.
6. Owner opens the OA's profile in the LINE app and **adds it as a friend** (push messages only reach friends who have
   not blocked the OA).
7. LINE Developers console → provider `CherryLee & Co.` → channel **CherryLee Staff Alerts** → **Basic settings**:
   - copy **Channel ID** → secret `LINE_ALERT_CHANNEL_ID`
   - copy **Channel secret** → secret `LINE_ALERT_CHANNEL_SECRET`
   - copy **Your user ID** (starts with `U`) → secret `LINE_ALERT_TO` (alerts go to the owner only)
8. Do **not** issue a long-lived channel access token. Our code issues a fresh 15-minute stateless token per alert.
9. Optional: to send alerts to a staff group instead of the owner, do § 5.6 and replace `LINE_ALERT_TO` with the group ID.
10. ⚠️ UNVERIFIED: whether the new OA can be hidden from LINE search. If OA Manager has a "show in search results"
    setting, turn it off.

### 5.3 HTTP calls (exact)

All calls are made **server-side only** from `src/server/line-alert.server.ts` (first line
`import "@tanstack/react-start/server-only";`). Use `fetch` with an `AbortSignal` so the whole alert finishes within
**4,000 ms** (D7). Reference: https://developers.line.biz/en/reference/messaging-api/ ,
https://developers.line.biz/en/docs/basics/channel-access-token/

**(a) Issue a stateless channel access token** (`issueLineStatelessToken`)

```http
POST https://api.line.me/oauth2/v3/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id={LINE_ALERT_CHANNEL_ID}&client_secret={LINE_ALERT_CHANNEL_SECRET}
```

Response 200: `{ "token_type": "Bearer", "access_token": "…", "expires_in": 900 }`. The token is valid 15 minutes,
cannot be revoked, and issuance is unlimited. Never log or store it. Non-200 → error code `line_token_http_<status>`.

**(b) Push a text message** (`pushLineText`)

```http
POST https://api.line.me/v2/bot/message/push
Content-Type: application/json
Authorization: Bearer {access_token}
X-Line-Retry-Key: {staff_notifications.id}      ← a UUID; same key on every retry of the same notification

{ "to": "{LINE_ALERT_TO}", "messages": [ { "type": "text", "text": "{alert text, ≤ 5000 chars}" } ] }
```

| Response | Meaning | Our status |
|---|---|---|
| 200 | accepted | `sent` |
| 409 | a request with this retry key was already accepted ("If you retry an API request that the LINE Platform returned the status code 2xx, you'll get the status code 409") | `sent` (not a duplicate) |
| 400 | bad request (often a wrong `LINE_ALERT_TO`) | `failed`, `line_push_http_400` |
| 401 | bad or expired token | `failed`, `line_push_http_401` |
| 403 | not allowed (e.g. plan restriction) | `failed`, `line_push_http_403` |
| 429 | rate limit **or monthly quota used up** ("You have reached your monthly limit.") | `failed`, `line_push_http_429` |
| 5xx | LINE problem | `failed`, `line_push_http_<status>` |

Retry keys are valid for 24 hours after the first request
(https://developers.line.biz/en/docs/messaging-api/retrying-api-request/). A resend from the admin after 24 hours can
deliver a second copy; that is acceptable.

**(c) Reply to a webhook event** (only for the optional group-ID capture in § 5.6; replies are free and don't count
against the quota)

```http
POST https://api.line.me/v2/bot/message/reply
Content-Type: application/json
Authorization: Bearer {access_token}

{ "replyToken": "{event.replyToken}", "messages": [ { "type": "text", "text": "…" } ] }
```

**(d) Check the monthly quota** (manual, by the builder; no admin UI in P1)

```http
GET https://api.line.me/v2/bot/message/quota               → { "type": "limited", "value": 300 }
GET https://api.line.me/v2/bot/message/quota/consumption   → { "totalUsage": 42 }
Authorization: Bearer {access_token}
```

The same numbers are visible in LINE Official Account Manager → **Insight** / **Messages**.

### 5.4 Code: see `20-server-api.md` § 7.5 (single source)

`issueLineStatelessToken` and `pushLineText` (signature `{ channelId, channelSecret, to, text, retryKey, signal }`,
result `LinePushResult = { ok, status, error? }`) are specified and tested in `20-server-api.md` § 7.5. Error codes
stored in `staff_notifications.last_error` come from that code: `line_token_http_<status>`, `line_token_missing`,
`line_push_http_<status>`, `timeout`, `network`, plus `missing_config` and `exception` from `notifyStaff` (§ 7.8).
Never log the token, the channel secret, `LINE_ALERT_TO` or the alert text.

### 5.5 Flow: `notifyStaff` (`src/server/staff-notify.server.ts`)

Called by `submitBookingRequest` (kind `booking_request`), `submitEnrolment` (`enrolment_submitted`) and
`retryStaffNotification` (staff "resend"). **Consent alerts are queued by the database** (trigger
`queue_consent_change_alert`, D29) for every decision that moves away from `granted`, on any channel; the server pushes
them with `deliverAlertIds` / `deliverConsentAlert` (`20-server-api.md` § 7.8), which call `notifyStaff` with the existing
row id. It **never throws**. The exact code is in `20-server-api.md` § 7.8; the outline below is for reading only.

```
1. insert staff_notifications {kind, ref_id, status:'pending', attempts:0}  → id      (service role)
   (retryStaffNotification re-uses the existing row instead)
2. read studio_settings.staff_alerts_enabled
      false → update status='skipped' → return
3. optionalServerEnv LINE_ALERT_CHANNEL_ID, LINE_ALERT_CHANNEL_SECRET, LINE_ALERT_TO
      any missing → status='failed', last_error='missing_config', attempts+1 → return
4. text = buildStaffAlertText({...})            (pure, src/lib/backend/staff-alert-text.ts; no names/phones/LINE IDs)
5. result = await pushLineText({... retryKey: id, signal: AbortSignal.timeout(4000) })
6. ok   → status='sent', sent_at=now(), attempts+1, last_error=null
   fail → status='failed', attempts+1, last_error=result.error
7. any unexpected exception → status='failed', last_error='exception' (best effort) → return
```

`last_error` values: see § 5.4 (one list, from `20-server-api.md`).

Why awaited: on Cloudflare Workers, work started after the response is sent may be cut off. The 4-second cap keeps
the parent's wait short. Why no automatic retry: there is no background worker; staff press "ส่งแจ้งเตือนอีกครั้ง /
Resend alert" in `/admin/inbox/$requestId`, which calls `retryStaffNotification` with the same retry key.

`adminUrl` = `PUBLIC_SITE_URL` (or, if unset, the request origin) + path:

| kind | path |
|---|---|
| `booking_request` | `/admin/inbox/{booking_requests.id}` |
| `enrolment_submitted` | `/admin/families/{families.id}` |
| `consent_withdrawn` | `/admin/families/{families.id}` |

A UUID in a link is not personal data on its own, and the page needs a staff login.

### 5.6 Optional: send alerts to a staff group (F1-08)

Only if more than one person should get alerts (for example Kru Cherry and Uncle Lee). Each group push counts **once per
group member** against the 300/month quota (§ 5.8).

🧑 HUMAN steps:
1. LINE Developers → channel → **Messaging API** tab → **Allow bot to join group chats** → Edit → enable (it opens OA
   Manager; save there). Off by default.
2. Make sure F1-08 (`src/routes/api/line/alert-webhook.ts`) is deployed and the site is **published** (G10).
3. Messaging API tab → **Webhook URL** = `{PUBLIC_SITE_URL}/api/line/alert-webhook` → **Verify** (expects 200) →
   turn **Use webhook** on.
4. Create a LINE group with the staff (no parents, ever) and invite "CherryLee Staff Alerts".
5. The bot replies in the group with the group ID. Copy it into the secret `LINE_ALERT_TO` and Publish.
6. Turn **Use webhook** **off** again. While it is on, every message staff write in that group is sent to our server
   (we ignore it, but it is still staff chat content leaving LINE).

🤖 AGENT: the route `src/routes/api/line/alert-webhook.ts` is specified in `20-server-api.md` § 10.1 (single source:
raw body first, signature check before parsing, a guarded `JSON.parse`, reply text inline, stores and logs nothing).
`verifyLineSignature` (`20-server-api.md` § 7.6): `base64(HMAC-SHA256(key = channel secret, data = raw UTF-8 body))`
checked with Web Crypto `crypto.subtle.verify` (https://developers.line.biz/en/docs/messaging-api/verify-webhook-signature/).

### 5.7 Alert message templates (PII-free)

Alerts are Thai only (internal, studio voice). The **canonical** implementation is `buildStaffAlertText` in
`src/lib/backend/staff-alert-text.ts`, specified in `20-server-api.md`; if wording differs, `20-server-api.md` wins.
English is given here only so reviewers can read it.

**Allowed in an alert:** ref code, a date, number of children, a purpose label, an admin link.
**Never in an alert:** guardian or child names or nicknames, phone, LINE ID, email, ages, health or allergy words about a
specific child, payment amounts, free-text messages from parents.

`booking_request` (exact, from the architect's brief):

```
คำขอจองใหม่ค่ะ
รหัส: {ref}
วันที่สนใจ: {date}
จำนวนเด็ก: {n} คน
ดูรายละเอียด: {adminUrl}
```

EN reading: "New booking request · Code: {ref} · Preferred date: {date} · Children: {n} · Details: {adminUrl}".
`{date}` = the chosen session date (P2) → else `preferred_date` → else the preferred-day label (`sat` → เสาร์,
`sun` → อาทิตย์, `either` → เสาร์หรืออาทิตย์) → else `ยังไม่ระบุ`. Dates use `formatSessionDate(date, "th")`
(Buddhist year).

`enrolment_submitted` and `consent_withdrawn`: the exact Thai lines are the ones in `buildStaffAlertText`
(`20-server-api.md` § 8.6), e.g. "ผู้ปกครองส่งข้อมูลลงทะเบียนแล้วค่ะ" and "มีการถอนความยินยอมค่ะ / เรื่อง: {purposeLabel} /
กรุณาตรวจสอบและดำเนินการในหลังบ้านค่ะ". Do not copy wording from older drafts of this file. EN reading: "A family has
sent their enrolment details" · "Consent withdrawn · Topic: {purpose} · please check and act in the admin" (health: the
row is already deleted; media: takedown runbook, `50-security-privacy.md` § 17).

Unit test (required): build each kind with fake inputs that include a name-like nickname, a phone `0800000001` and a
LINE ID `test.line.id` in the source record, and assert none of them appear in the output.

### 5.8 Quota maths (Free plan, Thailand)

Push, multicast and broadcast messages count; replies don't. A push to a group counts once per member
(https://developers.line.biz/en/docs/messaging-api/pricing/ ;
https://lineforbusiness.com/th/service/line-oa-features/broadcast-message).

| `LINE_ALERT_TO` | Messages per alert | Alerts per month on 300 |
|---|---|---|
| owner user ID | 1 | 300 |
| group of 2 staff | 2 | 150 |
| group of 3 staff | 3 | 100 |

When the quota is used up, LINE returns 429 and the message is **not** sent. Our row becomes `failed` with
`line_push_http_429`; the request is still safe in the inbox. If this happens regularly, either alert only the owner, or move
the alert OA to a paid plan (Basic ฿1,280/month + VAT, 15,000 messages; prices from the lineforbusiness page above,
⚠️ check current prices before buying).

### 5.9 What is never connected

- `@cherryleeandco`: no Messaging API, no webhook, no provider link (D6). Parent chats stay on staff phones.
- No LINE chat content is stored in our database. No LINE user IDs of parents are stored before P7.

### 5.10 Parents' contact rule (D35, decision 4 of 14 Oct 2026)

- **D26 stands.** A LINE Official Account cannot add a user by LINE ID or message someone who has not messaged it. Parents
  message `@cherryleeandco` first, or add the OA themselves.
- **Staff never add a parent** from a personal LINE account. No screen asks staff to copy a parent's LINE ID in order to
  add them. Any button, field or copy that does is removed (checked at G10).
- **The system never receives a parent's LINE user ID** (no webhook, no LINE Login before P7). The optional **LINE ID hint**
  a parent may type on `/book` (D26) is used only to find the right chat. The owner has not asked to remove it, so it stays
  optional. The owner confirms this reading in one line (open).
- **Follow-up messages** (`marketing_line`, D31) are typed by hand in an existing chat. They are never sent in bulk or through
  the Messaging API.
- **Round two (14 Oct 2026, item 8): D26 is kept, no change.** The owner answered "คงไว้" (keep it). This confirms the reading of D35 that the owner was asked to confirm: parents message `@cherryleeandco` first or add the OA themselves, and staff never copy a parent's LINE ID.
- **Exports and print do not leave the system (D33, D42).** The export and the signing sheet are made on request and go only to the staff member's browser. Nothing is sent to LINE, e-mail or any third party, and the signing sheet is not stored on the server. A PDF saved from the browser is a file on the staff member's own device, so the device rules in `50-security-privacy.md` § 23 item 7 apply.
- **Notice time from the channel that received it (D53, round three; D26 unchanged).** A cancellation notice can arrive by phone, on LINE, by telling a teacher, or in person (`cancel_notice_channel` = `line`, `phone`, `teacher` or `in_person`). The system receives nothing from any of these: no webhook, no call log and no LINE push (D6). Staff type the time the notice reached the studio into the booking screen (`cancel_notice_at`): the call time for `phone`, the message time shown in the OA chat for `line`, the time the teacher was told for `teacher`, and the time of the visit for `in_person`. The LINE rule stays as it is (D26, D35, D47). **Confirmed:** the notice time is recorded from the channel that received it, and no integration is needed for it.

---

## 6. Cloudflare Turnstile (G7, P1)

Free bot check for `/book` (D18). Cookieless by Cloudflare's description; listed in the privacy notice.
Docs: https://developers.cloudflare.com/turnstile/

### 6.1 Widget setup (G7) 🧑 HUMAN (owner)

1. Create a Cloudflare account with the studio's email (the site does **not** need to be hosted on Cloudflare).
2. Dashboard → **Turnstile** → **Add widget**.
   - Widget name: `CherryLee booking form`
   - Hostnames (exact; each one also covers its subdomains; wildcards are not allowed):
     - `cherryleeandco.com` (the live domain, D37; `www.cherryleeandco.com` is UNVERIFIED: check in the Cloudflare console and add it as its own hostname if it is not covered)
     - `id-preview--fa9b86e9-5d99-468e-be51-3be106fa410c.lovable.app` (the Lovable preview host, for testing)
     - the published `<published-name>.lovable.app` host, only while it is still used
     - **never** the apex `lovable.app` (that would authorise every Lovable site)
   - Widget mode: **Managed**
   - Pre-clearance: **No**
3. Copy the **Site key** (public) → give it to the builder → committed in `src/lib/backend/public-config.ts` as
   `TURNSTILE_SITE_KEY` (🤖 AGENT task in F1-05).
4. Copy the **Secret key** → secret `TURNSTILE_SECRET_KEY` (§ 4). Never in chat or code.

Test keys (always work, also on `localhost`; from https://developers.cloudflare.com/turnstile/troubleshooting/testing/):

| Purpose | Site key | Secret key |
|---|---|---|
| always passes | `1x00000000000000000000AA` (`TURNSTILE_TEST_SITE_KEY`) | `1x0000000000000000000000000000000AA` |
| always fails | `2x00000000000000000000AB` | `2x0000000000000000000000000000000AA` |
| "token already spent" | — | `3x0000000000000000000000000000000AA` |

### 6.2 Client (browser) 🤖 AGENT (`src/components/booking/TurnstileWidget.tsx`, F1-05)

- Load the script **only on `/book`** (not in `__root.tsx`), so Cloudflare sees a visitor only when they open the form:
  `https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit` (load it directly; don't proxy or self-host it).
- Site key: `turnstileSiteKey()` from `public-config.ts` (`20-server-api.md` § 8.7).
- Render explicitly inside a `useEffect`, and remove it in the cleanup. **The code is `TurnstileWidget` in
  `30-ui.md` § 2.5** (single source: `theme: "light"`, `action: "booking_request"`, `language` from the page, reset after
  a failed submit, `onUnavailable` → LINE fallback).
- Send the token as a field of the form input (name it in `booking.schema.ts`; `20-server-api.md` is authoritative).
  Zod: string, 1–2048 characters.
- If the widget errors, the form shows (TH/EN, from `src/content/booking.tsx`) a warm line with the LINE button, e.g.
  "ระบบตรวจสอบโหลดไม่สำเร็จ ทักหาเราทาง LINE ได้เลยนะคะ / The check didn't load. You're welcome to message us on LINE."
- If a Content-Security-Policy is ever added, allow `https://challenges.cloudflare.com` in `script-src` and `frame-src`.

### 6.3 Server check 🤖 AGENT (`src/server/turnstile.server.ts`, `verifyTurnstile`)

```http
POST https://challenges.cloudflare.com/turnstile/v0/siteverify
Content-Type: application/x-www-form-urlencoded

secret={TURNSTILE_SECRET_KEY}&response={token}&remoteip={visitor IP, only if known}&idempotency_key={crypto.randomUUID()}
```

Response JSON: `{ success, challenge_ts, hostname, "error-codes": [...], action, cdata }`.
Accept **only** if `success === true` **and** `action === "booking_request"`. Everything else (including a network error
or timeout after 4,000 ms) → `PublicResult` code `bot_check_failed`. We fail closed, and the UI always offers LINE.
Tokens are valid for 300 seconds and can be used once; the widget refreshes them automatically.
Source: https://developers.cloudflare.com/turnstile/get-started/server-side-validation/

Optional hardening (P1 may skip): also compare `hostname` with `new URL(PUBLIC_SITE_URL).hostname` or the preview host,
and return `bot_check_failed` on mismatch.

Order in `submitBookingRequest` (D18): zod → honeypot (`isHoneypotFilled` → fake success, store nothing) → min fill time
(`isTooFast`, `MIN_FILL_MS = 3000`) → `verifyTurnstile` → `checkRateLimit("booking_request", hashIp(ip), 5, 20)` →
`studio_settings.booking_form_open` → insert → `notifyStaff`.

Unit tests (fetch mocked): success + right action → true; success + wrong action → false; `success:false` → false;
HTTP 500 → false; timeout → false.

---

## 7. Scheduled jobs (pg_cron)

Decision D19: retention runs **in SQL only**. No HTTP job, no `LOVABLE_CRON_SECRET`, no server route — **unless**
Lovable refuses `cron.schedule` when 0002 is applied. Then (R-19): remove the extension line and the two `cron.schedule`
statements from the unapplied 0002 draft, apply it, build card **P1-16** (`src/routes/api/cron/purge.ts`,
`20-server-api.md` § 10.2) and create a Lovable Job (More → Cloud → Jobs) that POSTs to it daily at 19:15 UTC. Lovable's
generated `cron-auth.ts` checks `LOVABLE_CRON_SECRET`. Record which path was used in § 2 row 16.

| Job name | Schedule (UTC) | Bangkok time | Command | Created in |
|---|---|---|---|---|
| `purge-expired-records` | `15 19 * * *` | 02:15 daily | `select public.purge_expired_records();` | `sql/0002_booking_requests.sql` (function body replaced in 0004, 0005, 0007) |
| `cron-history-cleanup` | `0 20 * * *` | 03:00 daily | `delete from cron.job_run_details where end_time < now() - interval '7 days';` | `sql/0002_booking_requests.sql` |

- 🧑 Where to see runs: **More → Cloud → Jobs** (enable/disable and run history: Succeeded / Failed / Running).
  Times may show in your timezone or UTC.
- 🧑 Check once a week in the first month, then monthly. A **Failed** run: open the run → copy the error **message only**
  (it never contains personal data, but don't paste row contents) → ask the builder.
- Cost note: each run uses a little Cloud usage, and **scheduled jobs keep the project from auto-pausing** (Lovable docs).
  That is good for a booking form, but it means Cloud is never idle. Check the monthly usage in **More → Cloud → Usage**
  after the first month and record it in § 2. ⚠️ UNVERIFIED how many credits a tiny daily job costs.
- If credits run out, Cloud pauses and **jobs stop**: retention deletes are late. After "Wake up", run the purge once
  manually (🧑 builder, **Cloud → SQL editor**, with the owner's OK: `select public.purge_expired_records();`) and note it.
- Storage files (slips, consent evidence) cannot be deleted by SQL (Supabase: deleting from `storage.objects` with SQL
  "will not remove the object from the bucket and will result in the object being orphaned",
  https://supabase.com/docs/guides/storage/management/delete-objects). Triggers queue old file paths in
  `storage_cleanup_queue` (from `sql/0004_families.sql`); an owner-only server function removes them through the
  Storage API (`runStorageCleanup`), run from `/admin/privacy` → "files to delete". See `50-security-privacy.md` § 19.4.

---

## 8. Payments: PromptPay and transfer slips

### 8.1 MVP (P3): no gateway, staff record payments (D17)

```
Staff confirm the seat on LINE (as today)
  → staff tell the family the amount and the studio's usual payment details on LINE (as today)
  → parent pays by PromptPay / bank transfer / cash
  → parent sends the slip in the LINE chat (as today)
  → staff check the studio's bank app, then in /admin/families/$familyId:
       createPackagePurchase (price snapshot from PRICES) → recordPayment (method, amount_thb, paid_at, receipt_no)
       optional: upload the slip image to the private bucket payment-slips (≤ 5 MB, jpg/png/webp/pdf)
```

Why no gateway or slip-checking API now:
- Card gateways cost about 3.65% + VAT per card payment (Opn: https://www.omise.co/pricing/thailand ; Stripe Thailand
  3.65% + ฿10: https://stripe.com/th/pricing). On ฿3,900 that is roughly ฿140–150 per booking; a direct PromptPay transfer
  to the studio costs ฿0.
- Slip-verification APIs (SlipOK, EasySlip) would share parents' payer names and partial account numbers with another
  processor. At this volume (well under 100 payments a month) checking the bank app by hand is enough.
- We store no bank account numbers, no card data, and slip images only if staff choose to upload one.
- Deposit, refund, cancellation and expiry rules are **the studio's decision** (G0 Q4–Q5). The site states none of them.

### 8.2 Optional later (F6-04): fixed-amount PromptPay QR page

A private page `/pay/$token` that shows a QR for the exact package amount, so parents don't type the amount.

🧑 HUMAN first:
- Owner decides on a **business** PromptPay ID (company tax ID, or a phone number used only for the studio). Never the
  owner's personal national ID: paying apps show the account name, and the QR can be decoded by anyone who sees it.
- Owner adds `PROMPTPAY_ID` (§ 4). It is server-side only (never `VITE_`, never in `public-config.ts`).
- Builder asks Lovable in chat to add the dependency `uqr@0.1.3` (zero dependencies, `renderSVG`). Do not add
  `promptpay-qr` (unmaintained since 2022, CommonJS) or `qrcode` (heavy dependencies).
- Open design point for the P6 task card: `/pay/$token` needs a token. `link_purpose` today has only `enrol` and
  `manage`; F6-04 must either add a value (an additive `alter type public.link_purpose add value 'pay'` in a new SQL file)
  or reuse the manage link. Decide in `20-server-api.md` before the card is written.

🤖 AGENT: `src/lib/backend/promptpay.ts` (pure, browser-safe, no dependencies), export `promptPayPayload(target, amountThb?)`.
The payload is built **on the server** (inside a server function that reads `PROMPTPAY_ID`) and only the payload string
or the SVG goes to the browser.

```ts
const tlv = (id: string, value: string): string =>
  `${id}${value.length.toString().padStart(2, "0")}${value}`;

/** CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF), uppercase hex, 4 chars. */
export function crc16Ccitt(input: string): string {
  let crc = 0xffff;
  for (const byte of new TextEncoder().encode(input)) {
    crc ^= byte << 8;
    for (let i = 0; i < 8; i++) crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
  }
  return crc.toString(16).toUpperCase().padStart(4, "0");
}

/** target: phone (10 digits) | national/tax ID (13) | e-wallet ID (15). amountThb omitted → static QR. */
export function promptPayPayload(target: string, amountThb?: number): string {
  const digits = target.replace(/[^0-9]/g, "");
  const type = digits.length >= 15 ? "03" : digits.length >= 13 ? "02" : "01";
  const formatted =
    digits.length >= 13 ? digits : ("0000000000000" + digits.replace(/^0/, "66")).slice(-13);
  const parts = [
    tlv("00", "01"),
    tlv("01", amountThb ? "12" : "11"),
    tlv("29", tlv("00", "A000000677010111") + tlv(type, formatted)),
    tlv("58", "TH"),
    tlv("53", "764"),
  ];
  if (amountThb) parts.push(tlv("54", amountThb.toFixed(2)));
  const body = parts.join("") + "6304";
  return body + crc16Ccitt(body);
}
```

Test vectors for `src/lib/backend/promptpay.test.ts`. The first eight are copied from the upstream library's tests
(https://raw.githubusercontent.com/dtinth/promptpay-qr/master/index.test.js, checked 13 Oct 2026). The last three were
derived with the same algorithm; we checked them for self-consistency only, so scan one with a real banking app before go-live.

| Target | Amount | Expected payload |
|---|---|---|
| `0801234567` | — | `00020101021129370016A000000677010111011300668012345675802TH530376463046197` |
| `080-123-4567` | — | `00020101021129370016A000000677010111011300668012345675802TH530376463046197` |
| `+66-89-123-4567` | — | `00020101021129370016A000000677010111011300668912345675802TH5303764630429C1` |
| `1111111111111` | — | `00020101021129370016A000000677010111021311111111111115802TH530376463047B5A` |
| `1-1111-11111-11-1` | — | `00020101021129370016A000000677010111021311111111111115802TH530376463047B5A` |
| `0123456789012` | — | `00020101021129370016A000000677010111021301234567890125802TH530376463040CBD` |
| `012345678901234` | — | `00020101021129390016A00000067701011103150123456789012345802TH530376463049781` |
| `000-000-0000` | `4.22` | `00020101021229370016A000000677010111011300660000000005802TH530376454044.226304E469` |
| `0801234567` | `3900` | `00020101021229370016A000000677010111011300668012345675802TH530376454073900.00630474C5` (derived) |
| `0801234567` | `14400` | `00020101021229370016A000000677010111011300668012345675802TH5303764540814400.0063048ECB` (derived) |
| `0801234567` | `26400` | `00020101021229370016A000000677010111011300668012345675802TH5303764540826400.0063042BE7` (derived) |

Rendering: `renderSVG(payload, { ecc: "M", border: 2 })` from `uqr`, shown with
`<div role="img" aria-label="…TH/EN label with the amount…" dangerouslySetInnerHTML={{ __html: svg }} />`. This is
the **only** allowed `dangerouslySetInnerHTML`, because the SVG comes from our own code and a fixed payload, never from user text.
Show the amount in baht (`formatBaht`) and the account name the parent should expect (owner provides it; copy in TH/EN).
A static PromptPay QR has no reference field, so staff still match payments by amount, time and slip.

---

## 9. Transactional email (optional)

### 9.1 Decision

- **P0–P5: no email.** Parents already use LINE; staff alerts go via LINE (§ 5). We don't collect parent email on
  `/book` (it is optional at enrolment, only for families who want receipts by email).
- **F6-05 (optional): backup alert to the owner's inbox only**, via Resend without a domain. Resend allows sending
  without a verified domain **only to the account owner's own email** from `onboarding@resend.dev`
  (https://resend.com/docs/lovable-integration ; https://resend.com/pricing: Free 3,000/month, 100/day).
- **After a studio-owned custom domain exists (G13):** for any parent-facing email, prefer **Lovable Emails** (built into
  Lovable, no extra vendor, fits D1). It needs a paid Lovable plan (the workspace is on Pro) and DNS access to the domain;
  for TanStack Start projects app emails do not require Cloud (https://docs.lovable.dev/features/custom-emails).
  Resend with a verified domain is the alternative. ⚠️ Resend stores account data in the US whatever sending region is
  chosen (https://resend.com/docs/dashboard/domains/regions); disclose it in the privacy notice if used.

### 9.2 Resend owner-only backup alert (F6-05)

🧑 HUMAN (owner):
1. Sign up at https://resend.com with the studio inbox that should receive backup alerts (that address becomes
   `STAFF_NOTIFY_EMAIL`).
2. Resend → **API Keys → Create API key**, permission **Sending access**. Add as secret `RESEND_API_KEY`; add
   `STAFF_NOTIFY_EMAIL` (§ 4).

🤖 AGENT: inside `notifyStaff`, **after** the LINE attempt and only if both secrets exist and LINE failed (or always, if
the owner prefers; one flag decided in the F6-05 card). Plain `fetch`, no SDK, same 4-second budget rules, never throws:

```http
POST https://api.resend.com/emails
Authorization: Bearer {RESEND_API_KEY}
Content-Type: application/json

{ "from": "CherryLee Alerts <onboarding@resend.dev>",
  "to": ["{STAFF_NOTIFY_EMAIL}"],
  "subject": "{subject}",
  "text": "{body}" }
```

### 9.3 Email templates (TH + EN)

**T1 · Owner backup alert** (F6-05). Same PII rules as LINE alerts (§ 5.7).

Subject: `คำขอจองใหม่ {ref} · New booking request {ref}`

```
คำขอจองใหม่ค่ะ
รหัส: {ref}
วันที่สนใจ: {date}
จำนวนเด็ก: {n} คน
ดูรายละเอียด: {adminUrl}

(อีเมลนี้ส่งสำรองเพราะการแจ้งเตือนทาง LINE ไม่สำเร็จค่ะ)

New booking request
Code: {ref}
Preferred date: {dateEn}
Children: {n}
Details: {adminUrl}

(Backup email: the LINE alert didn't go through.)
```

**T2 · Payment received note to a parent** — **parked**. Only after a custom domain + Lovable Emails (or verified Resend),
only to families who gave an email at enrolment for this purpose, and only after the owner approves the wording.
It is a thank-you note, not a tax invoice, and states no refund or expiry rules.

Subject: `ขอบคุณสำหรับการชำระเงินค่ะ · Thank you for your payment`

```
สวัสดีค่ะ คุณ{guardianDisplayName}

CherryLee & Co. ได้รับการชำระเงินเรียบร้อยแล้วค่ะ
แพ็กเกจ: {packageLabelTh}
จำนวนเงิน: {amount} บาท
วันที่ชำระ: {paidOnTh}
เลขที่ใบเสร็จ: {receiptNo}

มีคำถามอะไร ทักหาเราทาง LINE @cherryleeandco ได้เลยนะคะ
อ่านนโยบายความเป็นส่วนตัว: {PUBLIC_SITE_URL}/privacy

---

Hello {guardianDisplayName},

CherryLee & Co. has received your payment. Thank you!
Package: {packageLabelEn}
Amount: ฿{amount}
Paid on: {paidOnEn}
Receipt no.: {receiptNo}

Any questions? Message us on LINE @cherryleeandco.
Privacy notice: {PUBLIC_SITE_URL}/privacy
```

Never include children's names, health information, or links that log someone in.

### 9.4 Domain and DNS steps (only after G13) 🧑 HUMAN

For **Lovable Emails**: follow Lovable's guided setup in the project (Emails / custom domain). It shows the DNS records to add.

For **Resend** with a domain:
1. Resend → **Domains → Add domain**. Use a sending subdomain such as `mail.<studio-domain>` so the main domain's
   email is untouched.
2. At the DNS provider, add **exactly** the records Resend shows (copy-paste; don't type from this document). They are
   normally: an **MX** and a **TXT (SPF)** record on the `send` subdomain, and a **TXT (DKIM)** record named
   `resend._domainkey`.
3. Add a **DMARC** TXT record on `_dmarc.<studio-domain>`, starting with monitoring only:
   `v=DMARC1; p=none; rua=mailto:<studio inbox>`.
4. Wait until Resend shows **Verified**, then change `from` to `CherryLee & Co. <noreply@mail.<studio-domain>>`.
5. Update the privacy notice recipients list (`50-security-privacy.md` § 24) before sending to parents.

---

## 10. Analytics (cookieless)

Decision D22: no GA4, no Meta Pixel, no cookie banner. Business numbers come from our own database (`/admin/reports`, P6).

### 10.1 Lovable built-in analytics (G12) 🧑 HUMAN

Lovable shows visitors, page views, sources, devices and countries for published projects, with no setup; it can be
turned off in Project settings (https://docs.lovable.dev/features/analytics). Its cookie behaviour is not documented
(⚠️ UNVERIFIED). Check it:
1. Open the **published** site in a private window. DevTools → **Application** → Cookies and Local Storage for the site's
   origin. Expected: only `cherrylee-lang` in Local Storage after you switch language; **no cookies**.
2. DevTools → **Network**: note any analytics requests and their domain.
3. Write the result in § 2 row 17. If Lovable analytics sets a cookie or identifier, turn it off in Project settings
   (or add a consent banner, which we prefer to avoid).

Note: hosting analytics and server logs may record full page paths, including `/enrol/<token>` and `/my/<token>`. Those
are visible only to people with access to the Lovable project. Tokens are stored hashed in our database, and enrol links
are single-use, but treat the Lovable dashboard as sensitive (`50-security-privacy.md` § 8).

### 10.2 Optional: Umami Cloud for button events (F6-03)

Umami Cloud Hobby: free, 100K events/month, 1 site, 6-month retention, cookieless, hosted in the US/EU
(https://umami.is/pricing ; tracker options https://docs.umami.is/docs/tracker-configuration).

🧑 HUMAN (owner): sign up at https://cloud.umami.is → add website → domain = the production host only → copy the
**Website ID** → builder commits it as `UMAMI_WEBSITE_ID` in `public-config.ts`. Add Umami to the privacy notice
(recipients + cross-border) **before** turning it on.

🤖 AGENT rules:
- Add the script only when `UMAMI_WEBSITE_ID` is not empty:
  `<script defer src="https://cloud.umami.is/script.js" data-website-id="{UMAMI_WEBSITE_ID}" data-domains="{production host}" data-exclude-search="true" data-do-not-track="true" data-auto-track="false">`.
- **`data-auto-track="false"` is required.** Private-link pages carry a secret token in the **path** (`/enrol/<token>`,
  `/my/<token>`, `/pay/<token>`), and `data-exclude-search` only strips the query string. Track page views manually only on
  an allowlist: `/`, `/book`, `/privacy`. Never on `/admin*`, `/enrol/*`, `/my/*`, `/pay/*`.
- Events (exact names), attached with `data-umami-event` or `umami.track(name)`, with **no event data** (no ref codes,
  no package, no ages):

  | Event | Where |
  |---|---|
  | `book-line-click` | every "จองผ่าน LINE / Book on LINE" button |
  | `book-form-open` | `/book` first render |
  | `book-form-submit` | after a successful `submitBookingRequest` (`ok: true`) |

- Proposed helper (name not in `00-overview.md`; confirm in `20-server-api.md`/`30-ui.md`): `src/lib/backend/analytics.ts`
  exporting `trackPageview()`, `trackEvent(name)` and `ANALYTICS_PATH_ALLOWLIST`, each a no-op when `window.umami` is missing.

Alternative: Cloudflare Web Analytics (free, cookieless by Cloudflare's description, but no custom events; an older
independent review found a cookie, so verify in DevTools). Plausible has no free tier.

### 10.3 Other third parties already on the site (disclose, don't add more)

- Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`) are loaded on every page from `src/routes/__root.tsx`:
  Google receives the visitor's IP address. Self-hosting the fonts would remove this (out of scope; a possible later task).
- Google Maps iframe on the homepage (contacts Google when the page loads). Parked option (card PK-06): click-to-load placeholder.
- YouTube: click-to-load on `youtube-nocookie.com` (`src/components/YouTubeVideo.tsx`); nothing loads before the click.

---

## 11. LINE Login / LIFF (optional P7)

Not planned for P0–P6. Owner decision gate before any work.

What it would give: parents open a LIFF page inside LINE, see their bookings and credits, and get reminder pushes.

What it needs (🧑 HUMAN unless noted):
1. A **LINE Login channel** under the **same** provider `CherryLee & Co.` (user IDs differ per provider).
2. The Messaging API enabled on `@cherryleeandco` with the **webhook off** (push doesn't need a webhook, so staff chat
   keeps working). This is the permanent provider link that D6 avoids until now: confirm the provider before enabling.
3. Link the OA to the Login channel (**Basic settings → Linked LINE Official Account**), use `bot_prompt=normal`.
4. Scopes: `openid` (optionally `profile`); **never** `email`.
5. Budget: every reminder counts against `@cherryleeandco`'s quota (e.g. 20 families × 8 weekends = 160 messages/month
   on top of broadcasts; may require the Basic plan).
6. Privacy: `guardians.line_user_id` stored only with the guardian's consent, a "disconnect LINE" option, deletion when
   the user unlinks the app in LINE settings, LIFF rules (no tracking cookies), and a privacy-notice update + lawyer check.

Sources: https://developers.line.biz/en/docs/liff/getting-started/ ; https://developers.line.biz/en/docs/line-login/link-a-bot/ ;
https://developers.line.biz/en/docs/line-login/managing-authorized-apps/ ; https://developers.line.biz/en/docs/liff/development-guidelines/

---

## 12. Custom domain follow-ups (G13)

**G13 is done (14 Oct 2026).** The studio's domain is `https://cherryleeandco.com` (D37). The steps below are the checklist
for the values the domain drives. 🧑 HUMAN steps (Lovable → Project settings → Domains, Cloudflare and Cloud → Secrets):

1. Cloudflare Turnstile: `cherryleeandco.com` is the hostname (§ 6.1). Keep the preview host for testing.
2. Secret `PUBLIC_SITE_URL` = `https://cherryleeandco.com` (no trailing slash). Publish.
3. Umami (if used): change the website domain and `data-domains`.
4. JSON-LD base `https://cherryleeandco.com` in `src/content/business.ts` (`BUSINESS_JSON_LD`): a **website task**, not a backend
   card. Describe only; the website change is made outside this plan.
5. Lovable Cloud Auth: Lovable adds the custom domain to redirect URLs automatically on publish; check
   **Cloud → Users → Auth settings** anyway.
6. LINE alert webhook URL (only if § 5.6 is still in use).
7. Privacy notice: the website line `https://cherryleeandco.com` is in the draft (`50-security-privacy.md` § 11, section 2). Include
   it in the first notice version that goes live.
8. Email: § 9.4 if parent-facing email is wanted.

---

## 13. Publish checklist (G10)

🧑 Owner presses Publish; builder runs the checks.

Before Publish:
1. All task cards of the phase are done and their acceptance commands passed (README).
2. `git pull --ff-only`; Lovable shows the latest commit (push an empty commit if a sync was missed; never force-push).
3. The phase's SQL files are applied (G4) and `types.ts` was regenerated.
4. Secrets for the phase exist (§ 4; Cloud → Secrets shows the names).
5. If the phase starts collecting new personal data: the privacy notice sections for this stage are live and
   `PRIVACY_NOTICE_VERSION` was bumped (`YYYY-MM-vN`, `00-overview.md` § 8.0); the owner approved it (G9a).
5b. **Cloud → Users → Auth settings still shows public sign-up disabled** (R-20; a no-role account would otherwise be
   possible), and `rls_smoke.sql` in the SQL editor shows no `FAIL`.
6. Leak check on a fresh build prints nothing:
   `grep -rlE "SUPABASE_SERVICE_ROLE_KEY|TURNSTILE_SECRET_KEY|LINE_ALERT_CHANNEL_SECRET|IP_HASH_SECRET|supabaseAdmin" .output/public`

Publish:
7. **Publish → Publish changes**. Lovable runs a security scan (RLS). **Fix every critical finding first**; never
   dismiss one without the builder's written reason in `90-task-breakdown.md`.

After Publish (on the published URL, with obviously fake data):
8. `/` loads; `/robots.txt` disallows `/admin`, `/enrol/`, `/my/`, `/pay/`.
9. `/book`: send one request as `ผู้ปกครองทดสอบ` / `0800000001`, children `น้องทดสอบ`; thank-you screen in TH and EN;
   LINE alert arrives with code/date/count/link only. Then mark the request **spam** or **closed** in the inbox.
10. `/admin/login` works; `/admin` HTML contains `noindex`.
11. **Cloud → Logs → Server logs**: search for `0800000001` and `ผู้ปกครองทดสอบ` → expect **no results**.
12. Record the publish date and results in `90-task-breakdown.md` § 2 (gate tracker).

---

## 14. Troubleshooting

| Symptom | Likely cause | Fix (who) |
|---|---|---|
| Admin pages show errors, `/book` falls back to "send on LINE", Cloud shows paused | Cloud ran out of credits or auto-paused | 🧑 Owner: add credits → **More → Cloud → Overview → Wake up**; then run the purge once (§ 7) |
| Inbox shows "แจ้งเตือนไม่สำเร็จ / Alert failed", `last_error = missing_config` | a LINE secret is missing or the site wasn't republished | 🧑 add the secret (§ 4), Publish, press Resend |
| `last_error = line_token_http_400` or `line_token_http_401` | wrong channel ID or secret, or the secret was reissued | 🧑 recopy both from Basic settings |
| `last_error = line_push_http_400` | `LINE_ALERT_TO` wrong (must be `U…`/`C…` + 32 hex), or the bot is no longer in the group | 🧑 recopy the user ID; re-invite the bot |
| `last_error = line_push_http_429` | monthly free quota used up (or rate limit) | wait for next month or alert only the owner (§ 5.8); requests are safe in the inbox |
| Alerts work, but the owner gets nothing on the phone | the owner blocked or removed the alert OA | 🧑 unblock / add as friend again |
| `timeout` | LINE slow; Workers 4 s budget | press Resend later |
| Turnstile widget shows an error mentioning the domain (client error code `110200`) | hostname not in the widget list | 🧑 add the exact hostname (§ 6.1); never the apex `lovable.app` |
| Every submission returns `bot_check_failed` | wrong `TURNSTILE_SECRET_KEY`, test secret in production, or the action name differs | 🧑 recheck the secret; 🤖 check `action: "booking_request"` on both sides |
| Many genuine parents get `rate_limited` | shared mobile IPs (CGNAT) | owner decides: raise limits in a new SQL draft (G4) |
| `rls` / "permission denied" errors in staff pages | role row missing, or a policy missing | 🧑 check `/admin/settings`; 🤖 report the table name; never "fix" by granting to `anon` |
| Jobs view shows **Failed** | SQL error in the purge function | builder reads the error text (no personal data) and drafts a fix SQL file |
| A new secret is not visible to server code | not republished, or `process.env` doesn't carry Cloud secrets (§ 2 row 9) | 🧑 Publish; report the § 2 result |
| Lovable sync missed a push | GitHub webhook hiccup | push any new commit (an empty one is fine); Reconnect does not pull |

---

## 15. Sources

- Lovable: Cloud https://docs.lovable.dev/features/cloud.md · database, backups, migrations https://docs.lovable.dev/features/database.md ·
  secrets https://docs.lovable.dev/features/secrets.md · jobs https://docs.lovable.dev/features/jobs.md ·
  auth https://docs.lovable.dev/features/authentication.md · publish https://docs.lovable.dev/features/publish.md ·
  GitHub https://docs.lovable.dev/integrations/github.md · credits https://docs.lovable.dev/introduction/credits-and-usage.md ·
  analytics https://docs.lovable.dev/features/analytics · emails https://docs.lovable.dev/features/custom-emails ·
  logs https://docs.lovable.dev/features/logs.md · DPA https://lovable.dev/th/data-processing-agreement
- LINE: Notify closing https://notify-bot.line.me/closing-announce · Messaging API reference
  https://developers.line.biz/en/reference/messaging-api/ · tokens https://developers.line.biz/en/docs/basics/channel-access-token/ ·
  retry key https://developers.line.biz/en/docs/messaging-api/retrying-api-request/ · signature
  https://developers.line.biz/en/docs/messaging-api/verify-webhook-signature/ · groups
  https://developers.line.biz/en/docs/messaging-api/group-chats/ · provider is permanent
  https://developers.line.biz/en/docs/messaging-api/getting-started/ · pricing
  https://developers.line.biz/en/docs/messaging-api/pricing/ · Thai plans
  https://lineforbusiness.com/th/service/line-oa-features/broadcast-message
- Cloudflare Turnstile: server validation https://developers.cloudflare.com/turnstile/get-started/server-side-validation/ ·
  client rendering https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/ · testing
  https://developers.cloudflare.com/turnstile/troubleshooting/testing/ · hostnames
  https://developers.cloudflare.com/turnstile/concepts/domain-management · privacy https://www.cloudflare.com/turnstile-privacy-policy/
- Supabase: cron https://supabase.com/docs/guides/cron · storage deletes https://supabase.com/docs/guides/storage/management/delete-objects
- Payments: PromptPay vectors https://raw.githubusercontent.com/dtinth/promptpay-qr/master/index.test.js · uqr
  https://cdn.jsdelivr.net/npm/uqr@0.1.3/README.md · Opn pricing https://www.omise.co/pricing/thailand · Stripe TH
  https://stripe.com/th/pricing
- Email: Resend pricing https://resend.com/pricing · Resend + Lovable https://resend.com/docs/lovable-integration ·
  Resend regions https://resend.com/docs/dashboard/domains/regions
- Analytics: Umami pricing https://umami.is/pricing · tracker options https://docs.umami.is/docs/tracker-configuration ·
  Cloudflare Web Analytics https://developers.cloudflare.com/web-analytics/about/
