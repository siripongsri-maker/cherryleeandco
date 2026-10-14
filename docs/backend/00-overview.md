# 00 · Backend overview: CherryLee & Co.

Planning document, October 2026. Lovable Cloud is not enabled yet. This file sets the decisions and the names
every other file in `docs/backend/` must follow.

---

## สรุปสำหรับเจ้าของสตูดิโอ (Thai summary)

### ระบบหลังบ้านนี้คืออะไร

ตอนนี้เว็บไซต์ CherryLee & Co. แนะนำสตูดิโอได้อย่างเดียว การจองทุกอย่างเกิดขึ้นในแชต LINE
แผนนี้จะค่อยๆ เพิ่ม "หลังบ้าน" ให้ทีมงาน 1–2 คนดูแลการจองได้เป็นระเบียบขึ้น ข้อมูลไม่หายไปในแชต
และดูแลข้อมูลของเด็กๆ ได้อย่างปลอดภัยตาม พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล (PDPA)
**LINE @cherryleeandco ยังเป็นช่องทางหลักเหมือนเดิม** ผู้ปกครองทักแชตได้ตามปกติ เราจะไม่ไปเปลี่ยนการตั้งค่าแชตของบัญชีนี้

### จะได้อะไรบ้าง (ทยอยทำทีละขั้น ใช้ได้จริงทุกขั้น)

1. **ฟอร์ม "ฝากข้อมูลให้ติดต่อกลับ" บนเว็บ** ผู้ปกครองกรอกชื่อ อายุของน้อง แพ็กเกจและวันที่สนใจ แล้วเลือกว่าจะคุยทางไหน
   ถ้าเลือก LINE ผู้ปกครองกดส่ง "รหัสคำขอ" เข้าแชต @cherryleeandco แล้วทีมงานตอบในแชตนั้น
   (บัญชี LINE ทางการทักหาใครก่อนไม่ได้ จึงต้องให้ผู้ปกครองทักมาก่อน) ถ้าเลือกโทร ทีมงานโทรกลับตามเบอร์ที่ให้ไว้
   ทีมงานได้รับแจ้งเตือนทาง LINE ทันที ข้อความแจ้งเตือนมีแค่รหัสการจอง วันที่ และจำนวนเด็ก ไม่มีชื่อหรือเบอร์โทร
2. **หน้าทีมงาน (หลังบ้าน)** ใช้ภาษาไทยเป็นหลัก สลับเป็นอังกฤษได้ ดูคำขอจองทั้งหมด จดว่าติดต่อแล้วหรือยัง
3. **ตารางรอบเรียนเสาร์–อาทิตย์** ทีมงานกำหนดจำนวนที่นั่งเอง หน้าเว็บแสดงแค่ "ว่างอีกกี่ที่" ไม่แสดงชื่อใคร
4. **ทะเบียนครอบครัว** แพ็กเกจ 1 / 4 / 8 ครั้ง (เหลืออีกกี่ครั้ง) การชำระเงิน (ทีมงานตรวจสลิปและบันทึกเองเหมือนเดิม)
   และเช็กชื่อเข้า–ออก พร้อมดูว่าใครมารับน้องได้บ้าง
5. **ความปลอดภัยและความยินยอม** ข้อมูลแพ้อาหารสำหรับคลาสทำอาหารกับอังเคิลลีเก็บแยกไว้ต่างหาก
   ผู้ปกครองต้องติ๊กยินยอมเองโดยชัดแจ้ง ความยินยอมเรื่องรูปและวิดีโอแยกเป็นรายช่องทาง ถอนความยินยอมได้ง่ายทุกเมื่อ
6. **งาน PDPA** หน้านโยบายความเป็นส่วนตัว (ไทย/อังกฤษ) ตัวช่วยติดตามคำขอใช้สิทธิของผู้ปกครองพร้อมนับวันครบกำหนด
   บันทึกเหตุข้อมูลรั่วไหล และระบบลบข้อมูลอัตโนมัติเมื่อครบระยะเวลาเก็บ
7. **รายงานภาพรวม** เช่น จำนวนคำขอต่อสัปดาห์ ที่นั่งเต็มแค่ไหน รายรับต่อเดือน (แสดงเป็นตัวเลขรวม ไม่มีชื่อ)
   ส่วนระบบให้ผู้ปกครองดูการจองเองผ่าน LINE เป็นทางเลือกเสริมในอนาคต

### ทำทีละขั้น และหยุดดูผลก่อนไปต่อ

- **ขั้น A (ทำก่อน):** ฟอร์มฝากข้อมูล หน้าทีมงานดูคำขอ แจ้งเตือนทาง LINE และ (ถ้าต้องการ) ตารางรอบเรียนกับที่นั่งว่าง
- **จุดตัดสินใจ G-MVP:** ใช้ขั้น A จริงอย่างน้อย 8 สัปดาห์ แล้วเจ้าของสตูดิโอดูว่ามีคำขอมากพอและช่วยงานจริงไหม
  ถ้ายังไม่คุ้ม หยุดแค่ขั้น A ได้เลย ระบบที่ทำไปแล้วใช้งานได้ครบ
- **ขั้น B:** ทะเบียนครอบครัว แพ็กเกจ การชำระเงิน เช็กชื่อ พร้อมระบบลบข้อมูลอัตโนมัติ และปุ่มส่งออก ลบ หรือระงับข้อมูลของครอบครัว
- **ขั้น C:** ความยินยอมเรื่องรูปและวิดีโอ ลิงก์ส่วนตัวให้ผู้ปกครอง และข้อมูลการแพ้อาหาร
  (เจ้าของสตูดิโอเลือกได้ว่าจะเก็บข้อมูลแพ้อาหารในระบบ หรือใช้แบบฟอร์มกระดาษที่สตูดิโอเหมือนเดิม จุดตัดสินใจ G-HEALTH)
- **พักไว้ก่อน:** ตัวติดตามคำขอใช้สิทธิ บันทึกเหตุข้อมูลรั่วไหล หน้าดูบันทึกการเข้าถึง หน้าออกข้อความยินยอมฉบับใหม่ รายงาน
  สถิติเว็บ QR PromptPay อีเมลสำรอง และ LINE Login ช่วงนี้ใช้คู่มือขั้นตอนกับสเปรดชีตส่วนตัวของเจ้าของแทน

### ทำไมถึงออกแบบแบบนี้

- **เก็บเท่าที่จำเป็นในแต่ละช่วง** ตอนแรกขอแค่ข้อมูลสำหรับติดต่อกลับ ข้อมูลละเอียด เช่น การแพ้อาหาร หรือคนที่มารับน้อง
  ขอทีหลังเมื่อครอบครัวตัดสินใจมาเรียนแล้ว ผ่านลิงก์ส่วนตัวที่ทีมงานส่งให้ในแชต LINE
- **ไม่เก็บ** เลขบัตรประชาชน วันเกิดเต็ม (เก็บแค่เดือนและปีเกิด) ชื่อโรงเรียน เหตุผลที่ไม่ทานอาหารบางอย่าง หรือเลขบัญชีธนาคาร
- **ระบบไม่พังตามกัน** ถ้าหลังบ้านมีปัญหา หน้าเว็บยังเปิดได้ และมีปุ่มให้ทักทาง LINE แทนเสมอ
- **ทีมงานใช้ง่าย** ออกแบบให้คน 1–2 คนดูแลได้จากมือถือ

### สิ่งที่เจ้าของสตูดิโอต้องทำหรือตัดสินใจ

| เรื่อง | ทำไมต้องเป็นเจ้าของ |
|---|---|
| ตอบคำถามในหัวข้อ 13 (รูปแบบกิจการ จำนวนที่นั่งต่อรอบ กติกาแพ็กเกจ การชำระเงิน ระยะเวลาเก็บข้อมูล) | ระบบห้ามเดากติกาเอง |
| ตัดสินใจ G-MVP (ไปต่อขั้น B ไหม) และ G-HEALTH (เก็บข้อมูลแพ้อาหารในระบบหรือบนกระดาษ) | เป็นการตัดสินใจทางธุรกิจและเรื่องข้อมูลอ่อนไหว |
| กดเปิด Lovable Cloud และเลือก region **Asia Pacific** (เปลี่ยนภายหลังไม่ได้) | เป็นการตัดสินใจถาวรและเกี่ยวกับ PDPA |
| สร้างบัญชีผู้ใช้ของทีมงานในหลังบ้าน และตั้งรหัสผ่านที่แข็งแรง | เป็นสิทธิ์ของเจ้าของ |
| สร้าง LINE OA ใหม่สำหรับแจ้งเตือนทีมงาน (แพ็กเกจฟรี) จากบัญชี LINE ของสตูดิโอเอง | Provider ของ LINE ผูกแล้วเปลี่ยนไม่ได้ ต้องเป็นของสตูดิโอ |
| สมัคร Cloudflare Turnstile (ฟรี) เพื่อกันสแปมบนฟอร์ม | บัญชีควรเป็นของสตูดิโอ |
| ใส่รหัสลับ (secrets) ในหน้า Lovable Cloud เอง | ห้ามส่งรหัสลับในแชตหรือเก็บไว้ในโค้ด |
| ให้นักกฎหมายด้าน PDPA ช่วยดูนโยบายความเป็นส่วนตัวและข้อความขอความยินยอม | เอกสารนี้ไม่ใช่คำปรึกษาทางกฎหมาย |
| กด Publish ใน Lovable หลังจบแต่ละขั้น | งานใหม่ขึ้นเว็บจริงเมื่อกด Publish เท่านั้น |

### ค่าใช้จ่ายโดยประมาณต่อเดือน

| รายการ | ค่าใช้จ่าย |
|---|---|
| Lovable Pro (ใช้อยู่แล้ว) | เท่าเดิม |
| Lovable Cloud (ฐานข้อมูล ระบบล็อกอิน พื้นที่เก็บไฟล์ งานลบข้อมูลรายวัน) | Lovable ให้เครดิต Cloud ฟรี 20 เครดิตต่อเดือน (เป็นข้อเสนอชั่วคราว) ถ้าไม่พอ เติมได้ $15 ต่อ 50 เครดิต (ประมาณ 500 บาท) **ต้องเช็กตัวเลขประมาณการจริงในหน้า Advanced settings ก่อนเปิด** |
| LINE OA สำหรับแจ้งเตือนทีมงาน (แพ็กเกจฟรี) | 0 บาท (300 ข้อความต่อเดือน) |
| Cloudflare Turnstile กันสแปม | 0 บาท |
| สถิติผู้เข้าชมแบบไม่ใช้คุกกี้ (Umami, ไม่บังคับ) | 0 บาท |
| ค่านักกฎหมายตรวจเอกสาร (จ่ายครั้งเดียว) | ต้องขอใบเสนอราคา |
| โดเมนของตัวเอง (ไม่บังคับ) | รายปี ตามผู้ให้บริการ |

**สรุป:** ถ้าใช้งานอยู่ในโควตาฟรี ค่าใช้จ่ายเพิ่มต่อเดือนน่าจะประมาณ 0–500 บาท (ยังเป็นการประมาณ ต้องยืนยันหลังเปิด Cloud)

### สิ่งที่ระบบนี้จะไม่ทำ

ไม่รับบัตรเครดิต ไม่แทนที่แชต LINE ไม่เก็บรูปหรือวิดีโอของเด็กไว้ในระบบ ไม่ใส่คุกกี้ติดตามหรือโฆษณา
และไม่ตั้งกติกาแทนสตูดิโอ (เช่น การคืนเงิน วันหมดอายุแพ็กเกจ จำนวนเด็กต่อกลุ่ม) จนกว่าสตูดิโอจะกำหนดเอง

---

## 1. Goals and non-goals

### Goals

1. **Fewer lost bookings.** A structured booking request from the website lands in an admin inbox and pings staff on LINE
   within a minute. LINE chat stays the main channel.
2. **One place for the studio's records:** sessions and seats, families, packages and credits, payments, attendance,
   pickup persons, consents, all usable from a phone by one or two staff.
3. **Child safety:** allergy information is available to the teachers before a cooking session; authorised pickup
   persons are visible on the roster.
4. **PDPA by design** (Thai PDPA B.E. 2562): data minimisation by stage, explicit consent for health data, versioned
   consent evidence, rights requests with deadlines, breach log, automatic deletion, audit trail.
5. **Buildable by small agents.** Boring, explicit patterns; every task testable with the same commands.
6. **Cheap and robust.** Stays inside the Lovable plan the studio already has; the public site never breaks because the
   backend is slow or paused.

### Non-goals (P0–P6)

- Online card payments or a payment gateway. Payments stay PromptPay / bank transfer / cash, verified by staff.
- Replacing LINE chat, or connecting `@cherryleeandco` to the Messaging API / a webhook.
- Parent accounts with passwords. Parents use single-use links; LINE Login self-service is optional P7.
- Storing children's photos or videos. Media is referenced by YouTube id / title only.
- Marketing broadcasts, email newsletters, or collecting marketing consent.
- Advertising pixels, GA4, cookie banners (we stay cookieless instead).
- Inventing studio policy: refunds, cancellations, package expiry, make-up sessions, group size, lunch.

