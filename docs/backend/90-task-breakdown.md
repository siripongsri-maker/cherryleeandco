# 90 · Task breakdown: task cards for Claude Haiku

Planning document, October 2026. This file turns `00-overview.md` §§ 8–9 into **112 small task cards** (one card = one
small, testable change of about 1–4 files), a gate tracker, the dependency graph and the support agents that check every
card. Nothing here is done yet: Lovable Cloud is not enabled.

- **Order of authority** (README): `00-overview.md` (its § 15 review log wins over everything) → `10-data-model.md` →
  `20-server-api.md` → `30-ui.md` → the rest → this file. A card only points at those files; if a card and a spec disagree,
  the spec wins and the implementer stops and reports.
- **Stages** (D27): A = P0 + P1 + P2 (MVP) → **G-MVP** (≥ 8 weeks of real use) → B = P3 + P5 core → **G-HEALTH / G9b** →
  C = P4 → D = P6 (optional). Parked items run only after **G-PARK**.
- **Git stays with the human.** No card commits, pushes, rebases or resets. Lovable syncs `main` both ways: never force-push.

---

## 1. How to run with Haiku

### 1.1 Dependency graph

Arrows read "must be done before". `[G…]` = human gate. The exact `depends_on` of every card is in § 4; this picture is
the summary.

```
STAGE A · MVP ─────────────────────────────────────────────────────────────────────────────────────────────
 P0a (no database, batch 1 runs now, in parallel)
   P0-01 env ──┬─ P0-09 hash+ip ──┐          P0-03 ref+phone ── P0-04 common ──┐
               ├─ P0-10 turnstile ┤          P0-05 spam+age                    ├─ P0-18 admin copy core
               └─ P0-11 LINE ─────┤          P0-06 limits                      │
   P0-02 result ──────────────────┴──────────────────────────────────────────────┘
   P0-07 dates ── P0-08 alert text + public-config (also needs P0-03)
   P0-12 robots + ESLint · P0-13 AGENTS/README · P0-14 SQL 0001 review
 P0b [G1 → G2 → G3] → P0-15 verify bootstrap → [G4·0001, G5]
   P0-16 admin client → P0-17 auth middleware → P0-19 staff fns → P0-20 language + me (needs P0-18)
   → P0-21 admin routes → P0-22 shell + dashboard → P0-23 P0 check
 P1  P1-01 SQL 0002 [G4] ─┬─ P1-03 notify ──┬─ P1-06 handler (+P1-05 schema) ── P1-07 submit fn ──┐
                          ├─ P1-04 limit ───┘                                                    │
                          └─ P1-11 inbox fns ──┐                                                 │
     P1-12 inbox copy ── P1-15 settings ───────┴─ P1-17 inbox screens                            │
                         └─ P1-19 system check                                                   │
     P1-08 site + footer ─┬─ P1-09 header + FieldError ─┐                                        │
                          └─ P1-02 notice v1 ───────────┴─ P1-10 /privacy ──┐                    │
     P1-13 booking copy + Turnstile ─── P1-14 form + thanks (needs P1-02) ──┴─ P1-18 /book ──────┘
     [G6 G7 G8] → P1-21 preview e2e · P1-16 cron fallback (only if refused) · P1-20 webhook (optional)
 P2  P2-01 SQL 0003 [G4] ── P2-02 sessions fns ─┬─ P2-04 screen (+P2-03 copy)
                                                ├─ P2-05 session in inbox + alert
                                                └─ P2-06 picker ── P2-07 open dates (optional)
     → P2-08 STAGE A GO-LIVE [G9a …-v1, G10]
═══ G-MVP: owner go/no-go after ≥ 8 weeks (no = stop here; Stage A keeps working) ═══════════════════════════
STAGE B · Records ──────────────────────────────────────────────────────────────────────────────────────────
   P3-01 SQL 0004 [G4] ─┬─ P3-02 schema (+P3-05) ── P3-03 read ── P3-04 write ──┬─ P3-14 convert request
                        │                                                        └─ P3-10 family page ── P3-11 sheets ── P3-12 packages
                        ├─ P3-08 copy ── P3-09 families list ────────────────────────┘                         └─ P3-15 payments screen
                        ├─ P3-05 payments fns (→ P3-02) · P3-06 bookings fns · P3-07 roster fn ── P3-13 roster
                        ├─ P3-16 notice v2
                        └─ P3-17 SQL 0005 [G4] ── P3-18 SQL 0007 [G4] ── P5-01 privacy fns ─┬─ P5-03 owner card
                                                              P5-02 privacy copy ───────────┴─ P5-04 files tab
   P5-05 retention check (human) → P5-06 STAGE B GO-LIVE [G9a …-v2, G10]
═══ G-HEALTH decided · G0 Q9/Q15/Q17 answered · G9b legal review ════════════════════════════════════════════
STAGE C · Consent and safety ───────────────────────────────────────────────────────────────────────────────
   P4-01 SQL 0006 (+0006b) [G9b, G4] ─┬─ P4-02 tokens ─────────────────┬─ P4-05 enrol fns ── P4-06 submit ──┐
                                      ├─ P4-04 enrol schema (+P4-07) ──┤                                   │
                                      ├─ P4-03 consent alerts ─────────┴─ P4-13 my fns ── P4-22 /my        │
                                      ├─ P4-07 health fns ── P4-08 enrol copy + health ─┬─ P4-09 media ─┼─ P4-14 /enrol
                                      │                                                 └─ P4-10 sections ┘
                                      ├─ P4-11 consent fns · P4-12 media fns
                                      ├─ P4-15 admin copy ─┬─ P4-16 roster health
                                      │                    ├─ P4-17 links tab ── P4-18 consents tab
                                      │                    └─ P4-19 alerts list ── P4-21 media screen ── P4-23 videos.ts
                                      └─ P4-20 notice v3
   → P4-24 STAGE C GO-LIVE [HEALTH_IN_SYSTEM set, G9a …-v3, G10]
STAGE D (optional): P6-01 SQL 0008 [G4] → P6-02 reports fn → P6-03 screen → P6-04 publish
PARKED (G-PARK, one item at a time, never in parallel with another card): PK-01 → PK-02 · PK-03 · PK-04 · PK-05 ·
PK-06 · PK-07 · PK-08
```

### 1.2 Who does what

| Role | Who | Does | Never does |
|---|---|---|---|
| **Main session** (orchestrator) | Claude (Opus/Sonnet) in Claude Code | Reads § 2 and § 4, picks runnable cards, runs `git pull --ff-only` before each batch, starts card agents and support agents, merges their reports, asks the human for gates and commits | Commits or pushes without the user's explicit yes; runs a human gate itself |
| **Card agent** | Claude **Haiku**, one per card (`agent_name`) | Exactly what its card says, only in the files it lists | git state changes, package installs, SQL against the database, Lovable/Supabase tools that change state |
| **Support agents** (§ 3) | Haiku by default | Read-only checks after each card; `cl-docs-sync` edits docs only | Edit code (except `cl-docs-sync` editing `docs/` and the status cells of this file) |
| **Builder** | The person running Claude and Lovable for the studio | G3, G4, G6-style steps that need Lovable, SQL editor runs, commits and pushes | Paste personal data into any chat |
| **Owner** | Studio owner | G0, G1, G2, G5, G6, G7, G8, G9a, G9b, G10, G11, G-MVP, G-HEALTH, G-PARK | — |

### 1.3 The loop for one card

1. **Pick.** A card is runnable when every id in `depends_on` is ☑ in § 4 and every *BEFORE* part of its `human_gate` is
   marked done in § 2. A card whose `human_gate` says "only if …" is skipped (mark it `skipped` in § 4) unless the
   condition holds.
