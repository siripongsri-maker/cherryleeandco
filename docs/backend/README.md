# CherryLee & Co. backend plan

This folder is the plan for the backend and data collection of the CherryLee & Co. website: booking requests,
a staff admin area, sessions and seats, families and packages, consent and safety records, and PDPA privacy operations.
**Nothing in this folder is live code.** The SQL files are drafts to apply through Lovable, and the TypeScript
snippets are skeletons for the implementers.

Status: planning (October 2026), ready for implementation by card. Lovable Cloud is **not enabled** yet. Work is
delivered in stages (D27): **A** = P0 + P1 + P2 (MVP) → owner go/no-go **G-MVP** → **B** = P3 + P5 core → **G-HEALTH** and
legal review **G9b** → **C** = P4 → **D** = P6 (optional); parked items need **G-PARK**. Do not start any card that needs
the database before its human gates (`00-overview.md` § 9, tracked in `90-task-breakdown.md` § 2) are done.

## Files

| File | What it holds |
|---|---|
| [`00-overview.md`](00-overview.md) | Thai summary for the studio owner; goals, architecture, key decisions, what we collect at each stage, phases P0–P7 with acceptance criteria, human gates, secrets, naming, open questions. **Read first.** |
| [`10-data-model.md`](10-data-model.md) | Every table, enum, view and database function, with columns, RLS policies, retention rules and an ER sketch. |
| [`sql/`](sql/) | Draft migrations `0001_foundation.sql` … `0008_reporting.sql` (+ optional `0006b_seed_media_parents_group.sql`), applied **in order** (0001 → 0002 → 0003 → 0004 → 0005 → 0007 → 0006 (+0006b) → 0008), one per G4 gate, through Lovable chat. Additive only. Plus `sql/tests/rls_smoke.sql` (read-only) and `sql/seed_dev.sql` (fake data, ROLLBACK), both run in **Cloud → SQL editor**, never through chat. |
| [`20-server-api.md`](20-server-api.md) | Every server function and server route: file, name, zod input, auth, return shape, error codes, plus server-only helper modules. |
| [`30-ui.md`](30-ui.md) | Public pages (`/book`, `/privacy`, `/enrol/$token`, `/my/$token`) and the Thai-first admin (`/admin/*`): routes, components, states, TH/EN copy keys, accessibility. |
| [`40-integrations.md`](40-integrations.md) | Lovable Cloud setup and migration workflow, LINE staff alerts, Cloudflare Turnstile, scheduled jobs, analytics, optional PromptPay/Resend, secrets setup steps. |
| [`50-security-privacy.md`](50-security-privacy.md) | PDPA mapping, ROPA (record of processing), retention schedule, consent rules (incl. children 10+), DSR and breach runbooks, security checklist, logging rules. |
| [`90-task-breakdown.md`](90-task-breakdown.md) | How to run with Haiku and the dependency graph (§ 1), the **gate tracker** (§ 2), the support agents (§ 3), the card index with batch and status (§ 4) and the **112 task cards** (§ 5): one card = one small, testable change of about 1–4 files, each with `agent_name`, `depends_on`, `human_gate`, `reads`, `creates`, `modifies`, `steps`, `acceptance`. |

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
`src/routeTree.gen.ts`, and `createFileRoute("/new/path")` fails type-checking until it does.
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
- Import the service-role client **only** from `@/server/supabase-admin.server`, never from
  `@/integrations/supabase/client.server` directly.
- Use `.validator(schema)` on server functions (`.inputValidator` is deprecated in the installed version).
- Read secrets only through `requireServerEnv("NAME")` / `optionalServerEnv("NAME")`, inside handlers.
  Never use `import.meta.env` for secrets. Bracket form `process.env["NAME"]` (tsconfig requires it).
- Don't touch `src/server.ts`, and keep `errorMiddleware` and `csrfMiddleware` in `src/start.ts`.

**Privacy and children's data**
- Never put real personal data in code, tests, fixtures, seeds, logs, prompts or commit messages.
  Test data is obviously fake: `ผู้ปกครองทดสอบ`, `Test Parent`, `น้องทดสอบ`, phone `0800000001`, LINE ID `test.line.id`.
- Never `console.log` request bodies, names, phone numbers, LINE IDs, health fields or IP addresses.
  Log only an error code and a row id.
- Never pre-tick a consent checkbox, and never combine two purposes in one checkbox.
- Health/allergy data is read only through the audited database functions, never with a plain `select`.
- No cookies, no tracking pixels, no new third-party scripts unless the task card says so.

**Copy and UI** (from `AGENTS.md`)
- Every user-facing string exists in Thai **and** English, in a `src/content/*` file, never hard-coded in a component.
- Thai studio voice ends with ค่ะ; warm, non-judgmental, no fear-based wording. Say บอร์ดเกมการเงิน / board games,
  never "money game".
- Wrap Thai compound words and names in `<Nobr>` (or U+2060 in plain strings); mark English inside Thai with `<En>`.
- Don't invent facts: no group sizes, lunch arrangements, refund/cancellation/expiry rules, outcomes or guarantees.
  Unknown policy → a field staff fill in, or "ask us on LINE".
- Touch targets ≥ 44 px, visible focus rings, labels on every input, errors announced (`aria-live`), text contrast ≥ 4.5:1.