---

## 2. Where we start from (verified facts)

- Site: Lovable project `fa9b86e9-5d99-468e-be51-3be106fa410c`, synced two-way with GitHub `siripongsri-maker/github-seed`
  branch `main`. TanStack Start 1.168.60 / Router 1.170.41, React 19, Tailwind 4, zod 3.25, React Query 5 (already
  provided in `src/routes/__root.tsx`), shadcn/ui in `src/components/ui`. Built by `@lovable.dev/vite-tanstack-config`
  2.25.3 → nitro preset `cloudflare-module` (Cloudflare Workers, `nodejs_compat`).
- Routes today: `src/routes/__root.tsx`, `src/routes/index.tsx` (one bilingual page, `?lang=en`).
  `src/start.ts` registers `errorMiddleware` and `csrfMiddleware` (server functions only). `src/server.ts` wraps SSR errors.
- Copy: `src/content/site.tsx`; links and prices: `src/content/business.ts` (`PRICES = { single: 3900, four: 14400, eight: 26400 }`,
  `lineMessageUrl(text)`); clips with a free-text consent note: `src/content/videos.ts` (`canShow`).
- Language choice is stored in `localStorage` key `cherrylee-lang`; YouTube is click-to-load (`youtube-nocookie.com`);
  a Google Maps iframe loads on the page; no analytics scripts. `public/robots.txt` allows everything.
- Backend: none. Lovable Cloud `enabled: false`. Workspace "Siripong's Lovable" is on the Pro plan.
- Program facts: ages 6–12; every Saturday and Sunday 09:00–15:00; "small groups" (max size not published);
  Story Playlit, Basic Cooking (with Uncle Lee — food allergies matter), Money Wise (บอร์ดเกมการเงิน / board games,
  role-play shop, sometimes a supermarket trip with parents). Teachers Kru Cherry and Uncle Lee; Kru Arm appears in videos.

---

## 3. Architecture

```
  Parents (browser, phone)                        Staff (browser, phone) — Thai-first admin
  /  /book  /privacy                              /admin/login → /admin/*  (ssr:false, noindex)
  /enrol/$token  /my/$token (private links)       Lovable Cloud Auth: email + password, sign-up disabled
        │                                          session in localStorage → "Authorization: Bearer …"
        │ server functions (POST = CSRF-checked)         │ server functions + requireStaff / requireOwner
        ▼                                                ▼
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │ Lovable hosting · TanStack Start on Cloudflare Workers                       │
 │  src/lib/backend/*.functions.ts   zod validation, spam checks, role checks   │
 │  src/server/*.server.ts           server-only: secrets, service-role client, │
 │                                   Turnstile, LINE push, HMAC, link tokens    │
 │  src/routes/api/line/alert-webhook.ts  (optional, alert OA only)             │
 └───────┬───────────────────────────────┬──────────────────────┬──────────────┘
         │ service role                   │ user JWT (RLS)       │ fetch()
         │ (public form, token links)     │ (staff)              ├──► LINE Messaging API → "CherryLee Staff Alerts" OA
         ▼                                ▼                      │      → owner / staff group (PII-free text)
 ┌─────────────────────────────────────────────────────┐        └──► Cloudflare Turnstile siteverify
 │ Lovable Cloud = Supabase · region Asia Pacific      │
 │  Postgres: RLS on every table, anon has no grants   │
 │  Auth: staff only · user_roles (owner | staff)      │
 │  Storage (private): payment-slips, consent-evidence │
 │  pg_cron: purge_expired_records() daily 02:15 BKK   │
 └─────────────────────────────────────────────────────┘

 Parents ⇄ studio chat stays on LINE OA @cherryleeandco — unchanged, not connected to our server.
```

### Main request flows

1. **Booking request:** `/book` form → `submitBookingRequest` (server fn) → zod → honeypot + min fill time →
   Turnstile siteverify → rate limit (`check_rate_limit`, HMAC-hashed IP) → insert `booking_requests` (service role) →
   insert `staff_notifications` row → push LINE alert, awaited with a 4-second timeout because Workers may stop
   work after the response is sent (a failure is recorded, never returned to the parent) → return `{ ok, refCode }` →
   thank-you screen with a "send this code on LINE" button (`lineMessageUrl` from `business.ts`). Parents who chose
   LINE must send that code: a LINE Official Account cannot start a chat with a LINE ID (D26).
2. **Staff reads/writes:** admin page → `useServerFn(fn)` → `requireStaff` (generated `requireSupabaseAuth` + role check)
   → `context.supabase` (RLS as the staff user, so policies and audit triggers see `auth.uid()`).
3. **Enrolment:** staff creates a link in the family page → copies it into the family's LINE chat → parent opens
   `/enrol/$token` → `getEnrolmentForm` / `submitEnrolment` resolve the token hash, scope every query to that family,
   write everything in one database transaction (`submit_enrolment`, D30): consent records (`channel = 'web'`,
   `method = 'checkbox'`), health, contacts → staff alert "enrolment submitted" (+ one alert per withdrawal, D29).
4. **Retention:** pg_cron runs `public.purge_expired_records()` daily; no HTTP, no secret.

---

## 4. What exists after each phase (at a glance)

| Phase | Tables / storage added | Public routes | Admin routes |
|---|---|---|---|
| P0 | `user_roles`, `audit_log`, `studio_settings` | — | `/admin/login`, `/admin` |
| P1 | `booking_requests`, `rate_limit_events`, `staff_notifications` | `/book`, `/privacy` | `/admin/inbox`, `/admin/inbox/$requestId`, `/admin/settings` (owner: staff roles, studio settings) |
| P2 | `sessions` | open dates on `/book` (+ optional homepage widget) | `/admin/sessions` |
| P3 | `families`, `guardians`, `children`, `family_contacts`, `package_purchases`, `payments`, `bookings`; bucket `payment-slips` | — | `/admin/families`, `/admin/families/$familyId`, `/admin/sessions/$sessionId` (roster), `/admin/payments` |
| P4 | `consent_texts`, `consent_records`, `child_health`, `family_links`, `media_assets`, `media_asset_children`; bucket `consent-evidence` | `/enrol/$token`, `/my/$token` (moved from P5, D27) | `/admin/media`; health + consent panels on family and roster pages |
| P5 | `dsr_requests`, `breach_incidents`; restriction columns on `families` | — | owner privacy card on the family page (export, erase, restrict) and `/admin/privacy` "files to delete" (core); DSR tracker, breach log, audit viewer and consent-text publishing UI are **parked** (D27) |
| P6 | report views | (optional `/pay/$token`) | `/admin/reports` |
| P7 | (optional) `guardians.line_user_id` | LINE Login / LIFF | — |

---

## 5. Key decisions

Each decision has an id so the other files can point to it.