2. **Pull.** Main session: `git pull --ff-only` (stop if it isn't a fast-forward).
3. **Run the card agent** with the card text (§ 5) and the shared preamble (§ 1.6). It changes only `creates` + `modifies`.
4. **`cl-test-runner`** runs the standard acceptance (§ 1.6) on the changed files and reports the last lines.
5. **`cl-reviewer`** checks the diff against the card, the cited spec sections and the golden rules. Add
   `cl-i18n-checker` for any card touching `src/content/**` or UI text, `cl-ui-a11y-checker` for any card touching
   `src/components/**` or `src/routes/**`, `cl-privacy-checker` for any card that collects, shows, stores or logs
   personal data (all P1 booking, P3, P4, P5 cards and every notice card), `cl-sql-reviewer` for SQL cards.
6. **Fix loop.** Any FAIL goes back to the same card agent with the findings, at most **2 rounds**. Still failing → stop and
   ask the human; never widen the card's file list on your own.
7. **Commit (human).** The builder reviews `git diff`, commits only the card's files with the message
   `<card id>: <title>` (plus the attribution lines the session requires), and pushes to `main`. One card = one commit
   (a batch of independent cards may share one commit if the builder prefers).
8. **Record.** `cl-docs-sync` ticks the card in § 4 and, for gates, fills § 2 with what the human reported (date, who).

### 1.4 Parallel batches and file ownership

- The **batch** number in § 4 is the card's depth inside its stage. Cards with the same batch number in the same stage
  can run in parallel **once their cross-stage dependencies are done**. The build check behind this file proved that two
  cards which touch the same file are always ordered by `depends_on`, so one batch never edits a file twice.
- Shared files are edited in a chain, in this order: `src/content/admin/index.ts` (P0-18 → P1-12 → P1-15 → P2-03 →
  P3-08 → P5-02 → P4-15 → P6-03), `src/components/admin/AdminShell.tsx` (P0-22 → P1-15 → P1-17 → P2-04 → P3-09 →
  P3-15 → P5-04 → P4-21 → P6-03), the dashboard `src/routes/admin/_staff/index.tsx` (P0-22 → P1-17 → P2-04 → P3-15 →
  P5-04 → P4-19 → P4-21), `src/server/staff-notify.server.ts` (P1-03 → P2-05 → P4-03), `src/content/privacy.tsx`
  (P1-02 → P3-16 → P4-20), the family page route (P3-10 → P3-12 → P5-03 → P4-17 → P4-18).
- Parked cards may share files with finished cards (PK-04 with `public-config.ts`/`Pricing.tsx`, PK-06 with `site.tsx`,
  PK-08 with `40-integrations.md`): run a parked card **alone**, after checking no open card lists the same files.
- Optional or conditional cards: P1-16 (only if `cron.schedule` was refused), P1-20 (staff group alerts), P2-07 (homepage
  strip). If the P2 screens are skipped, mark P2-02 … P2-07 `skipped` and run P2-08 after P1-21 and P2-01 (0003 is
  applied anyway). If Stage C is skipped, P6-03 depends on P5-02 and P5-04 instead of P4-15 and P4-21.

### 1.5 Card fields

| Field | Meaning |
|---|---|
| `id` | `P<phase>-<nn>`; `PK-<nn>` for parked items. Other files cite these ids. |
| `agent_name` | Kebab-case, prefix `cl-`; becomes `.claude/agents/<agent_name>.md` (§ 1.7). |
| `phase` | `P0a` (no database), `P0b`, `P1`, `P2`, `P3`, `P5`, `P4`, `P6`, `PK`. |
| `depends_on` | Card ids that must be ☑ first (cross-stage ids included). |
| `human_gate` | What a person must do **BEFORE** the card can start and/or **AFTER** it (the card is ☑ only when the AFTER part is recorded in § 2). |
| `reads` | Exact files and sections. Read these and the shared preamble, nothing else unless a section points onward. |
| `creates` / `modifies` | The **only** files the card may touch. Anything else → stop and report. |
| `steps` | Do them in order. ✅ blocks are copied exactly; 📝 specs are followed exactly. |
| `acceptance` | Commands and observable checks; paste the last lines of each command in the report. |

### 1.6 Shared preamble for every card agent

Put this text at the top of every card agent file (§ 1.7).

> You implement one task card for the CherryLee & Co. backend plan. Read `docs/backend/README.md` (golden rules) and
> `AGENTS.md` first, then only the sections your card lists.
>
> **Standard acceptance (SA)**, from the repo root, in this order: `npx prettier --write <changed files>` →
> `npx vite build` (must end with `✓ built`; it also regenerates `src/routeTree.gen.ts`) → `npx tsc --noEmit` (no output,
> exit 0) → `npx eslint <changed files>` (exit 0) → `npx vitest run` (all pass) → the leak grep from
> `docs/backend/README.md` (must print nothing). Paste the last lines of each.
>
> **Stop and report (do not improvise) if:** a file outside your card's `creates`/`modifies` would have to change; a ✅
> block still fails after type-only fixes; a name in your card conflicts with a spec file; a generated file
> (`src/integrations/supabase/*`, `.env`, migrations) is missing, different or would need editing (a
> `src/routeTree.gen.ts` rewritten by `npx vite build` is expected: never edit or revert it, just mention it if your card
> adds no route);
> a human gate in your card is not marked done in § 2 (or a generated type your card names is missing from
> `src/integrations/supabase/types.ts`: report "types not regenerated"); a package is missing; a step would put personal data in code,
> tests, logs, URLs, LINE text or commit messages; copy would state a fact the studio hasn't confirmed (00 § 2, § 13).
>
> **Never:** run git commands that change state, install packages, run SQL against any database, call Lovable or
> Supabase tools that change state, pre-tick a consent control, read health data with a plain select, log request
> bodies or personal data, or hard-code user-facing text outside `src/content/*`.
>
> **Report** in this shape: files changed · commands run with their last lines · anything you were unsure about ·
> follow-ups. Do not write report files.

### 1.7 Turning cards into `.claude/agents/*.md`

One file per card and one per support agent. Template:

```markdown
---
name: <agent_name>
description: <card title>. Card <id> of docs/backend/90-task-breakdown.md. Use only when the main session assigns this card.
tools: Read, Edit, Write, Bash, Grep, Glob   # review/check cards: Read, Grep, Glob, Bash
model: haiku
---

<shared preamble § 1.6>

## Card <id> · <title>
- depends_on: … (the main session has checked these)
- human_gate: …
- reads: …
- creates: … · modifies: …
### Steps
1. …
### Acceptance
- …
```

Review-only cards (SQL reviews, phase checks, human-run checks) get `tools: Read, Grep, Glob, Bash` and the line
"Do not edit any file" in their description. Bash is for read-only commands and the SA commands only.

---

## 2. Gate tracker

Fill in only from the human's own report (date, who, short note). `cl-docs-sync` may write a row after the human
confirms it in chat; no agent ever marks a gate on its own evidence.

| Gate | What (details in 00 § 9) | Who | Needed before | Status | Date | By | Notes |
|---|---|---|---|---|---|---|---|
| G0 | Answers to 00 § 13 (legal form, accounts, capacity habit, payment timing, retention OK) | Owner | P0 (partial OK) | ☐ | | | |
| G1 | Cloud permissions: Enable Cloud / Modify DB / Configure auth = Ask; backward-incompatible = Never | Owner | P0-15 | ☐ | | | |
| G2 | Enable Cloud on main, region Asia Pacific (permanent); save the DPA | Owner | P0-15 | ☐ | | | |
| G3 | Bootstrap auth prompt; sign-up disabled; leaked-password check on | Builder | P0-15 | ☐ | | | |
| G4 · 0001 | Apply `0001_foundation.sql`; record migration folder and live-DB behaviour (40 § 2 rows 4–5); `types.ts` lists `current_app_role` and `app_role` | Builder | P0-16, P0-17 | ☐ | | | |
| G5 | Owner user + owner role via Cloud → SQL editor | Owner | P0-16 | ☐ | | | |
| G4 · 0002 | Apply `0002`; pg_cron jobs visible? (40 § 2 row 16); `types.ts` lists `booking_requests`, `studio_settings`, `check_rate_limit` | Builder | P1-03, P1-04, P1-06 | ☐ | | | cron refused? → P1-16 |
| G6 | Secrets in Cloud → Secrets (`IP_HASH_SECRET`, `TURNSTILE_SECRET_KEY`, `LINE_ALERT_*`, `PUBLIC_SITE_URL`) | Owner | P1-21 | ☐ | | | |
| G7 | Turnstile widget with exact hostnames; site key committed | Owner + builder | P1-21 | ☐ | | | |
| G8 | Staff Alerts OA (Free), `LINE_ALERT_TO` | Owner | P1-21 | ☐ | | | |
| G4 · 0003 | Apply `0003` (also when the P2 screens are skipped) | Builder | P2-02, P3-01 | ☐ | | | |
| G9a · v1 | Notice `…-v1` approved, placeholders filled, draft banner off; the `/book` short notice (`bookingContent.notice`, cards P1-13/P1-14) approved with it; retention periods confirmed (G0 Q6) | Owner (+ lawyer) | P2-08 go-live | ☐ | | | version: |
| G10 · Stage A | Publish; scan fixed; sign-up disabled; `rls_smoke.sql` no FAIL | Owner | end of Stage A | ☐ | | | |
| **G-MVP** | ≥ 8 weeks of real use → go / no-go for Stage B | Owner | P3-01 | ☐ | | | decision: |
| G11 | Payment record retention (accountant) | Owner + accountant | P3-01 (may be "pending") | ☐ | | | |
| G4 · 0004 | Apply `0004`; `types.ts` lists `families`, `create_family_from_request`, `set_primary_guardian` | Builder | P3-02 … | ☐ | | | |
| G0 Q15 | What the 4 class clips' consent covered → `legacy_consent_purposes` | Owner | P3-17 | ☐ | | | |
| G4 · 0005 | Apply the **whole** `0005` file in Stage B (tables and every function, incl. `submit_enrolment`); only the P4 screens wait for Stage C. `types.ts` then lists `consent_records`, `child_health`, `submit_enrolment` | Builder | P3-18, P4-* | ☐ | | | |
| G4 · 0007 | Apply `0007` | Builder | P5-01 | ☐ | | | |
| F5-06 | Owner MFA available? (record only) | Builder | P5-05 | ☐ | | | |
| G9a · v2 | Notice `…-v2` approved | Owner (+ lawyer) | P5-06 go-live | ☐ | | | version: |
| G10 · Stage B | Publish Stage B; delete fake families first | Owner | end of Stage B | ☐ | | | |
| **G-HEALTH** | System (`HEALTH_IN_SYSTEM = true`) or paper (health rows removed from 0006) | Owner (+ lawyer) | P4-01 | ☐ | | | choice: |
| G0 Q9 / Q17 | Private parents' group? Approve OWNER-APPROVE lines | Owner | P4-01 | ☐ | | | |
| G9b | Lawyer + owner review of consent texts and D11 | Owner + lawyer | P4-01 (before G4 · 0006) | ☐ | | | |
| G4 · 0006 (+0006b) | Apply consent wording (0006b only if Q9 = yes) | Builder | P4-02 … | ☐ | | | |
| G9a · v3 | Notice `…-v3` approved | Owner (+ lawyer) | P4-24 go-live | ☐ | | | version: |
| G10 · Stage C | Publish Stage C | Owner | end of Stage C | ☐ | | | |
| G4 · 0008 | Apply `0008` (Stage D, optional) | Builder | P6-02 | ☐ | | | |
| G10 · Stage D | Publish reports | Owner | end of Stage D | ☐ | | | |
| G12 | Analytics cookie check; optional Umami / Resend / PromptPay ID | Owner | PK-04, PK-05, PK-07 | ☐ | | | |
| G13 | Custom domain + follow-ups (40 § 12) | Owner | any time | ☐ | | | |
| G-PARK | Un-park one item (write which) | Owner | each PK card | ☐ | | | item: |

### 2.1 Notes log

One line per event (date · who · what). Use it for: a publish-scan finding dismissed with the builder's written reason
(40 § 13), a G9b wording change the lawyer rejected (50 § 12.2), a restore (50 § 7.3), a skipped or conditional card
and why, and any deviation from a card.

| Date | Who | Note |
|---|---|---|
| | | |

---

## 3. Support agents

Reused across all stages. Default model Haiku; their output is advice to the main session, which decides.

| Agent | Role | When | Tools |
|---|---|---|---|
| `cl-test-runner` | Runs the standard acceptance (§ 1.6) and any card-specific commands; reports pass/fail with the last lines. Never edits files, never "fixes" a failing test. | After every code card, and before every phase check | Read, Bash (read-only + SA commands) |
| `cl-reviewer` | Read-only review of the diff against the card and the cited spec sections: only listed files changed; ✅ blocks copied faithfully; names match 00 § 10 / 20 § 13 / 30 § 7 / § 6 here; `*.functions.ts` export only `createServerFn` results and use `@/server/*` only inside handlers (R-26); staff functions use `context.supabase`, public ones `supabaseAdmin` filtered by the resolved id; no raw rows returned; errors via `adminError` / `adminErrorFromDb`; no `console.log` of data. Output: PASS or a numbered FAIL list with file:line. | After `cl-test-runner` passes, every code card | Read, Grep, Glob, Bash (git diff, git status) |
| `cl-i18n-checker` | Thai/English parity (same keys, same order, both languages changed together); Thai studio voice ends with ค่ะ where natural; warm, non-judgmental, no fear wording; `<Nobr>` for Thai compound words and names, `<En>` for English inside Thai; no hard-coded user-facing strings outside `src/content/*`; never "money game" (use บอร์ดเกมการเงิน / board games); no invented facts, policies, group sizes or promises (R-24). | Any card touching `src/content/**` or UI text | Read, Grep, Glob |
| `cl-ui-a11y-checker` | Checks 30 § 6: labels on every input, errors linked and announced (`aria-live`, `role="alert"`), touch targets ≥ 44 px (`min-h-11`), visible focus, text contrast tokens only (never `dusty`, `mustard`, `sage`, `coral`, `cherry-logo` for text), status as text not colour only, `role="list"` on styled lists, 360 px without horizontal scroll, admin `ssr: false` + noindex, `/enrol` and `/my` noindex + no-referrer. | Any card touching `src/components/**` or `src/routes/**` | Read, Grep, Glob |
| `cl-sql-reviewer` | Read-only review of one SQL draft before G4, against `10-data-model.md` § 2.3: additive only; RLS on every new table; `anon` has no grants; `revoke all` then minimal grants; every SECURITY DEFINER function has `set search_path = ''`, schema-qualified names, explicit revoke/grant; names and enums match 00 § 10; idempotent (`if not exists`, guarded `DO` blocks); depends-on order; `rls_smoke.sql` covers every new object. Lists findings; never edits; never runs SQL. | Every SQL card (P0-14, P1-01, P2-01, P3-01, P3-17, P3-18, P4-01, P6-01) and any new fix-forward SQL file | Read, Grep, Glob |
| `cl-privacy-checker` | PDPA and child-safety lens: data minimisation by stage (00 § 6); no personal data in logs, URLs, LINE text, toasts, analytics or test fixtures (fake data only); consent controls never pre-ticked, one purpose each, full text visible above the control (R-04); health only through the audited SQL functions and never on LINE; private links hash-only and never in query keys; the privacy notice covers everything a stage collects and the version was bumped before go-live (R-02, R-28); no children's names in media titles, alt text or file names. | Every card that collects, shows, stores or logs personal data; every notice card; every phase check | Read, Grep, Glob |
| `cl-docs-sync` | Keeps docs true after a card or gate: ticks § 4, fills § 2 from the human's report, records facts the builder observed in 40 § 2, updates names in the "names introduced" tables when a card added one, keeps README/AGENTS pointers current. Never invents facts, never changes a decision, never edits code. | After each card is committed, after each gate, at each phase end | Read, Edit (only `docs/**`, `AGENTS.md`, `README.md`), Grep |

---

## 4. Card index

Batch = depth inside its stage (§ 1.4). Status: ☐ open · ☑ done · `skipped` (with a § 2.1 note).

| Card | Batch | Agent | Title | Depends on | Status |
|---|---|---|---|---|---|
| P0-01 | 1 | `cl-p0-env-helper` | Server env helper: requireServerEnv / optionalServerEnv | — | ☐ |
| P0-02 | 1 | `cl-p0-result-types` | Shared result type and admin error codes (result.ts) | — | ☐ |
| P0-03 | 1 | `cl-p0-refcode-phone` | Pure helpers: ref-code.ts and thai-phone.ts with tests | — | ☐ |
| P0-04 | 2 | `cl-p0-common-schema` | Shared zod pieces: common.schema.ts | P0-03 | ☐ |
| P0-05 | 1 | `cl-p0-spam-age` | Pure helpers: spam-checks.ts and age.ts with tests | — | ☐ |
| P0-06 | 1 | `cl-p0-db-limits` | SQL text limits for zod boundary tests (limits.ts) | — | ☐ |
| P0-07 | 1 | `cl-p0-dates` | Date helpers (dates.ts) incl. formatDateTime | — | ☐ |
| P0-08 | 2 | `cl-p0-alert-text-config` | staff-alert-text.ts (PII-free LINE text) and public-config.ts | P0-03, P0-07 | ☐ |
| P0-09 | 2 | `cl-p0-hash-ip` | Server-only: hash.server.ts and client-ip.server.ts | P0-01 | ☐ |
| P0-10 | 2 | `cl-p0-turnstile` | Server-only: turnstile.server.ts (siteverify, fail closed) | P0-01 | ☐ |
| P0-11 | 2 | `cl-p0-line` | Server-only: line-alert.server.ts and line-signature.server.ts | P0-01 | ☐ |
| P0-12 | 1 | `cl-p0-robots-eslint` | robots.txt disallows private paths; ESLint blocks client.server imports | — | ☐ |
| P0-13 | 1 | `cl-p0-docs-pointers` | AGENTS.md and README.md point to the backend plan | — | ☐ |
| P0-14 | 1 | `cl-p0-sql-0001-review` | Review SQL 0001_foundation.sql before G4 | — | ☐ |
| P0-15 | 2 | `cl-p0-verify-bootstrap` | Verify what Lovable generated after G3 (F0-06) and record it | P0-14 | ☐ |
| P0-16 | 3 | `cl-p0-admin-client` | Server-only door to the service-role client | P0-15 | ☐ |
| P0-17 | 4 | `cl-p0-auth-middleware` | requireStaff / requireOwner middleware | P0-16, P0-02 | ☐ |
| P0-18 | 3 | `cl-p0-admin-copy-core` | Admin copy: core module and the index that assembles adminContent | P0-02, P0-04 | ☐ |
| P0-19 | 5 | `cl-p0-staff-functions` | staff.schema.ts and staff.functions.ts (getAdminMe, settings, staff roles) | P0-17 | ☐ |
| P0-20 | 6 | `cl-p0-admin-language` | AdminLanguageProvider and useAdminMe hook | P0-18, P0-19 | ☐ |
| P0-21 | 7 | `cl-p0-admin-routes` | Admin layout route (ssr:false, noindex) and login page | P0-20 | ☐ |
| P0-22 | 8 | `cl-p0-admin-shell` | Staff guard, AdminShell (empty nav) and the P0 dashboard | P0-21 | ☐ |
| P0-23 | 9 | `cl-p0-phase-check` | P0 phase check (read-only) | P0-01, P0-02, P0-03, P0-04, P0-05, P0-06, P0-07, P0-08, P0-09, P0-10, P0-11, P0-12, P0-13, P0-22 | ☐ |
| P1-01 | 1 | `cl-p1-sql-0002` | Review SQL 0002_booking_requests.sql, then G4 | P0-15 | ☐ |
| P1-02 | 2 | `cl-p1-privacy-notice-v1` | Privacy notice content …-v1 (src/content/privacy.tsx) | P1-08 | ☐ |
| P1-03 | 2 | `cl-p1-staff-notify` | staff-notify.server.ts (Stage A version) | P1-01, P0-16, P0-11, P0-08 | ☐ |
| P1-04 | 2 | `cl-p1-rate-limit` | rate-limit.server.ts (check_rate_limit RPC, fails open) | P1-01, P0-16 | ☐ |
| P1-05 | 1 | `cl-p1-booking-schema` | booking.schema.ts (D26 contact rule) with tests | P0-04, P0-05, P0-06 | ☐ |
| P1-06 | 3 | `cl-p1-booking-handler` | booking-request.server.ts (handleBookingRequest) with tests | P1-03, P1-04, P1-05, P0-09, P0-10, P0-02, P0-16, P0-03, P0-05 | ☐ |
| P1-07 | 4 | `cl-p1-booking-function` | submitBookingRequest server function | P1-06 | ☐ |
| P1-08 | 1 | `cl-p1-site-footer` | site.tsx additions (form links, subpage strings, FAQ, export En) and Footer hrefPrefix | — | ☐ |
| P1-09 | 2 | `cl-p1-subheader-fielderror` | SubpageHeader and FieldError components | P1-08 | ☐ |
| P1-10 | 3 | `cl-p1-privacy-route` | /privacy route, prose styles and footer privacy link | P1-02, P1-09 | ☐ |
| P1-11 | 3 | `cl-p1-inbox-functions` | inbox.schema.ts and inbox.functions.ts (list, get, update, retry) | P1-01, P0-17, P1-03 | ☐ |
| P1-12 | 1 | `cl-p1-admin-copy-inbox` | Admin copy module: inbox | P0-18 | ☐ |
| P1-13 | 2 | `cl-p1-booking-copy-turnstile` | booking.tsx copy and TurnstileWidget | P1-08, P0-08 | ☐ |
| P1-14 | 5 | `cl-p1-booking-form` | BookingForm and BookingThanks components with tests | P1-13, P1-07, P1-09, P1-02, P1-05, P0-02 | ☐ |
| P1-15 | 2 | `cl-p1-settings-screen` | Admin copy: settings module + /admin/settings (owner) | P1-12, P0-22, P0-19 | ☐ |
| P1-16 | 2 | `cl-p1-cron-fallback` | FALLBACK ONLY: /api/cron/purge route for a Lovable Job | P1-01 | ☐ |
| P1-17 | 4 | `cl-p1-inbox-screens` | /admin/inbox list + detail screens, nav tab, dashboard cards | P1-11, P1-12, P1-15 | ☐ |
| P1-18 | 6 | `cl-p1-book-route` | /book route and homepage entry points | P1-14, P1-10 | ☐ |
| P1-19 | 3 | `cl-p1-system-check` | Owner system check: getSystemCheck + settings section | P1-15, P0-09 | ☐ |
| P1-20 | 1 | `cl-p1-alert-webhook` | OPTIONAL: LINE alert-OA webhook to capture a staff group id | P0-11 | ☐ |
| P1-21 | 7 | `cl-p1-preview-e2e` | P1 end-to-end check on the Lovable preview (F1-10) | P1-17, P1-18, P1-19 | ☐ |
| P2-01 | 1 | `cl-p2-sql-0003` | Review SQL 0003_sessions.sql, then G4 | P1-01 | ☐ |
| P2-02 | 2 | `cl-p2-sessions-functions` | sessions.schema.ts + sessions.functions.ts (public open dates + staff list/save/generate) | P2-01, P0-17, P0-07, P0-06 | ☐ |
| P2-03 | 1 | `cl-p2-admin-copy-sessions` | Admin copy module: sessions (+ roster keys) | P1-15 | ☐ |
| P2-04 | 3 | `cl-p2-sessions-screen` | /admin/sessions screen, nav tab and dashboard next-session card | P2-02, P2-03, P1-17 | ☐ |
| P2-05 | 3 | `cl-p2-session-in-inbox` | Chosen session in the inbox detail and in the LINE alert date (F2-05) | P2-02, P1-17, P1-03 | ☐ |
| P2-06 | 3 | `cl-p2-session-picker` | SessionPicker on /book (client-fetched, LINE fallback) | P2-02, P1-18 | ☐ |
| P2-07 | 4 | `cl-p2-open-dates-strip` | OPTIONAL: homepage 'Open dates' strip | P2-06, P1-08 | ☐ |
| P2-08 | 4 | `cl-p2-stage-a-golive` | Stage A go-live check (G9a …-v1, G10) | P1-21, P2-04, P2-05, P2-06 | ☐ |
| P3-01 | 1 | `cl-p3-sql-0004` | Review SQL 0004_families.sql, then G4 | P2-01, P2-08 | ☐ |
| P3-02 | 3 | `cl-p3-families-schema` | families.schema.ts with view types (§14.4) and boundary tests | P3-01, P0-04, P0-06, P3-05 | ☐ |
| P3-03 | 4 | `cl-p3-families-read` | families.functions.ts part 1: listFamilies, getFamily | P3-02, P0-17 | ☐ |
| P3-04 | 5 | `cl-p3-families-write` | families.functions.ts part 2: create from request, save family/guardian/child/contact, soft delete | P3-03 | ☐ |
| P3-05 | 2 | `cl-p3-payments-functions` | payments.schema.ts + payments.functions.ts (packages, payments, slips) | P3-01, P0-17, P0-06 | ☐ |
| P3-06 | 2 | `cl-p3-bookings-functions` | bookings.schema.ts + bookings.functions.ts (book, status, cancel) | P3-01, P0-17 | ☐ |
| P3-07 | 2 | `cl-p3-session-roster-fn` | getSessionRoster (SessionRoster type, three queries) | P3-01, P2-02 | ☐ |
| P3-08 | 2 | `cl-p3-admin-copy-families-payments` | Admin copy modules: families and payments | P2-03, P3-01 | ☐ |
| P3-09 | 5 | `cl-p3-families-list` | /admin/families list screen + nav tab | P3-03, P3-08, P2-04 | ☐ |
| P3-10 | 6 | `cl-p3-family-overview` | /admin/families/$familyId: page, banners and Overview tab (read + staff note) | P3-09, P3-04 | ☐ |
| P3-11 | 7 | `cl-p3-family-edit-sheets` | Family Overview edit sheets: guardian, child, contact (soft delete) | P3-10 | ☐ |
| P3-12 | 8 | `cl-p3-family-packages-history` | Family page: Packages & payments tab and Class history tab | P3-11, P3-05, P3-06 | ☐ |
| P3-13 | 5 | `cl-p3-roster` | Roster /admin/sessions/$sessionId (check-in/out, pickup, add booking) + cancel warning | P3-07, P3-06, P2-04, P3-03 | ☐ |
| P3-14 | 6 | `cl-p3-convert-request` | Convert an inbox request into a family (one SQL call) | P3-04, P2-05 | ☐ |
| P3-15 | 9 | `cl-p3-payments-screen` | /admin/payments screen, slip upload, nav tab, dashboard card | P3-12, P3-09 | ☐ |
| P3-16 | 2 | `cl-p3-privacy-notice-v2` | Privacy notice …-v2: add every [P3] section and row | P1-02, P1-10, P3-01 | ☐ |
| P3-17 | 2 | `cl-p3-sql-0005` | Review SQL 0005_consent_health.sql, then G4 (whole file in Stage B, P4 screens later) | P3-01 | ☐ |
| P3-18 | 3 | `cl-p3-sql-0007` | Review SQL 0007_privacy_ops.sql, then G4 | P3-17 | ☐ |
| P5-01 | 1 | `cl-p5-privacy-functions` | privacy.schema.ts + privacy.functions.ts core (export, erase, restrict, files to delete) | P3-18, P0-16, P0-17, P0-06 | ☐ |
| P5-02 | 1 | `cl-p5-admin-copy-privacy` | Admin copy module: privacy (owner card + files to delete) | P3-08 | ☐ |
| P5-03 | 2 | `cl-p5-family-privacy-card` | Owner privacy card on the family page + restriction banner | P5-01, P5-02, P3-12, P3-04 | ☐ |
| P5-04 | 2 | `cl-p5-files-to-delete` | /admin/privacy 'Files to delete' tab (owner), nav item, dashboard card | P5-01, P5-02, P3-15 | ☐ |
| P5-05 | 3 | `cl-p5-retention-check` | Retention, export, erase and restriction check with fake data (human-run) | P5-03, P5-04 | ☐ |
| P5-06 | 4 | `cl-p5-stage-b-golive` | Stage B go-live check (G9a …-v2, G10) | P3-13, P3-14, P3-15, P3-16, P5-05 | ☐ |
| P4-01 | 1 | `cl-p4-sql-0006` | Review consent wording 0006 (+0006b), then G9b and G4 | P3-18, P5-06 | ☐ |
| P4-02 | 2 | `cl-p4-link-tokens` | link-tokens.server.ts (32-byte tokens, hash only) with tests | P3-17, P0-09, P0-16, P4-01 | ☐ |
| P4-03 | 2 | `cl-p4-consent-alerts` | staff-notify: consent_withdrawn branch + deliverAlertIds / deliverConsentAlert | P3-17, P2-05, P4-01 | ☐ |
| P4-04 | 3 | `cl-p4-enrolment-schema` | enrolment.schema.ts and consent-texts.server.ts with tests | P3-17, P0-04, P0-05, P0-06, P0-16, P4-01, P4-07 | ☐ |
| P4-05 | 4 | `cl-p4-enrolment-functions` | enrolment.functions.ts: getEnrolmentForm, createEnrolmentLink, revokeFamilyLink | P4-02, P4-04, P0-17 | ☐ |
| P4-06 | 5 | `cl-p4-enrolment-submit` | enrolment-submit.server.ts (one SQL call) + submitEnrolment | P4-05, P4-03, P4-07 | ☐ |
| P4-07 | 2 | `cl-p4-health-functions` | health.schema.ts + health.functions.ts (audited) + HEALTH_IN_SYSTEM | P3-17, P0-17, P0-08, P4-01 | ☐ |
| P4-08 | 4 | `cl-p4-enrol-copy-health` | enrol.tsx copy, ConsentTextBody and HealthSection (+ test) | P4-04, P4-07, P1-08 | ☐ |
| P4-09 | 5 | `cl-p4-media-section` | MediaSection: one block per published purpose, full text visible (+ test) | P4-08 | ☐ |
| P4-10 | 5 | `cl-p4-enrol-sections` | GuardianSection and ContactsSection for /enrol | P4-08 | ☐ |
| P4-11 | 3 | `cl-p4-consent-functions` | consent.schema.ts + consent.functions.ts (staff consent recording, evidence) | P3-17, P4-03, P3-02, P0-06 | ☐ |
| P4-12 | 2 | `cl-p4-media-functions` | media.schema.ts + media.functions.ts (publishability matrix, takedown) | P3-17, P0-17, P4-01 | ☐ |
| P4-13 | 4 | `cl-p4-my-functions` | my.schema.ts + my.functions.ts (getMyConsents, updateMyConsent, createManageLink) | P4-02, P4-03, P4-04, P0-17 | ☐ |
| P4-14 | 6 | `cl-p4-enrol-page` | EnrolPage and the /enrol/$token route (noindex, no-referrer) | P4-05, P4-06, P4-09, P4-10 | ☐ |
| P4-15 | 2 | `cl-p4-admin-copy-consent` | Admin copy modules: health, consents (+ child script), media | P5-02, P4-01 | ☐ |
| P4-16 | 3 | `cl-p4-roster-health` | Roster: allergy cell (three states), audited health dialog, photo badge | P4-07, P4-15, P3-13, P3-07 | ☐ |
| P4-17 | 5 | `cl-p4-family-links` | Family page: parent links tab and consent chips (getFamily P4 fields) | P4-05, P4-11, P4-13, P4-15, P5-03 | ☐ |
| P4-18 | 6 | `cl-p4-family-consents` | Family page: Consents tab, record dialog, child script | P4-17 | ☐ |
| P4-19 | 3 | `cl-p4-pending-alerts` | Unsent enrolment/consent alerts: listPendingStaffAlerts + dashboard list | P4-03, P4-15, P5-04, P2-05, P3-14 | ☐ |
| P4-20 | 2 | `cl-p4-privacy-notice-v3` | Privacy notice …-v3: [P4] sections and the /my sentence | P3-16, P4-01 | ☐ |
| P4-21 | 4 | `cl-p4-media-screen` | /admin/media screen, nav item, dashboard takedown card | P4-12, P4-15, P4-19 | ☐ |
| P4-22 | 5 | `cl-p4-my-page` | my-consents.tsx copy, MyConsentsPage and the /my/$token route | P4-13, P4-08 | ☐ |
| P4-23 | 5 | `cl-p4-videos-link` | videos.ts: optional mediaAssetId + takedown note in README | P4-21, P0-13 | ☐ |
| P4-24 | 7 | `cl-p4-stage-c-golive` | Stage C go-live check (G-HEALTH switch, G9a …-v3, G10) | P4-01, P4-14, P4-16, P4-18, P4-20, P4-22, P4-23 | ☐ |
| P6-01 | 1 | `cl-p6-sql-0008` | Review SQL 0008_reporting.sql, then G4 (Stage D, optional) | P3-18 | ☐ |
| P6-02 | 2 | `cl-p6-reports-functions` | reports.schema.ts + getReports (aggregates only) | P6-01, P0-17 | ☐ |
| P6-03 | 3 | `cl-p6-reports-screen` | Admin copy: reports module + /admin/reports screen with CSV | P6-02, P4-15, P4-21 | ☐ |
| P6-04 | 4 | `cl-p6-stage-d-golive` | Stage D check and publish | P6-03 | ☐ |
| PK-01 | 1 | `cl-pk-privacy-records-fns` | PARKED: DSR, breach and audit functions | P5-01 | ☐ |
| PK-02 | 2 | `cl-pk-privacy-tabs` | PARKED: /admin/privacy DSR, breach and audit tabs + dashboard dsrDue | PK-01, P5-04 | ☐ |
| PK-03 | 1 | `cl-pk-consent-texts-ui` | PARKED: owner consent-text publishing (one SQL transaction) | P4-11, P1-19 | ☐ |
| PK-04 | 1 | `cl-pk-umami` | PARKED: Umami cookieless analytics (F6-03) | P1-18 | ☐ |
| PK-05 | 1 | `cl-pk-resend-backup` | PARKED: Resend owner-only backup email alert (F6-05) | P4-03 | ☐ |
| PK-06 | 1 | `cl-pk-map-click-to-load` | PARKED: click-to-load Google Map on the homepage | P1-08 | ☐ |
| PK-07 | 1 | `cl-pk-promptpay-spec` | PARKED: write the spec for /pay/$token (PromptPay QR) before any code | P3-05 | ☐ |
| PK-08 | 1 | `cl-pk-liff-spec` | PARKED: P7 LINE Login / LIFF decision note | — | ☐ |

---

## 5. Cards

Each card is self-contained together with the shared preamble (§ 1.6). `SA` lines refer to the standard acceptance in § 1.6.

### Stage A · P0 Foundations

#### P0-01 · Server env helper: requireServerEnv / optionalServerEnv

- **agent_name:** `cl-p0-env-helper` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §3 (✅ env.server.ts block + rules)
  - docs/backend/20-server-api.md §12 (testing locally)
- **creates:** `src/server/env.server.ts`, `src/server/env.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block for src/server/env.server.ts from 20 §3 exactly. Line 1 must be: import "@tanstack/react-start/server-only";
  2. Write src/server/env.server.test.ts (vitest globals, default jsdom environment): requireServerEnv('CL_TEST_VAR') throws 'missing_env:CL_TEST_VAR' when unset and when vi.stubEnv('CL_TEST_VAR', ''); returns 'obviously-fake' when stubbed to it; optionalServerEnv returns undefined for unset and '' and the value otherwise; afterEach(() => vi.unstubAllEnvs()).
  3. Never create src/server/index.ts; never touch src/server.ts.
  4. Stop and report if importing @tanstack/react-start/server-only fails under vitest (do not add a mock without reporting).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/env.server.test.ts: all tests pass
  - head -1 src/server/env.server.ts prints the server-only import line

#### P0-02 · Shared result type and admin error codes (result.ts)

- **agent_name:** `cl-p0-result-types` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §4 (✅ (rev) result.ts block and the error-handling paragraphs)
  - docs/backend/10-data-model.md §16 (SQLSTATE codes)
- **creates:** `src/lib/backend/result.ts`, `src/lib/backend/result.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) block from 20 §4 into src/lib/backend/result.ts exactly (it includes family_restricted, D28).
  2. Write result.test.ts: ok(1) equals {ok:true,data:1}; fail('too_fast') equals {ok:false,code:'too_fast'}; adminErrorFromDb: {code:'23505'}→'conflict', '23503'→'not_found', 'P0002'→'not_found', {code:'23514',message:'no sessions left'}→'no_credit_left', {code:'23514',message:'parental responsibility'}→'responsibility_required', {code:'23514',message:'processing is restricted'}→'family_restricted', {code:'23514',message:'x'}→'invalid_state', '42501'→'forbidden', null→'server_error' (compare error.message); toAdminErrorCode(new Error('Unauthorized: no token'))→'unauthorized', new Error('family_restricted')→'family_restricted', new Error('boom')→'server_error', 'text'→'server_error'.
  3. The block is ✅ (rev): if tsc fails, fix types only, keep the logic, and list the change in your report.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/result.test.ts: all cases above pass

#### P0-03 · Pure helpers: ref-code.ts and thai-phone.ts with tests

- **agent_name:** `cl-p0-refcode-phone` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.1 (ref-code.ts + test)
  - docs/backend/20-server-api.md §8.2 (thai-phone.ts + test)
