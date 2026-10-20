# CherryLee & Co. backend plan

This folder is the plan for the backend and data collection of the CherryLee & Co. website: booking requests,
a staff admin area, sessions and seats, families and packages, consent and safety records, and PDPA privacy operations.
**Nothing in this folder is live code.** The SQL files are drafts to apply through Lovable, and the TypeScript
snippets are skeletons for the implementers.

Status: planning (October 2026), ready for implementation by card. Lovable Cloud is **not enabled** yet. Work is
delivered in stages (D27): **A** = P0 + P1 + P2 (MVP) → owner go/no-go **G-MVP** → **B** = P3 + P5 core → **G-HEALTH** and
legal review **G9b** → **C** = P4 → **D** = P6 (optional); parked items need **G-PARK**. Do not start any card that needs
the database before its human gates (`00-overview.md` § 9, tracked in `90-task-breakdown.md` § 2) are done.

**Domain:** `https://cherryleeandco.com` (live; G13 done, D37). The owner's decisions of 14 October 2026 are in
`00-overview.md` § 5 (D31–D39, the second set of answers D40–D47, and the third set D48–D55) and §§ 13A–13B. New cards from those decisions: **P3-19** (staff follow-up list for families who
opted in), **P3-20** (apply the marketing text, `0006a`) and **P4-25** (signature print sheet). Card P4-09 gets the print checkbox (`media_print`); P3-04 and P3-11 get the marketing checkbox; P4-13 and P4-22 get the marketing control on `/my`.