| # | Decision | Why |
|---|---|---|
| D1 | **Lovable Cloud** (Supabase Postgres + Auth + Storage + pg_cron) is the only backend. No second vendor. | Native to Lovable, included in the plan the studio already pays for, Workers-compatible, generated auth wiring. |
| D2 | Region **Asia Pacific**, chosen by the owner when enabling. Permanent. | Closest to Bangkok. It is still outside Thailand (city not documented), so the privacy notice discloses the transfer (PDPA s.28/29). |
| D3 | **Every browser read/write goes through TanStack server functions.** The `anon` role has no table grants; RLS is on for every table, deny by default. | One place for validation and spam checks; no public database API surface. |
| D4 | **Two database clients.** Staff functions use the RLS-scoped `context.supabase` from the generated `requireSupabaseAuth`. Public and private-link functions use the service role, imported only via `src/server/supabase-admin.server.ts`, and must filter every query by the request/family they resolved. | Defence in depth (RLS + code checks) and correct actor in audit triggers; the service role stays server-only. |
| D5 | **Staff auth**: email + password, sign-up disabled, leaked-password check on; roles in `user_roles` (`owner`, `staff`) checked by SECURITY DEFINER `has_role()`. Admin routes `ssr: false` + `noindex`. Every staff server function checks the role; route guards are only for UX. | Matches what Lovable generates for TanStack (session in localStorage, Bearer token to server functions) without editing generated files. |
| D6 | **`@cherryleeandco` is not connected** to the Messaging API or a webhook in P0–P6. | The provider link is permanent, the free quota is shared with broadcasts, and every parent message would be forwarded to our server. |
| D7 | **Staff alerts via a separate "CherryLee Staff Alerts" LINE OA** (Free plan, 300 msgs/month), stateless channel token, `X-Line-Retry-Key` = notification id. Alert text has no names, phones or health data. `LINE_ALERT_TO` is the owner's own LINE user ID (no webhook needed) or a staff group ID (optional webhook to capture it). The DB row is the source of truth; a failed alert never fails a submission and shows in the admin. | LINE Notify ended 31 Mar 2025; chats live on staff phones, so keep them PII-free. |
| D8 | **A booking request is not consent.** Lawful basis PDPA s.24(3) (steps before a contract at the parent's request). No consent checkbox on `/book`; a short notice and a link to `/privacy` next to the submit button; `privacy_notice_version` saved. | PDPC consent guideline: don't bundle consent or use it where another basis fits. |
| D9 | **Minimise by stage** (§ 6). A request stores children as a small JSON list (`nickname` optional, `age_years`) on the request row, not as child records. Child profiles exist only after staff confirm a booking. | Unconverted enquiries hold the least data and are deleted after 6 months. |
| D10 | **Health data in its own table `child_health`.** A DB trigger blocks writes without a current explicit guardian consent (`health_allergy`). Reads only through audited functions (`get_child_health`, `list_session_health_flags`). Rosters show allergy chips, full notes need one more tap, and **never** say "no allergies" by default: no record = "no allergy info, check with the family before cooking" (R-07). Withdrawal or refusal deletes the row and sets the non-sensitive marker `children.allergy_check_needed_at`. Never sent on LINE. Whether to store allergy data in the system at all is an owner decision (G-HEALTH); the paper form at the studio stays a valid alternative. | PDPA s.26 (sensitive data, explicit consent only); least-privilege access with an audit trail. |
| D11 | **Children aged 10+** (PDPA s.20(1)): media publication needs the guardian's **and** the child's own consent, recorded by staff in person with a kid-friendly script. Health storage needs the guardian's explicit consent; the child's own agreement is confirmed at the first session, and if the child says no the row is deleted and staff talk with the family. Birth month unknown → treated as "needs child consent". | Safety data must exist before the first cooking class; publication can wait. **Needs lawyer confirmation.** |
| D12 | **Consent evidence**: `consent_texts` are versioned TH/EN texts with a generated sha256 and cannot be edited after publishing; `consent_records` are append-only (a trigger blocks UPDATE/DELETE except inside the purge/erase functions). Current state = latest row per child × purpose × given_by. | s.19 evidence, withdrawal as easy as giving, exact wording provable. |
| D13 | **Parents enter details through private links** (`/enrol/$token`, `/my/$token`) that staff paste into the family's existing LINE chat. Tokens: 32 random bytes, only the sha256 hash is stored; enrol links are single-use and expire after 14 days; manage links expire after **90 days** and are re-issued on request (R-21). Using a link does **not** mark the guardian's identity as checked: staff confirm in the chat and tick it (`identity_check_method = 'line_account'`). Contact fields a parent changes through a link wait in `guardians.pending_link_changes` until staff confirm them. | No parent passwords; fits the current workflow; a link pasted into the wrong chat can't silently take over a family. |
| D14 | **Seats:** `sessions` (one per Saturday/Sunday date, 09:00–15:00) with a staff-set `capacity` and `seats_held_offline` (seats promised on LINE but not entered yet). Public sees only seats left per date, never capacity or names. | The studio hasn't published a group size; aggregate numbers only. |
| D15 | **Public pages never wait on the database.** Open dates are fetched in the browser after render with a LINE fallback; if a form can't reach the server it offers "send on LINE instead" (without putting personal data in the link). | Cloud can pause or fail; the homepage stays fast and server-rendered. |
| D16 | **Packages and credits:** `package_purchases` (`single`/`four`/`eight` → 1/4/8 sessions, price snapshot from `PRICES`) and `bookings` (child × session) that use a purchase. Balance = total − non-cancelled credit-consuming bookings (view `package_balances`). `expires_on` is nullable; staff choose `absent` vs `cancelled`. | Gives the studio the numbers without inventing expiry, sharing or forfeit rules. |
| D17 | **Payments recorded by staff**, methods `promptpay` / `bank_transfer` / `cash` / `other`. No gateway, no card data. Optional slip image upload by staff to the private `payment-slips` bucket; parents keep sending slips on LINE. PromptPay QR page is optional (P6). | Zero fees; the studio's current habit; minimal financial data. |
| D18 | **Bot protection on `/book`:** honeypot field + minimum fill time 3 s + Cloudflare Turnstile (action `booking_request`) + DB rate limit on an HMAC-SHA-256 of the IP (5/hour, 20/day). Raw IPs are never stored; the hash rows live 24 hours. | Free, cookieless, no shared memory needed on Workers. |
| D19 | **Retention in SQL:** every personal-data table has `retain_until` (or a rule in the purge function); `public.purge_expired_records()` runs daily via pg_cron at `15 19 * * *` UTC (02:15 Bangkok). | No HTTP job or secret needed; shows in Lovable's Jobs view. |
| D20 | **Audit:** a generic trigger `audit_row_change()` logs actor, action, table and row id (never field values) on sensitive tables; health reads are logged inside the read functions. Kept 12 months. | PDPC security notification: audit trails, need-to-know access. |
| D21 | **Migrations are drafted** as `docs/backend/sql/NNNN_*.sql`, additive only, and **applied by a human through Lovable chat** so Lovable keeps its migration history and regenerates `src/integrations/supabase/types.ts`. Implementers never run DDL. | Lovable's docs don't say whether SQL pushed via GitHub is applied; this path is the documented one. |
| D22 | **Cookieless analytics only.** Admin reports come from our own DB (aggregates). Optional Umami Cloud (cookieless) for CTA events in P6. No GA4, no Meta Pixel. | No cookie banner needed; children's service. |
| D23 | **Copy in content files:** new public pages use `src/content/<page>.tsx` (`th` + `en`) and the existing `LanguageProvider`; the admin uses `src/content/admin.tsx` and its own `AdminLanguageProvider` (Thai default). | Same rule as the existing site (`AGENTS.md`). |
| D24 | **`src/content/videos.ts` stays the static list** of clips on the homepage. Consent truth moves to the DB (`media_assets` + consents). A withdrawal creates a takedown alert; a human removes or hides the clip in `videos.ts` and republishes. | The homepage must not depend on the DB; YouTube/Facebook takedowns are manual anyway. |
| D25 | Money as **integer baht**; dates of sessions as `date`; all timestamps `timestamptz`; display and "today" in `Asia/Bangkok`; cron in UTC. | Prices are whole baht; avoids timezone off-by-one on Saturday/Sunday dates. |
| D26 | **LINE is a parent-initiated path.** A LINE Official Account can't add a user by LINE ID or message someone who hasn't messaged it. `/book` asks how to talk: **LINE** = the parent taps "send my code to @cherryleeandco" on the thank-you screen and staff reply in that chat; **phone** = staff call `contact_phone` (then required). `contact_line_id` is an optional matching hint only. Staff never add parents from personal LINE accounts. | Sources: https://developers.line.biz/en/docs/messaging-api/getting-user-ids/ · https://support.sinch.com/hc/en-us/articles/54632381572883-Can-I-send-a-message-a-LINE-user-with-their-ID-or-phone-number . Keeps families' data off staff personal phones (D6/D7). |
| D27 | **Deliver in stages with go/no-go gates** (§ 8.0): Stage A = P0 + P1 (+ P2) is the MVP; **G-MVP** (owner, after ≥ 8 weeks of real use) decides whether to build Stage B (P3 records + P5 core privacy); **G-HEALTH** decides whether allergy data is stored in the system in Stage C (P4 + `/my`). DSR tracker, breach log, audit viewer, consent-text publishing UI, reports and every P6/P7 extra are **parked**: runbooks + a private owner spreadsheet until volume justifies them. | A 1–2 person weekend studio whose bookings live in LINE should only carry the system it uses; less stored data = less PDPA risk. |
| D28 | **Restriction (PDPA s.34) is real data**, not a status trick: `families.processing_restricted_at` + `restriction_note`, set only by the owner through `set_family_restriction()`. While set, the database refuses new bookings, enrol links, granted consents and profile edits (withdrawals still work); the family is never marked inactive or auto-erased. | `families.status` is system-managed and recomputed nightly, so it can't carry a restriction. |
| D29 | **Consent-change alerts come from the database.** An AFTER INSERT trigger on `consent_records` queues a `consent_withdrawn` staff notification whenever a guardian's or child's decision moves away from `granted` (any channel). Server code then pushes the queued row (`deliverConsentAlert`); unsent rows show in the admin with a resend button. | Every path (web enrol, `/my`, staff recording, a 10+ child's "no") starts the takedown/health runbook. |
| D30 | **Multi-row writes run in one SQL transaction**: `create_family_from_request`, `submit_enrolment` (locks the link row), `publish_consent_text`, `set_media_asset_children`, `set_primary_guardian` (R-39). Screens that need many rows use one set-returning function: `get_sessions_with_seats`, `consent_matrix`, `media_publishability`. | No half-written families or consent texts; no per-row RPC loops on Workers. |

---

## 6. Data-collection map by stage

Lawful bases refer to the Thai PDPA. Retention periods are **proposals the owner must confirm** (§ 12).

| Stage | Who enters it | What we collect | Lawful basis | Kept |
|---|---|---|---|---|
| **0. Visiting the site** | — | Nothing stored by us. Browser `localStorage` keeps the language choice. Turnstile runs on `/book` only. YouTube loads after "play". Google Maps iframe contacts Google (parked option, card PK-06: click-to-load). | Not needed (functional) | — |
| **1. Booking request** (`/book`) | Parent | What to call the parent (`guardian_name`); how they want to talk (`line` = they send the ref code to @cherryleeandco, or `phone` = call back); phone number (required only for `phone`); LINE ID (optional matching hint, D26); for each child (1–3): nickname (optional) and age in years (6–12); package interest (`single`/`four`/`eight`/not sure); preferred day or a session date; optional message (hint: "please don't include health details here"); page language; privacy-notice version. Server adds a reference code. An HMAC of the IP is kept 24 h for rate limiting. | s.24(3) pre-contract | 6 months |
| **2. Confirmed booking** (staff, admin) | Staff | Family record: guardian name, phone/LINE ID; child nickname and birth month (or age until enrolment); package purchase; payments (amount, method, date, receipt no., optional slip image); seat bookings. | s.24(3) contract; payments also s.24(6) accounting | Profile: 12 months after last activity. Payments/packages: 5 years after the accounting year (accountant to confirm). |
| **3. Enrolment link** (`/enrol/$token`, before the first session) | Parent | Confirms guardian details and the statement "I have parental responsibility for this child"; child birth month (YYYY-MM); **health (optional, separate unticked explicit-consent box)**: allergen chips, other allergens, foods to avoid (no reason asked), care notes; **media consent per channel** (`media_parents_group`, `media_website`, `media_social`, `media_youtube`) + face visible / face hidden; emergency contacts and authorised pickup persons (name, phone, relationship) with "I've told them and shared the privacy notice". | Profile/contacts: s.24(3)/(5); health: s.26 explicit consent; media: s.19/s.20 consent | Health: deleted on withdrawal or 6 months without a booking. Contacts: with the profile. Consent evidence: life of the consent + 3 years. |
| **4. First session** (in person) | Staff | Child's own consent (age 10+) for media and agreement to health info, via a kid-friendly script; guardian identity check if not done; check-in / check-out times and who picked up. | s.20(1); s.24(3)/(5) child safety | Attendance 24 months |
| **5. Ongoing** | Staff / parent | Attendance, package balance, payments, consent changes (via `/my/$token` or LINE). | As above | As above |
| **6. End** | System / owner | Automatic purge; rights requests (export, erasure) handled by the owner. | s.33, s.37(3) | Rights-request log 3 years |

### What we deliberately do NOT collect

- Thai national ID numbers, passport numbers, or copies of ID cards (guardians or pickup persons).
- Children's full legal names, full birth dates, schools, gender, nationality, home addresses.
- Reasons for foods to avoid (could reveal religion — also s.26 data), free-text medical histories, diagnoses, medication lists.
- Parent email on the booking request (it is an optional enrolment field, only for families who want receipts by email), social media profiles.
- Raw IP addresses, device fingerprints, cookies, advertising IDs, LINE chat content.
- Payer bank account numbers (slip images only if staff choose to upload one).
- Photos or videos of children (media is referenced by YouTube id and title only).
- Marketing consent (there is no marketing channel in scope).

---

## 7. Roles and access

| Data | anon (browser) | Parent via private link | `staff` | `owner` | Server (service role) |
|---|---|---|---|---|---|
| Open sessions (seats left only) | via `getOpenSessions` | — | read/write sessions | read/write | read |
| `booking_requests` | insert via `submitBookingRequest` only | — | read, update status/notes | + delete | insert |
| Families, guardians, children, contacts | — | own family only, via token functions | read/write | + delete | scoped by token |
| `child_health` | — | write own child's (with consent) | via audited functions only | same | scoped by token |
| Packages, bookings, attendance | — | — | read/write | + void | — |
| `payments` | — | — | read, create, mark paid | + void/refund, delete slip | — |
| Consent records | — | append for own family | append (paper / in person / child) | + publish consent texts | append |
| Media assets | — | — | read/write | same | — |
| DSR, breach log, audit log, staff roles, settings | — | — | — (settings: read) | read/write | — |

`owner` = the studio owner (one person). `staff` = teachers/admins (e.g. Uncle Lee, Kru Arm — studio to confirm).
Staff accounts are created by the owner in **Lovable → More → Cloud → Users → Add user**; the role is then set in
`/admin/settings`. Remove access the same day someone leaves (delete the role row, then the user).

---

## 8. Phased roadmap

Feature ids (`F1-03`) name **what** a phase delivers. `90-task-breakdown.md` turns them into task cards with their
own ids (`P1-04`, agent `cl-p1-…`) and says which feature each card implements; never mix the two. A phase is done
when its acceptance criteria pass on the Lovable preview **and** the owner has pressed Publish (G10).

### 8.0 Delivery stages and go/no-go gates (D27)

| Stage | Phases | Ships | Gate before it starts | Gate before it goes live |
|---|---|---|---|---|
| **A · MVP** | P0, P1, P2 (P2 screens recommended, can be skipped; `0003` is applied either way because `0004` builds on it) | admin login, `/book`, inbox, LINE staff alerts, `/privacy` (notice `…-v1`), sessions + seats | G0–G3 | G4 per SQL file, G5–G8, **G9a (notice v1)**, G10 |
| **G-MVP** | — | Owner go/no-go after **≥ 8 weeks** of real use: number of web requests, staff time saved, whether family records are wanted at all. "No" = stop here; Stage A keeps working on its own. | — | — |
| **B · Records** | P3 + **P5 core** | families, packages, payments, bookings, roster/attendance; retention job v4, export, erase, restriction, files-to-delete; notice `…-v2` with the `[P3]` sections | **G-MVP = go**, G11 noted | 0004, **0005 and 0007 applied** (retention/erase for families live in 0007, which depends on 0005's tables; P4 screens stay off), **G9a (notice v2)**, G10 |
| **C · Consent & safety** | P4 (incl. `/my/$token`, moved from P5 so web consent can be withdrawn on the web from day one) | enrol link, media consents, child 10+ consent, takedown alerts, `/admin/media`; allergy data **only if G-HEALTH = system**; notice `…-v3` with `[P4]`/`[P5]` sections | **G-HEALTH** decided, G0 Q9 + Q15 answered, **G9b** | 0006 (+ 0006b only if G0 Q9 = yes), **G9a (notice v3)**, G10 |
| **D · Reports** (optional) | P6 core (0008 + `/admin/reports`) | aggregates only | owner asks for it | G4 (0008), G10 |
| **Parked** | F5-02 DSR tracker / breach log / audit viewer UI, F5-05 consent-text publishing UI, F6-03 Umami, F6-04 PromptPay page, F6-05 Resend, P7 LIFF | — | owner explicitly un-parks one item (**G-PARK**) | its own cards and gates |

While an item is parked, the owner uses the runbooks in `50-security-privacy.md` (§ 18 DSR, § 20 breach, § 5 monthly
audit review via Cloud → Database → `audit_log` read-only view) and a **private** spreadsheet with the same fields as
`dsr_requests` / `breach_incidents` (no health details, kept 3 / 5 years). New consent wording is published as a new
SQL draft (like 0006) or with `publish_consent_text()` in the SQL editor (G4-style approval); that function refuses the
**first** `health_allergy` text, which only a reviewed SQL draft may add after a G-HEALTH = system decision (R-35).
The SQL for these items already exists (0005, 0007), so un-parking only adds screens.

**No real family data before Stage B is live.** Lovable drafts share one database: until Stage B is published, staff
enter only obviously fake test families on the preview and delete them before go-live.

**Privacy notice per stage (PDPA s.23, notice before collection).** `PRIVACY_NOTICE_VERSION` uses the format
`YYYY-MM-vN` (e.g. `2026-11-v1`): N goes up by one each time the meaning changes, YYYY-MM is the month it goes live.
The wording source is `50-security-privacy.md` §§ 11.3–11.4 (sections tagged `[P1]`, `[P3]`, `[P4]`, `[P5]`, `[P6]`);
`src/content/privacy.tsx` implements it (pattern in `30-ui.md` § 3.4). Each stage's go-live checklist (G10) includes
"the notice covers everything this stage collects and the version was bumped".

### P0 · Foundations and human gates

Goal: backend switched on safely, guard rails in the code, owner can sign in to an empty admin.

P0a (can start now, no database needed):
- **F0-01** `src/server/env.server.ts` (`requireServerEnv`, `optionalServerEnv`) + test.
- **F0-02** Pure helpers with vitest tests: `ref-code.ts`, `thai-phone.ts`, `spam-checks.ts`, `age.ts`, `dates.ts`,
  `result.ts`, `common.schema.ts`, `staff-alert-text.ts`, `public-config.ts`, `limits.ts` (in `src/lib/backend/`);
  server-only `hash.server.ts`, `line-signature.server.ts`, `turnstile.server.ts`, `line-alert.server.ts`,
  `client-ip.server.ts` (fetch mocked in tests).
- **F0-03** `public/robots.txt`: add `Disallow: /admin`, `/enrol/`, `/my/`, `/pay/`. ESLint: forbid importing
  `@/integrations/supabase/client.server` outside `src/server/**`.
- **F0-04** `AGENTS.md`: add a short "Backend" section pointing to `docs/backend/README.md` and the golden rules.
- **F0-05** Draft `docs/backend/sql/0001_foundation.sql` (done in planning; a card only pre-checks it).

P0b (after gates G1–G3, then G4 for 0001 and G5):
- **F0-06** Verify what Lovable generated (`src/integrations/supabase/*`, `.env`, `supabase/config.toml`,
  `@supabase/supabase-js`, `functionMiddleware: [attachSupabaseAuth]` in `src/start.ts` with both existing middlewares
  still there). Write findings into `40-integrations.md` § 2.
- **F0-07** `src/server/supabase-admin.server.ts` (marker + re-export of `supabaseAdmin`).
- **F0-08** `src/lib/backend/auth.middleware.ts` (`requireStaff`, `requireOwner`) + `staff.functions.ts`.
- **F0-09** Admin shell: `src/routes/admin/route.tsx`, `admin/login.tsx`, `admin/_staff/route.tsx`, `admin/_staff/index.tsx`,
  `src/i18n/AdminLanguageProvider.tsx`, `src/content/admin/index.ts` + `src/content/admin/core.tsx` (the admin copy is
  split into one module per area, added by the card that builds that area, R-17), `src/components/admin/AdminShell.tsx`, sign-out.

Acceptance:
- Owner signs in at `/admin/login` on the preview and sees an empty dashboard showing their role; a signed-in user with
  no role sees "ไม่มีสิทธิ์เข้าถึง / No access"; signed-out visits to `/admin/*` go to `/admin/login`.
- Read-only RLS smoke check (`sql/tests/rls_smoke.sql`, pasted into **Cloud → SQL editor** by the builder with the
  owner's OK): no `FAIL` lines. Cloud → Users → Auth settings shows **sign-up disabled**.
- All acceptance commands in `README.md` pass; leak check prints nothing; `/admin` HTML has `noindex`.
- Human gates: G0–G5 done (G0 answers may still be partial).

### P1 · Booking requests, admin inbox, staff alerts

Goal: parents can leave a structured request; staff see it in the inbox and get a LINE alert.

- **F1-01** SQL `0002_booking_requests.sql`: enums, `booking_requests`, `rate_limit_events`, `check_rate_limit()`,
  `staff_notifications`, `purge_expired_records()` v1 + pg_cron jobs (`purge-expired-records`, `cron-history-cleanup`).
  If Lovable refuses `cron.schedule`: the HTTP fallback job (route `/api/cron/purge`, R-19).
- **F1-02** `/privacy` page with the `[P1]` sections (TH/EN), `PRIVACY_NOTICE_VERSION = "YYYY-MM-v1"`:
  `src/routes/privacy.tsx`, `src/content/privacy.tsx`. **Gate G9a** before go-live.
- **F1-03** `booking.schema.ts` (`BookingRequestInput`, D26 contact rule) + `booking.functions.ts` (`submitBookingRequest`)
  with the checks in D18, insert, notification, `PublicResult` return.
- **F1-04** `staff-notify.server.ts`: create `staff_notifications` row, build PII-free text, push, record `sent`/`failed`.
- **F1-05** `/book` page: `src/routes/book.tsx`, `src/content/booking.tsx`, `src/components/booking/BookingForm.tsx`,
  `TurnstileWidget.tsx`, `BookingThanks.tsx` (ref code + "ส่งรหัสทาง LINE" as the main action for parents who chose LINE),
  failure fallback to LINE, `src/components/SubpageHeader.tsx` for non-home pages. `?package=` and `?lang=` prefill.
- **F1-06** Admin inbox: `/admin/inbox` (filters by status, unread badge), `/admin/inbox/$requestId` (detail, status,
  staff note, "mark spam", "resend alert", tap-to-call; the LINE ID is shown as a **matching hint** to find the parent's
  chat in @cherryleeandco, never as "add this person", D26); `inbox.functions.ts`.
- **F1-07** Homepage entry points: a secondary "ฝากข้อมูลให้ติดต่อกลับ / Leave your details" link in the CTA band and under
  the pricing cards, and an updated FAQ "จองที่นั่งอย่างไร?" answer. LINE stays the primary button. Copy in `site.tsx`, both languages.
- **F1-08** (optional) `/api/line/alert-webhook` to capture a staff group ID (replies the group id into the group; stores nothing).
- **F1-09** `/admin/settings` (owner): list staff users and roles, give/remove `staff` role by email of an existing
  Cloud user (`listStaff`, `setStaffRole`, `removeStaffRole`), studio settings (`booking_form_open`,
  `staff_alerts_enabled`, `default_session_capacity`).
- **F1-10** Preview end-to-end check after G6–G8 (main session + owner).

Acceptance:
- A test request on the preview creates one row with a `CL-XXXXX` code, shows the thank-you screen in TH and EN, and the
  owner receives a LINE alert within a minute containing only code, date, number of children and the admin link.
- With alerts misconfigured, the request still saves and the inbox shows "แจ้งเตือนไม่สำเร็จ / Alert failed" with a resend button.
- Unit tests cover: honeypot → fake success and nothing stored; < 3 s → `too_fast`; Turnstile false → `bot_check_failed`;
  rate limit → `rate_limited`; invalid phone/LINE ID/age → `invalid_input`; alert text contains no name/phone.
- The form works with keyboard only, every input has a label, errors are announced, touch targets ≥ 44 px.
- No personal data in server logs (spot-check Lovable → Cloud → Logs); `/privacy` linked next to the submit button.
- A parent who picks LINE and gives no phone or LINE ID can still send the form; the thank-you screen makes "send my
  code on LINE" the main action and explains that the studio replies in that chat (D26). Picking phone without a
  number shows `preferred_missing`.
- Privacy notice `…-v1` (all `[P1]` sections) is live and approved (G9a) before the form is published.

### P2 · Sessions and seats

Goal: staff manage weekend dates and capacity; parents see open dates and seats left.

- **F2-01** SQL `0003_sessions.sql`: `session_status`, `sessions`, `booking_requests.session_id`, `session_seats_left()`,
  `get_open_sessions(p_from, p_to)` (service role only), `get_sessions_with_seats(p_from, p_to)` (one call for the admin
  month list, D30), `generate_weekend_sessions(p_from, p_weeks, p_capacity)`;
  `studio_settings.default_session_capacity` used as default.
- **F2-02** Admin `/admin/sessions`: month list, "สร้างรอบเสาร์–อาทิตย์ N สัปดาห์ / Create weekend sessions", edit capacity,
  status, `seats_held_offline`, public note (TH/EN), staff note.
- **F2-03** `sessions.functions.ts`: `getOpenSessions` (public, next 8 weeks), `listSessions`, `saveSession`,
  `generateWeekendSessions` (staff).
- **F2-04** `/book` session picker (client-fetched, fallback "ask on LINE"); full dates show a "full" badge and still allow
  a request (wording: owner to approve, no promise of a call-back when a seat frees). Optional homepage "รอบที่เปิดรับ /
  Open dates" strip in the pricing section.
- **F2-05** Inbox shows the chosen session; alert text includes its date.

Acceptance: staff create 8 weekends in one action; the public list shows only date, time and seats left for `open`
sessions from today (Bangkok) onwards; capacity never appears in any public response; with the DB unreachable `/book`
still renders and offers LINE; seats left = capacity − `seats_held_offline` (until P3 adds bookings).

### P3 · Families, packages, payments, bookings, attendance (Stage B)

Goal: the studio's day-to-day records in one place.

- **F3-01** SQL `0004_families.sql`: `families`, `guardians`, `children`, `family_contacts` (soft delete `is_active`),
  `package_purchases` (`sessions_used_purged`), `payments`, `bookings`, view `package_balances`,
  `booking_requests.converted_family_id`, `session_seats_left()` v2, `get_sessions_with_seats` v2,
  `create_family_from_request()` (one transaction), session-cancel trigger, bucket `payment-slips` + storage policies,
  purge v2, audit triggers.
- **F3-02** "Convert to family" from an inbox request (prefills guardian and children with each child's age from the
  request; staff confirm) → one `create_family_from_request` call.
- **F3-03** `/admin/families` (search by nickname, guardian name, phone) and `/admin/families/$familyId` (guardians,
  children, contacts, packages + balances, payments, bookings history).
- **F3-04** Package purchase (staff close, owner void / expiry) + payment recording; optional slip upload
  (jpg/png/webp/pdf ≤ 5 MB), 60-second signed view, owner slip deletion.
- **F3-05** Book a child into a session using a package credit; cancel returns the credit; seats update; cancelling a
  whole session (with a warning) cancels its held/confirmed bookings.
- **F3-06** Roster `/admin/sessions/$sessionId`: children booked, check-in / check-out time, picked up by (guardian or
  authorised pickup person), attended / absent.
- **F3-07** `/admin/payments`: pending payments to verify, paid this month.
- **F3-08** Privacy notice `…-v2`: add every `[P3]` section (family records, payments, attendance, contacts, retention
  rows) before Stage B goes live (G9a).

Acceptance: on test data, request → family → 4-session package → payment marked paid → two bookings → check-in/out →
balance shows 2 left and seats left drops by 2; a `staff` user cannot void payments or delete families (owner can);
`audit_log` has rows for each write on families/guardians/children/contacts/payments with the staff user id;
deleting a contact keeps the "picked up by" record; notice `…-v2` live.

### P5 core · Privacy operations needed by Stage B

Goal: old data disappears by itself, and the owner can answer access, erasure and restriction requests from day one
of Stage B.

- **F5-01** SQL `0007_privacy_ops.sql` (applied after 0005): `dsr_requests`, `breach_incidents` (tables only while their
  screens are parked), restriction columns + guard (D28), `mark_inactive_families()`, `export_family_data()`,
  `erase_family()`, purge v4 (all tables).
- **F5-02c** Owner privacy card on the family page: export JSON, erase with typed confirmation, restrict / lift
  restriction (`setFamilyRestriction`); restricted-family banner on the family page.
- **F5-07** `/admin/privacy` "files to delete" (`listStorageCleanup`, `runStorageCleanup`): owner deletes queued
  storage files the same day as an erasure and monthly otherwise.
- **F5-06** Owner MFA (TOTP) — only if Lovable Cloud allows MFA; verify first (human).

Parked until G-PARK: **F5-02** DSR tracker with countdowns, breach log with the 72-hour timer, audit log viewer;
**F5-05** consent-text publishing UI. **F5-03** `/my/$token` moved to Stage C (P4). **F5-04** notice text is split by
stage (F1-02, F3-08, F4-10).

Acceptance: the Jobs view shows the daily purge as Succeeded; fake rows with past `retain_until` disappear after a run
(SQL editor, fake data only); export returns one family's data only; erase removes personal data but keeps anonymised
payment amounts and dates; a restricted family can't get a new booking or link and is skipped by the inactivity job;
used credits stay used after the bookings behind them are purged.

### P4 · Safety and consent records (Stage C)

Goal: allergy info (only if G-HEALTH = system) and media permissions recorded properly, with evidence, before they are
used; parents can withdraw on the web as easily as they gave consent.

- **F4-01** SQL `0005_consent_health.sql` (the whole file was already applied in Stage B at G4 · 0005, functions
  included; only the P4 screens wait for Stage C): consent enums, `consent_texts`,
  `consent_records` (append-only), view `current_consents`, `child_health` + consent trigger + withdrawal trigger,
  consent-change alert trigger (D29), `family_links`, `media_assets`, `media_asset_children`, functions
  `child_age_years`, `has_active_consent`, `consent_status`, `can_publish_media`, `get_child_health`,
  `upsert_child_health`, `list_session_health_flags`, `consent_matrix`, `media_publishability`,
  `set_media_asset_children`, `publish_consent_text`, `submit_enrolment`; bucket `consent-evidence`; purge v3.
- **F4-02** SQL `0006_seed_consent_texts.sql`: v1 TH/EN texts for health and three media channels. **Gate G9b** (legal
  review) before applying. `0006b_seed_media_parents_group.sql` only if G0 Q9 confirms the private parents' group.
- **F4-03** Staff: "สร้างลิงก์กรอกข้อมูล / Create enrolment link" on the family page (copy button, expiry shown, revoke).
- **F4-04** Public `/enrol/$token`: guardian confirmation + parental-responsibility statement, child birth month, health
  section (own unticked explicit-consent box showing the full text; "ไม่ใช่ตอนนี้ / Not now" records nothing; a separate
  "ไม่ต้องการให้ข้อมูลนี้ / I don't want to share this" records a refusal and deletes earlier info), media: **each
  published purpose shows its title and full text above its own unticked control** (R-04) + face level, contacts with
  "I've told them". Noindex + `no-referrer`. Staff alert on submit; staff confirm changed contact details. A link
  re-sent to an enrolled family shows each child's current media decision; an unticked box keeps it (R-33);
  withdrawing happens on `/my` or with staff.
- **F4-05** Staff consent recording: paper/in-person (evidence upload), child's own consent for 10+ with the script in `30-ui.md`.
- **F4-06** Health on roster: three states (allergies / parent reported none / no info — check with the family before
  cooking), full notes via `get_child_health` (audited); edit via `upsert_child_health`. Hidden if G-HEALTH = paper.
- **F4-07** `/admin/media`: assets (the 6 clips in `videos.ts` are seeded; legacy cover per channel from G0 Q15), link
  children, publishability matrix per channel; legacy-only clips show "check manually", never "needs takedown".
- **F4-08** `videos.ts`: optional `mediaAssetId` on `Video`; README note on the takedown steps.
- **F4-09** Parent `/my/$token` "ความยินยอมของฉัน / My consents" (moved from P5): current consents for **every** child of
  the family (inactive ones labelled), withdraw or grant with one click, full text visible; staff create/revoke manage links (90 days).
- **F4-10** Privacy notice `…-v3`: add every `[P4]` section and the `/my` part of `[P5]` before Stage C goes live (G9a).

Acceptance: inserting into `child_health` without a granted `health_allergy` consent fails in the DB; a withdrawal
record deletes the health row and queues a staff alert; each health read writes one `audit_log` row; a 10+ child without
their own media consent shows "not publishable"; an enrol link works once and not after expiry, and two concurrent
submits can't both succeed; `consent_texts` rows can't be edited after insert (only `retired_at`); no consent control is
pre-ticked and every consent control has its full text visible (UI tests); withdrawing a granted media channel on
`/my` (or by staff) records `withdrawn` and alerts staff, while an unticked box on a re-sent `/enrol` link keeps the
earlier decision (R-33); a 10+ child's health "no" hides the health box on `/enrol` (R-34); notice `…-v3` live.

### P6 · Reporting (Stage D, optional) and parked extras

- **F6-01** SQL `0008_reporting.sql`: views with `security_invoker = true`: `report_requests_weekly`,
  `report_session_fill`, `report_attendance_monthly`, `report_revenue_monthly` (owner only).
- **F6-02** `/admin/reports`: requests per week by status, request → family conversion, seats filled per session,
  attendance rate, revenue per month, outstanding credits. Aggregates only. CSV download (no health, no contacts).
- **F6-03** (parked) Analytics: confirm Lovable's built-in analytics sets no cookies (G12); optional Umami Cloud cookieless.
- **F6-04** (parked) `/pay/$token` fixed-amount PromptPay QR (needs `PROMPTPAY_ID` and the `uqr` package added by Lovable).
- **F6-05** (parked) Resend backup email alert to the owner's inbox only.

Acceptance: report numbers match a hand count on test data; no names or contacts in any report.

### P7 · (parked) Parent self-service via LINE Login / LIFF

Parents see their bookings and credits and get reminders. Needs a LINE Login channel under the **same studio-owned
provider**, the Messaging API on `@cherryleeandco` (webhook off), quota budget (each reminder counts), privacy-notice
update, `guardians.line_user_id` with consent and a "disconnect LINE" option. Owner decision gate before any work.

---

## 9. Human-gated steps

Implementers never do these. "Builder" = the person running Claude / Lovable for the studio (with the main Claude
session acting only after the user's explicit yes in chat). "Owner" = the studio owner.

| Gate | When | Who | What |
|---|---|---|---|
| **G0** | Before P0 | Owner | Answer § 13 (at least: legal form, owner/staff accounts, capacity habit, payment timing, retention OK). |
| **G1** | Before enabling | Owner (workspace owner) | Lovable → Settings → Cloud permissions: **Enable Cloud = Ask each time**, **Modify database = Ask each time**, **Configure auth = Ask each time**, **Execute backward incompatible database migrations = Never allow**. Check Advanced settings → estimated monthly cost. |
| **G2** | P0 | Owner | Enable Lovable Cloud on the **main version** (not a draft), region **Asia Pacific** (permanent). Read and keep a copy of Lovable's DPA (https://lovable.dev/th/data-processing-agreement). |
| **G3** | P0 | Builder | One bootstrap prompt in Lovable chat: *"Set up staff login with email and password only. Disable public sign-up. Turn on leaked-password protection. Do not create any tables. Keep errorMiddleware and csrfMiddleware in src/start.ts."* Then `git pull --ff-only` and run F0-06. |
| **G4** | Each migration | Builder | Paste one `docs/backend/sql/NNNN_*.sql` into Lovable chat: *"Apply this SQL migration exactly as written. Do not change it."* Approve the shown SQL. Then `git pull --ff-only` (gets Lovable's migration file + regenerated `types.ts`). On 0001, record which folder Lovable used and whether the change hit the live DB before Publish. |
| **G5** | P0 | Owner | Create own user (Cloud → Users → Add user), then run the owner-role SQL template from `40-integrations.md` § 1 in **Cloud → SQL editor** (not Lovable chat, so it never becomes a migration; the email is typed there only, never committed). |
| **G6** | P1 | Owner | Secrets in Cloud → Secrets: `IP_HASH_SECRET` (generate on your own computer with `openssl rand -hex 32` and paste directly; never in chat or code), `TURNSTILE_SECRET_KEY`, `LINE_ALERT_CHANNEL_ID`, `LINE_ALERT_CHANNEL_SECRET`, `LINE_ALERT_TO`, `PUBLIC_SITE_URL`. |
| **G7** | P1 | Owner | Cloudflare account (studio-owned) → Turnstile widget with **exact** hostnames: the published `*.lovable.app` host, `id-preview--fa9b86e9-5d99-468e-be51-3be106fa410c.lovable.app`, later the custom domain. **Never** the apex `lovable.app`. Site key → builder puts it in `src/lib/backend/public-config.ts`; secret → G6. |
| **G8** | P1 | Owner | LINE Developers: a provider named "CherryLee & Co." owned by the studio's own LINE account (permanent). New OA "CherryLee Staff Alerts" (Free), Messaging API on, chat / auto-reply / greeting off. Owner adds the OA as a friend; `LINE_ALERT_TO` = owner's user ID from Basic settings (or a group ID via F1-08). |
| **G9a** | Before **each** stage goes live (A: `…-v1`, B: `…-v2`, C: `…-v3`) | Owner (+ lawyer) | Approve the privacy-notice version that covers everything the stage collects (§ 8.0). Lawyer review strongly recommended. |
| **G9b** | Before Stage C | Owner + Thai PDPA lawyer | Review consent texts (health, media, children 10+ approach in D11, the `OWNER-APPROVE` lines), then apply `0006_seed_consent_texts.sql` (+ `0006b` only if G0 Q9 = yes). |
| **G10** | End of each phase | Owner | Publish in Lovable (Publish → Publish changes). Before pressing it: fix any critical RLS findings from the publish security scan; confirm Cloud → Users → Auth settings still shows **sign-up disabled**; confirm the privacy notice covers the stage (§ 8.0); run `rls_smoke.sql` in the SQL editor (no `FAIL`). Checklist: `40-integrations.md` § 13. |
| **G-MVP** | After ≥ 8 weeks of Stage A in real use | Owner | Go/no-go for Stage B, based on real request volume and whether family records are wanted (D27). Record the decision and date in `90-task-breakdown.md` § 2. |
| **G-HEALTH** | Before Stage C | Owner (+ lawyer) | Store allergy data in the system (explicit consent, audited) **or** keep the paper allergy form at the studio. The switch (R-29): **system** = builder sets `HEALTH_IN_SYSTEM = true` in `src/lib/backend/public-config.ts` and applies 0006 as reviewed; **paper** = keep `HEALTH_IN_SYSTEM = false` and delete the two `health_allergy` rows from the **unapplied** 0006 draft before G4, so no health consent (and so no health row) can ever exist; `/enrol` and `/my` then show no health section (they only show purposes with a current text) and the roster shows "see the paper allergy form at the studio". The health code is built either way. |
| **G-PARK** | Any time | Owner | Un-park one parked item (DSR/breach/audit screens, consent-text publishing UI, Umami, PromptPay, Resend, LIFF); only then its cards may run. |
| **G11** | P3 | Owner + accountant | Confirm payment record retention (5 years? juristic person or sole proprietor?). |
| **G12** | P6 | Owner | Check Lovable analytics in DevTools for cookies; optional Umami account; optional Resend; optional PromptPay ID. |
| **G13** | Any time | Owner | Custom domain (optional): then update Turnstile hostnames, `PUBLIC_SITE_URL`, Umami domains, JSON-LD URLs. |

---

## 10. Naming conventions

### Database

- Tables: `snake_case`, plural (`booking_requests`). Columns: `snake_case`; FKs `<entity>_id`; times `*_at timestamptz`;
  dates `*_on date` (except `session_date`, `birth_month`); money `*_thb integer`; every table has `id uuid primary key
  default gen_random_uuid()` (log tables: `bigint generated always as identity`), `created_at`, and `updated_at` where rows change.
- Retention column: `retain_until timestamptz`. Deadlines that depend on another timestamp are set by a BEFORE trigger,
  not a generated column (`timestamptz + interval` is not immutable).
- Functions: `snake_case` verbs; SECURITY DEFINER functions always `set search_path = ''` and schema-qualify everything.
- Policies: `"<table>_<role>_<action>"`, e.g. `"booking_requests_staff_select"`.
- Views: `security_invoker = true`. Storage paths: `<family_id>/<uuid>.<ext>`.

**Tables:** `user_roles`, `audit_log`, `studio_settings`, `booking_requests`, `rate_limit_events`, `staff_notifications`,
`sessions`, `families`, `guardians`, `children`, `family_contacts`, `package_purchases`, `payments`, `bookings`,
`consent_texts`, `consent_records`, `child_health`, `family_links`, `media_assets`, `media_asset_children`,
`dsr_requests`, `breach_incidents`. **Views:** `package_balances`, `current_consents`, `report_requests_weekly`,
`report_session_fill`, `report_attendance_monthly`, `report_revenue_monthly`. **Buckets:** `payment-slips`, `consent-evidence`.

**Enums (exact values):**

| Enum | Values |
|---|---|
| `app_role` | `owner`, `staff` |
| `site_lang` | `th`, `en` |
| `booking_request_status` | `new`, `contacted`, `waitlisted`, `converted`, `closed`, `spam` |
| `contact_preference` | `line`, `phone` |
| `package_code` | `single`, `four`, `eight` |
| `preferred_day` | `sat`, `sun`, `either` |
| `notification_kind` | `booking_request`, `enrolment_submitted`, `consent_withdrawn` |
| `notify_status` | `pending`, `sent`, `failed`, `skipped` |
| `session_status` | `draft`, `open`, `closed`, `cancelled` |
| `family_status` | `active`, `inactive` |
| `identity_check_method` | `in_person`, `line_account`, `phone_callback` |
| `package_purchase_status` | `active`, `closed`, `void` |
| `payment_method` | `promptpay`, `bank_transfer`, `cash`, `other` |
| `payment_status` | `pending`, `paid`, `refunded`, `void` |
| `booking_status` | `held`, `confirmed`, `attended`, `absent`, `cancelled` |
| `consent_purpose` | `health_allergy`, `media_parents_group`, `media_website`, `media_social`, `media_youtube` |
| `consent_decision` | `granted`, `refused`, `withdrawn` |
| `consent_given_by` | `guardian`, `child` |
| `consent_channel` | `web`, `line`, `paper`, `in_person` |
| `consent_method` | `checkbox`, `signature`, `staff_recorded_verbal` |
| `media_level` | `face_visible`, `face_hidden` |
| `link_purpose` | `enrol`, `manage` |
| `media_asset_kind` | `youtube`, `photo`, `other` |
| `media_asset_status` | `active`, `taken_down` |
| `dsr_right` | `access`, `portability`, `objection`, `erasure`, `restriction`, `rectification`, `withdraw_consent` |
| `dsr_channel` | `in_person`, `registered_mail`, `line`, `email`, `web` |
| `dsr_status` | `received`, `in_review`, `waiting_for_requester`, `extended`, `completed`, `refused` |
| `breach_risk` | `unlikely`, `risk`, `high` |

Allergen chips (`child_health.allergens text[]`, checked list): `peanut`, `tree_nut`, `milk`, `egg`, `wheat`, `soy`,
`fish`, `shellfish`, `sesame`; anything else goes in `other_allergens`.

**Database functions:** `has_role(_user_id uuid, _role app_role)`, `is_staff()`, `is_owner()`, `current_app_role()`,
`set_updated_at()`, `audit_row_change()`, `prevent_update_delete()`, `check_rate_limit(p_bucket text, p_key_hash text,
p_max_per_hour int, p_max_per_day int)`, `purge_expired_records()`, `session_seats_left(p_session_id uuid)`,
`get_open_sessions(p_from date, p_to date)`, `generate_weekend_sessions(p_from date, p_weeks int, p_capacity int)`,
`child_age_years(p_birth_month date, p_on date)`, `has_active_consent(p_child_id uuid, p_purpose consent_purpose)`,
`consent_status(p_child_id uuid, p_purpose consent_purpose)` → `'granted' | 'needs_child' | 'not_granted'`,
`can_publish_media(p_asset_id uuid, p_purpose consent_purpose)`, `get_child_health(p_child_id uuid)`,
`upsert_child_health(p_child_id uuid, p_allergens text[], p_other_allergens text, p_foods_to_avoid text, p_care_notes text)`,
`list_session_health_flags(p_session_id uuid)`, `mark_inactive_families()`, `export_family_data(p_family_id uuid)`,
`erase_family(p_family_id uuid)`. Purge/erase bypass for append-only tables: `set local cherrylee.allow_purge = 'on'`.
Added by the review (§ 15): `get_sessions_with_seats(p_from date, p_to date)`, `create_family_from_request(p_request_id
uuid, p_display_name text, p_guardian jsonb, p_children jsonb)`, `consent_matrix(p_child_ids uuid[])`,
`media_publishability()`, `set_media_asset_children(p_asset_id uuid, p_child_ids uuid[])`,
`publish_consent_text(p_purpose, p_title_th, p_body_md_th, p_title_en, p_body_md_en, p_is_explicit,
p_requires_child_consent_from_age)`, `submit_enrolment(p_link_id uuid, p jsonb)`, `set_family_restriction(p_family_id
uuid, p_restricted boolean, p_note text)`, `set_primary_guardian(p_guardian_id uuid)` (R-39); trigger functions `guard_package_purge_counter`,
`cancel_bookings_of_cancelled_session`, `queue_consent_change_alert`, `guard_family_restriction_columns`,
`block_restricted_family`. New columns: `guardians.pending_link_changes`, `children.allergy_check_needed_at`,
`family_contacts.is_active`, `package_purchases.sessions_used_purged`, `media_assets.legacy_consent_purposes`,
`families.processing_restricted_at`, `families.restriction_note`. Transaction flag for restrictions:
`cherrylee.allow_restriction_change` (only inside `set_family_restriction`).

**SQL files:** `docs/backend/sql/0001_foundation.sql`, `0002_booking_requests.sql`, `0003_sessions.sql`,
`0004_families.sql`, `0005_consent_health.sql`, `0006_seed_consent_texts.sql`, `0006b_seed_media_parents_group.sql`
(optional), `0007_privacy_ops.sql`, `0008_reporting.sql`, `sql/tests/rls_smoke.sql`, `sql/seed_dev.sql`.
**Apply order:** 0001 → 0002 → 0003 → 0004 → 0005 → 0007 → (0006, 0006b at G9b) → 0008. **pg_cron jobs:** `purge-expired-records` (`15 19 * * *`),
`cron-history-cleanup` (`0 20 * * *`).

### TypeScript files

| Kind | Path pattern | Rule |
|---|---|---|
| Server-only modules | `src/server/<name>.server.ts` | first line `import "@tanstack/react-start/server-only";` |
| Server functions | `src/lib/backend/<area>.functions.ts` | never in a `server/` folder; **exports nothing but `createServerFn(...)` results** (no helpers, types or constants: put those in `<area>.schema.ts` or a pure helper), and uses `@/server/*` imports only inside `.handler()` bodies (R-26) |
| Zod schemas + shared types | `src/lib/backend/<area>.schema.ts` | browser-safe |
| Pure helpers | `src/lib/backend/<name>.ts` | browser-safe, unit-tested |
| Middleware | `src/lib/backend/auth.middleware.ts` | `requireStaff`, `requireOwner` |
| Public components | `src/components/booking/*`, `src/components/enrol/*`, `src/components/my/*`, `src/components/privacy/*`, `src/components/SubpageHeader.tsx` | |
| Admin components | `src/components/admin/*` | |
| Copy | `src/content/booking.tsx`, `privacy.tsx`, `enrol.tsx`, `my-consents.tsx`; admin: `src/content/admin/index.ts` (assembles `adminContent`) + one module per area `src/content/admin/<area>.tsx` (`core`, `inbox`, `settings`, `sessions`, `families`, `payments`, `health`, `consents`, `media`, `privacy`, `reports`), R-17 | export `<name>Content: Record<Lang, …>`; admin area modules export `admin<Area>: Record<Lang, Admin<Area>>` |
| Tests | next to the file: `<name>.test.ts` | |

Server-only modules: `env.server.ts` (`requireServerEnv`, `optionalServerEnv`), `supabase-admin.server.ts`
(`supabaseAdmin`), `client-ip.server.ts` (`getClientIp`), `hash.server.ts` (`hmacSha256Hex`, `sha256Hex`, `hashIp`),
`rate-limit.server.ts` (`checkRateLimit`), `turnstile.server.ts` (`verifyTurnstile`), `line-alert.server.ts`
(`issueLineStatelessToken`, `pushLineText`), `line-signature.server.ts` (`verifyLineSignature`), `staff-notify.server.ts`
(`notifyStaff`), `link-tokens.server.ts` (`newLinkToken`, `resolveLinkToken`).

Pure helpers: `ref-code.ts` (`makeRefCode`, `REF_CODE_PATTERN`), `thai-phone.ts` (`normaliseThaiPhone`, `isValidThaiPhone`),
`spam-checks.ts` (`isHoneypotFilled`, `isTooFast`, `MIN_FILL_MS = 3000`), `age.ts` (`ageFromBirthMonth`,
`needsChildConsent`, `CHILD_CONSENT_AGE = 10`), `dates.ts` (`todayInBangkok`, `formatSessionDate`, `upcomingWeekendDates`),
`result.ts` (`PublicResult<T>`, `PublicErrorCode`), `staff-alert-text.ts` (`buildStaffAlertText`), `public-config.ts`
(`TURNSTILE_SITE_KEY`, `TURNSTILE_TEST_SITE_KEY`, `UMAMI_WEBSITE_ID`, `HEALTH_IN_SYSTEM` from P4, R-29), `limits.ts`
(`DB_LIMITS`), `promptpay.ts` (P6, `promptPayPayload`).

### Server functions (file → exported names)

| File | Public (no login) | Staff | Owner only |
|---|---|---|---|
| `booking.functions.ts` | `submitBookingRequest` | | |
| `sessions.functions.ts` | `getOpenSessions` | `listSessions`, `saveSession`, `generateWeekendSessions`, `getSessionRoster` | |
| `inbox.functions.ts` | | `listBookingRequests`, `getBookingRequest`, `updateBookingRequest`, `retryStaffNotification`, `listPendingStaffAlerts` (P4, R-30) | |
| `staff.functions.ts` | | `getAdminMe` (any signed-in user), `getStudioSettings` | `listStaff`, `setStaffRole`, `removeStaffRole`, `updateStudioSettings`, `getSystemCheck` (P1, R-30) |
| `families.functions.ts` | | `listFamilies`, `getFamily`, `createFamilyFromRequest`, `saveFamily`, `saveGuardian` (incl. confirming link changes), `saveChild`, `saveFamilyContact`, `deleteFamilyContact` (soft delete) | |
| `payments.functions.ts` | | `createPackagePurchase`, `updatePackagePurchase` (close), `recordPayment`, `updatePayment`, `listPayments`, `getSlipUrl`, `uploadPaymentSlip` | `voidPayment`, `deletePaymentSlip`, `updatePackagePurchase` (void, expiry) |
| `bookings.functions.ts` | | `createBooking`, `updateBookingStatus`, `cancelBooking` | |
| `enrolment.functions.ts` | `getEnrolmentForm`, `submitEnrolment` (token) | `createEnrolmentLink`, `revokeFamilyLink` | |
| `consent.functions.ts` | | `listChildConsents`, `recordStaffConsent`, `uploadConsentEvidence`, `getConsentEvidenceUrl` | parked: `listConsentTexts`, `publishConsentText`, `retireConsentText` |
| `health.functions.ts` | | `getChildHealth`, `saveChildHealth`, `getSessionHealthFlags` | |
| `media.functions.ts` | | `listMediaAssets`, `saveMediaAsset`, `setMediaAssetChildren`, `markMediaTakenDown` | |
| `my.functions.ts` | `getMyConsents`, `updateMyConsent` (token) | `createManageLink` | |
| `privacy.functions.ts` | | | core: `exportFamilyData`, `eraseFamily`, `setFamilyRestriction`, `listStorageCleanup`, `runStorageCleanup`; parked: `listDsrRequests`, `saveDsrRequest`, `listBreachIncidents`, `saveBreachIncident`, `listAuditLog` |
| `reports.functions.ts` | | `getReports` (revenue fields only for owner) | |
| `src/routes/api/cron/purge.ts` (fallback only, R-19) | server route called by a Lovable Job with `LOVABLE_CRON_SECRET` | | |

Public functions return `PublicResult<T>` = `{ ok: true; data: T } | { ok: false; code: PublicErrorCode }` and never
throw for expected errors. `PublicErrorCode` = `invalid_input` | `too_fast` | `bot_check_failed` | `rate_limited` |
`form_closed` | `link_invalid` | `link_expired` | `link_used` | `server_error`. Staff functions throw (React Query shows the error);
`AdminErrorCode` adds `family_restricted` (D28) to the list in `20-server-api.md` § 4.
React Query keys: `["admin", <area>, …params]`, `["public", "open-sessions"]`.

### Routes

| URL | File |
|---|---|
| `/book` | `src/routes/book.tsx` (`?lang=`, `?package=single\|four\|eight`, `?session=<uuid>`) |
| `/privacy` | `src/routes/privacy.tsx` |
| `/enrol/$token` | `src/routes/enrol.$token.tsx` (noindex, `referrer: no-referrer`) |
| `/my/$token` | `src/routes/my.$token.tsx` (noindex, `referrer: no-referrer`) |
| `/pay/$token` (P6, optional) | `src/routes/pay.$token.tsx` |
| `/api/line/alert-webhook` (optional) | `src/routes/api/line/alert-webhook.ts` |
| `/admin/*` layout | `src/routes/admin/route.tsx` (`ssr: false`, noindex; children inherit `ssr: false`) |
| `/admin/login` | `src/routes/admin/login.tsx` |
| guarded layout (pathless) | `src/routes/admin/_staff/route.tsx` |
| `/admin` | `src/routes/admin/_staff/index.tsx` |
| `/admin/inbox`, `/admin/inbox/$requestId` | `src/routes/admin/_staff/inbox/index.tsx`, `…/inbox/$requestId.tsx` |
| `/admin/sessions`, `/admin/sessions/$sessionId` | `src/routes/admin/_staff/sessions/index.tsx`, `…/sessions/$sessionId.tsx` |
| `/admin/families`, `/admin/families/$familyId` | `src/routes/admin/_staff/families/index.tsx`, `…/families/$familyId.tsx` |
| `/admin/payments`, `/admin/media`, `/admin/reports` | `src/routes/admin/_staff/payments.tsx`, `media.tsx`, `reports.tsx` |
| `/admin/privacy`, `/admin/settings` (owner) | `src/routes/admin/_staff/privacy.tsx`, `settings.tsx` |

The `createFileRoute("…")` string is the route **id** (includes `_staff`); copy what `npx vite build` writes into
`src/routeTree.gen.ts` if unsure.

### Fixed values

`REF_CODE_PATTERN = /^CL-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$/` · booking rate limit 5/hour and 20/day per IP hash
(bucket `booking_request`; when the visitor IP is unknown the limit is **skipped** and `[booking] no_client_ip` is
logged, never a shared "unknown" bucket) · Turnstile action `booking_request` · enrol link 14 days, single use · manage link **90 days** ·
public sessions window 8 weeks · `CHILD_CONSENT_AGE = 10` · children per request 1–3, age 6–12 · `guardian_name` ≤ 80,
`nickname` ≤ 30, `message` ≤ 500 chars · slip/evidence uploads ≤ 5 MB, `image/jpeg`, `image/png`, `image/webp`,
`application/pdf` · signed URLs 60 s · admin language `localStorage` key `cherrylee-admin-lang`.

---

## 11. Environment and secrets (names only)

Never put a value in chat, code, tests or commits. Public keys that are safe to publish live in
`src/lib/backend/public-config.ts`; **do not add lines to `.env`** (Lovable generates it).

| Name | Kind | Set by | Phase | Used by |
|---|---|---|---|---|
| `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` | public, build-time (`.env`) | Lovable (auto) | P0 | generated client |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_URL`, `LOVABLE_API_KEY` | server secret | Lovable (auto) | P0 | generated clients |
| `LOVABLE_CRON_SECRET` | server secret | Lovable (only if a Job calls a route) | P1 fallback only | `src/routes/api/cron/purge.ts` via the generated `authenticateCronRequest`, only if `cron.schedule` was refused (R-19) |
| `IP_HASH_SECRET` | server secret (64 hex chars) | Owner | P1 | `hash.server.ts` |
| `TURNSTILE_SECRET_KEY` | server secret | Owner | P1 | `turnstile.server.ts` |
| `LINE_ALERT_CHANNEL_ID` | server secret | Owner | P1 | `line-alert.server.ts` |
| `LINE_ALERT_CHANNEL_SECRET` | server secret | Owner | P1 | `line-alert.server.ts`, `line-signature.server.ts` |
| `LINE_ALERT_TO` | server secret (user ID `U…` or group ID `C…`) | Owner | P1 | `staff-notify.server.ts` |
| `PUBLIC_SITE_URL` | server config (no trailing slash; falls back to the request origin) | Owner | P1 | links in alerts |
| `PROMPTPAY_ID` | server secret | Owner | P6 (optional) | `/pay/$token` |
| `RESEND_API_KEY`, `STAFF_NOTIFY_EMAIL` | server secret | Owner | P6 (optional) | email backup alert |
| `TURNSTILE_SITE_KEY` | public constant in `public-config.ts` | Builder commits | P1 | `TurnstileWidget.tsx` (dev falls back to test key `1x00000000000000000000AA`) |
| `UMAMI_WEBSITE_ID` | public constant in `public-config.ts` | Builder commits | P6 (optional) | `__root.tsx` script |

Local development has no server secrets, so server functions that need them can't run locally. Implementers verify
with unit tests (fetch and Supabase mocked) and the build; end-to-end checks happen on the Lovable preview.

---

## 12. Retention schedule (proposal — owner to confirm, lawyer to review)

| Data | Proposed period | Mechanism |
|---|---|---|
| `rate_limit_events` (IP hashes) | 24 hours | purge |
| `staff_notifications` | 30 days | `retain_until` |
| `booking_requests` | 6 months after creation | `retain_until` |
| Families, guardians, children, contacts | 12 months after the last booking, payment, package purchase, consent change or private-link use (profile edits don't count, R-25); restricted families are skipped (D28) | `mark_inactive_families()` sets `retain_until` |
| `child_health` | Immediately on withdrawal/refusal; otherwise 6 months after the child's last session | trigger + purge |
| `bookings` (attendance) | 24 months after the session date | `retain_until` |
| `package_purchases`, `payments`, slips | 5 years after the end of the accounting year (G11) | `retain_until`; anonymised on erase |
| `consent_records`, evidence files | Life of the consent + 3 years (PDPA s.78 claims period) | purge after family deletion + 3 years |
| `family_links` | 30 days after expiry | purge |
| `dsr_requests` | 3 years after response | `retain_until` |
| `breach_incidents` | 5 years | `retain_until` |
| `audit_log` | 12 months | `retain_until` |
| `media_assets` links to children | Until withdrawal; yearly review | manual |

---

## 13. Open questions for the studio

Business (owner answers, G0):
1. Is CherryLee & Co. a sole proprietor, partnership or company? (Controller name in the privacy notice; accounting retention.)
2. Who is the single **owner** account? Who gets **staff** accounts (Kru Cherry, Uncle Lee, Kru Arm?) Who should receive LINE alerts?
3. How many seats do you usually offer per Saturday/Sunday? (Set per session; only "seats left" is shown publicly.) Do you want seats left shown at all?
4. Do 4- and 8-session packages expire? Can siblings share one package? If a child misses a day, is the credit used? Make-up days?
5. When do families pay: before the seat is confirmed, or on the day? Deposits? Refunds? (We record facts only; the site won't state rules you haven't set.)
6. Are the retention periods in § 12 workable?
7. Will you keep using paper enrolment/consent forms? Where are they stored?
8. Is the allergen list enough for Uncle Lee's cooking class? Anything else the teachers need before cooking (e.g. "no restrictions")?
9. Which channels do you actually use for photos/videos: a private parents' LINE group, the website, Facebook/Instagram/TikTok, YouTube? Print?
10. Whose LINE account owns `@cherryleeandco` and will own the LINE Developers provider? (Must be the studio's own.)
11. Do you plan a custom domain?
12. Budget for a one-off PDPA lawyer review?
13. Do you want a PromptPay QR payment page later? Which PromptPay ID (business tax ID or a dedicated phone)?
14. For the website FAQ (not the backend): lunch/break arrangement and maximum group size, if you want them published.
15. The four class clips already on the website: what exactly did parents agree to on 2026-10-13: the website only, or
    also YouTube / Facebook / the parents' group? (Sets `media_assets.legacy_consent_purposes` in 0005 before G4, R-11.)
16. Should a studio-owned phone's LINE account ever add parents as friends? Default **no**: parents message
    @cherryleeandco first (D26), so no family data sits on personal phones.
17. Please approve (or change) every sentence that describes what the studio will do: the lines marked `OWNER-APPROVE`
    in `0006`, the health "tell a teacher before cooking" note, the "full date" wording on `/book`, and the 7-day
    takedown target (R-24).
18. **G-HEALTH:** keep allergy information in the system (explicit consent, audited, deleted on withdrawal) or keep
    using a paper form at the studio?
19. **G-MVP** (after ≥ 8 weeks of Stage A): go on to family records (Stage B)?

Technical (builder verifies after enabling Cloud; details in `40-integrations.md`):
- Which migration folder Lovable writes (`drizzle/` or `supabase/migrations/`), and whether DB changes reach the live
  database before Publish.
- Whether the bootstrap kept `errorMiddleware` + `csrfMiddleware` in `src/start.ts`.
- Cloud auto-pause window and whether the daily cron job (which prevents pausing) costs noticeably.
- Whether `cf-connecting-ip` / `getRequestIP()` returns the real visitor IP on Lovable hosting.
- Which city "Asia Pacific" is, and whether Lovable's DPA includes SCCs (PDPA s.29).
- Whether Lovable Cloud exposes Supabase MFA (TOTP) for the owner account.

---

## 14. Sources

- Lovable Cloud, permissions, regions: https://docs.lovable.dev/features/cloud.md · database & migrations: https://docs.lovable.dev/features/database.md ·
  secrets: https://docs.lovable.dev/features/secrets.md · jobs: https://docs.lovable.dev/features/jobs.md ·
  auth: https://docs.lovable.dev/features/authentication.md · publish: https://docs.lovable.dev/features/publish.md ·
  GitHub sync: https://docs.lovable.dev/integrations/github.md · credits: https://docs.lovable.dev/introduction/credits-and-usage.md
- Supabase RBAC pattern: https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac ·
  cron: https://supabase.com/docs/guides/cron · getClaims: https://supabase.com/docs/reference/javascript/auth-getclaims
- TanStack Start server functions: https://tanstack.com/start/latest/docs/framework/react/guide/server-functions ·
  server routes: https://tanstack.com/start/latest/docs/framework/react/guide/server-routes ; installed-version behaviour
  (`.validator`, import protection by `**/server/**`, `ssr: false` inheritance) checked in `node_modules`.
- PDPA (PDPC unofficial English translation): https://www.pdpc.or.th/wp-content/uploads/2023/12/2_Personal-Data-Protection-Act-2019.pdf ·
  PDPC consent guideline: https://www.pdpc.or.th/1356/ · notice guideline: https://www.pdpc.or.th/1365/ ·
  breach e-service: https://www.pdpc.or.th/17259/ · complaints: https://complaint.pdpc.or.th/ ·
  access-request rules (2026): https://www.tilleke.com/insights/thailand-issues-new-rules-on-data-subject-access-requests/ ·
  erasure rules (2024): https://www.tilleke.com/insights/thailand-issues-criteria-for-deletion-destruction-and-de-identification-of-personal-data/ ·
  cross-border: https://www.tilleke.com/insights/thailand-unveils-regulations-for-cross-border-personal-data-transfer
- LINE: Notify end https://notify-bot.line.me/closing-announce · Messaging API reference https://developers.line.biz/en/reference/messaging-api/ ·
  provider is permanent https://developers.line.biz/en/docs/messaging-api/getting-started/ ·
  channel access tokens https://developers.line.biz/en/docs/basics/channel-access-token/ ·
  webhook signature https://developers.line.biz/en/docs/messaging-api/verify-webhook-signature/ ·
  Thai OA plans https://lineforbusiness.com/th/service/line-oa-features/broadcast-message
- Cloudflare Turnstile: https://developers.cloudflare.com/turnstile/get-started/server-side-validation/ ·
  test keys https://developers.cloudflare.com/turnstile/troubleshooting/testing/ ·
  hostnames https://developers.cloudflare.com/turnstile/concepts/domain-management
- Umami: https://umami.is/pricing · PromptPay EMVCo test vectors: https://raw.githubusercontent.com/dtinth/promptpay-qr/master/index.test.js

This plan is not legal advice. A Thai PDPA lawyer should review the privacy notice, consent wording, the children-10+
approach (D11), the cross-border position and the retention schedule before the related phases go live.

---

## 15. Review resolutions (October 2026)

An independent review (verdict: database layer strong, plan not yet ready for Haiku) raised 2 blockers, 13 major and
12 minor issues (R-01 … R-27). A finalisation pass while writing the task cards found five more gaps (R-28 … R-32). A
second verification round (a verifier plus Haiku dry-runs of cards P0-17, P1-06, P1-14, P3-04 and P4-06) added
R-33 … R-48. This log is **authoritative**: it sits in the top file of the order of authority, so if any lower file
still says something else, this table wins and the lower file is the one to fix. Every entry is already applied to the
files named.

| # | Issue (severity) | Resolution | Applied in |
|---|---|---|---|
| R-01 | No task cards / gate tracker (blocker) | `90-task-breakdown.md`: gate tracker, how to run with Haiku, dependency graph, one card per small change, support agents | 90, README |
| R-02 | Notice shipped after collection; two version formats (blocker) | Notice per stage (`…-v1` A, `…-v2` B, `…-v3` C), format `YYYY-MM-vN` only, wording source = 50 §§ 11.3–11.4 tagged by phase, G9a per stage, G10 checks it | 00 § 8.0/§ 9, 30 § 3.4, 50 § 11.1 |
| R-03 | LINE call-back by LINE ID impossible (major) | D26: LINE = parent sends the ref code to @cherryleeandco; phone required only for call-backs; LINE ID = optional matching hint; inbox shows "find chat", not "add" | 00 D26/§ 6, 0002, 20 § 9.1, 30 § 3.2/§ 4.3, 50 § 11 |
| R-04 | Media consent text hidden in a collapsible (major) | Title + full `body_md` above each unticked control on `/enrol` and `/my`; UI test checks every consent control has its text in the DOM | 30 §§ 3.5–3.6, 50 § 13 |
| R-05 | Takedown alert only for `withdrawn` via two functions (major) | D29: `queue_consent_change_alert` trigger (any channel, guardian or child); ~~`/enrol` records `withdrawn` when a granted switch is turned off~~ (superseded by R-33: on `/enrol` only the explicit health decline can withdraw); `deliverConsentAlert` pushes | 0005, 20 §§ 7.8, 9.8–9.12 |
| R-06 | All four media text ids required (major) | Media is a list of only the purposes shown; texts not published are hidden and nothing is recorded for them | 20 § 9.8, 30 § 3.5, 0005 `submit_enrolment` |
| R-07 | Allergy data lost or shown as "none" (major) | Roster three states; `children.allergy_check_needed_at`; "Not now" = skipped, explicit "I don't want to share" = refused; child-refusal deletion stays a G9b lawyer question | 0004, 0005, 20 § 9.10, 30 §§ 3.5/4.3 |
| R-08 | Orphan check would delete kept slips/evidence (major) | Orphan = object not referenced by any `payments.slip_path` or `consent_records.evidence_path` (never "family missing"); slips stay on erasure unless G11/lawyer decide otherwise (then `erase_family` nulls `slip_path` in a new SQL file); 50 § 18.3 corrected; orphan check is a manual, parked runbook step | 50 §§ 7.3, 18.3, 19.4; 20 § 9.13 |
| R-09 | Restriction via system-managed status (major) | D28 columns + DB guard + `set_family_restriction()`; owner card on the family page | 0007, 20 § 9.13, 30 § 4.3, 50 § 18.4 |
| R-10 | Used credits come back after purge (major) | `package_purchases.sessions_used_purged`, maintained only by the purge; view and `validate_booking` count it | 0004, 0005, 0007 |
| R-11 | Media publishability conflicts (major) | `legacy_consent_purposes` (seed from G0 Q15); legacy-only assets → "check manually", never "needs takedown"; YouTube asset on the website also needs `media_youtube` (SQL) | 0005, 20 § 9.11, 30 § 4.3 |
| R-12 | Scope too large (major) | D27 stages A–D, G-MVP, G-HEALTH, parked items with runbooks | 00 §§ 5, 8.0, 9; 90 |
| R-13 | View types and complex handlers undefined (major) | `20-server-api.md` § 14: compiled-style types for every view type + mapping to SQL + handler skeletons | 20 § 14 |
| R-14 | Duplicate code/copy in 40 and 50 (major) | 40/50 now link to the 20/30 blocks; `runStorageCleanup` everywhere; notice wording only in 50, code pattern only in 30 | 40 §§ 5–6, 50 §§ 11, 19 |
| R-15 | Non-atomic multi-step writes (major) | D30 functions: `create_family_from_request`, `submit_enrolment` (row lock), `publish_consent_text`, `set_media_asset_children` | 0004, 0005, 20 |
| R-16 | Zod vs SQL limits (minor) | Zod aligned to SQL; `src/lib/backend/limits.ts` lists the SQL limits; a vitest checks boundaries | 20 §§ 8.9, 9.9, 9.13; 10 § 4.1 |
| R-17 | `admin.tsx` too big for one card (minor) | Split into `src/content/admin/<area>.tsx` + `index.ts`; each card copies only its keys | 30 § 5, 90 |
| R-18 | N+1 RPCs on Workers (minor) | `get_sessions_with_seats`, `consent_matrix`, `media_publishability` | 0003–0005, 20 |
| R-19 | SQL via Lovable chat; no cron fallback (minor) | SQL editor for smoke/seed/G5; chat only for DDL migrations; fallback card `/api/cron/purge` + Lovable Job | 40 §§ 1, 3, 7; sql headers; 90 |
| R-20 | Definer helpers probeable by no-role users (minor) | `has_role`, `has_active_consent` not executable by `authenticated`; `session_seats_left` checks staff; sign-up-disabled check at every G10 | 0001, 0003–0005, rls_smoke, 40 § 13 |
| R-21 | Enrol link treated as verified identity (minor) | Link use never sets identity; changed contact fields wait in `guardians.pending_link_changes` for staff; manage links 90 days | 0004, 0005, 20 §§ 9.5, 9.8, 9.12 |
| R-22 | Contact delete erases pickup history (minor) | `family_contacts.is_active` soft delete | 0004, 0005, 20 § 9.5 |
| R-23 | Missing writes; cancelled session keeps bookings (minor) | `updatePackagePurchase`, `deletePaymentSlip`; session cancel trigger + UI warning | 0004, 20 §§ 9.4, 9.6 |
| R-24 | Copy states unconfirmed facts (minor) | `media_parents_group` text moved to optional `0006b`; P1 thank-you no longer promises a private link; waitlist/health promises reworded and marked owner-approve; "free trial" comment removed | 0006, 0006b, 20 § 9.7, 30 §§ 3.2/3.5 |
| R-25 | Inactivity wording; missing-IP behaviour (minor) | Notice lists the exact activities; missing IP = limit skipped + `no_client_ip` log (no shared bucket) | 00 § 12, 0007, 50 §§ 4, 11 |
| R-26 | `*.functions.ts` exports/imports (minor) | Export only `createServerFn` results; `@/server/*` used only inside handlers; leak grep stays | 00 § 10, 20 § 1, README |
| R-27 | `/my` hides inactive children (minor) | Load all children of the family, label inactive ones | 20 § 9.12, 30 § 3.6 |
| R-28 | Notice section ids/phases implicit; rights-request log missing from `…-v1` (finalisation) | 30 § 3.4 has one id/phase table for every notice section and `PrivacySection.phase` in code; the stale "v2 additions" example table is gone; 3.9 and its two retention rows ship in `…-v1` because the owner's runbook log exists from Stage A | 30 § 3.4, 50 § 11 |
| R-29 | G-HEALTH had no switch in code (finalisation) | `HEALTH_IN_SYSTEM` in `public-config.ts` (UI only); "paper" removes the health rows from the unapplied 0006, so the database can't accept health data; `/enrol` and `/my` stay data-driven | 00 § 9, 20 § 8.7, 30 §§ 3.5, 3.6, 4.3 |
| R-30 | Unsent consent/enrolment alerts had no list; F1-10 secret check had no function (finalisation) | `listPendingStaffAlerts` + dashboard "alerts not sent" with resend (card P4-19); owner `getSystemCheck` on `/admin/settings` (card P1-19), names only, never values | 20 §§ 9.2, 9.3, 13; 30 §§ 4.3, 5.1 |
| R-31 | Purge acceptance test could not pass after 0007 (finalisation) | Runbook backdates `created_at` as well, because `mark_inactive_families()` runs first and clears `retain_until` on active families | 50 § 19.5 |
| R-32 | Stale wording (finalisation) | SQL editor instead of Lovable chat for non-migration SQL (40 G5/§ 7, 10 § 6.1, 50 § 19.3); admin copy pointers (20 § 4, 30 § 5 comment); version labels (50 § 11); decision range (40 header); `90-task-breakdown.md` written (closes R-01) | 10, 20, 30, 40, 50, 90 |
| R-33 | Re-sent enrol link silently withdrew media consents (major): every box starts unticked, so "off" recorded `withdrawn` for earlier grants | `submit_enrolment`: ticked = `granted`; unticked = `refused` only when the guardian never decided that purpose, otherwise nothing. `getEnrolmentForm` returns `currentMedia` (one `consent_matrix` call); the media block shows the current decision + `keepNote`; withdrawals go through `/my` or staff. Boxes are never pre-ticked from the current state | 0005 § 10c; 20 § 9.8 (`CurrentMediaDecision`); 30 § 3.5 (MediaSection, enrol copy); 10 § 13; 50 § 16.1; 00 § 8 P4; 90 P4-04/05/09/14/24; seed_dev § 7b.7 |
| R-34 | A 10+ child's health "no" turned a guardian's health grant into a `42501` → `server_error` that rolled back the whole `/enrol` statement (major) | `submit_enrolment` raises `23514` before any write (handler → `invalid_input`); `getEnrolmentForm` returns `childRefusedHealth`; `HealthSection` (optional `childRefused`) shows only `health.childRefusedNote` (OWNER-APPROVE) and sends `skipped` | 0005 § 10c; 20 § 9.8; 30 § 3.5; 90 P4-05/06/08/14; seed_dev § 7b.7 |
| R-35 | 0006 header pointed at the parked `/admin/settings` publisher; nothing stopped a first `health_allergy` text after G-HEALTH = paper (minor) | 0006 header: new versions by reviewed SQL draft or `publish_consent_text()` in the SQL editor (PK-03 parked). `publish_consent_text` refuses the **first** `health_allergy` text (`23514`) | 0005, 0006; 00 § 8.0; 20 § 9.9; 50 § 12.0; seed_dev § 6 |
| R-36 | Restriction gaps (major): the family row itself (name, language, staff note) stayed editable although D28 says "profile edits"; an inactive contact could be edited; FK set-null columns would block staff offboarding or a request purge | `block_restricted_family` also runs BEFORE UPDATE on `families` (only system and restriction columns may change while restricted); the contact exception is only `is_active` true → false; `identity_checked_by`, `created_by`, `source_request_id` count as system columns | 0007 § 4b; 10 § 9; 20 § 9.5; 50 § 18.4; 90 P3-04/P3-18/P5-05; seed_dev § 7b.8 |
| R-37 | Restriction blocks the very correction an accuracy dispute needs (minor) | Runbook: owner lifts → makes only the requested correction → restricts again, one DSR-sheet line; the audit log already records each step | 50 § 18.4, § 28 Q9; seed_dev § 7b.8 |
| R-38 | LINE-path requests (D26) may have no phone and no LINE ID, but conversion requires one (minor) | Convert dialog shows the request's phone/LINE ID as editable fields and `convertDialog.contactNeeded` when both are empty; zod `contact_required` stays (a family record needs a way to reach the parent; `guardians_contact_present`) | 30 § 4.3, § 5 inbox copy; 20 § 9.5; 90 P3-14; seed_dev § 7b.1 |
| R-39 | `saveGuardian` primary swap was two unguarded statements; other `families.functions` write rules were ambiguous; staff could hard-delete contacts (major) | New SQL `set_primary_guardian()` (one transaction; D30); `saveGuardian` writes plain fields first, then the RPC; `isPrimary: false` never un-sets the primary; identity/responsibility columns only on their flags; `saveFamilyContact` re-stamps `guardian_attests_informed_at` only when name/phone change; `deleteFamilyContact` idempotent; `saveFamily` insert sets `created_by`; `family_contacts` hard delete owner only | 0004 §§ 14c, 15; rls_smoke; 10 §§ 8, 11; 00 D30, § 10; 20 § 9.5; 30 § 4.3; 90 P3-01/P3-04/P3-11; seed_dev § 7b.2 |
| R-40 | P0-17 could not prove or test the role gate (major for Haiku) | Card gate = G4 · 0001 + types check (`current_app_role`, `app_role`); P0-15 records the generated `auth-middleware.ts` imports (40 § 2 row 18); 📝 `auth.middleware.test.ts`; 20 § 6 explains how thrown codes reach the UI (server-function handler, not `errorMiddleware`) | 20 § 6; 40 § 2; 90 § 2, P0-15, P0-17 |
| R-41 | Type and test gaps in ✅ blocks (minor) | `status: "new" as const`; `children_count ?? 0`; `form_closed` test via `vi.hoisted`; honeypot field has no max; the second `ConsentPurpose` in `staff-alert-text.ts` is no longer exported; P0-10 keeps Cloudflare's dummy test secret; P1-06 reads/deps/types check | 20 §§ 7.8, 7.10, 8.6, 9.1; 90 P0-10, P1-03, P1-06 |
| R-42 | Rule conflicts that would fail a review (minor) | README: the public/token pass-through validator is the one exception to `.validator(schema)`; `./supabase-admin.server` inside `src/server/` is the same door; a rebuilt `routeTree.gen.ts` is not a stop; the leak grep is run unchanged | README; 20 § 9.0; 90 § 1.6, P1-07, P4-05, P4-06 |
| R-43 | Strict-TS write traps and missing imports (major for Haiku) | 20 § 9.0 write rules (no `undefined` keys, update-by-id `.select("id")` → `not_found`, guarded indexing, test mocks); `families.schema.ts` imports `ConsentPurpose` and `PaymentRow`, so P3-02 depends on P3-05; `createEnrolmentLink` maps errors with `adminErrorFromDb`; § 9.0 public errors list `22023` | 20 §§ 9.0, 9.5, 9.8; 90 § 4 (batches recomputed), P3-02/P3-03 |
| R-44 | P4-06 had no gate, missing reads, mixed test scope; P4-04 imported a file from a card it didn't depend on (major for Haiku) | P4-04 and P4-06 depend on P4-07; P4-06 gate G4 · 0005 + `submit_enrolment` in `types.ts`; handler tests only, with a fake fixture and mock shapes; schema tests stay in P4-04 | 20 § 9.8; 90 § 4, P4-04, P4-06 |
| R-45 | `/book` form: radio groups had no accessible name, a hard-coded honeypot label, no test recipe, and the short notice states a proposed retention with no gate (major) | `aria-labelledby` on each `RadioGroup`; `bookingContent.honeypotLabel`; 📝 `BookingForm.test.tsx` / `BookingThanks.test.tsx` (fireEvent, `LanguageProvider`, fake `window.turnstile`, `ResizeObserver` stub); `notice` marked OWNER-APPROVE and approved at G9a · v1 with G0 Q6 | 30 §§ 3.2, 6, 7; 90 § 2, P1-13, P1-14, P2-08 |
| R-46 | `AGENTS.md` says copy lives only in `site.tsx` (minor) | Card P0-13 amends that bullet to `src/content/*` | 90 P0-13 |
| R-47 | Leftovers of R-09/R-14 (minor) | 50 PDPA row s.34, the DSR deadline row and lawyer question 9 describe the D28 restriction; LINE error codes `line_token_http_<status>` / `line_push_http_<status>` everywhere; the `privacy.tsx` code block keeps one sample section per language, so 50 is the only notice wording | 50 §§ 10, 18.1, 28; 40 §§ 5.8, 14; 20 § 14.1; 30 § 3.4 |
| R-48 | "0005 tables only in Stage B" read as "functions later" (minor) | G4 · 0005 applies the whole file in Stage B, `submit_enrolment` included; only P4 screens wait | 00 § 8 P4; 10 § 1; 0005 header; 90 § 2, P3-17 |