- **creates:** `src/lib/backend/ref-code.ts`, `src/lib/backend/ref-code.test.ts`, `src/lib/backend/thai-phone.ts`, `src/lib/backend/thai-phone.test.ts`
- **modifies:** —
- **steps:**
  1. Copy each ✅ code block and the test block under it from 20 §8.1 and §8.2 exactly.
  2. No imports from @/server/* or @/integrations/*: these files ship to the browser.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/ref-code.test.ts src/lib/backend/thai-phone.test.ts: all pass

#### P0-04 · Shared zod pieces: common.schema.ts

- **agent_name:** `cl-p0-common-schema` · **phase:** P0a · **batch:** 2
- **depends_on:** P0-03
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.8 (✅ common.schema.ts)
  - docs/backend/10-data-model.md §4.1 (limits shared with zod)
- **creates:** `src/lib/backend/common.schema.ts`, `src/lib/backend/common.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block from 20 §8.8 exactly.
  2. Write common.schema.test.ts: Uuid accepts '00000000-0000-4000-8000-000000000001'; IsoMonth rejects '2026-13' and accepts '2026-10'; LineIdSchema accepts 'test.line.id' and rejects 'a b'; ThaiPhoneSchema parses '080-000-0001' to '0800000001' and fails 'abc' with message 'invalid_phone'; SearchQuery turns 'a%b,c' into 'a b c'; PersonName rejects 81 characters; MEDIA_PURPOSES has 4 items and CONSENT_PURPOSES has 5.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/common.schema.test.ts: all pass

#### P0-05 · Pure helpers: spam-checks.ts and age.ts with tests

- **agent_name:** `cl-p0-spam-age` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.3 (spam-checks.ts + test)
  - docs/backend/20-server-api.md §8.4 (age.ts + test)
- **creates:** `src/lib/backend/spam-checks.ts`, `src/lib/backend/spam-checks.test.ts`, `src/lib/backend/age.ts`, `src/lib/backend/age.test.ts`
- **modifies:** —
- **steps:**
  1. Copy each ✅ code block and its test block from 20 §8.3 and §8.4 exactly.
  2. Keep CHILD_CONSENT_AGE = 10 and MIN_FILL_MS = 3000 (00-overview §10 fixed values).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/spam-checks.test.ts src/lib/backend/age.test.ts: all pass

#### P0-06 · SQL text limits for zod boundary tests (limits.ts)

- **agent_name:** `cl-p0-db-limits` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.9 (✅ (rev) limits.ts)
  - docs/backend/10-data-model.md §4.1 (the limits table)
- **creates:** `src/lib/backend/limits.ts`, `src/lib/backend/limits.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) block from 20 §8.9 exactly.
  2. Write limits.test.ts that compares every DB_LIMITS value with the table in 10-data-model.md §4.1 written out as a literal object in the test (one expect per key). If a value differs between 20 §8.9 and 10 §4.1, stop and report: 10-data-model.md wins.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/limits.test.ts: all pass

#### P0-07 · Date helpers (dates.ts) incl. formatDateTime

- **agent_name:** `cl-p0-dates` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.5 (✅ dates.ts + test, and the 📝 formatDateTime addition with its tests)
  - docs/backend/30-ui.md §4.3 first paragraph (timestamp format)
- **creates:** `src/lib/backend/dates.ts`, `src/lib/backend/dates.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ dates.ts block and its test block from 20 §8.5.
  2. Append formatDateTime exactly as in the 📝 block under it, and add its four test cases to dates.test.ts.
  3. Import Lang with `import type { Lang } from "@/content/site";` (type-only, so no site code ships with it).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/dates.test.ts: all pass, including the four formatDateTime cases

#### P0-08 · staff-alert-text.ts (PII-free LINE text) and public-config.ts

- **agent_name:** `cl-p0-alert-text-config` · **phase:** P0a · **batch:** 2
- **depends_on:** P0-03, P0-07
- **human_gate:** After G7 (Stage A) the builder writes the real Turnstile site key into TURNSTILE_SITE_KEY in a separate commit.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §8.6 (✅ staff-alert-text.ts + test)
  - docs/backend/20-server-api.md §8.7 (✅ public-config.ts)
  - docs/backend/40-integrations.md §5.7 (alert templates are PII-free)
- **creates:** `src/lib/backend/staff-alert-text.ts`, `src/lib/backend/staff-alert-text.test.ts`, `src/lib/backend/public-config.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks and the test block from 20 §8.6 and §8.7 exactly. Do NOT add HEALTH_IN_SYSTEM yet (card P4-07 adds it).
  2. Add one test: the text built for every kind never contains a name, a phone number or a LINE ID (use the fake inputs from the test block).
  3. Leave TURNSTILE_SITE_KEY = "" and UMAMI_WEBSITE_ID = "".
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/staff-alert-text.test.ts: all pass

#### P0-09 · Server-only: hash.server.ts and client-ip.server.ts

- **agent_name:** `cl-p0-hash-ip` · **phase:** P0a · **batch:** 2
- **depends_on:** P0-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.1 (✅ client-ip.server.ts)
  - docs/backend/20-server-api.md §7.2 (✅ hash.server.ts + tests)
  - docs/backend/50-security-privacy.md §4 (raw IPs never stored or logged)
- **creates:** `src/server/hash.server.ts`, `src/server/hash.server.test.ts`, `src/server/client-ip.server.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks and the hash test block from 20 §7.1 and §7.2 exactly; both files start with the server-only import.
  2. Never log an IP or a hash.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/hash.server.test.ts: all pass

#### P0-10 · Server-only: turnstile.server.ts (siteverify, fail closed)

- **agent_name:** `cl-p0-turnstile` · **phase:** P0a · **batch:** 2
- **depends_on:** P0-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.4 (✅ turnstile.server.ts + tests)
  - docs/backend/40-integrations.md §6.3 (server check facts)
- **creates:** `src/server/turnstile.server.ts`, `src/server/turnstile.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block and its test block from 20 §7.4 exactly (fetch is stubbed with vi.stubGlobal; the secret is stubbed with vi.stubEnv('TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA'), Cloudflare's published dummy test secret, a public test value; keep it as written).
  2. afterEach: vi.unstubAllGlobals(); vi.unstubAllEnvs().
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/turnstile.server.test.ts: all pass

#### P0-11 · Server-only: line-alert.server.ts and line-signature.server.ts

- **agent_name:** `cl-p0-line` · **phase:** P0a · **batch:** 2
- **depends_on:** P0-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.5 (✅ line-alert.server.ts + tests)
  - docs/backend/20-server-api.md §7.6 (✅ line-signature.server.ts + tests)
  - docs/backend/40-integrations.md §5.3 (HTTP facts only)
- **creates:** `src/server/line-alert.server.ts`, `src/server/line-alert.server.test.ts`, `src/server/line-signature.server.ts`, `src/server/line-signature.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks and their test blocks from 20 §7.5 and §7.6 exactly. 20 is the single source: ignore any older code in 40.
  2. Error codes are exactly those in 20 §7.5 (e.g. missing_config, timeout, line_push_http_401); do not invent others.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/line-alert.server.test.ts src/server/line-signature.server.test.ts: all pass

#### P0-12 · robots.txt disallows private paths; ESLint blocks client.server imports

- **agent_name:** `cl-p0-robots-eslint` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/00-overview.md §8 P0a item F0-03
  - docs/backend/20-server-api.md §1 last bullet (ESLint rule)
  - eslint.config.js
  - public/robots.txt
- **creates:** —
- **modifies:** `public/robots.txt`, `eslint.config.js`
- **steps:**
  1. public/robots.txt: keep 'User-agent: *' and 'Allow: /', then add the lines 'Disallow: /admin', 'Disallow: /enrol/', 'Disallow: /my/', 'Disallow: /pay/'.
  2. eslint.config.js: in the existing no-restricted-imports paths array add { name: "@/integrations/supabase/client.server", message: "Import supabaseAdmin from @/server/supabase-admin.server" }.
  3. Add a second config object after the main one (before eslintPluginPrettier): files ['src/server/**/*.ts'], rules { 'no-restricted-imports': ['error', { paths: [ `<copy of the existing server-only entry only>` ] }] } so src/server/* may import the generated client.
  4. Do not change any other rule.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx eslint . exits 0
  - A scratch file src/lib/backend/__lint_probe.ts containing `import { supabaseAdmin } from "@/integrations/supabase/client.server";` makes npx eslint report the new message; delete the probe file before finishing

#### P0-13 · AGENTS.md and README.md point to the backend plan

- **agent_name:** `cl-p0-docs-pointers` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - AGENTS.md
  - README.md
  - docs/backend/README.md (golden rules to summarise)