**Round two (the owner's second set of answers, 14 Oct 2026), by number** (details in `00-overview.md` § 5):
- **D40** credit rule with notice: cancelled with notice keeps the credit; absent or late cancellation uses one (`absent`, `cancelled_late`). Studio path: D48; report source: D49.
- **D41** notice by LINE (`cancel_notice_at` = the time the LINE message arrived) or in person; no paper, no web form. Widened to four channels by D53.
- **D42** one health route for export and print: `get_child_health` with includeHealth; the allergen checklist prints on every sheet.
- **D43** follow-up label "ครอบครัวน้อง" + the child's nickname (EN "Family of <nickname>"), staff only; lawyer checks it (G9b). Widened to all attending children by D52.
- **D44** one follow-up row per granted guardian. Stays in round three.
- **D45** class clips certified by the owner (G0 Q15 ☑; all five channels).
- **D46** allergen `flour` added; nuts as one group "ถั่ว" (`peanut`, `tree_nut`).
- **D47** LINE OA rule kept (D26 and D35, no change).

**Round three (the owner's third set of answers, 14 Oct 2026), by number** (details in `00-overview.md` § 5):
- **D48** studio cancels a session: the credit is returned (status `cancelled_studio`); the make-up check is removed, and a rebooking uses the credit.
- **D49** family cancels late or misses: the seat stays booked, not an absence, one credit is used; every cancellation goes to `booking_cancellation_log`.
- **D50** a `cancelled_late` booking counts for the 6-month `child_health` clock.
- **D51** the health consent status line is on every print sheet; `includeHealth` controls the content only.
- **D52** follow-up label: the nicknames of all attending children ("ครอบครัวน้องมะลิ และ น้องดาว"; "Family of A and B"); D44 stays.
- **D53** four notice channels count: `line`, `phone`, `teacher`, `in_person`.
- **D54** identifiers in the docs are kept; nothing is removed.
- **D55** lawyer sign-off for the changed wording is recorded as done (owner's report); the written note is to be filed.

Round three overrides D40 (studio path, D48; report source, D49), D41 (channels, D53), D43 (label, D52) and D36 (make-up rule, D48). Cards: P3-06, P3-13, P3-19, P3-20, P4-25.

## Files

| File | What it holds |
|---|---|
| [`00-overview.md`](00-overview.md) | Thai summary for the studio owner; goals, architecture, key decisions, what we collect at each stage, phases P0–P7 with acceptance criteria, human gates, secrets, naming, open questions. **Read first.** |
| [`10-data-model.md`](10-data-model.md) | Every table, enum, view and database function, with columns, RLS policies, retention rules and an ER sketch. |
| [`sql/`](sql/) | Draft migrations `0001_foundation.sql` … `0008_reporting.sql` (+ `0006a_seed_marketing_text.sql` for the guardian marketing text, and optional `0006b_seed_media_parents_group.sql`), applied **in order** (0001 → 0002 → 0003 → 0004 → 0005 → 0006a → 0007 → 0006 (+0006b) → 0008), one per G4 gate, through Lovable chat. Additive only. Plus `sql/tests/rls_smoke.sql` (read-only) and `sql/seed_dev.sql` (fake data, ROLLBACK), both run in **Cloud → SQL editor**, never through chat. |
| [`20-server-api.md`](20-server-api.md) | Every server function and server route: file, name, zod input, auth, return shape, error codes, plus server-only helper modules. |
| [`30-ui.md`](30-ui.md) | Public pages (`/book`, `/privacy`, `/enrol/$token`, `/my/$token`) and the Thai-first admin (`/admin/*`): routes, components, states, TH/EN copy keys, accessibility. |
| [`40-integrations.md`](40-integrations.md) | Lovable Cloud setup and migration workflow, LINE staff alerts, Cloudflare Turnstile, scheduled jobs, analytics, optional PromptPay/Resend, the parents' contact rule (D35), secrets setup steps. |
| [`50-security-privacy.md`](50-security-privacy.md) | PDPA mapping, ROPA (record of processing), retention schedule, consent rules (incl. children 10+), the guardian follow-up opt-in and print consent, DSR and breach runbooks, security checklist, logging rules. |
| [`90-task-breakdown.md`](90-task-breakdown.md) | How to run with Haiku and the dependency graph (§ 1), the **gate tracker** (§ 2), the support agents (§ 3), the card index with batch and status (§ 4) and the task cards (§ 5, including P3-19, P3-20 and P4-25 from 14 Oct 2026): one card = one small, testable change of about 1–4 files, each with `agent_name`, `depends_on`, `human_gate`, `reads`, `creates`, `modifies`, `steps`, `acceptance`. |

If two files disagree, the order of authority is: `00-overview.md` (decisions and naming; its § 15 review log wins over
everything) → `10-data-model.md` → `20-server-api.md` → `30-ui.md` → the rest → `90-task-breakdown.md`. Fix the lower file;
never quietly change a name.

## How implementing agents (Claude Haiku) use this folder

1. **Read** this README, the shared preamble in `90-task-breakdown.md` § 1.6, then only the sections your task card
   lists under `reads`. Also read the repo's `AGENTS.md`. (`00-overview.md` §§ 5, 8 and 10 explain the decisions,
   phases and names if a card's reference is unclear.)
2. **Check the gate.** Each card lists `depends_on` (earlier cards) and `human_gate` (what a person does BEFORE and/or
   AFTER it). If a card in `depends_on` is not ☑ in `90-task-breakdown.md` § 4, or a BEFORE gate is not marked done in
   § 2, stop and report "blocked by …". Never try to do a human gate yourself.
3. **Pull first.** The main session runs `git pull --ff-only` before handing out a batch. Implementers do not run
   git commands that change state (no commit, push, rebase, reset, stash). `git status` and `git diff` are fine.
4. **Change only the files your card names** (`creates` + `modifies`). If you think another file must change, stop and
   say so. After you finish, the main session runs the support agents (`cl-test-runner`, `cl-reviewer` and the
   checkers listed in `90-task-breakdown.md` § 3) on your change.
5. **Run the acceptance commands** (below) and paste the last lines of each output in your report.
6. **Report** in this shape: files changed · commands run with results · anything you were unsure about · follow-ups.
   Do not write report files.

### Acceptance commands (run from the repo root, in this order)

```sh
npx prettier --write <every file you changed>
npx vite build                      # must end with "✓ built"; also regenerates src/routeTree.gen.ts
npx tsc --noEmit                    # must print nothing and exit 0
npx eslint <every file you changed> # must exit 0
npx vitest run                      # all tests pass
# Leak check: must print NOTHING. A hit means server code reached the browser bundle.
grep -rlE "SUPABASE_SERVICE_ROLE_KEY|TURNSTILE_SECRET_KEY|LINE_ALERT_CHANNEL_SECRET|IP_HASH_SECRET|supabaseAdmin|handleBookingRequest|handleSubmitEnrolment|resolveLinkToken|upsert_child_health|purge_expired_records" .output/public
```

Run `npx vite build` **before** `npx tsc --noEmit` whenever you add or rename a route file: the build regenerates
`src/routeTree.gen.ts`, and `createFileRoute("/new/path")` fails type-checking until it does. A `routeTree.gen.ts`
rewritten by the build is expected and is **not** a stop: never edit it by hand and never revert it; if your card adds
no route and `git status` still shows it changed, say so in your report (the builder decides whether to commit it).
The leak grep above already lists every server-only name in this plan; cards run it **unchanged** and never edit this
README to "extend" it.
Do not run `npm install`, `bun install` or add packages. If a task needs a package, the card says so and a human
asks Lovable to add it; afterwards use `npm install --no-package-lock` only if the card tells you to.

### Golden rules (break one and the work is rejected)

**Lovable and git**
- Never force-push, rebase, amend or squash pushed commits. Lovable syncs `main` both ways.
- Never edit generated files: `src/integrations/supabase/*`, `supabase/config.toml`, `.env`, `src/routeTree.gen.ts`,
  anything under `drizzle/` or `supabase/migrations/`.
- Never enable Lovable Cloud, change Cloud settings, add secrets, or call any Lovable/Supabase tool that changes
  state (`enable_database`, `send_message`, `query_database` writes, `deploy_project`). Those are human gates.
- SQL is written **only** as draft files in `docs/backend/sql/`. A human applies them through Lovable chat.

**Where code goes** (the build only keeps code out of the browser by **folder**, not by file name)
- Server-only code (secrets, service-role client, Turnstile, LINE, HMAC, tokens) → `src/server/<name>.server.ts`,
  and the **first line** is `import "@tanstack/react-start/server-only";`.
- Never create `src/server/index.ts` (the SSR entry is the file `src/server.ts`; don't touch it).
- Server functions → `src/lib/backend/<area>.functions.ts`. Never put them, hooks or components in a folder named `server`.
- Shared zod schemas and types → `src/lib/backend/<area>.schema.ts` (safe for the browser).
- Import the service-role client **only** from `@/server/supabase-admin.server` (inside `src/server/` the relative
  `./supabase-admin.server` is the same file), never from `@/integrations/supabase/client.server` directly.
- Use `.validator(schema)` on server functions (`.inputValidator` is deprecated in the installed version). One
  exception: public and private-link functions use a typed pass-through `.validator((input: <Raw>) => input)` and run
  `safeParse` inside the handler, so bad input returns `invalid_input` instead of throwing (`20-server-api.md` § 9.0).
- Read secrets only through `requireServerEnv("NAME")` / `optionalServerEnv("NAME")`, inside handlers.
  Never use `import.meta.env` for secrets. Bracket form `process.env["NAME"]` (tsconfig requires it).
- Don't touch `src/server.ts`, and keep `errorMiddleware` and `csrfMiddleware` in `src/start.ts`.

**Privacy and children's data**
- Never put real personal data in code, tests, fixtures, seeds, logs, prompts or commit messages.
  Test data is obviously fake: `ผู้ปกครองทดสอบ`, `Test Parent`, `น้องทดสอบ`, phone `0800000001`, LINE ID `test.line.id`.
- Never `console.log` request bodies, names, phone numbers, LINE IDs, health fields or IP addresses.
  Log only an error code and a row id.
- Never pre-tick a consent checkbox, and never combine two purposes in one checkbox.
- Marketing is a guardian-only opt-in, default off (`marketing_line`, D31), contacted by hand only. Never send bulk or
  automated marketing, and never use a child's information for it, except the nicknames of the attending children as a staff-only label (D43, widened by D52).
- Health/allergy data is read only through the audited database functions (`get_child_health` for export and print too, D42), never with a plain `select`.
- No cookies, no tracking pixels, no new third-party scripts unless the task card says so.

**Copy and UI** (from `AGENTS.md`)
- Every user-facing string exists in Thai **and** English, in a `src/content/*` file, never hard-coded in a component.
- Thai studio voice ends with ค่ะ; warm, non-judgmental, no fear-based wording. Say บอร์ดเกมการเงิน / board games,
  never "money game".
- Wrap Thai compound words and names in `<Nobr>` (or U+2060 in plain strings); mark English inside Thai with `<En>`.
- Don't invent facts: no refund rules, deposits, outcomes or guarantees. Copy may state only facts the owner has approved
  for publishing (`00-overview.md` § 13A, for example 8 seats per session) or facts from the studio's own Facebook page. Don't publish the cancellation, credit or make-up rule unless the owner asks (D36, D48, D49). The credit rule and the notice wording (D40, D41, D48, D49, D53) are drafts in `50-security-privacy.md` § 3.11 and stay unpublished unless the owner asks.
  Unknown policy → a field staff fill in, or "ask us on LINE".
- Touch targets ≥ 44 px, visible focus rings, labels on every input, errors announced (`aria-live`), text contrast ≥ 4.5:1.