- **creates:** —
- **modifies:** `AGENTS.md`, `README.md`
- **steps:**
  1. AGENTS.md: after the existing 'CherryLee & Co. project notes' bullets (outside the LOVABLE:BEGIN/END block, never inside it) add a short '## Backend' section: plan in docs/backend/ (start with docs/backend/README.md); server-only code in src/server/*.server.ts with the server-only marker; server functions in src/lib/backend/*.functions.ts; SQL only as drafts in docs/backend/sql applied by a human through Lovable; never edit src/integrations/supabase/*; no personal data in code, tests, logs or URLs; children's health data only through the audited SQL functions.
  2. README.md: add a 2–4 line '## Backend (planned)' section before '## Content sources' pointing to docs/backend/README.md and saying nothing is live until the owner enables Lovable Cloud.
  3. AGENTS.md, first 'CherryLee & Co. project notes' bullet (R-46): change only its bold part from 'Copy lives in `src/content/site.tsx`' to 'Copy lives in `src/content/*`' and add after its first sentence: '(homepage: `site.tsx`; backend pages: `booking.tsx`, `privacy.tsx`, `enrol.tsx`, `my-consents.tsx`, `admin/*`)'. Keep the rest of that bullet as it is.
  4. Keep both files' existing wording unchanged otherwise.
- **acceptance:**
  - npx prettier --check AGENTS.md README.md exits 0 (or run --write first)
  - git diff shows changes only outside <!-- LOVABLE:BEGIN --> … <!-- LOVABLE:END -->

#### P0-14 · Review SQL 0001_foundation.sql before G4

- **agent_name:** `cl-p0-sql-0001-review` · **phase:** P0a · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** None to start. This card only reviews; the human gates G1 → G2 → G3 come next (P0-15).
- **reads:**
  - docs/backend/10-data-model.md §§1, 2, 4, 6.1–6.3, 8, 11
  - docs/backend/sql/0001_foundation.sql
  - docs/backend/sql/tests/rls_smoke.sql (0001 part)
  - docs/backend/00-overview.md §15 R-20
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist (90 §3) on docs/backend/sql/0001_foundation.sql.
  2. Check rls_smoke.sql has a check for every table and every function granted to authenticated in 0001; list any gap.
  3. Do not edit any file. Report findings to the main session; the main session decides on fixes before G4.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P0-15 · Verify what Lovable generated after G3 (F0-06) and record it

- **agent_name:** `cl-p0-verify-bootstrap` · **phase:** P0b · **batch:** 2
- **depends_on:** P0-14
- **human_gate:** BEFORE: owner G1 (Cloud permissions), owner G2 (enable Cloud on main, region Asia Pacific), builder G3 (bootstrap prompt, then git pull --ff-only and npm install --no-package-lock). AFTER this card: builder G4 applies 0001 through Lovable chat, owner G5 (owner role via Cloud → SQL editor), builder runs rls_smoke.sql in the SQL editor (no FAIL); mark G1–G5 done in 90 §2.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/40-integrations.md §1 (G3 + post-pull verification a–f) and §2 (observed table)
  - docs/backend/20-server-api.md §2 (expected generated shapes)
- **creates:** —
- **modifies:** `docs/backend/40-integrations.md`
- **steps:**
  1. Run the read-only commands a–f from 40 §1 'Post-pull verification'. Never print the contents of .env.
  2. Check src/start.ts lists functionMiddleware [attachSupabaseAuth] AND requestMiddleware [errorMiddleware, csrfMiddleware]. If either of ours is missing: stop and report (the builder asks Lovable to restore them).
  3. Check the generated exports exist: supabaseAdmin in src/integrations/supabase/client.server.ts, requireSupabaseAuth in auth-middleware.ts, supabase in client.ts. Note whether cron-auth.ts exists.
  3b. Record the import lines of src/integrations/supabase/auth-middleware.ts (`grep -n "^import" src/integrations/supabase/auth-middleware.ts`, module names only), the exported middleware name and its context members in 40 §2 row 18 (R-40). If it imports client.server, @tanstack/react-start/server-only or reads SUPABASE_SERVICE_ROLE_KEY: stop and report (card P0-17 would pull it into browser-bundled code).
  4. Run npx vite build, npx tsc --noEmit and npx vitest run to prove the generated code builds; write results and the answers to rows 4, 6, 7, 18 into the 40 §2 table (date + 'cl-p0-verify-bootstrap').
  5. Do not edit any generated file.
- **acceptance:**
  - 40 §2 rows 4, 6, 7, 18 filled
  - npx vite build ✓ built; npx tsc --noEmit exit 0; npx vitest run all pass
  - Report lists every generated file name found

#### P0-16 · Server-only door to the service-role client

- **agent_name:** `cl-p0-admin-client` · **phase:** P0b · **batch:** 3
- **depends_on:** P0-15
- **human_gate:** Requires G4(0001) and G5 marked done in 90 §2.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §2 (✅ supabase-admin.server.ts)
- **creates:** `src/server/supabase-admin.server.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block from 20 §2 exactly (server-only marker + re-export of supabaseAdmin from @/integrations/supabase/client.server).
  2. Stop and report if the generated client.server.ts does not export supabaseAdmin (do not edit the generated file).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - grep -rn 'integrations/supabase/client.server' src --include=*.ts --include=*.tsx lists only src/server/supabase-admin.server.ts

#### P0-17 · requireStaff / requireOwner middleware

- **agent_name:** `cl-p0-auth-middleware` · **phase:** P0b · **batch:** 4
- **depends_on:** P0-16, P0-02
- **human_gate:** BEFORE: G1–G3, G4 · 0001 and G5 marked done in 90 §2 (G4 · 0001 regenerates src/integrations/supabase/types.ts with current_app_role and app_role), and 40 §2 row 18 filled by P0-15.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §2 (the three clients; how the staff token travels)
  - docs/backend/20-server-api.md §6 (✅ auth.middleware.ts, caller table, 'What must exist before this block type-checks', 'How a thrown code reaches the admin UI', 📝 auth.middleware.test.ts)
  - docs/backend/40-integrations.md §2 row 18 (imports of the generated auth-middleware.ts)
  - docs/backend/sql/0001_foundation.sql §3 (current_app_role)
- **creates:** `src/lib/backend/auth.middleware.ts`, `src/lib/backend/auth.middleware.test.ts`
- **modifies:** —
- **steps:**
  1. Read-only checks first; on any difference stop and report (do not edit generated files): (a) `requireSupabaseAuth` is exported from `@/integrations/supabase/auth-middleware` (the import path the ✅ block uses); (b) its server context has `supabase`, `userId` and `claims` (20 §6, from 20 §2); (c) `grep -n "current_app_role" src/integrations/supabase/types.ts` and `grep -n "app_role:" src/integrations/supabase/types.ts` each print at least one line (the function and the enum; 0001 §3: `current_app_role()` takes no arguments, returns `app_role` = owner | staff | NULL, granted to authenticated); a miss = "types not regenerated", not a type-only fix; (d) 40 §2 row 18 shows no client.server, server-only or service-role import.
  2. Copy the ✅ block from 20 §6 exactly.
  3. Copy the 📝 auth.middleware.test.ts block from 20 §6 (it mocks the generated middleware and calls each `.server` callback directly: owner and staff pass, no role → forbidden, failed lookup → server_error, staff on requireOwner → forbidden). No token → `Unauthorized: …` is the generated middleware's job and is checked on the preview in P0-22.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/auth.middleware.test.ts: all pass

#### P0-18 · Admin copy: core module and the index that assembles adminContent

- **agent_name:** `cl-p0-admin-copy-core` · **phase:** P0b · **batch:** 3
- **depends_on:** P0-02, P0-04
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern + index.ts block
  - docs/backend/30-ui.md §5 reference block, members meta … labels (type L4149–4262; th L4708–4891; en L5519–5707) and errors (type L4704–4705; th L5499–5516; en L6320–6337); find them by key name if lines moved
  - docs/backend/30-ui.md §5.1 rows marked core (family_restricted error, dashboard.consentAlerts, dashboard.filesToDelete)
- **creates:** `src/content/admin/core.tsx`, `src/content/admin/index.ts`
- **modifies:** —
- **steps:**
  1. Create src/content/admin/core.tsx: export type Labels`<K extends string>` = Record`<K, string>`; export type AdminCore = { meta; common; login; shell; dashboard; labels; errors } copied from the reference type; const th: AdminCore and const en: AdminCore copied from the reference th/en objects; export const adminCore: Record`<Lang, AdminCore>` = { th, en }.
  2. Write labels.allergens as Labels<"peanut" | "tree_nut" | "milk" | "egg" | "wheat" | "soy" | "fish" | "shellfish" | "sesame"> (do not import health.schema). labels.consentPurpose uses ConsentPurpose from @/lib/backend/common.schema; errors uses Record`<AdminErrorCode, string>` from @/lib/backend/result.
  3. Add the §5.1 core keys (errors.family_restricted, dashboard.consentAlerts(n), dashboard.filesToDelete(n)) in Thai and English.
  4. Create src/content/admin/index.ts exactly like the index.ts block in 30 §5 (core only).
  5. Do not create src/content/admin.tsx. Change Thai and English together; Thai staff copy keeps ค่ะ where natural.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker reports TH/EN key parity for core.tsx
  - grep -c 'family_restricted' src/content/admin/core.tsx ≥ 3 (type via AdminErrorCode, th, en)

#### P0-19 · staff.schema.ts and staff.functions.ts (getAdminMe, settings, staff roles)

- **agent_name:** `cl-p0-staff-functions` · **phase:** P0b · **batch:** 5
- **depends_on:** P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.0 (conventions)
  - docs/backend/20-server-api.md §9.2 (✅ staff.schema.ts, ✅ staff.functions.ts, function table)
  - docs/backend/20-server-api.md §1 rules (R-26)
- **creates:** `src/lib/backend/staff.schema.ts`, `src/lib/backend/staff.functions.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks from 20 §9.2 exactly (six functions: getAdminMe, getStudioSettings, listStaff, setStaffRole, removeStaffRole, updateStudioSettings). Do not add getSystemCheck (card P1-19).
  2. staff.functions.ts exports nothing but createServerFn results; @/server/* imports are used only inside .handler() bodies.
  3. The ✅ code was compiled against a loose stub: if the real src/integrations/supabase/types.ts needs `?? null` or a narrower type, change the type only and report it.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Leak grep also finds nothing for 'auth.admin' in .output/public

#### P0-20 · AdminLanguageProvider and useAdminMe hook

- **agent_name:** `cl-p0-admin-language` · **phase:** P0b · **batch:** 6
- **depends_on:** P0-18, P0-19
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/30-ui.md §4.2 (✅ AdminLanguageProvider.tsx, ✅ useAdminMe.ts)
- **creates:** `src/i18n/AdminLanguageProvider.tsx`, `src/components/admin/useAdminMe.ts`
- **modifies:** —
- **steps:**
  1. Copy both ✅ blocks from 30 §4.2 exactly. The provider imports adminContent from "@/content/admin" (the folder index).
  2. Admin language is stored in localStorage key cherrylee-admin-lang; Thai is the default.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P0-21 · Admin layout route (ssr:false, noindex) and login page

- **agent_name:** `cl-p0-admin-routes` · **phase:** P0b · **batch:** 7
- **depends_on:** P0-20
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.1 (route tree)
  - docs/backend/30-ui.md §4.2 (✅ admin/route.tsx, ✅ admin/login.tsx)
- **creates:** `src/routes/admin/route.tsx`, `src/routes/admin/login.tsx`
- **modifies:** —
- **steps:**
  1. Copy both ✅ blocks from 30 §4.2 exactly.
  2. Run npx vite build before npx tsc --noEmit (the build regenerates src/routeTree.gen.ts). Never edit routeTree.gen.ts by hand.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - After npx vite build, src/routeTree.gen.ts contains '/admin/login'

#### P0-22 · Staff guard, AdminShell (empty nav) and the P0 dashboard

- **agent_name:** `cl-p0-admin-shell` · **phase:** P0b · **batch:** 8
- **depends_on:** P0-21
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.2 (✅ admin/_staff/route.tsx, ✅ AdminShell.tsx)
  - docs/backend/30-ui.md §4.3 '/admin dashboard' (P0 shell)
  - docs/backend/30-ui.md §6 checklist
- **creates:** `src/routes/admin/_staff/route.tsx`, `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **modifies:** —
- **steps:**
  1. Copy the ✅ _staff/route.tsx and AdminShell.tsx blocks from 30 §4.2.
  2. P0 state of AdminShell: TABS and MORE have no entries (their routes don't exist yet). Try `const TABS = [] as const;` and `const MORE = [] as const;`; if tsc rejects that, declare `const TABS: ReadonlyArray<{ to: "/admin"; key: "dashboard"; Icon: typeof LayoutGrid }> = [];` and `const MORE: ReadonlyArray<{ to: "/admin"; key: "dashboard"; ownerOnly: boolean }> = [];`. Later screen cards widen these types and add their entry.
  3. Create src/routes/admin/_staff/index.tsx with createFileRoute("/admin/_staff/"): h1 t.dashboard.title, t.dashboard.hello(me.email ?? '') and the role label (useAdminMe). No data cards yet; each later card adds its own.
  4. Run npx vite build before npx tsc --noEmit.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - On the preview (human): signed-out /admin redirects to /admin/login; the owner sees the dashboard with role owner; a user without a role sees 'ไม่มีสิทธิ์เข้าถึง / No access'
  - curl -s `<preview>`/admin | grep -c noindex ≥ 1 (human)

#### P0-23 · P0 phase check (read-only)

- **agent_name:** `cl-p0-phase-check` · **phase:** P0b · **batch:** 9
- **depends_on:** P0-01, P0-02, P0-03, P0-04, P0-05, P0-06, P0-07, P0-08, P0-09, P0-10, P0-11, P0-12, P0-13, P0-22
- **human_gate:** Human: owner signs in on the preview (P0 acceptance in 00 §8); builder confirms Cloud → Users → Auth settings shows sign-up disabled and rls_smoke.sql shows no FAIL. Record in 90 §2.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/00-overview.md §8 P0 acceptance
  - docs/backend/90-task-breakdown.md §2 (gate tracker)
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the full standard acceptance on a clean checkout (git status shows only intended files).
  2. Run cl-privacy-checker over src/server and src/lib/backend (no console.log of data, no secrets, server-only markers present).
  3. Report pass/fail per card; cl-docs-sync then marks cards done in 90 §4. Never mark a human gate yourself.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Every P0 acceptance line in 00 §8 is checked off by the human or listed as open

### Stage A · P1 Booking requests, inbox, alerts

#### P1-01 · Review SQL 0002_booking_requests.sql, then G4

- **agent_name:** `cl-p1-sql-0002` · **phase:** P1 · **batch:** 1
- **depends_on:** P0-15
- **human_gate:** AFTER review: builder G4 applies 0002 via Lovable chat (approve pg_cron if asked), git pull --ff-only, checks types.ts contains booking_requests, runs rls_smoke.sql in Cloud → SQL editor (no FAIL), records in 40 §2 row 16 whether the pg_cron jobs appear in Cloud → Jobs. If Lovable refuses cron.schedule: follow 40 §7 (remove the extension line and both cron.schedule statements from the UNAPPLIED draft, apply, then run card P1-16).
- **reads:**
  - docs/backend/10-data-model.md §§6.4–6.6, 13
  - docs/backend/sql/0002_booking_requests.sql
  - docs/backend/sql/tests/rls_smoke.sql
  - docs/backend/00-overview.md D18, D19, D26
  - docs/backend/40-integrations.md §§3, 7
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist (90 §3) on 0002. Also check: the D26 contact rule (phone required only when preferred_contact = 'phone'); check_rate_limit is executable by service_role only; purge v1 deletes booking_requests, rate_limit_events and staff_notifications by retain_until; cron job names and schedules match 00 §10.
  2. Check rls_smoke.sql covers booking_requests, rate_limit_events, staff_notifications and check_rate_limit; list gaps.
  3. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P1-02 · Privacy notice content …-v1 (src/content/privacy.tsx)

- **agent_name:** `cl-p1-privacy-notice-v1` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-08
- **human_gate:** AFTER: owner fills placeholders and approves (G9a for …-v1, lawyer review recommended) before Stage A goes live (card P2-08). Until then draftBanner stays non-null.
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.4 (single-source note, id/phase table, ✅ privacy.tsx code pattern)
  - docs/backend/50-security-privacy.md §11.1 (versions), §11.3 (TH draft), §11.4 (EN draft), §11.6 (placeholders)
  - docs/backend/00-overview.md §8.0 (notice per stage)
- **creates:** `src/content/privacy.tsx`
- **modifies:** —
- **steps:**
  1. Start from the ✅ code pattern in 30 §3.4 (types incl. PrivacySection.phase, PRIVACY_NOTICE_VERSION, CONTROLLER_LEGAL_NAME, PrivacyContent, meta, summary, draftBanner).
  2. Set PRIVACY_NOTICE_VERSION to '`<YYYY-MM>`-v1' where YYYY-MM is the current month in Bangkok; make the `updated` lines name the same month (Thai month + Buddhist year in th).
  3. Build th.sections and en.sections from 50 §11.3 and §11.4: exactly the rows of the 30 §3.4 id/phase table whose phase is P1 and whose card is P1-02 (15 sections, in table order, each with phase: "P1"). The code block holds ONE sample section per language (`controller`) only to show the JSX style: replace it with the full array (R-47). Leave out every row or paragraph tagged [P3], [P4], [P5] or [P6] inside them.
  4. Text inside a section: keep the 50 wording; `<p>`/`<ul>`; the sharing and retention sections as `<div className="overflow-x-auto"><table>` with `<caption className="sr-only">`; Thai compound words and names in `<Nobr>`, English inside Thai in `<En>`; {{…}} placeholders → CONTROLLER_LEGAL_NAME / EMAIL / LINE_ID where they fit, else the visible text '[owner to fill: …]'.
  5. Stop and report if a 50 sentence states a business fact not in 00-overview §2 (do not invent or delete facts).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: same 15 section ids in th and en, same order; every section has phase 'P1'
  - cl-privacy-checker: every [P1] item of 50 §11.3 is present; no [P3]/[P4] text present
  - grep -c 'phase: "P1"' src/content/privacy.tsx = 30

#### P1-03 · staff-notify.server.ts (Stage A version)

- **agent_name:** `cl-p1-staff-notify` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-01, P0-16, P0-11, P0-08
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.8 (✅ notifyStaff block, phase notes, tests to write)
  - docs/backend/40-integrations.md §5.5 (flow)
  - docs/backend/00-overview.md D7
- **creates:** `src/server/staff-notify.server.ts`, `src/server/staff-notify.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) notifyStaff block from 20 §7.8 (types NotificationKind, NotifyOutcome, loadAlertInput, notifyStaff), including `childrenCount: data.children_count ?? 0` (the generated column is typed number | null). If tsc still fails on a generated type, make a type-only fix and report it.
  2. Stage A rule from the phase notes: in loadAlertInput keep the booking_request and enrolment_submitted branches; for consent_withdrawn write `throw new Error("kind_not_ready");` (card P4-03 replaces it). Do not add deliverAlertIds / deliverConsentAlert yet.
  3. Write the tests listed under 'Tests to write' except the two marked (P4-03): mock ./supabase-admin.server and ./line-alert.server; vi.stubEnv for LINE names.
  4. Alert text comes only from buildStaffAlertText; never put a name, phone or LINE ID in it or in logs.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/staff-notify.server.test.ts: all pass

#### P1-04 · rate-limit.server.ts (check_rate_limit RPC, fails open)

- **agent_name:** `cl-p1-rate-limit` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-01, P0-16
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.3 (✅ block + SQL contract)
  - docs/backend/sql/0002_booking_requests.sql check_rate_limit
- **creates:** `src/server/rate-limit.server.ts`, `src/server/rate-limit.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block from 20 §7.3. If 0002's check_rate_limit returns something other than boolean true = allowed, adapt only the return line and report.
  2. Tests (mock ./supabase-admin.server): rpc → {data:true} returns true; {data:false} returns false; {error:{code:'x'}} returns true and console.error is called once with '[rate-limit] rpc_failed' and nothing else.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/rate-limit.server.test.ts: all pass

#### P1-05 · booking.schema.ts (D26 contact rule) with tests

- **agent_name:** `cl-p1-booking-schema` · **phase:** P1 · **batch:** 1
- **depends_on:** P0-04, P0-05, P0-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.1 (✅ (rev) booking.schema.ts and ✅ (rev) schema tests)
  - docs/backend/10-data-model.md §4.1 limits
  - docs/backend/00-overview.md D26
- **creates:** `src/lib/backend/booking.schema.ts`, `src/lib/backend/booking.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy both ✅ (rev) blocks from 20 §9.1.
  2. Add boundary tests with DB_LIMITS (20 §8.9 pattern): guardianName at personName passes and +1 fails; nickname at nickname passes and +1 fails; message at requestMessage passes and +1 fails.
  3. Phone is required only when preferredContact = 'phone' (code preferred_missing); a LINE choice with no phone and no LINE ID is valid.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/booking.schema.test.ts: all pass

#### P1-06 · booking-request.server.ts (handleBookingRequest) with tests

- **agent_name:** `cl-p1-booking-handler` · **phase:** P1 · **batch:** 3
- **depends_on:** P1-03, P1-04, P1-05, P0-09, P0-10, P0-02, P0-16, P0-03, P0-05
- **human_gate:** BEFORE (inherited through P1-03/P1-04 → P1-01): G1–G3 and G4 · 0002 marked done in 90 §2, so src/integrations/supabase/types.ts exists with the 0002 objects.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §4 (ok, fail, PublicResult, PublicErrorCode)
  - docs/backend/20-server-api.md §§7.1–7.4 and §7.8 (signatures: getClientIp; hashIp is async; checkRateLimit takes four arguments; verifyTurnstile(token, action, ip: string | null); notifyStaff returns NotifyOutcome and owns the 4 s budget)
  - docs/backend/20-server-api.md §7.10 (✅ (rev) handler + ✅ (rev) tests)
  - docs/backend/20-server-api.md §9.1 (BookingRequestInput / BookingRequestRaw from P1-05; the 9-step logic list)
  - docs/backend/10-data-model.md §§6.3, 6.4, 15 (booking_requests columns and enums, generated types)
  - docs/backend/00-overview.md D7, D18
  - docs/backend/50-security-privacy.md §4 (check order, missing IP = skip limit)
- **creates:** `src/server/booking-request.server.ts`, `src/server/booking-request.server.test.ts`
- **modifies:** —
- **steps:**
  1. Read-only check: src/integrations/supabase/types.ts lists booking_requests, studio_settings, the enum booking_request_status and the function check_rate_limit; if any is missing, stop and report "types not regenerated" (10 §15).
  2. Copy the ✅ (rev) handler and test blocks from 20 §7.10 (the handler has `status: "new" as const`; the tests import from "vitest" and include form_closed via the `vi.hoisted` holder). Keep the relative `./supabase-admin.server` import inside src/server (it is the README's service-role door).
  3. Order of checks exactly as 50 §4: zod → honeypot (fake success, nothing stored) → too fast → Turnstile → rate limit (skipped with '[booking] no_client_ip' when getClientIp() is null) → booking_form_open → insert → `await notifyStaff(...)` (no timeout in the handler: the 4 s budget lives inside notifyStaff, on the LINE call only) → ok(refCode).
  4. Never log the request body, names, phones, LINE IDs or IPs.
  5. If tsc fails inside src/server/staff-notify.server.ts (P1-03's file), stop and report it against P1-03; do not edit that file.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/booking-request.server.test.ts: all pass (honeypot, too_fast, bot_check_failed, rate_limited, invalid_input, form_closed, success)

#### P1-07 · submitBookingRequest server function

- **agent_name:** `cl-p1-booking-function` · **phase:** P1 · **batch:** 4
- **depends_on:** P1-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.0 and §9.1 (✅ booking.functions.ts)
  - docs/backend/20-server-api.md §1 rules (R-26)
- **creates:** `src/lib/backend/booking.functions.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block from 20 §9.1. The validator is a typed pass-through; zod runs in the handler (public function never throws for expected problems).
  2. Export nothing but submitBookingRequest.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - The README leak grep, run unchanged (it already lists handleBookingRequest), prints nothing

#### P1-08 · site.tsx additions (form links, subpage strings, FAQ, export En) and Footer hrefPrefix

- **agent_name:** `cl-p1-site-footer` · **phase:** P1 · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §2.1 (✅ site.tsx diff + Footer prop)
  - docs/backend/30-ui.md §3.1 (copy keys only)
  - src/content/site.tsx
  - src/components/Footer.tsx
- **creates:** —
- **modifies:** `src/content/site.tsx`, `src/components/Footer.tsx`
- **steps:**
  1. Apply the ✅ diff in 30 §2.1 to src/content/site.tsx (cta.formLink, pricing.formLink, subpage strings incl. privacyLink, updated FAQ answer, `export` of En) in Thai and English together.
  2. Add the Footer hrefPrefix prop exactly as in 30 §2.1 (default keeps the homepage unchanged). Do not add the privacy link to Footer yet (card P1-10).
  3. Do not change any existing fact, price or link.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run (existing videos.test.ts still passes)
  - The homepage renders the same as before in both languages (npx vite build, then open / and /?lang=en in npx vite preview)

#### P1-09 · SubpageHeader and FieldError components

- **agent_name:** `cl-p1-subheader-fielderror` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §2.2 (✅ FieldError.tsx)
  - docs/backend/30-ui.md §2.3 (✅ SubpageHeader.tsx)
  - docs/backend/30-ui.md §6 (SubpageHeader test)
- **creates:** `src/components/SubpageHeader.tsx`, `src/components/SubpageHeader.test.tsx`, `src/components/forms/FieldError.tsx`
- **modifies:** —
- **steps:**
  1. Copy both ✅ blocks from 30 §2.2 and §2.3.
  2. Write SubpageHeader.test.tsx: language buttons expose aria-pressed; the logo link goes to '/' in Thai and '/?lang=en' in English (wrap in LanguageProvider; mock the router Link if needed, as the existing tests do).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/SubpageHeader.test.tsx: all pass

#### P1-10 · /privacy route, prose styles and footer privacy link

- **agent_name:** `cl-p1-privacy-route` · **phase:** P1 · **batch:** 3
- **depends_on:** P1-02, P1-09
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §2.4 (prose + table styles)
  - docs/backend/30-ui.md §3.4 (✅ src/routes/privacy.tsx; footer link)
  - docs/backend/30-ui.md §6 checklist
- **creates:** `src/routes/privacy.tsx`
- **modifies:** `src/styles.css`, `src/components/Footer.tsx`
- **steps:**
  1. Copy the ✅ privacy route from 30 §3.4.
  2. Add the .privacy-prose rules from 30 §2.4 (p, ul, table, th/td) inside the existing @layer components { … } in src/styles.css. Use only text tokens (ink, ink-soft, ink-line); never decorative colours for text.
  3. Footer: add t.subpage.privacyLink as a link to /privacy (+ ?lang=en in English) next to the credit line, min-h-11.
  4. Run npx vite build before npx tsc --noEmit (new route).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Preview: /privacy and /privacy?lang=en render 15 sections with the draft banner, no horizontal scroll at 360 px

#### P1-11 · inbox.schema.ts and inbox.functions.ts (list, get, update, retry)

- **agent_name:** `cl-p1-inbox-functions` · **phase:** P1 · **batch:** 3
- **depends_on:** P1-01, P0-17, P1-03
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.3 (✅ inbox.schema.ts, ✅ inbox.functions.ts, 📝 getBookingRequest)
  - docs/backend/20-server-api.md §14.1 (BookingRequestDetail type, mapping table, skeleton)
  - docs/backend/20-server-api.md §9.0
- **creates:** `src/lib/backend/inbox.schema.ts`, `src/lib/backend/inbox.functions.ts`, `src/lib/backend/inbox.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks from 20 §9.3; add the BookingRequestDetail type from 20 §14.1 to inbox.schema.ts exactly as written.
  2. Add getBookingRequest following the §14.1 skeleton: sessionId/sessionDate null (P2-05 fills them), convertedFamilyId null (P3-14 fills it); children parsed with zod, never cast; on parse failure [] and log '[inbox] children_unreadable' with the row id only.
  3. Write inbox.schema.test.ts: InboxFilterSchema accepts the 8 filters and rejects 'x'; UpdateBookingRequestInput rejects a staffNote longer than DB_LIMITS.staffNoteLong.
  4. Do not add listPendingStaffAlerts (card P4-19).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/inbox.schema.test.ts: all pass

#### P1-12 · Admin copy module: inbox

- **agent_name:** `cl-p1-admin-copy-inbox` · **phase:** P1 · **batch:** 1
- **depends_on:** P0-18
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern
  - docs/backend/30-ui.md §5 reference block members inbox and request (type L4263–4332; th L4892–4988; en L5708–5804)
  - docs/backend/30-ui.md §5.1 rows 'inbox · request.lineHowTo(ref)' and 'request.lineHint'
- **creates:** `src/content/admin/inbox.tsx`
- **modifies:** `src/content/admin/index.ts`
- **steps:**
  1. Create src/content/admin/inbox.tsx with type AdminInbox = { inbox; request } and th/en objects copied from the reference block, plus the §5.1 keys request.lineHowTo(ref: string) and request.lineHint (TH and EN).
  2. Edit src/content/admin/index.ts: import adminInbox/AdminInbox, AdminContent = AdminCore & AdminInbox, spread ...adminInbox.th / ...adminInbox.en.
  3. The LINE copy must never suggest adding a parent by LINE ID (D26).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity for inbox.tsx

#### P1-13 · booking.tsx copy and TurnstileWidget

- **agent_name:** `cl-p1-booking-copy-turnstile` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-08, P0-08
- **human_gate:** AFTER (before go-live, card P2-08): the `notice` text is privacy-notice wording with the PROPOSED 6-month retention (00 §12); the owner confirms the retention periods (G0 Q6) and approves the notice together with the …-v1 notice (G9a · v1).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.2 (✅ (rev) src/content/booking.tsx)
  - docs/backend/30-ui.md §2.5 (✅ TurnstileWidget.tsx)
  - docs/backend/40-integrations.md §6.2 (client facts)
  - docs/backend/50-security-privacy.md §11.5 (short notice next to submit)
- **creates:** `src/content/booking.tsx`, `src/components/booking/TurnstileWidget.tsx`
- **modifies:** —
- **steps:**
  1. Copy both ✅ blocks (booking.tsx includes `honeypotLabel`, R-45). The short notice next to the submit button must match 50 §11.5 in meaning; if it differs, 50 wins and you report it.
  2. No consent checkbox on /book (D8). No promise of a private link, a call-back time or a free seat (R-24).
  3. The waitlistNote, the `notice` (6-month retention, G9a · v1 + G0 Q6) and any 'what happens next' line are OWNER-APPROVE: copy the planned wording unchanged and list them in your report. They are approved by the AFTER gate above, so they are not an "unconfirmed fact" stop.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity; never the words 'money game'

#### P1-14 · BookingForm and BookingThanks components with tests

- **agent_name:** `cl-p1-booking-form` · **phase:** P1 · **batch:** 5
- **depends_on:** P1-13, P1-07, P1-09, P1-02, P1-05, P0-02
- **human_gate:** AFTER: the `notice` it renders is approved with G9a · v1 before go-live (see P1-13).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.2 (field table, states, the ✅ (rev) BookingContent type in booking.tsx for key names, ✅ (rev) BookingForm.tsx, ✅ BookingThanks.tsx, 📝 tests)
  - docs/backend/30-ui.md §2.2 (FieldError props) and §2.5 (TurnstileWidget props and the window.turnstile API the tests fake)
  - docs/backend/30-ui.md §1.2–1.3 (components, form pattern)
  - docs/backend/30-ui.md §6 (checklist and test list)
  - docs/backend/20-server-api.md §9.1 (BookingFormFields, BookingFormSchema, BookingFormValues, contactRule) and §4 (PublicErrorCode)
  - src/i18n/LanguageProvider.tsx (tests render inside it)
- **creates:** `src/components/booking/BookingForm.tsx`, `src/components/booking/BookingThanks.tsx`, `src/components/booking/BookingForm.test.tsx`, `src/components/booking/BookingThanks.test.tsx`
- **modifies:** —
- **steps:**
  1. Copy exactly two ✅ fences from 30 §3.2: `src/components/booking/BookingForm.tsx` (✅ (rev): `aria-labelledby` on the three RadioGroups, honeypot label from `c.honeypotLabel`) and `src/components/booking/BookingThanks.tsx`. Do NOT copy the `src/content/booking.tsx` fence (card P1-13) or the `src/routes/book.tsx` fence (card P1-18). Keep the F2-04 comment where SessionPicker will go.
  2. Copy the two 📝 test blocks under BookingThanks in 30 §3.2 into BookingForm.test.tsx and BookingThanks.test.tsx. They use `fireEvent` only (user-event is not installed; never add packages), render inside `<LanguageProvider initialLang="th">` (so the notice link is "/privacy"), fake `window.turnstile` per test (`fakeTurnstile(true)` gives a token, `false` never does), stub `ResizeObserver` in the test file (never edit src/test/setup.ts), mock `useServerFn` to return the mocked submitBookingRequest (no router warning), and choose an age before testing preferred_missing. Use only the fake values in the blocks.
  3. The thank-you screen's main action is 'send my code on LINE' (lineMessageUrl with the ref code only, no personal data); BookingThanks.test.tsx checks it and the focus on the heading.
  4. Known behaviour, report it but do not change it: with an empty age, the preferred_missing message appears only after an age is chosen (zod stops early).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/booking/BookingForm.test.tsx src/components/booking/BookingThanks.test.tsx: all pass (incl. 'gives every radio group an accessible name')

#### P1-15 · Admin copy: settings module + /admin/settings (owner)

- **agent_name:** `cl-p1-settings-screen` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-12, P0-22, P0-19
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/settings' (staff accounts + studio settings only; consent texts are parked)
  - docs/backend/30-ui.md §5 reference member settings (type L4667–4703; th L5443–5498; en L6263–6319)
  - docs/backend/30-ui.md §4.1 (add the nav item in the same task)
  - docs/backend/20-server-api.md §11 (query keys)
- **creates:** `src/content/admin/settings.tsx`, `src/routes/admin/_staff/settings.tsx`
- **modifies:** `src/content/admin/index.ts`, `src/components/admin/AdminShell.tsx`
- **steps:**
  1. Create src/content/admin/settings.tsx (type AdminSettings = { settings }, th/en from the reference) and add it to index.ts like card P1-12 did.
  2. Create route createFileRoute("/admin/_staff/settings"): owner only (if me.role !== 'owner' show t.errors.forbidden); sections 'บัญชีทีมงาน' (listStaff table, setStaffRole by email, removeStaffRole with AlertDialog, hidden on own row) and 'การตั้งค่าสตูดิโอ' (two Switch + capacity input → updateStudioSettings). Do not build the consent-text section (parked PK-03).
  3. AdminShell: add { to: "/admin/settings", key: "settings", ownerOnly: true } to MORE (widen the declared type if P0-22 typed it).
  4. Query keys ['admin','staff'] and ['admin','settings']; errors via toAdminErrorCode → toast t.errors[code].
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Preview (human): staff user does not see Settings in More; owner can grant and remove a test staff role

#### P1-16 · FALLBACK ONLY: /api/cron/purge route for a Lovable Job

- **agent_name:** `cl-p1-cron-fallback` · **phase:** P1 · **batch:** 2
- **depends_on:** P1-01
- **human_gate:** Run this card ONLY if Lovable refused cron.schedule at G4 for 0002 (recorded in 40 §2 row 16). AFTER: owner creates a Lovable Job (Cloud → Jobs) POSTing daily 19:15 UTC to `<PUBLISHED_URL>`/api/cron/purge; Publish (G10).
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §10.2 (📝 route)
  - docs/backend/40-integrations.md §7
  - src/integrations/supabase/cron-auth.ts (generated; read only)
- **creates:** `src/routes/api/cron/purge.ts`
- **modifies:** —
- **steps:**
  1. Open src/integrations/supabase/cron-auth.ts and use its exported checker exactly as named and typed there; if the file or export is missing, stop and report 'cron-auth not generated'.
  2. Write the route from 20 §10.2 with dynamic imports inside the handler; never hand-roll a secret comparison; log only '[cron] purge_failed' with the error code.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - The README leak grep, run unchanged (it already lists purge_expired_records), prints nothing

#### P1-17 · /admin/inbox list + detail screens, nav tab, dashboard cards

- **agent_name:** `cl-p1-inbox-screens` · **phase:** P1 · **batch:** 4
- **depends_on:** P1-11, P1-12, P1-15
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/inbox' (✅ skeleton) and '/admin/inbox/$requestId' (P1 parts only)
  - docs/backend/30-ui.md §4.3 '/admin dashboard' (newRequests, failed alerts)
  - docs/backend/20-server-api.md §11
  - docs/backend/00-overview.md D26
- **creates:** `src/routes/admin/_staff/inbox/index.tsx`, `src/routes/admin/_staff/inbox/$requestId.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. Copy the ✅ inbox list skeleton (createFileRoute("/admin/_staff/inbox/")).
  2. Build the detail page from 30 §4.3: contact card with tel: link; for LINE show request.lineHowTo(ref) and, when given, the LINE ID with request.lineHint and a Copy button (never 'add friend'); children; interests; message; team status buttons + staff note → updateBookingRequest; alerts list with resend → retryStaffNotification. No convert button yet (P3-14).
  3. AdminShell: add { to: "/admin/inbox", key: "inbox", Icon: Inbox } to TABS.
  4. Dashboard: add cards t.dashboard.newRequests(n) and t.dashboard.failedAlerts(n) linking to /admin/inbox; show t.dashboard.allClear when both are 0.
  5. Run npx vite build before tsc. Never show last_error raw beyond its short code.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-ui-a11y-checker passes 30 §6 for both pages

#### P1-18 · /book route and homepage entry points

- **agent_name:** `cl-p1-book-route` · **phase:** P1 · **batch:** 6
- **depends_on:** P1-14, P1-10
- **human_gate:** AFTER: owner G7 (Turnstile widget with exact hostnames) and the builder commits the site key in public-config.ts.
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.2 (✅ src/routes/book.tsx)
  - docs/backend/30-ui.md §3.1 (CtaBand and Pricing links)
  - src/components/sections/CtaBand.tsx
  - src/components/sections/Pricing.tsx
- **creates:** `src/routes/book.tsx`
- **modifies:** `src/components/sections/CtaBand.tsx`, `src/components/sections/Pricing.tsx`
- **steps:**
  1. Copy the ✅ book route (search params lang, package; session comes in P2-06).
  2. CtaBand: add the text link under the two buttons exactly as 30 §3.1. Pricing: add the centred formLink below the plan cards. LINE buttons stay primary and unchanged.
  3. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Preview: /book renders without any database call (works with Cloud paused); every input has a label; 360 px has no horizontal scroll

#### P1-19 · Owner system check: getSystemCheck + settings section

- **agent_name:** `cl-p1-system-check` · **phase:** P1 · **batch:** 3
- **depends_on:** P1-15, P0-09
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.2 table row getSystemCheck
  - docs/backend/30-ui.md §4.3 '/admin/settings' System check bullet
  - docs/backend/30-ui.md §5.1 settings.systemCheck rows
- **creates:** —
- **modifies:** `src/lib/backend/staff.schema.ts`, `src/lib/backend/staff.functions.ts`, `src/content/admin/settings.tsx`, `src/routes/admin/_staff/settings.tsx`
- **steps:**
  1. staff.schema.ts: add SecretName and SystemCheck types exactly as 20 §9.2 describes.
  2. staff.functions.ts: add getSystemCheck (GET, requireOwner). Inside the handler only: optionalServerEnv per name, getClientIp() !== null. Return booleans only.
  3. settings.tsx copy: add settings.systemCheck { title, lead, run, present, missing, clientIp } in TH and EN from 30 §5.1.
  4. Settings route: add the 'ตรวจระบบ / System check' section with a 'Check now' button (useMutation-style manual call) and ✓/✗ + text rows; never show values.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - grep -n 'process.env' src/lib/backend/staff.functions.ts finds nothing (only optionalServerEnv)

#### P1-20 · OPTIONAL: LINE alert-OA webhook to capture a staff group id

- **agent_name:** `cl-p1-alert-webhook` · **phase:** P1 · **batch:** 1
- **depends_on:** P0-11
- **human_gate:** Only if the owner wants alerts in a staff group (F1-08). AFTER: owner sets the webhook URL on the CherryLee Staff Alerts channel only (never on @cherryleeandco, D6), Publish (G10).
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §10.1 (✅ alert-webhook.ts)
  - docs/backend/40-integrations.md §5.6
- **creates:** `src/routes/api/line/alert-webhook.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ block from 20 §10.1 (signature check first, replies the group id into the group, stores nothing, logs no message text).
  2. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P1-21 · P1 end-to-end check on the Lovable preview (F1-10)

- **agent_name:** `cl-p1-preview-e2e` · **phase:** P1 · **batch:** 7
- **depends_on:** P1-17, P1-18, P1-19
- **human_gate:** BEFORE: owner G6 (secrets in Cloud → Secrets), G7 (Turnstile), G8 (Staff Alerts OA, LINE_ALERT_TO). The builder pushes and the preview rebuilds. AFTER: results recorded in 40 §2 rows 9, 10 and 90 §2.
- **reads:**
  - docs/backend/00-overview.md §8 P1 acceptance
  - docs/backend/40-integrations.md §2 rows 9–10, §13
  - docs/backend/50-security-privacy.md §9 checklist
- **creates:** —
- **modifies:** —
- **steps:**
  1. Give the builder this checklist and record answers (do not do the human steps): System check shows every secret ✓ and visitor IP ✓; a test request (fake data: ผู้ปกครองทดสอบ, 0800000001) shows the thank-you in TH and EN with a CL-XXXXX code; the owner's LINE alert arrives within a minute with only code, date, number of children and the admin link; with LINE_ALERT_TO removed temporarily the request still saves and the inbox shows the failed badge + resend works after restoring it.
  2. Rate limit: from one phone, the 6th request within an hour gets rate_limited; in the SQL editor `select count(distinct key_hash) from public.rate_limit_events;` grows when a second network is used. If every network gives one hash, report it (20 §7.1 says to switch the limit off in code until fixed).
  3. Spot-check Cloud → Logs: no names, phones or LINE IDs. Delete the test requests afterwards (staff mark spam; purge removes them).
- **acceptance:**
  - Every P1 acceptance line in 00 §8 is checked by the human or listed as open
  - cl-privacy-checker: no personal data in logs, alerts or URLs

### Stage A · P2 Sessions and seats

#### P2-01 · Review SQL 0003_sessions.sql, then G4

- **agent_name:** `cl-p2-sql-0003` · **phase:** P2 · **batch:** 1
- **depends_on:** P1-01
- **human_gate:** AFTER review: builder G4 applies 0003 (needed even if the P2 screens are skipped, because 0004 builds on it), git pull --ff-only, types.ts contains 'sessions', rls_smoke.sql no FAIL; mark G4(0003) in 90 §2.
- **reads:**
  - docs/backend/10-data-model.md §6.7, §8
  - docs/backend/sql/0003_sessions.sql
  - docs/backend/sql/tests/rls_smoke.sql
  - docs/backend/00-overview.md D14, R-18, R-20
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist on 0003. Also check: get_open_sessions never returns capacity or names and is service-role only; session_seats_left calls require_staff_or_server(); generate_weekend_sessions skips existing dates; get_sessions_with_seats is security invoker.
  2. Check rls_smoke.sql covers sessions and these four functions; list gaps. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P2-02 · sessions.schema.ts + sessions.functions.ts (public open dates + staff list/save/generate)

- **agent_name:** `cl-p2-sessions-functions` · **phase:** P2 · **batch:** 2
- **depends_on:** P2-01, P0-17, P0-07, P0-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.4 (✅ sessions.schema.ts, ✅ getOpenSessions, 📝 staff table)
  - docs/backend/20-server-api.md §14.2 (SessionRow type, mapping, skeleton)
  - docs/backend/20-server-api.md §9.0
- **creates:** `src/lib/backend/sessions.schema.ts`, `src/lib/backend/sessions.functions.ts`, `src/lib/backend/sessions.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks; add SessionRow and the ListSessionsInput .refine (max 93 days apart) from §14.2.
  2. Add listSessions (one rpc get_sessions_with_seats), saveSession (insert/update; 23505 → conflict), generateWeekendSessions (rpc; returns { created }). Do not add getSessionRoster (P3-07).
  3. getOpenSessions is public: supabaseAdmin, returns PublicResult`<OpenSession[]>`, never capacity.
  4. Tests: ListSessionsInput rejects a 94-day range; SaveSessionInput rejects a non-weekend date if the schema says so; publicNote longer than DB_LIMITS.publicNote fails; capacity above DB_LIMITS.sessionCapacityMax fails.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/sessions.schema.test.ts: all pass
  - grep -n 'capacity' in the getOpenSessions handler: not returned

#### P2-03 · Admin copy module: sessions (+ roster keys)

- **agent_name:** `cl-p2-admin-copy-sessions` · **phase:** P2 · **batch:** 1
- **depends_on:** P1-15
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern
  - docs/backend/30-ui.md §5 reference members sessions and roster (type L4333–4404; th L4989–5098; en L5805–5918)
  - docs/backend/30-ui.md §5.1 row 'sessions · sessions.cancelWarning(n)'
- **creates:** `src/content/admin/sessions.tsx`
- **modifies:** `src/content/admin/index.ts`
- **steps:**
  1. Create src/content/admin/sessions.tsx (type AdminSessions = { sessions; roster }), TH and EN, plus sessions.cancelWarning(n) from §5.1.
  2. Add it to src/content/admin/index.ts (import, & AdminSessions, spreads).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity

#### P2-04 · /admin/sessions screen, nav tab and dashboard next-session card

- **agent_name:** `cl-p2-sessions-screen` · **phase:** P2 · **batch:** 3
- **depends_on:** P2-02, P2-03, P1-17
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/sessions' (P2 parts; no roster link or cancel warning yet)
  - docs/backend/30-ui.md §4.3 '/admin dashboard' (nextSession, seatsLeft, noCapacity)
  - docs/backend/30-ui.md §1.2 (Sheet, Dialog)
  - docs/backend/20-server-api.md §11 (query keys)
- **creates:** `src/routes/admin/_staff/sessions/index.tsx`, `src/components/admin/sessions/SessionEditSheet.tsx`, `src/components/admin/sessions/GenerateSessionsDialog.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. Route createFileRoute("/admin/_staff/sessions/") with ?month=YYYY-MM (default current Bangkok month), prev/next month, table from listSessions.
  2. SessionEditSheet: SaveSessionInput fields (status, capacity, seats held offline, public note TH/EN, staff note); weekend-only date (isWeekendDate, edit.notWeekend).
  3. GenerateSessionsDialog: from (next Saturday), weeks (8, 1–12), capacity (studio default, may be empty) → generateWeekendSessions → toast done(n).
  4. AdminShell: add { to: "/admin/sessions", key: "sessions", Icon: CalendarDays } to TABS. Dashboard: next open session in the next 14 days with seatsLeft(n) or noCapacity.
  5. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-ui-a11y-checker passes 30 §6
  - Preview (human): staff create 8 weekends in one action

#### P2-05 · Chosen session in the inbox detail and in the LINE alert date (F2-05)

- **agent_name:** `cl-p2-session-in-inbox` · **phase:** P2 · **batch:** 3
- **depends_on:** P2-02, P1-17, P1-03
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.8 phase note F2-05
  - docs/backend/20-server-api.md §14.1 (sessionId, sessionDate rows)
  - docs/backend/30-ui.md §4.3 '/admin/inbox/$requestId' (Interested in: chosen session)
- **creates:** —
- **modifies:** `src/server/staff-notify.server.ts`, `src/lib/backend/inbox.functions.ts`, `src/routes/admin/_staff/inbox/$requestId.tsx`, `src/server/staff-notify.server.test.ts`
- **steps:**
  1. staff-notify.server.ts loadAlertInput('booking_request'): also select session_id; when set, load sessions.session_date and use it for dateLabel instead of preferred_date.
  2. inbox.functions.ts getBookingRequest: fill sessionId and sessionDate (one extra select by id when session_id is set).
  3. Detail page: show formatSessionDate(sessionDate) under 'Interested in' when present.
  4. Add a test: with a session_id the alert uses the session date.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/staff-notify.server.test.ts: all pass

#### P2-06 · SessionPicker on /book (client-fetched, LINE fallback)

- **agent_name:** `cl-p2-session-picker` · **phase:** P2 · **batch:** 3
- **depends_on:** P2-02, P1-18
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.3 (SessionPicker spec)
  - docs/backend/30-ui.md §3.2 field 8 and ?session= param
  - docs/backend/00-overview.md D15 (never block the page)
- **creates:** `src/components/booking/SessionPicker.tsx`, `src/components/booking/SessionPicker.test.tsx`
- **modifies:** `src/components/booking/BookingForm.tsx`, `src/routes/book.tsx`
- **steps:**
  1. Build SessionPicker exactly as 30 §3.3 (useServerFn(getOpenSessions), query key ['public','open-sessions'], staleTime 60 s, retry 1; badges are text; full dates selectable with waitlistNote; first option 'No date yet').
  2. BookingForm: replace the F2-04 comment with `<SessionPicker />`; choosing a session sets sessionId, preferredDate and preferredDay.
  3. book.tsx: accept ?session=`<uuid>` (validated as a uuid) and pass it as the preselected id.
  4. Tests (mock the server function): loading, error → unavailable text, empty → none text, a full date shows 'Full' text, never shows capacity.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/booking/SessionPicker.test.tsx: all pass

#### P2-07 · OPTIONAL: homepage 'Open dates' strip

- **agent_name:** `cl-p2-open-dates-strip` · **phase:** P2 · **batch:** 4
- **depends_on:** P2-06, P1-08
- **human_gate:** Only if the owner wants seats shown on the homepage (G0 Q3).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.3 (OpenDates spec + copy table)
  - src/components/sections/Pricing.tsx
- **creates:** `src/components/sections/OpenDates.tsx`
- **modifies:** `src/content/site.tsx`, `src/components/sections/Pricing.tsx`
- **steps:**
  1. site.tsx: add SiteContent.pricing.openDates { title, seatsLeft(n), open, full, more } in TH and EN (1 seat → '1 seat left').
  2. OpenDates: next 4 open dates as chips linking to /book?session=`<id>` (+ &lang=en); hidden while loading, on error and when empty (never an error on the homepage).
  3. Pricing: render `<OpenDates />` under the pricing title.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - With the network blocked the homepage shows no strip and no error

#### P2-08 · Stage A go-live check (G9a …-v1, G10)

- **agent_name:** `cl-p2-stage-a-golive` · **phase:** P2 · **batch:** 4
- **depends_on:** P1-21, P2-04, P2-05, P2-06
- **human_gate:** Human: owner approves the …-v1 notice (G9a; placeholders filled, draftBanner set to null in a separate builder commit), fixes critical findings of the Lovable publish security scan, confirms sign-up disabled, runs rls_smoke.sql (no FAIL), then presses Publish (G10). If the P2 screens were skipped, this card depends only on P1-21 and P2-01. Then G-MVP starts: ≥ 8 weeks of real use.
- **reads:**
  - docs/backend/00-overview.md §8.0 Stage A row, §8 P1/P2 acceptance
  - docs/backend/40-integrations.md §13 (publish checklist)
  - docs/backend/50-security-privacy.md §9, §11.1
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the standard acceptance on main and cl-privacy-checker on everything added in Stage A.
  2. Check privacy.tsx: version '`<YYYY-MM>`-v1', 15 P1 sections, CONTROLLER_LEGAL_NAME set, draftBanner null; list anything still '[owner to fill: …]'. Check 90 §2 shows G0 Q6 (retention periods) answered and the G9a · v1 row says the /book short notice (`bookingContent.notice`) was approved with it.
  3. Produce the 40 §13 checklist for the owner with each line marked done/open from evidence; never mark a human gate yourself.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - 40 §13 checklist delivered with no open blocker
  - 90 §2: G9a(v1) and G10(Stage A) dates filled by cl-docs-sync after the owner confirms

### Stage B · P3 Family records

#### P3-01 · Review SQL 0004_families.sql, then G4

- **agent_name:** `cl-p3-sql-0004` · **phase:** P3 · **batch:** 1
- **depends_on:** P2-01, P2-08
- **human_gate:** BEFORE: owner records G-MVP = go (90 §2) and G11 (payment retention) answered or noted pending. AFTER review: builder G4 applies 0004, git pull --ff-only, types.ts contains 'families', 'package_balances', 'create_family_from_request' and 'set_primary_guardian', rls_smoke.sql no FAIL. Real family data stays out until Stage B is published (00 §8.0).
- **reads:**
  - docs/backend/10-data-model.md §§6.8–6.15, 7, 9, 10, 13
  - docs/backend/sql/0004_families.sql
  - docs/backend/sql/tests/rls_smoke.sql
  - docs/backend/00-overview.md D16, D17, R-10, R-15, R-21, R-22, R-23, R-39
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist on 0004. Also check: create_family_from_request runs in one transaction and maps each child's age_years; set_primary_guardian (R-39) clears the other primary before setting the new one, in one function, SECURITY INVOKER, granted to authenticated only; package_balances subtracts sessions_used_purged; the session-cancel trigger cancels held/confirmed bookings; family_contacts has is_active (soft delete) and only the owner may hard-delete it (policy family_contacts_owner_delete); payment-slips bucket is private with staff-only storage policies; purge v2 is a full re-declaration.
  2. Check rls_smoke.sql covers every new table, the view and the bucket policies; list gaps. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P3-02 · families.schema.ts with view types (§14.4) and boundary tests

- **agent_name:** `cl-p3-families-schema` · **phase:** P3 · **batch:** 3
- **depends_on:** P3-01, P0-04, P0-06, P3-05
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.5 (✅ (rev) families.schema.ts, incl. `type ConsentPurpose` from ./common.schema and `type PaymentRow` from ./payments.schema)
  - docs/backend/20-server-api.md §14.4 (FamilyListRow, GuardianView, ChildView, ContactView, PackageView, BookingHistoryRow, LinkView, ConsentCell, FamilyDetail + mapping tables)
  - docs/backend/20-server-api.md §14.5 (PaymentRow, created by P3-05 in payments.schema.ts)
  - docs/backend/10-data-model.md §4.1
- **creates:** `src/lib/backend/families.schema.ts`, `src/lib/backend/families.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) block from 20 §9.5 (its imports include `type ConsentPurpose` from ./common.schema and `type PaymentRow` from ./payments.schema), then add every §14.4 type exactly as written (one ConsentCell definition here; consent.schema.ts imports it later). Never define PaymentRow or ConsentPurpose a second time.
  2. Tests: SaveFamilyInput.id is optional; SaveGuardianInput accepts confirmLinkChanges and confirmsParentalResponsibility; boundary tests for personName, nickname, relationship, email, staffNoteLong against DB_LIMITS.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/families.schema.test.ts: all pass

#### P3-03 · families.functions.ts part 1: listFamilies, getFamily

- **agent_name:** `cl-p3-families-read` · **phase:** P3 · **batch:** 4
- **depends_on:** P3-02, P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.5 table rows listFamilies, getFamily
  - docs/backend/20-server-api.md §14.4 listFamilies skeleton and getFamily skeleton
  - docs/backend/20-server-api.md §14.5 (PaymentRow and its mapping: getFamily maps payments the same way)
  - docs/backend/20-server-api.md §9.0 (paging, errors, strict-TS rules)
- **creates:** `src/lib/backend/families.functions.ts`
- **modifies:** —
- **steps:**
  1. Implement listFamilies exactly as the §14.4 skeleton (no q: one paged query; with q: three id queries, de-duplicated, then the page; children and primary guardian in two more queries; PAGE_SIZE 30).
  2. Implement getFamily per the skeleton: restriction fields null (P5-03 fills them), links [] and consent cells [] (P4-17 fills them); contacts only is_active = true; payments expose hasSlip, never slip_path; never select token_hash.
  3. Export only createServerFn results (this card: listFamilies and getFamily; P3-04 adds six more to the same file).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-04 · families.functions.ts part 2: create from request, save family/guardian/child/contact, soft delete

- **agent_name:** `cl-p3-families-write` · **phase:** P3 · **batch:** 5
- **depends_on:** P3-03
- **human_gate:** BEFORE (inherited through P3-03 → P3-02 → P3-01): G-MVP = go and G4 · 0004 marked done in 90 §2 with types regenerated. Read-only check first: src/integrations/supabase/types.ts lists families, guardians, children, family_contacts, create_family_from_request and set_primary_guardian; if not, stop and report "types not regenerated".
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §4 (adminError, adminErrorFromDb, AdminErrorCode incl. family_restricted)
  - docs/backend/20-server-api.md §6 (requireStaff; context.supabase, context.userId)
  - docs/backend/20-server-api.md §9.0 (conventions and the strict-TS write rules)
  - docs/backend/20-server-api.md §9.5 (✅ (rev) families.schema.ts block for the input schema names: CreateFamilyFromRequestInput (children[].ageYears), SaveFamilyInput, SaveGuardianInput, SaveChildInput, SaveFamilyContactInput, DeleteFamilyContactInput; and the table rows createFamilyFromRequest … deleteFamilyContact with the paragraph under them)
  - docs/backend/sql/0004_families.sql §14b create_family_from_request and §14c set_primary_guardian (return value and errors)
  - docs/backend/00-overview.md D13, D28, R-21, R-22, R-36, R-39
- **creates:** —
- **modifies:** `src/lib/backend/families.functions.ts`
- **steps:**
  1. Imports: the six input schemas from ./families.schema, adminError and adminErrorFromDb from ./result, requireStaff from ./auth.middleware. Add and export six `createServerFn` results named exactly createFamilyFromRequest, saveFamily, saveGuardian, saveChild, saveFamilyContact, deleteFamilyContact (00 §10), each `.middleware([requireStaff]).validator(<Name>Input)`, method POST, client `context.supabase`.
  2. createFamilyFromRequest: ONE rpc('create_family_from_request', …) with each child's age_years taken from the input (never matched by index); the RPC returns the bare uuid → return `{ familyId: data }`; on error `throw adminErrorFromDb(error)` (P0002 → not_found, 23514 already converted → invalid_state, 23505 → conflict).
  3. saveFamily: insert sets created_by = context.userId; never writes status, last_activity_at or retain_until.
  4. saveGuardian, two steps in this order (R-39): write the plain fields (insert with is_primary false; update never touches is_primary); then, only when isPrimary and the row is not primary yet, ONE rpc('set_primary_guardian', { p_guardian_id }). isPrimary false never un-sets the current primary. Identity columns only when markIdentityChecked (identity_check_method, identity_checked_by = context.userId, identity_checked_at = now); has_parental_responsibility = true and responsibility_attested_at = now only when confirmsParentalResponsibility (never set back to false); confirmLinkChanges sets pending_link_changes = null.
  5. saveFamilyContact: insert sets guardian_attests_informed_at = now; update reads name, phone first and sets guardian_attests_informed_at = now only when one of them changed (R-39).
  6. deleteFamilyContact = update is_active = false with .select('id') (never .delete()); empty result → not_found; an already inactive contact still returns { deleted: true }.
  7. Every update by id chains .select('id') and throws not_found when nothing came back; build payloads without undefined-valued keys (conditional spread); guard array access (20 §9.0).
  8. Errors: saveFamily, saveGuardian, saveChild and saveFamilyContact pass DB errors through adminErrorFromDb, so 23514 'processing is restricted' becomes family_restricted (the database refuses edits of a restricted family, incl. the family row itself, R-36). deleteFamilyContact is allowed for a restricted family.
  9. No unit-test file: createServerFn handlers are not unit-tested in this plan (20 §7.10 note). The behaviour is checked by cl-reviewer against the §9.5 rows and on the preview in P3-11 and P5-05; say so in your report.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - grep -n "\.delete()" src/lib/backend/families.functions.ts prints nothing

#### P3-05 · payments.schema.ts + payments.functions.ts (packages, payments, slips)

- **agent_name:** `cl-p3-payments-functions` · **phase:** P3 · **batch:** 2
- **depends_on:** P3-01, P0-17, P0-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.6 (✅ (rev) payments.schema.ts, ✅ uploadPaymentSlip, 📝 table)
  - docs/backend/20-server-api.md §14.5 (PaymentRow)
  - docs/backend/00-overview.md D16, D17, R-23
- **creates:** `src/lib/backend/payments.schema.ts`, `src/lib/backend/payments.functions.ts`, `src/lib/backend/payments.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks; add PaymentRow from §14.5.
  2. Add createPackagePurchase (price from PRICES in @/content/business, ignore client price), recordPayment, updatePayment, listPayments, getSlipUrl (60 s signed URL), voidPayment (owner), updatePackagePurchase (staff: close only; owner: void and expiresOn; never sessions_used_purged), deletePaymentSlip (owner; sets slip_path = null so the trigger queues the file).
  3. Uploads: ≤ 5 MB, image/jpeg|png|webp|application/pdf, path `<family_id>`/`<uuid>`.`<ext>`, private bucket payment-slips.
  4. Tests: UpdatePackagePurchaseInput and VoidPaymentInput shapes; receiptNo limit; a 5 MB + 1 byte size check helper rejects.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/payments.schema.test.ts: all pass

#### P3-06 · bookings.schema.ts + bookings.functions.ts (book, status, cancel)

- **agent_name:** `cl-p3-bookings-functions` · **phase:** P3 · **batch:** 2
- **depends_on:** P3-01, P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.7 (✅ (rev) bookings.schema.ts, ✅ createBooking, 📝 table, race note)
- **creates:** `src/lib/backend/bookings.schema.ts`, `src/lib/backend/bookings.functions.ts`, `src/lib/backend/bookings.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks; add updateBookingStatus (confirm, check_in, check_out with pickup from guardians or ACTIVE authorised contacts of the same family, mark_absent) and cancelBooking (not after attended).
  2. Errors: 23505 on bookings → already_booked; 'no sessions left' → no_credit_left; session full → session_full; others through adminErrorFromDb.
  3. Tests: UpdateBookingStatusInput requires a pickup person for check_out.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/bookings.schema.test.ts: all pass

#### P3-07 · getSessionRoster (SessionRoster type, three queries)

- **agent_name:** `cl-p3-session-roster-fn` · **phase:** P3 · **batch:** 2
- **depends_on:** P3-01, P2-02
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.4 row getSessionRoster
  - docs/backend/20-server-api.md §14.3 (PickupOption, RosterRow, SessionRoster, skeleton steps 1–3)
- **creates:** —
- **modifies:** `src/lib/backend/sessions.schema.ts`, `src/lib/backend/sessions.functions.ts`
- **steps:**
  1. Add the §14.3 types to sessions.schema.ts exactly; photoStatus stays null (P4-16 fills it).
  2. Add getSessionRoster following skeleton steps 1–3 (no per-row calls; pickup options only from guardians and ACTIVE authorised contacts).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-08 · Admin copy modules: families and payments

- **agent_name:** `cl-p3-admin-copy-families-payments` · **phase:** P3 · **batch:** 2
- **depends_on:** P2-03, P3-01
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern
  - docs/backend/30-ui.md §5 reference members families and family (type L4419–4487; th L5113–5210; en L5933–6033) and payments (type L4488–4510; th L5211–5247; en L6034–6070)
  - docs/backend/30-ui.md §5.1 rows for family.* banners, family.packages.close/void/expiry, family.allergyRemoved, payments.deleteSlipConfirm
- **creates:** `src/content/admin/families.tsx`, `src/content/admin/payments.tsx`
- **modifies:** `src/content/admin/index.ts`
- **steps:**
  1. Create families.tsx (type AdminFamilies = { families; family }) and payments.tsx (type AdminPayments = { payments }) with TH and EN, plus every §5.1 key for these modules.
  2. Add both to index.ts (imports, & types, spreads).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity; staffNoteHint says no health details

#### P3-09 · /admin/families list screen + nav tab

- **agent_name:** `cl-p3-families-list` · **phase:** P3 · **batch:** 5
- **depends_on:** P3-03, P3-08, P2-04
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/families'
  - docs/backend/20-server-api.md §11
- **creates:** `src/routes/admin/_staff/families/index.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`
- **steps:**
  1. Route createFileRoute("/admin/_staff/families/") with ?q (debounced 300 ms) and ?status; cards on phones, table on md+; 'เพิ่มครอบครัว' Dialog → saveFamily (no id) → navigate to the new family (the detail route arrives in P3-10: until then navigate with a plain string href if the typed Link fails).
  2. AdminShell: add { to: "/admin/families", key: "families", Icon: Users } to TABS.
  3. Empty states families.empty / emptySearch. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-10 · /admin/families/$familyId: page, banners and Overview tab (read + staff note)

- **agent_name:** `cl-p3-family-overview` · **phase:** P3 · **batch:** 6
- **depends_on:** P3-09, P3-04
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/families/$familyId' (banners, Overview)
  - docs/backend/20-server-api.md §14.4 FamilyDetail
  - docs/backend/00-overview.md R-21 (link changes)
- **creates:** `src/routes/admin/_staff/families/$familyId.tsx`, `src/components/admin/family/FamilyBanners.tsx`, `src/components/admin/family/FamilyOverviewTab.tsx`
- **modifies:** —
- **steps:**
  1. Route createFileRoute("/admin/_staff/families/$familyId") with ?tab (overview default); Tabs shell with only the Overview tab for now.
  2. FamilyBanners: scheduledDeletion(date) when retainUntil is set; per guardian with pendingLinkChanges the linkChangesBanner listing each changed field with its OLD value (family.linkChangeOld) and a button confirmLinkChanges → saveGuardian({ id, confirmLinkChanges: true }). (Restriction banner: P5-03.)
  3. FamilyOverviewTab: guardian cards (tel: link, LINE ID copy, identityChecked/NotChecked, responsibility tick), children cards (age from birth month, else reportedAge, else ageUnknown), active contacts with role badges, staff note editor (hint: no health details). Edit sheets come in P3-11.
  4. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-ui-a11y-checker passes 30 §6

#### P3-11 · Family Overview edit sheets: guardian, child, contact (soft delete)

- **agent_name:** `cl-p3-family-edit-sheets` · **phase:** P3 · **batch:** 7
- **depends_on:** P3-10
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 Overview bullet (guardianForm, childForm, contactForm, deleteContactConfirm)
  - docs/backend/30-ui.md §1.3 (form pattern)
  - docs/backend/20-server-api.md §9.5 rows saveGuardian, saveChild, saveFamilyContact, deleteFamilyContact
- **creates:** `src/components/admin/family/GuardianSheet.tsx`, `src/components/admin/family/ChildSheet.tsx`, `src/components/admin/family/ContactSheet.tsx`
- **modifies:** `src/components/admin/family/FamilyOverviewTab.tsx`
- **steps:**
  1. Three Sheet forms with react-hook-form + zodResolver using the families.schema inputs; FieldError for messages; Checkbox rows min-h-11, never pre-ticked (responsibility, informed).
  2. ContactSheet remove → AlertDialog deleteContactConfirm → deleteFamilyContact (soft delete, pickup history stays).
  2b. GuardianSheet: the isPrimary checkbox is ticked and disabled on the current primary guardian and starts unticked on the others (30 §4.3 Overview, R-39).
  3. Wire the edit/add buttons in FamilyOverviewTab; invalidate ['admin','family',familyId]; family_restricted shows t.errors.family_restricted.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-12 · Family page: Packages & payments tab and Class history tab

- **agent_name:** `cl-p3-family-packages-history` · **phase:** P3 · **batch:** 8
- **depends_on:** P3-11, P3-05, P3-06
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 'แพ็กเกจและการชำระเงิน' and 'ประวัติการเรียน' bullets
  - docs/backend/30-ui.md §4.3 '/admin/payments' (row actions, record dialog fields)
  - docs/backend/00-overview.md D16 (no invented expiry rules)
- **creates:** `src/components/admin/family/FamilyPackagesTab.tsx`, `src/components/admin/family/FamilyHistoryTab.tsx`, `src/components/admin/payments/RecordPaymentDialog.tsx`
- **modifies:** `src/routes/admin/_staff/families/$familyId.tsx`
- **steps:**
  1. FamilyPackagesTab: packages with balance(left, total), dates, status; 'เพิ่มแพ็กเกจ' (price read-only from PRICES); per package Close (staff) and, owner only, Void + expiry date → updatePackagePurchase; this family's payments; 'บันทึกการชำระเงิน' opens RecordPaymentDialog.
  2. RecordPaymentDialog (reused by /admin/payments in P3-15): payments.form.* fields incl. optional note, noBankDetails hint → recordPayment.
  3. FamilyHistoryTab: last 50 bookings: date · child · status · in/out · picked up by.
  4. Add both tabs to the route's Tabs.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-13 · Roster /admin/sessions/$sessionId (check-in/out, pickup, add booking) + cancel warning

- **agent_name:** `cl-p3-roster` · **phase:** P3 · **batch:** 5
- **depends_on:** P3-07, P3-06, P2-04, P3-03
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/sessions/$sessionId' (P3 parts only: no allergy cell, no photo badge)
  - docs/backend/30-ui.md §4.3 '/admin/sessions' (date link, booked column, cancel AlertDialog)
  - docs/backend/00-overview.md R-22, R-23
- **creates:** `src/routes/admin/_staff/sessions/$sessionId.tsx`, `src/components/admin/roster/PickupDialog.tsx`, `src/components/admin/roster/AddBookingDialog.tsx`
- **modifies:** `src/routes/admin/_staff/sessions/index.tsx`
- **steps:**
  1. Roster route createFileRoute("/admin/_staff/sessions/$sessionId"): header summary(booked, seatsLeft); rows: child, family link, status, in/out, actions check_in / check_out (PickupDialog: guardians + ACTIVE authorised contacts, required) / mark_absent / cancel.
  2. AddBookingDialog: family search (listFamilies), child, package with left(n) or noPackage, held/confirmed → createBooking; map session_full, no_credit_left, already_booked.
  3. sessions/index.tsx: date links to the roster, booked column, and choosing status 'cancelled' with booked > 0 opens AlertDialog sessions.cancelWarning(n) before saveSession.
  4. Leave clear placeholders (comments) where P4-16 adds the allergy cell and photo badge.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-ui-a11y-checker: cards on phones, actions ≥ 44 px

#### P3-14 · Convert an inbox request into a family (one SQL call)

- **agent_name:** `cl-p3-convert-request` · **phase:** P3 · **batch:** 6
- **depends_on:** P3-04, P2-05
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/inbox/$requestId' P3 bullet (convertDialog)
  - docs/backend/20-server-api.md §14.1 (convertedFamilyId)
  - docs/backend/20-server-api.md §9.5 CreateFamilyFromRequestInput (guardian phone/lineId with contact_required) and row createFamilyFromRequest
  - docs/backend/30-ui.md §5 reference block member request.convertDialog (incl. guardianPhone, guardianLineId, contactNeeded; card P1-12 already created these keys)
- **creates:** `src/components/admin/inbox/ConvertDialog.tsx`
- **modifies:** `src/routes/admin/_staff/inbox/$requestId.tsx`, `src/lib/backend/inbox.functions.ts`
- **steps:**
  1. inbox.functions.ts getBookingRequest: fill convertedFamilyId from booking_requests.converted_family_id.
  2. ConvertDialog: prefilled family name (guardian name), guardian phone and LINE ID (editable) and each child's nickname (required here) and ageYears from the request. When the request has neither a phone nor a LINE ID (a LINE-path request, D26), show convertDialog.contactNeeded above the two fields; zod contact_required keeps the dialog from submitting until one is filled (R-38). Staff confirm → createFamilyFromRequest → invalidate inbox + families → navigate to the family page.
  3. Detail page: show the convert button when not converted; when converted show the convertedTo link instead.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-15 · /admin/payments screen, slip upload, nav tab, dashboard card

- **agent_name:** `cl-p3-payments-screen` · **phase:** P3 · **batch:** 9
- **depends_on:** P3-12, P3-09
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/payments'
  - docs/backend/30-ui.md §4.3 '/admin dashboard' (pendingPayments)
  - docs/backend/40-integrations.md §8.1
- **creates:** `src/routes/admin/_staff/payments.tsx`, `src/components/admin/payments/SlipUploadButton.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. Route createFileRoute("/admin/_staff/payments"): tabs pending / paid_this_month; actions mark paid, view slip (getSlipUrl, open in new tab, never stored), attach slip (SlipUploadButton: accept image/jpeg,image/png,image/webp,application/pdf, ≤ 5 MB checked in the browser, FormData → uploadPaymentSlip), owner-only void/refund and delete slip (payments.deleteSlipConfirm → deletePaymentSlip); record via RecordPaymentDialog.
  2. AdminShell: add { to: "/admin/payments", key: "payments", Icon: CreditCard } to TABS. Dashboard: pendingPayments(n) card.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P3-16 · Privacy notice …-v2: add every [P3] section and row

- **agent_name:** `cl-p3-privacy-notice-v2` · **phase:** P3 · **batch:** 2
- **depends_on:** P1-02, P1-10, P3-01
- **human_gate:** AFTER: owner approves …-v2 (G9a) before Stage B goes live (card P5-06).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.4 (id/phase table)
  - docs/backend/50-security-privacy.md §11.1, §11.3, §11.4 ([P3] items)
  - docs/backend/00-overview.md §12 (retention)
- **creates:** —
- **modifies:** `src/content/privacy.tsx`
- **steps:**
  1. Insert sections family-records and contacts (phase "P3") after 'chat', TH and EN, from 50 §§11.3/11.4.
  2. Add the [P3] rows to the 'sharing' and 'retention' tables and nothing tagged [P4]/[P5]/[P6].
  3. Bump PRIVACY_NOTICE_VERSION to '`<YYYY-MM>`-v2' (month it goes live) and update the `updated` lines; set draftBanner back to the draft text until G9a.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-privacy-checker: every [P3] item of 50 §11.3 present, nothing [P4]
  - grep -c 'phase: "P3"' src/content/privacy.tsx = 4

#### P3-17 · Review SQL 0005_consent_health.sql, then G4 (whole file in Stage B, P4 screens later)

- **agent_name:** `cl-p3-sql-0005` · **phase:** P3 · **batch:** 2
- **depends_on:** P3-01
- **human_gate:** BEFORE: owner answers G0 Q15 (what the 4 class clips' consent covered) so media_assets.legacy_consent_purposes in the seed is right; the builder edits only that seed line in the UNAPPLIED draft if needed. AFTER review: builder G4 applies the WHOLE 0005 file (tables and every function, incl. submit_enrolment), git pull, types.ts contains consent_records, child_health and submit_enrolment (args p_link_id, p), rls_smoke.sql no FAIL. Only the P4 screens stay off until Stage C.
- **reads:**
  - docs/backend/10-data-model.md §§6.16–6.20, 7–11, 13
  - docs/backend/sql/0005_consent_health.sql
  - docs/backend/sql/tests/rls_smoke.sql
  - docs/backend/00-overview.md D10–D13, D29, D30, R-05, R-06, R-07, R-11, R-15, R-18, R-20, R-33, R-34, R-35
  - docs/backend/sql/seed_dev.sql § 6 (R-35 check) and § 7b (behaviour checks for this file)
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist on 0005. Also check: consent_records append-only except inside purge/erase; child_health has no table grants to authenticated and is read only via get_child_health / list_session_health_flags (both audit); the health trigger blocks writes without a current guardian health_allergy grant; queue_consent_change_alert fires for any move away from granted (guardian or child, any channel); submit_enrolment locks family_links FOR UPDATE and is service-role only; in submit_enrolment an unticked media box records 'refused' only when the guardian has no earlier decision, else nothing (R-33), and a health 'granted' after the child's own latest health 'no' raises 23514 before any write (R-34); publish_consent_text refuses the first health_allergy text (R-35); has_active_consent is not executable by authenticated; can_publish_media for a youtube asset on media_website also needs media_youtube; legacy-only assets are never 'needs takedown'; seed_dev.sql § 7b has a check for each of these.
  2. Check rls_smoke.sql covers the new tables, bucket and functions; list gaps. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P3-18 · Review SQL 0007_privacy_ops.sql, then G4

- **agent_name:** `cl-p3-sql-0007` · **phase:** P3 · **batch:** 3
- **depends_on:** P3-17
- **human_gate:** AFTER review: builder G4 applies 0007, git pull, types.ts contains dsr_requests and processing_restricted_at, rls_smoke.sql no FAIL; Cloud → Jobs shows the purge job (now v4).
- **reads:**
  - docs/backend/10-data-model.md §§6.21–6.22, 8, 13
  - docs/backend/sql/0007_privacy_ops.sql
  - docs/backend/sql/tests/rls_smoke.sql
  - docs/backend/00-overview.md D28, R-09, R-10, R-25, R-36, R-37
  - docs/backend/50-security-privacy.md §§18.3–18.4, 19
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist on 0007. Also check: set_family_restriction is the only way to change restriction columns; restricted families are blocked from new bookings, links, granted consents and profile edits, including the family row itself (families_block_restricted, R-36) and edits of inactive contacts, but withdrawals and a plain contact removal (is_active true → false) still work; FK set-null columns (identity_checked_by, created_by, source_request_id) never block staff offboarding or the purge; mark_inactive_families skips restricted families; erase_family keeps anonymised payments and does not queue slips/evidence; purge v4 increments sessions_used_purged before deleting credit bookings; seed_dev.sql § 7b.8 checks the restriction rules and the R-37 lift → correct → restrict sequence.
  2. Check rls_smoke.sql covers the new tables and functions; list gaps. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

### Stage B · P5 core privacy operations

#### P5-01 · privacy.schema.ts + privacy.functions.ts core (export, erase, restrict, files to delete)

- **agent_name:** `cl-p5-privacy-functions` · **phase:** P5 · **batch:** 1
- **depends_on:** P3-18, P0-16, P0-17, P0-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.13 (✅ (rev) privacy.schema.ts core types; 📝 table rows exportFamilyData, eraseFamily, setFamilyRestriction, listStorageCleanup, runStorageCleanup)
  - docs/backend/20-server-api.md §14.8 (CleanupRow)
  - docs/backend/50-security-privacy.md §§18.3–18.4, 19.4
- **creates:** `src/lib/backend/privacy.schema.ts`, `src/lib/backend/privacy.functions.ts`, `src/lib/backend/privacy.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the core part of the ✅ (rev) schema; add CleanupRow from §14.8. Do NOT add the parked DSR/breach/audit types or functions (PK-01).
  2. All five functions use requireOwner. exportFamilyData returns the jsonb for download only (never stored or logged). eraseFamily checks confirmText against display_name (trim) → confirm_mismatch, then rpc erase_family. setFamilyRestriction → rpc set_family_restriction (P0002 → not_found). runStorageCleanup removes up to `limit` (≤ 50) queued files through supabaseAdmin.storage and records deleted_at or a short last_error code; never logs paths with names.
  3. Tests: SetFamilyRestrictionInput note ≤ DB_LIMITS.restrictionNote; RunStorageCleanupInput limit ≤ 50; EraseFamilyInput requires confirmText.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/privacy.schema.test.ts: all pass

#### P5-02 · Admin copy module: privacy (owner card + files to delete)

- **agent_name:** `cl-p5-admin-copy-privacy` · **phase:** P5 · **batch:** 1
- **depends_on:** P3-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern
  - docs/backend/30-ui.md §5 reference member privacy (type L4594–4666; th L5344–5442; en L6169–6262)
  - docs/backend/30-ui.md §5.1 rows 'privacy · …'
- **creates:** `src/content/admin/privacy.tsx`
- **modifies:** `src/content/admin/index.ts`
- **steps:**
  1. Create privacy.tsx (type AdminPrivacy = { privacy }) with TH and EN, including the parked dsr/breach/audit keys (they are part of the reference type) and every §5.1 privacy key.
  2. Add it to index.ts.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity; restrictNoteLabel says no health details

#### P5-03 · Owner privacy card on the family page + restriction banner

- **agent_name:** `cl-p5-family-privacy-card` · **phase:** P5 · **batch:** 2
- **depends_on:** P5-01, P5-02, P3-12, P3-04
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/families/$familyId' (banners: restrictedBanner; owner card)
  - docs/backend/20-server-api.md §14.4 (restriction fields filled by P5-03)
  - docs/backend/00-overview.md D28
- **creates:** `src/components/admin/family/FamilyPrivacyCard.tsx`
- **modifies:** `src/lib/backend/families.functions.ts`, `src/components/admin/family/FamilyBanners.tsx`, `src/routes/admin/_staff/families/$familyId.tsx`
- **steps:**
  1. families.functions.ts getFamily: select processing_restricted_at and restriction_note and fill the FamilyDetail fields.
  2. FamilyBanners: red-bordered restrictedBanner(date, note) with text (not colour only) when processingRestrictedAt is set.
  3. FamilyPrivacyCard (only when me.role === 'owner'): export JSON (Blob download family-export-YYYY-MM-DD.json + exportNote), restrict / lift with a note field and AlertDialog restrictConfirm → setFamilyRestriction, erase with AlertDialog and typed family name (button disabled until exact) → eraseFamily → navigate to /admin/families + toast erasedThenFiles.
  4. Mount the card in the route (Overview tab, below the cards).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Preview with a fake family (human): restrict blocks a new booking with the family_restricted message; lift restores it

#### P5-04 · /admin/privacy 'Files to delete' tab (owner), nav item, dashboard card

- **agent_name:** `cl-p5-files-to-delete` · **phase:** P5 · **batch:** 2
- **depends_on:** P5-01, P5-02, P3-15
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/privacy' (Stage B ships only the files tab)
  - docs/backend/50-security-privacy.md §19.4
- **creates:** `src/routes/admin/_staff/privacy.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. Route createFileRoute("/admin/_staff/privacy"), owner only: files.lead, listStorageCleanup table (bucket · reason · queued · state), button 'ลบไฟล์ที่รออยู่' → runStorageCleanup → toast files.done(d, f). Do not build the DSR/breach/audit tabs (parked PK-02).
  2. AdminShell: add { to: "/admin/privacy", key: "privacy", ownerOnly: true } to MORE. Dashboard (owner only): filesToDelete(n) when > 0.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P5-05 · Retention, export, erase and restriction check with fake data (human-run)

- **agent_name:** `cl-p5-retention-check` · **phase:** P5 · **batch:** 3
- **depends_on:** P5-03, P5-04
- **human_gate:** Human (builder, SQL editor, owner's OK; fake data only): the 50 §19.5 purge test (backdate created_at AND retain_until), Jobs view shows Succeeded; export/erase/restrict on a fake family; owner MFA availability (F5-06) recorded in 40 §2 row 12.
- **reads:**
  - docs/backend/50-security-privacy.md §§19.2–19.5
  - docs/backend/00-overview.md §8 P5 core acceptance
  - docs/backend/sql/seed_dev.sql (behaviour checks)
- **creates:** —
- **modifies:** —
- **steps:**
  1. Give the builder the step list from 50 §19.5 and 00 §8 P5 acceptance as a checklist; collect results. Include running sql/seed_dev.sql in the SQL editor (it ends in ROLLBACK) and reading its NOTICE lines.
  2. Check: export returns one family only; erase keeps anonymised payment amounts and dates; a restricted family can't get a booking or link, can't be edited (incl. its name and staff note, R-36) and is skipped by mark_inactive_families; the owner can correct disputed data with lift → correct → restrict again (50 §18.4, R-37; seed_dev.sql § 7b.8); used credits stay used after the purge removes old bookings (sessions_used_purged).
  3. Do not run SQL yourself.
- **acceptance:**
  - Every P5 core acceptance line in 00 §8 is checked by the human or listed as open

#### P5-06 · Stage B go-live check (G9a …-v2, G10)

- **agent_name:** `cl-p5-stage-b-golive` · **phase:** P5 · **batch:** 4
- **depends_on:** P3-13, P3-14, P3-15, P3-16, P5-05
- **human_gate:** Human: owner approves …-v2 (G9a), confirms sign-up disabled, rls_smoke.sql no FAIL, fixes critical publish-scan findings, deletes all fake test families, then Publish (G10). Only after this may real family data be entered.
- **reads:**
  - docs/backend/00-overview.md §8.0 Stage B row, §8 P3 acceptance
  - docs/backend/40-integrations.md §13
  - docs/backend/50-security-privacy.md §9
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the standard acceptance on main and cl-privacy-checker over every Stage B file (no PII in logs/URLs/toasts; slips only via 60 s signed URLs; no health fields anywhere yet).
  2. Check privacy.tsx is …-v2 with the P3 sections and draftBanner null.
  3. Produce the 40 §13 checklist with each line done/open from evidence.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Every P3 acceptance line in 00 §8 is checked or listed as open

### Stage C · P4 Consent and safety

#### P4-01 · Review consent wording 0006 (+0006b), then G9b and G4

- **agent_name:** `cl-p4-sql-0006` · **phase:** P4 · **batch:** 1
- **depends_on:** P3-18, P5-06
- **human_gate:** BEFORE: owner decides G-HEALTH (system or paper) and answers G0 Q9 (private parents' group?) and Q17 (OWNER-APPROVE lines); owner + Thai PDPA lawyer review the wording (G9b). If G-HEALTH = paper the builder deletes the two health_allergy rows from the UNAPPLIED 0006 (instructions in its header). AFTER: builder G4 applies 0006 (and 0006b only if Q9 = yes), git pull, rls_smoke.sql no FAIL.
- **reads:**
  - docs/backend/sql/0006_seed_consent_texts.sql
  - docs/backend/sql/0006b_seed_media_parents_group.sql
  - docs/backend/50-security-privacy.md §§12.0–12.4, 13, 14, 15
  - docs/backend/00-overview.md D11, D12, R-24, R-29, §9 G-HEALTH and G9b rows
- **creates:** —
- **modifies:** —
- **steps:**
  1. Review the wording against 50 §12.1 (content checklist): one purpose per text, plain Thai with ค่ะ, no fear wording, no invented facts, 'money game' never used, withdrawal as easy as giving, the 10+ child approach stated, retention stated.
  2. List every OWNER-APPROVE line for the owner; check the file stays valid SQL if the health rows are removed (the last row has no trailing comma).
  3. Do not edit files.
- **acceptance:**
  - Report: wording checklist PASS/FAIL per text, OWNER-APPROVE list, SQL validity note

#### P4-02 · link-tokens.server.ts (32-byte tokens, hash only) with tests

- **agent_name:** `cl-p4-link-tokens` · **phase:** P4 · **batch:** 2
- **depends_on:** P3-17, P0-09, P0-16, P4-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.7 (✅ link-tokens.server.ts + tests)
  - docs/backend/00-overview.md D13 (enrol 14 days single use; manage 90 days)
- **creates:** `src/server/link-tokens.server.ts`, `src/server/link-tokens.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ blocks from 20 §7.7. Only the sha256 hash is stored; the raw token is returned once to staff and never logged.
  2. Manage links expire after 90 days (R-21); enrol links after 14 days and single use.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/link-tokens.server.test.ts: all pass

#### P4-03 · staff-notify: consent_withdrawn branch + deliverAlertIds / deliverConsentAlert

- **agent_name:** `cl-p4-consent-alerts` · **phase:** P4 · **batch:** 2
- **depends_on:** P3-17, P2-05, P4-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §7.8 (✅ consent_withdrawn branch in loadAlertInput; ✅ (rev) deliver helpers; tests marked (P4-03))
  - docs/backend/00-overview.md D29
- **creates:** —
- **modifies:** `src/server/staff-notify.server.ts`, `src/server/staff-notify.server.test.ts`
- **steps:**
  1. Replace the Stage A `throw new Error("kind_not_ready")` with the consent_withdrawn branch exactly as in the ✅ block (alert text says only the purpose and the admin link: no names, no health details).
  2. Append deliverAlertIds and deliverConsentAlert (✅ (rev) block). Server code never inserts consent_withdrawn rows: the database trigger queues them.
  3. Add the two (P4-03) tests: deliverAlertIds([]) makes no query; it skips sent rows and pushes at most 5.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/staff-notify.server.test.ts: all pass

#### P4-04 · enrolment.schema.ts and consent-texts.server.ts with tests

- **agent_name:** `cl-p4-enrolment-schema` · **phase:** P4 · **batch:** 3
- **depends_on:** P3-17, P0-04, P0-05, P0-06, P0-16, P4-01, P4-07
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.8 (✅ (rev) enrolment.schema.ts; enrolment.schema tests in 'Tests to write')
  - docs/backend/20-server-api.md §7.9 (✅ consent-texts.server.ts)
  - docs/backend/00-overview.md R-06, R-07
- **creates:** `src/lib/backend/enrolment.schema.ts`, `src/lib/backend/enrolment.schema.test.ts`, `src/server/consent-texts.server.ts`, `src/server/consent-texts.server.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) enrolment.schema.ts block (media is a list of only the purposes shown; health decision skipped | refused | granted; EnrolmentForm children carry currentMedia and childRefusedHealth, type CurrentMediaDecision, R-33/R-34). It imports ALLERGENS from ./health.schema, created by P4-07 (a dependency).
  2. Copy the ✅ consent-texts.server.ts block.
  3. enrolment.schema.test.ts (this card owns it; P4-06 does not): only media_website + media_youtube entries pass; a media switch on without mediaLevel fails; toSubmitEnrolmentPayload maps skipped health to { decision: 'skipped' }; boundary tests for otherAllergens, foodsToAvoid, careNotes vs DB_LIMITS.
  4. consent-texts.server.test.ts (mock ./supabase-admin.server): loadCurrentConsentTexts returns null for a purpose with no row and the highest version otherwise; areCurrentConsentTexts is false for a retired id.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/enrolment.schema.test.ts src/server/consent-texts.server.test.ts: all pass

#### P4-05 · enrolment.functions.ts: getEnrolmentForm, createEnrolmentLink, revokeFamilyLink

- **agent_name:** `cl-p4-enrolment-functions` · **phase:** P4 · **batch:** 4
- **depends_on:** P4-02, P4-04, P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.8 (✅ (rev) enrolment.functions.ts block and the bullets under it)
  - docs/backend/20-server-api.md §7.7 (resolveLinkToken, newLinkToken) and §4 (adminErrorFromDb)
  - docs/backend/sql/0005_consent_health.sql consent_matrix (columns it returns)
  - docs/backend/00-overview.md D13, D28, R-33, R-34
- **creates:** `src/lib/backend/enrolment.functions.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) block but leave out the submitEnrolment export and the handleSubmitEnrolment import (card P4-06 adds them). Keep the `type SubmitEnrolmentRaw` import from ./enrolment.schema (unused until P4-06; noUnusedLocals is off).
  2. Token functions are POST with the token in the body, return PublicResult, and query only rows of the resolved family. getEnrolmentForm makes ONE rpc('consent_matrix') for the family's children and fills currentMedia and childRefusedHealth (R-33/R-34). createEnrolmentLink returns the URL once; its insert error goes through adminErrorFromDb, so a restricted family → family_restricted.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - The README leak grep, run unchanged (it already lists resolveLinkToken), prints nothing

#### P4-06 · enrolment-submit.server.ts (one SQL call) + submitEnrolment

- **agent_name:** `cl-p4-enrolment-submit` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-05, P4-03, P4-07
- **human_gate:** BEFORE: G4 · 0005 marked done in 90 §2 (the whole 0005 file applied exactly as written, then git pull --ff-only), and the Stage C gates P4-01 needs (G-HEALTH, G9b, G4 · 0006) are recorded. Read-only check first: src/integrations/supabase/types.ts lists the function submit_enrolment with args p_link_id and p; if not, stop and report "types not regenerated".
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §4 (PublicErrorCode, fail, ok)
  - docs/backend/20-server-api.md §7.7 (resolveLinkToken and its LinkResolution shape), §7.8 (deliverAlertIds, notifyStaff, NotifyOutcome), §7.9 (areCurrentConsentTexts)
  - docs/backend/20-server-api.md §8.8 (PersonName, Uuid, IsoMonth, ThaiPhoneSchema limits for the fixture)
  - docs/backend/20-server-api.md §9.0 (errors: 22023/23514 → invalid_input; strict-TS test rules)
  - docs/backend/20-server-api.md §9.8 (✅ (rev) enrolment-submit.server.ts, the enrolment.functions.ts block, 'Key behaviours', 'Tests to write' first bullet incl. the fixture)
  - docs/backend/sql/0005_consent_health.sql submit_enrolment
  - docs/backend/00-overview.md D30, R-05, R-21, R-33, R-34
- **creates:** `src/server/enrolment-submit.server.ts`, `src/server/enrolment-submit.server.test.ts`
- **modifies:** `src/lib/backend/enrolment.functions.ts`
- **steps:**
  1. Copy the ✅ (rev) handler block: resolve token → check texts are current → ONE rpc('submit_enrolment', { p_link_id, p }) → deliverAlertIds(returned alert ids) → notifyStaff('enrolment_submitted', familyId).
  2. Add the submitEnrolment export and the handleSubmitEnrolment import to enrolment.functions.ts exactly as in the ✅ block; make sure `type SubmitEnrolmentRaw` is imported from ./enrolment.schema there (the validator uses it).
  3. Write the handler tests only (20 §9.8 'Tests to write', first bullet): expired link → link_expired and no RPC; SQL link_used → link_used; SQL 22023 → invalid_input; SQL 23514 → invalid_input; success → deliverAlertIds with the returned ids, then notifyStaff('enrolment_submitted', familyId); text not current → invalid_input and no RPC. Use the fixture given there (fake values only). The enrolment.schema tests belong to P4-04: do not write them here.
  4. Under noUncheckedIndexedAccess read mock calls as `mock.calls.at(0)?.[0]`; under exactOptionalPropertyTypes never write `key: undefined` in fixtures.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/server/enrolment-submit.server.test.ts: all pass
  - The README leak grep, run unchanged (it already lists handleSubmitEnrolment), prints nothing

#### P4-07 · health.schema.ts + health.functions.ts (audited) + HEALTH_IN_SYSTEM

- **agent_name:** `cl-p4-health-functions` · **phase:** P4 · **batch:** 2
- **depends_on:** P3-17, P0-17, P0-08, P4-01
- **human_gate:** AFTER (G-HEALTH): if the owner chose 'system', the builder changes HEALTH_IN_SYSTEM to true in a separate commit before Stage C goes live.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.10 (✅ (rev) health.schema.ts + healthRosterState test; ✅ (rev) health.functions.ts)
  - docs/backend/20-server-api.md §8.7 📝 HEALTH_IN_SYSTEM block
  - docs/backend/00-overview.md D10, R-07, R-29
- **creates:** `src/lib/backend/health.schema.ts`, `src/lib/backend/health.schema.test.ts`, `src/lib/backend/health.functions.ts`
- **modifies:** `src/lib/backend/public-config.ts`
- **steps:**
  1. Copy the ✅ (rev) blocks. Health is read ONLY through rpc get_child_health (POST, one audit row per call) and list_session_health_flags, written only through upsert_child_health; never .from('child_health').
  2. Test healthRosterState: no record → 'no_info'; record with allergens → 'allergies'; record with none reported → 'reported_none'.
  3. Append the HEALTH_IN_SYSTEM block from 20 §8.7 to public-config.ts with value false.
  4. 42501 from upsert_child_health → consent_required.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/health.schema.test.ts: all pass
  - grep -rn "from(\"child_health\")" src returns nothing

#### P4-08 · enrol.tsx copy, ConsentTextBody and HealthSection (+ test)

- **agent_name:** `cl-p4-enrol-copy-health` · **phase:** P4 · **batch:** 4
- **depends_on:** P4-04, P4-07, P1-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.5 (✅ enrol.tsx, ✅ ConsentTextBody.tsx, ✅ (rev) HealthSection.tsx, ✅ HealthSection.test.tsx)
  - docs/backend/50-security-privacy.md §12.3 (UI-only copy), §13 (consent mechanics)
- **creates:** `src/content/enrol.tsx`, `src/components/enrol/ConsentTextBody.tsx`, `src/components/enrol/HealthSection.tsx`, `src/components/enrol/HealthSection.test.tsx`
- **modifies:** —
- **steps:**
  1. Copy the four ✅ blocks from 30 §3.5 (enrol.tsx incl. health.childRefusedNote and media.currentGranted / currentNotGranted / keepNote, R-33/R-34; HealthSection with the optional childRefused prop; its test incl. the R-34 case). ConsentTextBody renders stored wording as text, never as HTML.
  2. HealthSection: the checkbox label is the consent text title and the full body is shown directly above it; never pre-ticked; 'Not now' records nothing (skipped); 'I don't want to share this' records refused with the declineNote; childRefused shows only childRefusedNote (no box).
  3. The new copy lines marked OWNER-APPROVE (childRefusedNote, keepNote) are approved at G9b/G0 Q17 with the rest of the enrol page: copy them unchanged and list them in your report.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/enrol/HealthSection.test.tsx: all pass
  - cl-i18n-checker and cl-privacy-checker pass

#### P4-09 · MediaSection: one block per published purpose, full text visible (+ test)

- **agent_name:** `cl-p4-media-section` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.5 Media bullet and 📝 MediaSection spec
  - docs/backend/30-ui.md §6 (consent controls checklist)
  - docs/backend/00-overview.md R-04, R-06, R-33
  - docs/backend/20-server-api.md §9.8 (CurrentMediaDecision, EnrolmentForm.children[].currentMedia)
  - docs/backend/20-server-api.md §8.5 (formatDateTime)
- **creates:** `src/components/enrol/MediaSection.tsx`, `src/components/enrol/MediaSection.test.tsx`
- **modifies:** —
- **steps:**
  1. Build MediaSection exactly as the 📝 spec: for each purpose in MEDIA_PURPOSES that has a text: bordered block, `<h4>`{title}`</h4>`, `<ConsentTextBody/>`, the current-decision line when `current[p]` exists, then an unticked Checkbox labelled media.agree (checked={value.on[p] === true}, never defaultChecked, never pre-ticked from `current`), then media.keepNote when `current[p]` exists (R-33). No Collapsible, no 'read more'. Face-level RadioGroup (no default) only when a box is ticked.
  2. Tests: every checkbox starts unchecked, also when current says granted; every published purpose's body is visible (toBeVisible); a purpose without a text renders nothing; ticking one shows the face question with nothing selected; a decided purpose shows its status line and keepNote.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/enrol/MediaSection.test.tsx: all pass

#### P4-10 · GuardianSection and ContactsSection for /enrol

- **agent_name:** `cl-p4-enrol-sections` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.5 page order steps 1 and 3
  - docs/backend/30-ui.md §1.3 (form pattern)
  - docs/backend/00-overview.md §6 stage 3, R-21, R-22
- **creates:** `src/components/enrol/GuardianSection.tsx`, `src/components/enrol/ContactsSection.tsx`
- **modifies:** —
- **steps:**
  1. GuardianSection (react-hook-form fields under a parent form): full name, phone, LINE ID (at least one), optional email (hint: receipts only), required unticked checkbox confirmsParentalResponsibility.
  2. ContactsSection: useFieldArray 0–4 contacts (name, phone, relationship, roles emergency/may collect with at least one = role_required, required 'I've told them' checkbox = informed_required), prefilled from existing contacts keeping their id; noIdNote under the heading.
  3. Copy keys come from enrolContent; no hard-coded strings.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-ui-a11y-checker passes 30 §6

#### P4-11 · consent.schema.ts + consent.functions.ts (staff consent recording, evidence)

- **agent_name:** `cl-p4-consent-functions` · **phase:** P4 · **batch:** 3
- **depends_on:** P3-17, P4-03, P3-02, P0-06
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.9 (✅ (rev) consent.schema.ts; 📝 rows listChildConsents, recordStaffConsent, uploadConsentEvidence, getConsentEvidenceUrl)
  - docs/backend/20-server-api.md §14.6 (ConsentHistoryRow, ChildConsents, recordStaffConsent skeleton)
  - docs/backend/00-overview.md D11, D29
- **creates:** `src/lib/backend/consent.schema.ts`, `src/lib/backend/consent.functions.ts`, `src/lib/backend/consent.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ (rev) schema; add §14.6 types (ConsentCell is imported from families.schema.ts).
  2. Add the four staff functions per §9.9 and the §14.6 skeleton: listChildConsents = ONE rpc consent_matrix + last 50 records; recordStaffConsent inserts one consent_records row then calls deliverConsentAlert(recordId); evidence upload ≤ 5 MB to the private consent-evidence bucket; signed URL 60 s.
  3. Do not add the parked owner functions (listConsentTexts, publishConsentText, retireConsentText: PK-03).
  4. Tests: RecordStaffConsentInput requires mediaLevel for a guardian media grant but not for given_by child (matches SQL); text limits vs DB_LIMITS.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/consent.schema.test.ts: all pass

#### P4-12 · media.schema.ts + media.functions.ts (publishability matrix, takedown)

- **agent_name:** `cl-p4-media-functions` · **phase:** P4 · **batch:** 2
- **depends_on:** P3-17, P0-17, P4-01
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.11 (✅ media.schema.ts; 📝 rows)
  - docs/backend/20-server-api.md §14.7 (MediaAssetRow, ChannelState, mediaChannelState, needsTakedown)
  - docs/backend/00-overview.md D24, R-11
- **creates:** `src/lib/backend/media.schema.ts`, `src/lib/backend/media.functions.ts`, `src/lib/backend/media.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ schema and add the §14.7 types and helpers.
  2. listMediaAssets: three calls, no loops (assets, asset-children with nicknames, ONE rpc media_publishability). saveMediaAsset never writes legacy_consent_purposes. setMediaAssetChildren = ONE rpc set_media_asset_children. markMediaTakenDown sets taken_down + all on_* false.
  3. Tests: a legacy-only asset with no linked children is 'check_manually', never needsTakedown; a youtube asset on the website needs media_youtube too.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/media.schema.test.ts: all pass

#### P4-13 · my.schema.ts + my.functions.ts (getMyConsents, updateMyConsent, createManageLink)

- **agent_name:** `cl-p4-my-functions` · **phase:** P4 · **batch:** 4
- **depends_on:** P4-02, P4-03, P4-04, P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.12 (✅ (rev) my.schema.ts, ✅ (rev) my.functions.ts)
  - docs/backend/00-overview.md R-27 (all children, inactive labelled), D29
- **creates:** `src/lib/backend/my.schema.ts`, `src/lib/backend/my.functions.ts`, `src/lib/backend/my.schema.test.ts`
- **modifies:** —
- **steps:**
  1. Copy both ✅ (rev) blocks. getMyConsents loads EVERY child of the family (isActive flag), one consent_matrix call. updateMyConsent inserts one record then deliverConsentAlert. Manage links last 90 days.
  2. Tests: UpdateMyConsentInput needs mediaLevel when granting media; decision 'withdrawn' needs no text id if the schema says so.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/lib/backend/my.schema.test.ts: all pass

#### P4-14 · EnrolPage and the /enrol/$token route (noindex, no-referrer)

- **agent_name:** `cl-p4-enrol-page` · **phase:** P4 · **batch:** 6
- **depends_on:** P4-05, P4-06, P4-09, P4-10
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.5 (route block, states, page order, submit mapping)
  - docs/backend/30-ui.md §6 checklist
  - docs/backend/50-security-privacy.md §13
- **creates:** `src/components/enrol/EnrolPage.tsx`, `src/components/enrol/EnrolPage.test.tsx`, `src/routes/enrol.$token.tsx`
- **modifies:** —
- **steps:**
  1. Route: copy the ✅ part (ssr false, robots noindex nofollow, referrer no-referrer, ?lang); component wraps `<LanguageProvider initialLang={lang}><EnrolPage token={token} /></LanguageProvider>`.
  2. EnrolPage: getEnrolmentForm on mount into component state (not React Query); refetch on language change; states loading → link problem card (with LINE button) → form → submitting → done (focus heading, no data shown back). Steps: GuardianSection; per child birth month/year selects + HealthSection (only when a health text exists; pass childRefused={child.childRefusedHealth}, R-34) + MediaSection (pass current={child.currentMedia}, R-33); ContactsSection; review & send with /privacy link. Submit mapping exactly as 30 §3.5.
  3. EnrolPage.test.tsx (mock the server functions): no checkbox is checked on first render, also for a child whose mock currentMedia says granted; every consent text body returned by the mock is visible; with no health text the health section is absent; with childRefusedHealth true that child has no health checkbox.
  4. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/enrol/EnrolPage.test.tsx: all pass
  - cl-privacy-checker: nothing personal in the URL or logs; token not in any query key

#### P4-15 · Admin copy modules: health, consents (+ child script), media

- **agent_name:** `cl-p4-admin-copy-consent` · **phase:** P4 · **batch:** 2
- **depends_on:** P5-02, P4-01
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §5 module table + pattern
  - docs/backend/30-ui.md §5 reference members health (type L4405–4418; th L5099–5112; en L5919–5932), consents and childScript (type L4511–4548; th L5248–5291; en L6071–6116), media (type L4549–4579; th L5292–5329; en L6117–6154)
  - docs/backend/30-ui.md §5.1 rows 'health · …'
  - docs/backend/30-ui.md §4.4 (child consent script)
- **creates:** `src/content/admin/health.tsx`, `src/content/admin/consents.tsx`, `src/content/admin/media.tsx`
- **modifies:** `src/content/admin/index.ts`
- **steps:**
  1. Create the three modules (AdminHealth = { health }, AdminConsents = { consents; childScript }, AdminMedia = { media }) with TH and EN, plus the §5.1 health keys (noInfo, reportedNone(date), removedOn(date), paperForm).
  2. Add all three to index.ts.
  3. The child script keeps 'no is always fine' and never asks about channels the guardian did not allow.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-i18n-checker: TH/EN parity; Thai kid-friendly lines kept

#### P4-16 · Roster: allergy cell (three states), audited health dialog, photo badge

- **agent_name:** `cl-p4-roster-health` · **phase:** P4 · **batch:** 3
- **depends_on:** P4-07, P4-15, P3-13, P3-07
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 roster (allergy cell, health dialog, photo badge)
  - docs/backend/20-server-api.md §14.3 step 4 (consent_matrix for media_parents_group)
  - docs/backend/00-overview.md D10, R-07, R-29
- **creates:** `src/components/admin/roster/HealthCell.tsx`, `src/components/admin/roster/HealthCell.test.tsx`, `src/components/admin/roster/HealthDialog.tsx`
- **modifies:** `src/routes/admin/_staff/sessions/$sessionId.tsx`, `src/lib/backend/sessions.functions.ts`
- **steps:**
  1. sessions.functions.ts getSessionRoster: add ONE rpc consent_matrix for the roster's children and fill photoStatus from purpose media_parents_group.
  2. HealthCell: state from healthRosterState(flag): allergies → one Badge per allergen + '+ other' + notes marker; reported_none → health.reportedNone(date); no_info (the default, also when no flag) → warning badge WITH text health.noInfo + health.removedOn(date) when allergyCheckNeededAt is set. If HEALTH_IN_SYSTEM is false show health.paperForm and no buttons.
  3. HealthDialog: opens on press only, calls getChildHealth (POST, audited) only then, drops the data on close; edit uses saveChildHealth; consent_required → health.noConsent.
  4. Roster route: getSessionHealthFlags once per session, render HealthCell and the photo badge.
  5. HealthCell.test.tsx: render each state with the admin copy and assert the visible text (never 'no allergies' unless reported_none).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/admin/roster/HealthCell.test.tsx: the three states render the right copy; no flag → health.noInfo text; HEALTH_IN_SYSTEM false → health.paperForm

#### P4-17 · Family page: parent links tab and consent chips (getFamily P4 fields)

- **agent_name:** `cl-p4-family-links` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-05, P4-11, P4-13, P4-15, P5-03
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 family page 'ลิงก์สำหรับผู้ปกครอง' bullet and Overview consent chips
  - docs/backend/20-server-api.md §14.4 (P4-17 adds family_links, never token_hash, + one consent_matrix call)
- **creates:** `src/components/admin/family/FamilyLinksTab.tsx`
- **modifies:** `src/lib/backend/families.functions.ts`, `src/components/admin/family/FamilyOverviewTab.tsx`, `src/routes/admin/_staff/families/$familyId.tsx`
- **steps:**
  1. getFamily: add family_links (id, purpose, expires_at, used_at, revoked_at, created_at; NEVER token_hash) and ONE rpc consent_matrix for the family's children → links and consent cells.
  2. FamilyLinksTab: enrol link card (create → Dialog showing the URL once with Copy and createdLead; list with linkState + expires(date) + revoke with confirm) and manage link card (createManageLink, 90 days). Create buttons disabled with family.restrictedShort while restricted.
  3. FamilyOverviewTab: consent status chips per purpose on each child card; allergyRemoved(date) when allergyCheckNeededAt is set.
  4. Add the Links tab to the route.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P4-18 · Family page: Consents tab, record dialog, child script

- **agent_name:** `cl-p4-family-consents` · **phase:** P4 · **batch:** 6
- **depends_on:** P4-17
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 family page 'ความยินยอม' bullet
  - docs/backend/30-ui.md §4.4 (child script)
  - docs/backend/20-server-api.md §14.6
- **creates:** `src/components/admin/family/FamilyConsentsTab.tsx`, `src/components/admin/family/RecordConsentDialog.tsx`
- **modifies:** `src/routes/admin/_staff/families/$familyId.tsx`
- **steps:**
  1. FamilyConsentsTab: per child a matrix (5 purposes × guardian / child (only when needsChildConsent) / status) and history (decision, channel, method, text version, recorded by, evidence link → getConsentEvidenceUrl).
  2. RecordConsentDialog: consents.form.*; optional evidence upload first (uploadConsentEvidence); givenBy child fixes channel in_person and shows the child script in a Collapsible ABOVE the form (staff aid, not consent text). responsibility_required points staff to the guardian sheet.
  3. Add the Consents tab to the route.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-privacy-checker: no consent control pre-ticked

#### P4-19 · Unsent enrolment/consent alerts: listPendingStaffAlerts + dashboard list

- **agent_name:** `cl-p4-pending-alerts` · **phase:** P4 · **batch:** 3
- **depends_on:** P4-03, P4-15, P5-04, P2-05, P3-14
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.3 📝 listPendingStaffAlerts
  - docs/backend/30-ui.md §4.3 dashboard 'Alerts not sent' paragraph
  - docs/backend/30-ui.md §5.1 core rows labels.notificationKind and dashboard.alertsTitle/openFamily/resend
- **creates:** —
- **modifies:** `src/lib/backend/inbox.schema.ts`, `src/lib/backend/inbox.functions.ts`, `src/content/admin/core.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. inbox.schema.ts: add PendingAlert type. inbox.functions.ts: add listPendingStaffAlerts exactly as specified (two queries, no loops).
  2. core.tsx: add labels.notificationKind and dashboard.alertsTitle / openFamily / resend in the type, th and en.
  3. Dashboard: consentAlerts(n) card + the 'Alerts not sent' list with Open family link and Resend (retryStaffNotification; invalidate ['admin','alerts']).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P4-20 · Privacy notice …-v3: [P4] sections and the /my sentence

- **agent_name:** `cl-p4-privacy-notice-v3` · **phase:** P4 · **batch:** 2
- **depends_on:** P3-16, P4-01
- **human_gate:** AFTER: owner approves …-v3 (G9a) before Stage C goes live (card P4-24).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.4 (id/phase table)
  - docs/backend/50-security-privacy.md §11.1, §11.3, §11.4 ([P4] items and the [P5] /my sentence in 3.8)
  - docs/backend/00-overview.md R-29
- **creates:** —
- **modifies:** `src/content/privacy.tsx`
- **steps:**
  1. Insert sections health (ONLY if G-HEALTH = system), media and links (phase "P4") after 'contacts', TH and EN; include the [P5] /my sentence in links.
  2. Add the [P4] paragraph to 'children' and the [P4] rows to 'sharing' and 'retention' (skip health rows if G-HEALTH = paper).
  3. Bump PRIVACY_NOTICE_VERSION to '`<YYYY-MM>`-v3'; draftBanner back to draft text until G9a.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-privacy-checker: every [P4] item present (health only if system); nothing [P6]

#### P4-21 · /admin/media screen, nav item, dashboard takedown card

- **agent_name:** `cl-p4-media-screen` · **phase:** P4 · **batch:** 4
- **depends_on:** P4-12, P4-15, P4-19
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/media'
  - docs/backend/20-server-api.md §14.7 (ChannelState)
  - docs/backend/50-security-privacy.md §17 (takedown runbook)
- **creates:** `src/routes/admin/_staff/media.tsx`, `src/components/admin/media/MediaAssetSheet.tsx`
- **modifies:** `src/components/admin/AdminShell.tsx`, `src/routes/admin/_staff/index.tsx`
- **steps:**
  1. Route createFileRoute("/admin/_staff/media"): lead, 'เพิ่มสื่อ' MediaAssetSheet (media.form.* incl. showsFaces + hint, onParentsGroup, titleHint: never children's names), table: title + kind, children chips with multi-select → setMediaAssetChildren, four channel cells as icon + text from ChannelState, status; needsTakedown rows get a destructive Badge with text, takedownReminder and 'บันทึกว่านำออกแล้ว' → markMediaTakenDown.
  2. AdminShell: add { to: "/admin/media", key: "media", ownerOnly: false } to MORE. Dashboard: takedowns(n) card.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - cl-privacy-checker: no child names in titles or alt text

#### P4-22 · my-consents.tsx copy, MyConsentsPage and the /my/$token route

- **agent_name:** `cl-p4-my-page` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-13, P4-08
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §3.6 (layout, actions, ✅ my-consents.tsx)
  - docs/backend/30-ui.md §5.1 public rows inactiveChild, agreeToText
  - docs/backend/50-security-privacy.md §16 (withdrawal flow)
- **creates:** `src/content/my-consents.tsx`, `src/components/my/MyConsentsPage.tsx`, `src/components/my/MyConsentsPage.test.tsx`, `src/routes/my.$token.tsx`
- **modifies:** —
- **steps:**
  1. Copy the ✅ my-consents.tsx block and add inactiveChild and agreeToText (TH/EN).
  2. Route like /enrol (ssr false, noindex, no-referrer, ?lang). MyConsentsPage: one card per child (every child; inactive labelled), one row per purpose with status text, since(date) and the purpose's full current text visible; Withdraw = one press → updateMyConsent({ decision: 'withdrawn' }) with an aria-live note; Give consent (media) = Dialog with title + full text + unticked agree checkbox + face choice; health has no grant button (healthGrantNote).
  3. MyConsentsPage.test.tsx: withdraw is one press (no confirm dialog); every row shows its full text; an inactive child still has its withdraw buttons.
  4. Run npx vite build before tsc.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/components/my/MyConsentsPage.test.tsx: all pass

#### P4-23 · videos.ts: optional mediaAssetId + takedown note in README

- **agent_name:** `cl-p4-videos-link` · **phase:** P4 · **batch:** 5
- **depends_on:** P4-21, P0-13
- **human_gate:** —
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/00-overview.md D24, F4-08
  - docs/backend/50-security-privacy.md §17.1–17.3
  - src/content/videos.ts
  - src/content/videos.test.ts
  - README.md §Videos
- **creates:** —
- **modifies:** `src/content/videos.ts`, `README.md`
- **steps:**
  1. Add an optional mediaAssetId?: string to the Video type (no values yet; the builder fills them from /admin/media). Do not change canShow or any consent flag.
  2. README.md 'Videos' section: add 3–5 lines on the takedown steps (alert → remove or hide the clip in videos.ts → republish → mark taken down in /admin/media), pointing to docs/backend/50-security-privacy.md §17.3.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - npx vitest run src/content/videos.test.ts: still passes

#### P4-24 · Stage C go-live check (G-HEALTH switch, G9a …-v3, G10)

- **agent_name:** `cl-p4-stage-c-golive` · **phase:** P4 · **batch:** 7
- **depends_on:** P4-01, P4-14, P4-16, P4-18, P4-20, P4-22, P4-23
- **human_gate:** Human: HEALTH_IN_SYSTEM matches G-HEALTH; owner approves …-v3 (G9a); sign-up disabled; rls_smoke.sql no FAIL; seed_dev.sql run in the SQL editor ends with its success row (§§ 6, 7 and 7b PASS lines: health needs consent, withdrawal deletes and alerts, child 10+ rules, R-33 re-enrol keeps media decisions, R-34 child's health "no", R-35 first health text, submit_enrolment scope/link_used); publish-scan findings fixed; Publish (G10).
- **reads:**
  - docs/backend/00-overview.md §8 P4 acceptance, §8.0 Stage C row
  - docs/backend/40-integrations.md §13
  - docs/backend/50-security-privacy.md §§13–17
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the standard acceptance and cl-privacy-checker over every Stage C file: no consent control pre-ticked, every consent control's full text visible, health only via audited functions, no health on LINE, /enrol and /my noindex + no-referrer.
  2. Give the builder the P4 acceptance list from 00 §8 (DB rejects health without consent; withdrawal deletes the health row and queues an alert; a 10+ child without own media consent is not publishable; an enrol link works once; two concurrent submits can't both succeed; consent_texts can't be edited; an unticked box on a re-sent enrol link keeps the earlier media decision; a child's own health "no" hides the health box) and collect results, pointing to the matching seed_dev.sql PASS lines.
  3. Produce the 40 §13 checklist with each line done/open.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - Every P4 acceptance line in 00 §8 is checked or listed as open

### Stage D · P6 Reports (optional)

#### P6-01 · Review SQL 0008_reporting.sql, then G4 (Stage D, optional)

- **agent_name:** `cl-p6-sql-0008` · **phase:** P6 · **batch:** 1
- **depends_on:** P3-18
- **human_gate:** BEFORE: the owner asks for reports (Stage D is optional). AFTER review: builder G4 applies 0008, git pull, types.ts contains report_revenue_monthly, rls_smoke.sql no FAIL.
- **reads:**
  - docs/backend/10-data-model.md §7
  - docs/backend/sql/0008_reporting.sql
  - docs/backend/sql/tests/rls_smoke.sql
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the cl-sql-reviewer checklist on 0008. Also check: every view has security_invoker = true; report_revenue_monthly is readable by the owner only; no view exposes names, contacts or health.
  2. Do not edit files.
- **acceptance:**
  - Read-only review report: one line per check (additive only, RLS on every new table, anon has no grants, every SECURITY DEFINER function has set search_path = '' and explicit revoke/grant, names match 10-data-model.md, safe to run twice, depends-on order) marked PASS or FAIL with file:line; no file changed

#### P6-02 · reports.schema.ts + getReports (aggregates only)

- **agent_name:** `cl-p6-reports-functions` · **phase:** P6 · **batch:** 2
- **depends_on:** P6-01, P0-17
- **human_gate:** —
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.14 (✅ reports.schema.ts, 📝 getReports)
  - docs/backend/20-server-api.md §14.9 (getReports skeleton)
- **creates:** `src/lib/backend/reports.schema.ts`, `src/lib/backend/reports.functions.ts`
- **modifies:** —
- **steps:**
  1. Copy the ✅ schema; implement getReports exactly as the §14.9 skeleton: read the four security_invoker views for the date range; revenue fields only when context.role === 'owner' (else null).
  2. Never return names, contacts or health data.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### P6-03 · Admin copy: reports module + /admin/reports screen with CSV

- **agent_name:** `cl-p6-reports-screen` · **phase:** P6 · **batch:** 3
- **depends_on:** P6-02, P4-15, P4-21
- **human_gate:** If Stage C was skipped, this card depends on P5-02 (index.ts) and P5-04 (AdminShell) instead of P4-15 and P4-21.
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/reports'
  - docs/backend/30-ui.md §5 reference member reports (type L4580–4593; th L5330–5343; en L6155–6168)
  - docs/backend/30-ui.md §1.2 (shadcn chart or tables)
- **creates:** `src/content/admin/reports.tsx`, `src/routes/admin/_staff/reports.tsx`
- **modifies:** `src/content/admin/index.ts`, `src/components/admin/AdminShell.tsx`
- **steps:**
  1. Create reports.tsx copy (AdminReports = { reports }, TH/EN) and add it to index.ts.
  2. Route createFileRoute("/admin/_staff/reports"): from/to (default last 3 months); sections requests per week, conversion(c, t), seats per session, attendance per month, revenue per month (owner only; staff see revenueOwnerOnly), credits(n); CSV download per section built in the browser (UTF-8 with BOM) with noPersonalData next to the button.
  3. AdminShell: add { to: "/admin/reports", key: "reports", ownerOnly: false } to MORE.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - CSV files contain only aggregate columns

#### P6-04 · Stage D check and publish

- **agent_name:** `cl-p6-stage-d-golive` · **phase:** P6 · **batch:** 4
- **depends_on:** P6-03
- **human_gate:** Human: report numbers match a hand count on test data; Publish (G10).
- **reads:**
  - docs/backend/00-overview.md §8 P6 acceptance
  - docs/backend/40-integrations.md §13
- **creates:** —
- **modifies:** —
- **steps:**
  1. Run the standard acceptance and cl-privacy-checker on the reports files (aggregates only, no names, no contacts).
  2. Give the builder the hand-count check and collect results.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing
  - P6 acceptance lines in 00 §8 checked or listed as open

### Parked (G-PARK)

#### PK-01 · PARKED: DSR, breach and audit functions

- **agent_name:** `cl-pk-privacy-records-fns` · **phase:** PK · **batch:** 1
- **depends_on:** P5-01
- **human_gate:** Only after the owner un-parks it (G-PARK, 90 §2).
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.13 parked rows (listDsrRequests, saveDsrRequest, listBreachIncidents, saveBreachIncident, listAuditLog)
  - docs/backend/20-server-api.md §14.8 (DsrRow, BreachRow, AuditRow)
  - docs/backend/50-security-privacy.md §§18, 20, 5
- **creates:** —
- **modifies:** `src/lib/backend/privacy.schema.ts`, `src/lib/backend/privacy.functions.ts`, `src/lib/backend/privacy.schema.test.ts`
- **steps:**
  1. Add the parked input schemas (zod limits aligned with DB_LIMITS dsrContact 120, dsrText 1000, breachTitle 200, breachText 4000) and §14.8 types.
  2. Add the five owner functions per the §9.13 rows: requested_right column (not 'right'); deadlines set by SQL triggers; descriptions never contain the leaked data; audit log shows no field values.
  3. Tests: boundary tests for the four limits.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-02 · PARKED: /admin/privacy DSR, breach and audit tabs + dashboard dsrDue

- **agent_name:** `cl-pk-privacy-tabs` · **phase:** PK · **batch:** 2
- **depends_on:** PK-01, P5-04
- **human_gate:** Only after G-PARK.
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/30-ui.md §4.3 '/admin/privacy' tabs (full design)
  - docs/backend/50-security-privacy.md §18.1 (15/30-day deadlines), §20 (72 hours)
- **creates:** `src/components/admin/privacy/DsrTab.tsx`, `src/components/admin/privacy/BreachTab.tsx`, `src/components/admin/privacy/AuditTab.tsx`
- **modifies:** `src/routes/admin/_staff/privacy.tsx`
- **steps:**
  1. Build the three tabs exactly as 30 §4.3 (reviewDue/dueIn/overdue with text, breach countdown with pdpcLink, audit table without field values) and add them to the privacy route next to Files to delete.
  2. Add the dashboard dsrDue(n) card only if it does not conflict with another open card (else report).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-03 · PARKED: owner consent-text publishing (one SQL transaction)

- **agent_name:** `cl-pk-consent-texts-ui` · **phase:** PK · **batch:** 1
- **depends_on:** P4-11, P1-19
- **human_gate:** Only after G-PARK. Every new wording still needs owner + lawyer review (G9b-style) before publishing.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/20-server-api.md §9.9 parked rows (listConsentTexts, publishConsentText, retireConsentText)
  - docs/backend/20-server-api.md §14.6 ConsentTextRow
  - docs/backend/30-ui.md §4.3 settings 'ข้อความขอความยินยอม' bullet
  - docs/backend/50-security-privacy.md §12
- **creates:** —
- **modifies:** `src/lib/backend/consent.schema.ts`, `src/lib/backend/consent.functions.ts`, `src/routes/admin/_staff/settings.tsx`
- **steps:**
  1. Add the three owner functions; publishConsentText makes ONE rpc publish_consent_text (TH + EN + retire previous in one transaction); zod title ≤ 200, body ≤ 10000, child age 7–19 (DB_LIMITS).
  2. Settings: versions table and a side-by-side TH/EN publish Dialog; retire with confirm (refuse retiring the only current version).
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-04 · PARKED: Umami cookieless analytics (F6-03)

- **agent_name:** `cl-pk-umami` · **phase:** PK · **batch:** 1
- **depends_on:** P1-18
- **human_gate:** Only after G-PARK and G12 (owner creates the Umami website; checks Lovable analytics sets no cookies). AFTER: privacy notice …-v4 with the [P6] rows (G9a).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - docs/backend/40-integrations.md §10.2
  - docs/backend/30-ui.md §3.1 last bullet (data-umami-event)
  - docs/backend/50-security-privacy.md §11.1 v4, §22
- **creates:** —
- **modifies:** `src/routes/__root.tsx`, `src/lib/backend/public-config.ts`, `src/components/sections/CtaBand.tsx`, `src/components/sections/Pricing.tsx`
- **steps:**
  1. Add the Umami script to __root.tsx only when UMAMI_WEBSITE_ID is non-empty (exact attributes from 40 §10.2); add the two data-umami-event attributes to the form links and LINE buttons. No other events, never personal data.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-05 · PARKED: Resend owner-only backup email alert (F6-05)

- **agent_name:** `cl-pk-resend-backup` · **phase:** PK · **batch:** 1
- **depends_on:** P4-03
- **human_gate:** Only after G-PARK; owner adds RESEND_API_KEY and STAFF_NOTIFY_EMAIL (G6-style) and a verified sender domain (G13). AFTER: notice …-v4 row for Resend.
- **reads:**
  - docs/backend/README.md (golden rules, acceptance commands, leak grep)
  - docs/backend/40-integrations.md §9.1–9.3
  - docs/backend/20-server-api.md §7.8 (notifyStaff flow)
- **creates:** `src/server/email-alert.server.ts`, `src/server/email-alert.server.test.ts`
- **modifies:** `src/server/staff-notify.server.ts`
- **steps:**
  1. Write sendBackupEmail(text) with fetch to the Resend API using optionalServerEnv; same PII-free text as LINE; called by notifyStaff only when the LINE push failed; never throws.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-06 · PARKED: click-to-load Google Map on the homepage

- **agent_name:** `cl-pk-map-click-to-load` · **phase:** PK · **batch:** 1
- **depends_on:** P1-08
- **human_gate:** Only after G-PARK. AFTER: add the cookies line to the notice (next version).
- **reads:**
  - AGENTS.md (house rules: TH/EN, `<Nobr>`/`<En>`, tone, accessibility)
  - src/components/sections/Visit.tsx
  - docs/backend/50-security-privacy.md §22
  - docs/backend/00-overview.md §6 stage 0
- **creates:** —
- **modifies:** `src/components/sections/Visit.tsx`, `src/content/site.tsx`
- **steps:**
  1. Replace the always-on iframe with a placeholder card and a button 'ดูแผนที่ / Show map' (≥ 44 px) that mounts the same iframe on press; keep the address text and the outbound Google Maps link visible without loading anything.
  2. Copy keys in site.tsx in TH and EN.
- **acceptance:**
  - Standard acceptance (docs/backend/README.md): npx prettier --write `<changed files>`; npx vite build ends with '✓ built'; npx tsc --noEmit exits 0 with no output; npx eslint `<changed files>` exits 0; npx vitest run: all pass; the leak grep prints nothing

#### PK-07 · PARKED: write the spec for /pay/$token (PromptPay QR) before any code

- **agent_name:** `cl-pk-promptpay-spec` · **phase:** PK · **batch:** 1
- **depends_on:** P3-05
- **human_gate:** Only after G-PARK and G0 Q13 (PromptPay ID). Code cards are written from this spec later; Lovable must add the uqr package first.
- **reads:**
  - docs/backend/40-integrations.md §8.2
  - docs/backend/20-server-api.md §9.15
  - docs/backend/30-ui.md §3.7
- **creates:** —
- **modifies:** `docs/backend/20-server-api.md`, `docs/backend/30-ui.md`
- **steps:**
  1. Docs only: fill 20 §9.15 and 30 §3.7 with the function, token, amount and copy spec (fixed amount from a pending payment, no card data, link expiry), following the existing 📝 style and the EMVCo test vectors in 40 §8.2. Do not write code.
- **acceptance:**
  - Spec reviewed by the main session; no file under src/ changed

#### PK-08 · PARKED: P7 LINE Login / LIFF decision note

- **agent_name:** `cl-pk-liff-spec` · **phase:** PK · **batch:** 1
- **depends_on:** — (runnable now)
- **human_gate:** Only after an explicit owner decision (00 §8 P7).
- **reads:**
  - docs/backend/00-overview.md §8 P7
  - docs/backend/40-integrations.md §11
  - docs/backend/50-security-privacy.md §23
- **creates:** —
- **modifies:** `docs/backend/40-integrations.md`
- **steps:**
  1. Docs only: list the decisions, consents, quota and notice changes P7 needs in 40 §11, with sources. Do not write code.
- **acceptance:**
  - No file under src/ changed

---

## 6. Names introduced by this file

Use them exactly. Names introduced by the spec files are listed in `20-server-api.md` § 13 and `30-ui.md` § 7.

| Name | File | Card |
|---|---|---|
| `SessionEditSheet`, `GenerateSessionsDialog` | `src/components/admin/sessions/` | P2-04 |
| `FamilyBanners`, `FamilyOverviewTab` | `src/components/admin/family/` | P3-10 |
| `GuardianSheet`, `ChildSheet`, `ContactSheet` | `src/components/admin/family/` | P3-11 |
| `FamilyPackagesTab`, `FamilyHistoryTab` | `src/components/admin/family/` | P3-12 |
| `RecordPaymentDialog` | `src/components/admin/payments/` | P3-12 (reused by P3-15) |
| `SlipUploadButton` | `src/components/admin/payments/` | P3-15 |
| `PickupDialog`, `AddBookingDialog` | `src/components/admin/roster/` | P3-13 |
| `ConvertDialog` | `src/components/admin/inbox/` | P3-14 |
| `FamilyPrivacyCard` | `src/components/admin/family/` | P5-03 |
| `GuardianSection`, `ContactsSection` | `src/components/enrol/` | P4-10 |
| `EnrolPage` | `src/components/enrol/` | P4-14 |
| `HealthCell`, `HealthDialog` | `src/components/admin/roster/` | P4-16 |
| `FamilyLinksTab` | `src/components/admin/family/` | P4-17 |
| `FamilyConsentsTab`, `RecordConsentDialog` | `src/components/admin/family/` | P4-18 |
| `MediaAssetSheet` | `src/components/admin/media/` | P4-21 |
| `MyConsentsPage` | `src/components/my/` | P4-22 |
| `DsrTab`, `BreachTab`, `AuditTab` | `src/components/admin/privacy/` | PK-02 (parked) |
| `sendBackupEmail` | `src/server/email-alert.server.ts` | PK-05 (parked) |
| Query key `["admin", "alerts"]` | dashboard alerts list | P4-19 |
| `auth.middleware.test.ts` | `src/lib/backend/` | P0-17 (R-40) |
| `BookingThanks.test.tsx` | `src/components/booking/` | P1-14 (R-45) |

---

## 7. Feature → card map

Feature ids (`F…`) come from `00-overview.md` § 8.

| Feature | Cards |
|---|---|
| F0-01 env helper | P0-01 |
| F0-02 pure and server-only helpers | P0-02 … P0-11 |
| F0-03 robots + ESLint | P0-12 |
| F0-04 AGENTS / README | P0-13 |
| F0-05 SQL 0001 | P0-14 (+ G4) |
| F0-06 verify bootstrap | P0-15 |
| F0-07 service-role door | P0-16 |
| F0-08 auth middleware + staff functions | P0-17, P0-19 |
| F0-09 admin shell | P0-18, P0-20, P0-21, P0-22 |
| F1-01 SQL 0002 (+ cron fallback) | P1-01, P1-16 |
| F1-02 `/privacy` `…-v1` | P1-02, P1-10 |
| F1-03 booking schema + function | P1-04, P1-05, P1-06, P1-07 |
| F1-04 staff notifications | P1-03 |
| F1-05 `/book` | P1-08, P1-09, P1-13, P1-14, P1-18 |
| F1-06 admin inbox | P1-11, P1-12, P1-17 |
| F1-07 homepage entry points | P1-08, P1-18 |
| F1-08 alert webhook (optional) | P1-20 |
| F1-09 `/admin/settings` | P1-15 |
| F1-10 preview end-to-end | P1-19, P1-21 |
| F2-01 SQL 0003 | P2-01 |
| F2-02 / F2-03 sessions admin + functions | P2-02, P2-03, P2-04 |
| F2-04 open dates on `/book` (+ homepage strip) | P2-06, P2-07 |
| F2-05 session in inbox and alert | P2-05 |
| Stage A go-live | P2-08 |
| F3-01 SQL 0004 | P3-01 |
| F3-02 convert request | P3-04, P3-14 |
| F3-03 families screens | P3-02, P3-03, P3-09, P3-10, P3-11 |
| F3-04 packages, payments, slips | P3-05, P3-12, P3-15 |
| F3-05 bookings | P3-06, P3-13 |
| F3-06 roster | P3-07, P3-13 |
| F3-07 `/admin/payments` | P3-15 |
| F3-08 notice `…-v2` | P3-16 |
| F4-01 SQL 0005 (applied in Stage B) | P3-17 |
| F5-01 SQL 0007 + core privacy functions | P3-18, P5-01 |
| F5-02c owner privacy card | P5-02, P5-03 |
| F5-07 files to delete | P5-04 |
| F5-06 owner MFA (human) | P5-05 |
| Stage B checks and go-live | P5-05, P5-06 |
| F4-02 SQL 0006 / 0006b | P4-01 |
| F4-03 enrolment links | P4-02, P4-05, P4-17 |
| F4-04 `/enrol/$token` | P4-04, P4-06, P4-08, P4-09, P4-10, P4-14 |
| F4-05 staff consent recording, child 10+ | P4-11, P4-15, P4-18 |
| F4-06 health on roster | P4-07, P4-16 |
| F4-07 `/admin/media` | P4-12, P4-21 |
| F4-08 `videos.ts` link | P4-23 |
| F4-09 `/my/$token` | P4-13, P4-22 |
| F4-10 notice `…-v3` | P4-20 |
| D29 alerts delivered and listed | P4-03, P4-19 |
| Stage C go-live | P4-24 |
| F6-01 / F6-02 reports | P6-01, P6-02, P6-03, P6-04 |
| F5-02 DSR / breach / audit screens (parked) | PK-01, PK-02 |
| F5-05 consent-text publishing (parked) | PK-03 |
| F6-03 Umami (parked) | PK-04 |
| F6-05 Resend (parked) | PK-05 |
| Click-to-load map (parked) | PK-06 |
| F6-04 PromptPay page (parked, spec first) | PK-07 |
| P7 LINE Login / LIFF (parked, decision first) | PK-08 |
