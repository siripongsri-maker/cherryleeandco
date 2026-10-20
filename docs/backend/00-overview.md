# 00 · Backend overview: CherryLee & Co.

Planning document, October 2026. Lovable Cloud is not enabled yet. This file sets the decisions and the names
every other file in `docs/backend/` must follow.

Updated 14 October 2026 with the owner's decisions: D31–D39 (§ 5), the status of each answer (§ 13A) and the review log (§ 15, R-49 to R-59).

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
   ผู้ปกครองต้องติ๊กยินยอมเองโดยชัดแจ้ง ความยินยอมเรื่องรูปและวิดีโอแยกเป็นรายช่องทาง (รวมสิ่งพิมพ์ของสตูดิโอ) ถอนความยินยอมได้ง่ายทุกเมื่อ ข่าวสารถึงผู้ปกครองเป็นทางเลือก ตั้งต้นเป็นไม่รับ และทีมงานติดต่อด้วยตนเองทีละครอบครัวเท่านั้น
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
| ให้นักกฎหมายด้าน PDPA ตรวจนโยบายความเป็นส่วนตัวทุกฉบับและข้อความขอความยินยอมทุกข้อ (อนุมัติงบแล้ว) | เอกสารนี้ไม่ใช่คำปรึกษาทางกฎหมาย |
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
| โดเมน cherryleeandco.com (มีแล้ว) | รายปี ตามผู้ให้บริการ |

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
- Storing children's photos or videos. No media files are stored: media is referenced by YouTube id or title, and print uses are recorded by reference (media_print, decision 3).
- Bulk or automated marketing: no broadcasts, no email newsletters, no automated sends. The only marketing is family
  follow-up for guardians who opted in (`marketing_line`, D31). Staff contact them by hand from the studio's LINE OA
  chat, one family at a time.
- Advertising pixels, GA4, cookie banners (we stay cookieless instead).
- Inventing studio policy: refunds, deposits, or any rule the owner has not given. Rules the owner has given are recorded
  in § 13A and D36 only.

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
| P3 | `families`, `guardians`, `children`, `family_contacts`, `package_purchases`, `payments`, `bookings`, `guardian_consent_records` (D31); bucket `payment-slips` | — | `/admin/families`, `/admin/families/$familyId`, staff follow-up list (P3-19), `/admin/sessions/$sessionId` (roster), `/admin/payments` |
| P4 | `consent_texts`, `consent_records`, `child_health`, `family_links`, `media_assets`, `media_asset_children`; bucket `consent-evidence` | `/enrol/$token`, `/my/$token` (moved from P5, D27) | `/admin/media`; health + consent panels on family and roster pages; `/admin/families/$familyId/print` (P4-25, D33) |
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
| D31 | **Family follow-up and sales only by opt-in (`marketing_line`).** A guardian purpose, never a child purpose. Default **off**: a separate unticked box with the full text above it, asked when a family record is created (P3-04) and in the P3-11 edit sheets; changed on `/my` (P4-13, P4-22) or by staff. Stored in the new append-only table `guardian_consent_records`, not in `consent_records` (which is per child). Staff see a follow-up list of families who said yes (P3-19) and contact them **by hand** from the studio's LINE OA chat, one family at a time. **No bulk or automated sends**; LINE broadcasts stay parked. Restricted families (D28) are never on the list. Text: `sql/0006a_seed_marketing_text.sql` (G4 · 0006a). | Owner wants family records as a customer base for follow-up and sales (answer 19). Opt-in, guardian-only and by-hand contact keep it within PDPA s.19, s.21 and s.32 and within the OA limits (D6, D26). |
| D32 | **Print is a media channel: `media_print`.** Added to `consent_purpose` in `0005`, with the same rules as `media_social` (child-level, `media_level`, default not granted). Its TH/EN text is in `0006` (lawyer reviewed). A separate control in MediaSection (P4-09) on `/enrol` and `/my`, in the publishability matrix and the admin media screen (P4-21). The five media channels are now five separate boxes: `media_parents_group`, `media_website`, `media_social`, `media_youtube`, `media_print`. | Owner uses print (answer 9). Each channel needs its own consent (s.19), so print is never bundled with the others. |
| D33 | **Export for signature (card P4-25).** Staff print or save as PDF a family's enrolment and consent record at `/admin/families/$familyId/print` (`ssr: false`, noindex). Browser print with the existing `@media print` rules; no PDF package; nothing stored on the server; signature lines included. Health appears only through the audited health function, and only when staff tick "include health" for that print. Every print is written to `audit_log` (action, family id, date; never the content). | Owner wants paper for signing while staying fully online (answers 7 and 18). Printing keeps health data out of files unless staff choose it, and every print is traceable. |
| D34 | **Keep Lovable Cloud (= Supabase).** No separate Supabase account. Gates G1 and G2 are unchanged. | Owner: "if already doing it, no need to redo" (answer 20). Lovable Cloud is Supabase underneath, so the plan as written already is the Supabase plan. |
| D35 | **The LINE OA contact rule stands (D26).** Parents message `@cherryleeandco` first, or add the OA themselves. Staff never add a parent by LINE ID, and no screen asks staff to copy a parent's LINE ID in order to add them (any such copy is removed). Staff reply only in chats the family started. | The OA cannot add or message a user who has not messaged it (platform limit). This overrides the "yes, add friends" answer (16) for adding friends, and keeps family data off personal phones (D6, D7). The owner confirms this reading in one line. |
| D36 | **Cancellations and make-up.** Packages never expire. Siblings may share a package. A missed day does not deduct a credit (**superseded by D40**). A make-up session needs notice of at least **3 hours before the original session starts**. The setting `studio_settings.cancel_notice_hours` (integer, default 3) is enforced in the make-up booking check. The site may publish this rule only if the owner asks. | Owner's answer 4. A setting lets the owner change the notice without a code change. Nothing is published until the owner asks. |
| D37 | **Domain: `https://cherryleeandco.com` (live; G13 done).** Used as `PUBLIC_SITE_URL`, as the Turnstile hostname (whether it covers `www.` is UNVERIFIED: check in the Cloudflare console before G7; if not, list `www.cherryleeandco.com` as its own hostname), and as the absolute base for JSON-LD and for the privacy notice's website field. The JSON-LD change is a website task, not part of this plan. | Owner already has the domain (answer 11). One address for alert links, bot checks and the notice. |
| D38 | **Lawyer review approved (budget).** A Thai PDPA lawyer reviews **every notice version** (v1, v2, v3 and later) and **every consent text** (`0006`, `0006a` and any later text), with the OWNER-APPROVE lines and the D11 rule. G9a and G9b are "owner + lawyer, budget approved". G9b is approved before `G4 · 0006a` (Stage B) and before `G4 · 0006` (Stage C). No Stage C go-live before G9b. The Stage A notice (v1) also goes to the lawyer before P2-08. | Owner: "ได้ ให้ฝ่ายกฎหมายตรวจ" (yes, the legal team reviews). This overrides the "no lawyer budget" answer (12). Stage B now needs the lawyer too, because the marketing text ships in Stage B. |
| D39 | **Allergen list: the nine FDA major food allergens.** `milk`, `egg`, `peanut`, `tree_nut`, `wheat`, `soy`, `fish`, `shellfish`, `sesame`, plus `other_allergens` (free text) and `foods_to_avoid`. This matches the existing CHECK list on `child_health.allergens` in `0005`, so there is no enum change. Thai labels go into the copy (`30-ui`). The list is not claimed to match a Thai list (none was found). | Owner asked for a general list (answer 8). The owner still confirms "แพ้ทั่ว" (probably ถั่ว) and "แพ้แป้ง" (wheat flour, or another flour?) before the labels are final. |
| D40 | **Credit rule with notice (round two, item 1).** A booking cancelled **with notice** at or before *session start − `cancel_notice_hours`* keeps its credit: status `cancelled`, no deduction. An **absent** booking (no notice), and a cancellation with notice later than that, use one credit: status `absent` or `cancelled_late`. Staff still record absent or cancelled (D16); a cancellation with late notice is saved as `cancelled_late`. A make-up needs the same notice (D36). A studio cancellation of a whole session is also `cancelled`, with no notice channel and no notice time, and keeps the credit; the reports count it apart (0008 `cancelled_studio`). **Overrides** D36's "a missed day does not deduct a credit" and the D16 balance rule that only `cancelled` bookings are free. **Round three:** the studio path is overridden by D48 (status `cancelled_studio`, credit returned) and the report source by D49. | Owner: "ขาดโดยไม่แจ้ง หักเครดิต แจ้งก่อน 3 ชั่วโมงไม่หัก" (no notice, a credit is deducted; notice 3 hours before, no deduction). The 3 hours stay a setting, so the owner can change them without a code change. |
| D41 | **Notice by LINE (round two, item 2).** The cancellation notice comes by LINE or in person. Staff record it on the booking screen with `cancel_notice_at` = the time the LINE message arrived (taken from the OA chat) and `cancel_notice_channel` = `line` or `in_person`. No paper channel and no web notice form in this scope. **Extends** D36 (the notice record). **Round three: overridden by D53** (four channels: `line`, `phone`, `teacher`, `in_person`). | Owner: "แจ้งทางไลน์" (notice is given on LINE). The OA chat already shows the arrival time, so staff need no new tool. |
| D42 | **One health route for export and print (round two, item 3).** The export (`export_family_data`, 0007) and the print sheet (P4-25) read health ONLY through `get_child_health`, with the staff's explicit `includeHealth` choice for that export or print. The plain join in `export_family_data` is removed: there is no second route. The print sheet always shows the **allergen checklist** (large, Thai and English labels) so teachers can use it in class. Other health notes (foods to avoid, care notes) print only when `includeHealth` is true. For an export, `includeHealth` false means no health in the file. Every print is audited (D33). **Refines** D33 and **overrides** D33's rule that health appears only when "include health" is ticked, for the allergen checklist only. | Owner: "ก็เลือกสักวิธี เอาที่อ่านได้แล้ว คนเอาไปใช้งานตอนทำคลาสได้" (choose one method that is readable and that people can use in class). A cooking-class sheet without the allergens would be unsafe (R-07). |
| D43 | **Follow-up label = "ครอบครัวน้อง" + the child's nickname, staff only (round two, item 4).** The staff follow-up list (P3-19) labels each family "ครอบครัวน้อง" + the child's **nickname** (for example "ครอบครัวน้องมะลิ"); English "Family of <nickname>". Nickname only: never a full name, age or health data. Staff only: never shown publicly and never sent. The notice (§ 3.10) and `0006a` say this truthfully and go to the lawyer under G9b. **Overrides** D31's promise that a child's information is never used, for this one label, and the README golden rule that says the same. **Round three: overridden by D52** (the nicknames of all attending children). | Owner: "ใช้ชื่อเด็ก และเป็น ครอบครัวน้อง" (use the child's name, as "ครอบครัวน้อง..."). The nickname is the least of the child's name that keeps the list readable for staff, and the promise has to match the practice. |
| D44 | **One follow-up row per granted guardian (round two, item 5).** A family with two guardians who both said yes to `marketing_line` has **two rows** in the follow-up list. Each row shows the family label (D43) and that guardian's name. One guardian's withdrawal removes only that guardian's row. The view `marketing_follow_up_list` (0007) and 20 § 9.5a follow this. **Refines** D31 (the list is per guardian, not per family). **Round three: stays** (D44 unchanged: two rows). | Owner: "สองแถว" (two rows). Each guardian's choice is a guardian purpose (D31), so each row is one guardian's own choice. |
| D45 | **Class clips consent certified (round two, item 6; G0 Q15 ☑).** On 14 Oct 2026 the owner certified that parents agreed to **all five channels** for the four class clips: website, parents' LINE group, social, YouTube and print. `legacy_consent_purposes` = all five. `legacy_consent_note` = "Owner certified 14 Oct 2026: parents agreed to all five channels (website, parents' LINE group, social, YouTube, print)". The builder still runs the session-setting step at G4 · 0005. The lawyer checks the legacy cover under G9b. **Overrides** R-55's condition that a written source must be recorded before G4. | Owner: "ใช่ รับรองแล้ว ไม่มีปัญหาเลย" (yes, certified, no problem). |
| D46 | **Allergen `flour`, and the nut group (round two, item 7).** Add `flour` to the allergens check in `0005`, and keep `wheat` as its own key. Labels: `flour` = "แป้ง (ทุกชนิด และผลิตภัณฑ์จากแป้ง)" / "Flour (all kinds, and products made with flour)"; `wheat` = "แป้งสาลี / ข้าวสาลี" / "Wheat". Nuts are one group, "ถั่ว" / "Nuts", with two keys: `peanut` (ถั่วลิสง) and `tree_nut` (ถั่วเปลือกแข็ง). **Overrides** D39's "nine values, no enum change": the check list gets one more value (an additive CHECK change). | Owner: "แพ้ถั่ว ใช่ แป้ง รวมทั้งแป้งสาลี แป้งอย่างอื่น ผลิตภัณฑ์จากแป้งทั้งหมด" (nut allergy yes; flour covers wheat flour, other flours and all products made from flour). The open "แพ้ทั่ว" and "แพ้แป้ง" questions are closed. |
| D47 | **LINE OA rule kept (round two, item 8).** D26 and D35 stand: parents message `@cherryleeandco` first, or add the OA themselves. No LINE ID copying and no adding by ID. No change. | Owner: "คงไว้" (keep it). This is the one-line confirmation of D35's reading that the owner was asked for. |
| D48 | **Studio cancels a session: the credit is returned (round three, item 1).** When staff cancel a whole session, each held or confirmed booking in it gets status `cancelled_studio`. The credit goes back to the balance (no credit is used and no notice rule applies), and the family can book a new session with it. The make-up check is removed: a rebooking uses a kept or returned credit through the normal balance check in `validate_booking()`, and `check_make_up_notice()` is retired (R-72). Erase and every other non-cancellation path keep their current behaviour. **Overrides D40's studio path** (status `cancelled`, credit kept) and **D36's make-up rule** (an original status of `cancelled` plus notice). Owner: "คืนเครดิต เอาไปจองรอบใหม่" (return the credit, use it to book a new session). | A studio cancellation should not cost the family a credit. It replaces the earlier `cherrylee.studio_cancel` rule that kept the credit; the flag `cherrylee.studio_cancel` is removed (R-71). `erase_family` does not cancel bookings and does not use any cancellation flag (verifier fix, round three): it keeps its round-two behaviour (credits kept, no status change, no log row) and uses `cherrylee.allow_purge` only. |
| D49 | **Family cancels late or misses: the seat stays booked, it is not an absence, one credit is used, and cancellations are counted in their own log (round three, item 2).** Status `cancelled_late`: the seat stays counted as booked, the booking does not count as absent in `attendance_rate`, and one credit is used. Every cancellation event is written to the new append-only table `booking_cancellation_log` (booking id, family id, session id, outcome, `notice_at`, `notice_channel`, `recorded_by`, `recorded_at`). Outcomes: `family_on_time` (status `cancelled`), `family_late` (status `cancelled_late`), `studio` (status `cancelled_studio`). `absent` (no notice) is not a cancellation and has no outcome in the log. Verifier fix (round three): the title says "misses"; the body and the SQL (`cancel_booking` refuses a family cancel with no notice; 20 § 9.7) treat a missed class as `absent`, not `cancelled_late`. The owner confirms this (§ 13B, j). The reports (0008) count cancellations from `booking_cancellation_log`, not from `bookings`. **Refines D40** (late cancellation) and **overrides D40's report source**. Owner: "ใช่ ไม่นับ แต่นับเป็นสถิติยกเลิก เก็บเป็นอีกฐาน" (yes: not counted as attendance, but counted as a cancellation statistic, kept in a separate base). | The statistics base is separate from attendance, so a late cancellation is neither an absence nor lost from the numbers. |
| D50 | **Health retention: a `cancelled_late` booking counts for the 6-month child_health clock (round three, item 3).** The clock does not change: `child_health` is deleted on withdrawal or refusal, or kept until 6 months after the child's last session (§ 12). A `cancelled_late` booking counts as a booking for that clock, for the same reason as before (it used a credit). Owner: "ใช่" (yes). **Open (§ 13B):** the decision does not say whether a `cancelled_studio` booking counts. The plan treats it as not counting, because it used no credit. | Confirms the rule already written in § 12 and 50 § 19.1. |
| D51 | **Print sheet: the health consent status line is on every sheet (round three, item 4).** Each printed sheet shows, for each child, the health consent status: granted, refused or not yet asked. The status line is always printed. The health content (foods to avoid, care notes) prints only when `includeHealth` is true. The allergen checklist always prints (D42). **Refines D33 and D42:** the status line is new and always shown; `includeHealth` controls content only. Owner: "ทุกใบ" (every sheet). | A sheet cannot be read as "no consent" or "no allergy" by accident; the content still needs the staff's tick. |
| D52 | **Follow-up label: the nicknames of all attending children (round three, item 5).** The family label on the staff follow-up list (D43) uses the nicknames of **all attending children**. A child is attending when the family has at least one booking for that child that is not cancelled in the 6-month retention window. The cancelled statuses are `cancelled`, `cancelled_late` and `cancelled_studio`. `absent` is not cancelled, so it counts (literal reading; open, § 13B). Thai: "ครอบครัว" + "น้อง" + each nickname. Two children: "ครอบครัวน้องมะลิ และ น้องดาว" (joined by " และ "). Three or more: "ครอบครัวน้อง…, น้อง… และ น้อง…" (commas, then " และ " before the last). English: "Family of A" / "Family of A and B" / "Family of A, B and C". Nicknames only: never a full name, age or health data. The nickname field does not contain the word "น้อง"; the label adds it (verifier fix: the forms and zod now refuse a leading "น้อง"). The window is the 6-month window; whether future bookings count is open (§ 13B, h). **Overrides D43's single-nickname label.** **D44 stays:** still one row per granted guardian, each with this label. Owner: "คนที่เข้าเรียน หรือ ถ้ามาพร้อมกัน ใช้คำว่า น้อง...และ น้อง ...." (the children who attend; if they come together, use "น้อง… และ น้อง …"). **Open (§ 13B):** a child with no nickname. | One label for siblings who attend together, still nicknames only. |
| D53 | **Notice: every channel counts (round three, item 6).** A cancellation notice counts when it reaches the studio by any of four channels: phone, LINE, telling a teacher, or in person. `cancel_notice_channel` = `line` \| `phone` \| `teacher` \| `in_person` (replaces the two-value rule of D41). `cancel_notice_at` = the time the notice reached the studio: the phone call time, the LINE message time (from the OA chat), the time the teacher was told, or the time of the visit. A notice at or before *session start − `cancel_notice_hours`* makes the cancellation `family_on_time` (status `cancelled`, credit kept). A later notice makes it `family_late` (status `cancelled_late`, D49). Owner: "แจ้งโทรศัพท์ แจ้งไลน์ แจ้งครู นับหมด ถือว่าแจ้ง" (phone, LINE, telling a teacher: all count as notice). **Overrides D41's channel list** (`line` and `in_person` only). D41's other limits stay: no paper channel and no web notice form. | One rule for every way a family reaches the studio. Staff record when the notice arrived, whichever channel it came through. |
| D54 | **Identifiers in the docs: kept, nothing removed (round three, item 7).** Owner: "ไม่ลบ" (do not remove). No change to any identifier in the docs. Recorded here so the decision log shows the question was asked. | Owner's answer. No work item. |
| D55 | **Lawyer sign-off for the changed wording: done (round three, item 8).** Per the owner's report in chat on 14 Oct 2026 ("ยืนยันแล้ว", confirmed), the lawyer's sign-off for the changed wording is recorded as **DONE**. It covers "คุณผู้ปกครอง" in `0006a`, the nickname line in `0006a`, and notice §§ 3.6, 3.10 and 3.11 (TH and EN). The **written** sign-off is not in the repo yet: the owner files it with this decision record. Check before G4 · 0006a: if the final text in `0006a` or in the notice differs from the text the lawyer read, flag it to the owner first (D38). | Records the owner's report without inventing a document. G9b is marked done on the owner's word; the written note is still to be filed. |

**Numbering and overrides (14 Oct 2026).** The owner's decisions use D31–D39. The lawyer decision was first listed as D30, but D30 already means multi-row writes, which many files cite, so the lawyer decision is **D38** (R-59). D1–D29 are not changed. D31 overrides the "no marketing" statements in §§ 1, 5 and 6. D38 overrides the "no lawyer budget" answer. D35 keeps D26 and overrides the owner's answer 16 for adding friends. The clips' legacy seed (R-55) is a review note, not a D-number.

**Round two (14 Oct 2026, the owner's second set of answers): D40–D47.** Each row says what it overrides or refines. In short: **D36** (a missed day no longer free: D40), **D16** (the balance rule: `absent` and `cancelled_late` use a credit: D40), **D31** (the child's information is no longer "never used" for the one follow-up label: D43; the list is per guardian: D44), **D33** (the allergen checklist prints without the include-health tick: D42), **D39** (ten allergen values and the nut group, not nine: D46), **R-55** (the clips' written-source condition: D45). **D26** and **D35** are confirmed, not changed (D47). D1–D29 and the other D30–D38 stand as before.

**Round three (14 Oct 2026, the owner's third set of answers): D48–D55.** Each row says what it overrides or refines. In short: **D40** studio path → **D48** (status `cancelled_studio`, credit returned); **D40** report source → **D49** (`booking_cancellation_log`); **D36** make-up rule → **D48** (removed; the balance check replaces it); **D41** channels → **D53** (four channels); **D43** label → **D52** (all attending children); **D44** stays (two rows); **D42** and **D33** print → **D51** (status line always, content only with the tick); **D16** balance: `cancelled_studio` returns the credit (D48), `cancelled_late` and `absent` still use one (D49, D40). D50 adds `cancelled_late` to the health clock; D54 keeps all identifiers; D55 records the lawyer sign-off as done.

---

## 6. Data-collection map by stage

Lawful bases refer to the Thai PDPA. Retention periods are **proposals the owner must confirm** (§ 12).

| Stage | Who enters it | What we collect | Lawful basis | Kept |
|---|---|---|---|---|
| **0. Visiting the site** | — | Nothing stored by us. Browser `localStorage` keeps the language choice. Turnstile runs on `/book` only. YouTube loads after "play". Google Maps iframe contacts Google (parked option, card PK-06: click-to-load). | Not needed (functional) | — |
| **1. Booking request** (`/book`) | Parent | What to call the parent (`guardian_name`); how they want to talk (`line` = they send the ref code to @cherryleeandco, or `phone` = call back); phone number (required only for `phone`); LINE ID (optional matching hint, D26); for each child (1–3): nickname (optional) and age in years (6–12); package interest (`single`/`four`/`eight`/not sure); preferred day or a session date; optional message (hint: "please don't include health details here"); page language; privacy-notice version. Server adds a reference code. An HMAC of the IP is kept 24 h for rate limiting. | s.24(3) pre-contract | 6 months |
| **2. Confirmed booking** (staff, admin) | Staff | Family record: guardian name, phone/LINE ID; child nickname and birth month (or age until enrolment); package purchase; payments (amount, method, date, receipt no., optional slip image); seat bookings; the guardian's follow-up choice (`marketing_line`, default off, D31). | s.24(3) contract; payments also s.24(6) accounting; follow-up only by consent (s.19) | Profile: 12 months after last activity. Payments/packages: 5 years after the accounting year (accountant to confirm). |
| **3. Enrolment link** (`/enrol/$token`, before the first session) | Parent | Confirms guardian details and the statement "I have parental responsibility for this child"; child birth month (YYYY-MM); **health (optional, separate unticked explicit-consent box)**: allergen chips, other allergens, foods to avoid (no reason asked), care notes; **media consent per channel** (`media_parents_group`, `media_website`, `media_social`, `media_youtube`, `media_print`, D32) + face visible / face hidden; emergency contacts and authorised pickup persons (name, phone, relationship) with "I've told them and shared the privacy notice". | Profile/contacts: s.24(3)/(5); health: s.26 explicit consent; media: s.19/s.20 consent | Health: deleted on withdrawal or 6 months without a booking. Contacts: with the profile. Consent evidence: life of the consent + 3 years. |
| **4. First session** (in person) | Staff | Child's own consent (age 10+) for media and agreement to health info, via a kid-friendly script; guardian identity check if not done; check-in / check-out times and who picked up. | s.20(1); s.24(3)/(5) child safety | Attendance 24 months |
| **5. Ongoing** | Staff / parent | Attendance, package balance, payments, consent changes (via `/my/$token` or LINE), including the follow-up choice (`marketing_line`). | As above | As above |
| **6. End** | System / owner | Automatic purge; rights requests (export, erasure) handled by the owner. | s.33, s.37(3) | Rights-request log 3 years |

### What we deliberately do NOT collect

- Thai national ID numbers, passport numbers, or copies of ID cards (guardians or pickup persons).
- Children's full legal names, full birth dates, schools, gender, nationality, home addresses.
- Reasons for foods to avoid (could reveal religion — also s.26 data), free-text medical histories, diagnoses, medication lists.
- Parent email on the booking request (it is an optional enrolment field, only for families who want receipts by email), social media profiles.
- Raw IP addresses, device fingerprints, cookies, advertising IDs, LINE chat content.
- Payer bank account numbers (slip images only if staff choose to upload one).
- Photos or videos of children (media is referenced by YouTube id and title only).
- Marketing consent other than the guardian opt-in `marketing_line` (D31). Never for children, no bought or shared
  contact lists, no advertising pixels.

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
| Guardian follow-up choice (`guardian_consent_records`, D31) | — | append own family's choice (`/my`) | append (record a parent's choice); read for the follow-up list (P3-19) | same | append |
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
| **A · MVP** | P0, P1, P2 (P2 screens recommended, can be skipped; `0003` is applied either way because `0004` builds on it) | admin login, `/book`, inbox, LINE staff alerts, `/privacy` (notice `…-v1`), sessions + seats | G0–G3 | G4 per SQL file, G5–G8, **G9a (notice v1)** (owner + lawyer, D38), G10 |
| **G-MVP** | — | Owner go/no-go after **≥ 8 weeks** of real use: number of web requests, staff time saved, whether family records are wanted at all. "No" = stop here; Stage A keeps working on its own. | — | — |
| **B · Records** | P3 + **P5 core** | families, packages, payments, bookings, roster/attendance; retention job v4, export, erase, restriction, files-to-delete; notice `…-v2` with the `[P3]` sections | **G-MVP = go**, G11 noted | 0004, **0005 and 0007 applied** (retention/erase for families live in 0007, which depends on 0005's tables; P4 screens stay off), **G4 · 0006a** (marketing text, after G9b, D31 and D38), **G9a (notice v2)**, G10 |
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
- **F3-05** Book a child into a session using a package credit. A family cancellation with notice at or before the threshold keeps the credit (`cancelled`); a late cancellation keeps the seat booked and uses one credit (`cancelled_late`, D49); no notice is `absent` (one credit). Every cancellation writes one row to `booking_cancellation_log` (D49, D53). Cancelling a whole session (with a warning) sets each held or confirmed booking to `cancelled_studio` and returns its credit (D48); seats update.
- **F3-06** Roster `/admin/sessions/$sessionId`: children booked, check-in / check-out time, picked up by (guardian or
  authorised pickup person), attended / absent.
- **F3-07** `/admin/payments`: pending payments to verify, paid this month.
- **F3-08** Privacy notice `…-v2`: add every `[P3]` section (family records, payments, attendance, contacts, retention
  rows, and the guardian follow-up opt-in in § 3.10 of the notice) before Stage B goes live (G9a, lawyer D38).
- **F3-09** Guardian follow-up opt-in (D31): the unticked `marketing_line` box on the create-from-request screen (P3-04)
  and in the P3-11 edit sheets, with the full text above it; a staff-only follow-up list of families who said yes
  (card **P3-19**). Contact only by hand from the LINE OA chat, one family at a time. No bulk or automated sends.
  Restricted families (D28) are left off the list.
- **F3-10** Marketing text: apply `sql/0006a_seed_marketing_text.sql` at **G4 · 0006a** (card **P3-20**), after G9b
  approves the text and before the family create screens go live.

Acceptance: on test data, request → family → 4-session package → payment marked paid → two bookings → check-in/out →
balance shows 2 left and seats left drops by 2; a `staff` user cannot void payments or delete families (owner can);
`audit_log` has rows for each write on families/guardians/children/contacts/payments with the staff user id;
deleting a contact keeps the "picked up by" record; notice `…-v2` live; the marketing box is unticked by default on
both family screens, the follow-up list shows only granted and unrestricted families, and `0006a` is applied only after G9b.

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
- **F4-10** Privacy notice `…-v3`: add every `[P4]` section and the `/my` part of `[P5]` before Stage C goes live (G9a, lawyer D38).
  The v3 notice also covers the print channel (§ 3.7) and the `/my` marketing control (§ 3.10).
- **F4-11** Print channel (D32): the `media_print` box in MediaSection on `/enrol` and `/my` (card **P4-09**), in the
  publishability matrix and the admin media screen (**P4-21**). Its text is in `0006` (G9b).
- **F4-12** Export for signature (D33, card **P4-25**): `/admin/families/$familyId/print`, browser print with the existing
  `@media print` rules, signature lines, nothing stored on the server. Health appears only through the audited health
  function, only when staff tick "include health" for that print. One `audit_log` row per print (action, family id, date).

Acceptance: inserting into `child_health` without a granted `health_allergy` consent fails in the DB; a withdrawal
record deletes the health row and queues a staff alert; each health read writes one `audit_log` row; a 10+ child without
their own media consent shows "not publishable"; an enrol link works once and not after expiry, and two concurrent
submits can't both succeed; `consent_texts` rows can't be edited after insert (only `retired_at`); no consent control is
pre-ticked and every consent control has its full text visible (UI tests); withdrawing a granted media channel on
`/my` (or by staff) records `withdrawn` and alerts staff, while an unticked box on a re-sent `/enrol` link keeps the
earlier decision (R-33); a 10+ child's health "no" hides the health box on `/enrol` (R-34); notice `…-v3` live; print is its own unticked box and its own matrix column; a print without "include health" shows no health data and writes one audit row.

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
| **G6** | P1 | Owner | Secrets in Cloud → Secrets (`PUBLIC_SITE_URL` is plain config, not a secret: set it as a variable, D37): `IP_HASH_SECRET` (generate on your own computer with `openssl rand -hex 32` and paste directly; never in chat or code), `TURNSTILE_SECRET_KEY`, `LINE_ALERT_CHANNEL_ID`, `LINE_ALERT_CHANNEL_SECRET`, `LINE_ALERT_TO` (value `https://cherryleeandco.com`, D37). |
| **G7** | P1 | Owner | Cloudflare account (studio-owned) → Turnstile widget with **exact** hostnames: `cherryleeandco.com` (the live domain; whether it covers `www.` is UNVERIFIED: check in the console, and add `www.cherryleeandco.com` if not) and the preview host `id-preview--fa9b86e9-5d99-468e-be51-3be106fa410c.lovable.app` for testing (D37). The published `*.lovable.app` host only while it is still used. **Never** the apex `lovable.app`. Site key → builder puts it in `src/lib/backend/public-config.ts`; secret → G6. |
| **G8** | P1 | Owner | LINE Developers: a provider named "CherryLee & Co." owned by the studio's own LINE account (permanent). New OA "CherryLee Staff Alerts" (Free), Messaging API on, chat / auto-reply / greeting off. Owner adds the OA as a friend; `LINE_ALERT_TO` = owner's user ID from Basic settings (or a group ID via F1-08). |
| **G9a** | Before **each** stage goes live (A: `…-v1`, B: `…-v2`, C: `…-v3`) | Owner + lawyer (budget approved, D38) | Approve the privacy-notice version that covers everything the stage collects (§ 8.0). The lawyer reviews **every** version, not only v1. |
| **G9b** | Before **G4 · 0006a** (Stage B, marketing text) and before Stage C (`0006`) | Owner + Thai PDPA lawyer (budget approved, D38) | Review every consent text: `0006` (health, the five media channels incl. `media_print`, children 10+ approach in D11, the `OWNER-APPROVE` lines) and `0006a` (the `marketing_line` text). Round two (D43): the child-nickname line in `0006a` and in notice § 3.10 is checked too. Round two (D40, D41): the cancellation notice § 3.11 (LINE notice and credit rule) is checked too. Then apply `0006a_seed_marketing_text.sql` in Stage B, and `0006_seed_consent_texts.sql` in Stage C (+ `0006b` only if G0 Q9 = yes). **Round three (D55, 14 Oct 2026):** the lawyer sign-off for the changed wording (`0006a` "คุณผู้ปกครอง" and the nickname line; notice §§ 3.6, 3.10, 3.11) is **done**, per the owner's report in chat. The written note is to be filed with the decision record. |
| **G10** | End of each phase | Owner | Publish in Lovable (Publish → Publish changes). Before pressing it: fix any critical RLS findings from the publish security scan; confirm Cloud → Users → Auth settings still shows **sign-up disabled**; confirm the privacy notice covers the stage (§ 8.0); run `rls_smoke.sql` in the SQL editor (no `FAIL`). Checklist: `40-integrations.md` § 13. |
| **G-MVP** | After ≥ 8 weeks of Stage A in real use | Owner | Go/no-go for Stage B, based on real request volume and whether family records are wanted (D27). Intent noted on 14 Oct 2026: yes, family records as a customer base for follow-up and sales (D31); the decision itself still waits for 8 weeks of use. Record the decision and date in `90-task-breakdown.md` § 2. |
| **G-HEALTH** | Before Stage C | Owner (+ lawyer) | **Decided 14 Oct 2026: system** (owner's answer 18; Stage C still waits for G9b). The two options were: store allergy data in the system (explicit consent, audited) **or** keep the paper allergy form at the studio. The switch (R-29): **system** = builder sets `HEALTH_IN_SYSTEM = true` in `src/lib/backend/public-config.ts` and applies 0006 as reviewed; **paper** = keep `HEALTH_IN_SYSTEM = false` and delete the two `health_allergy` rows from the **unapplied** 0006 draft before G4, so no health consent (and so no health row) can ever exist; `/enrol` and `/my` then show no health section (they only show purposes with a current text) and the roster shows "see the paper allergy form at the studio". The health code is built either way. |
| **G-PARK** | Any time | Owner | Un-park one parked item (DSR/breach/audit screens, consent-text publishing UI, Umami, PromptPay, Resend, LIFF); only then its cards may run. |
| **G11** | P3 | Owner + accountant | Confirm payment record retention (5 years? juristic person or sole proprietor?). |
| **G12** | P6 | Owner | Check Lovable analytics in DevTools for cookies; optional Umami account; optional Resend; optional PromptPay ID. |
| **G13** | Done 14 Oct 2026 | Owner | Domain `https://cherryleeandco.com` (D37). Set the values it drives: `PUBLIC_SITE_URL` and the Turnstile hostname (`40-integrations.md` §§ 4, 6.1, 12). Umami domain if used. JSON-LD is a website task, not part of this plan. |
| **G4 · 0006a** | Stage B, before the family create screens go live (P3-04, P3-11) | Builder | Paste `sql/0006a_seed_marketing_text.sql` into Lovable chat, as for G4, only after G9b has approved the marketing text (D31, D38). |
| **G0 Q15** | Before the G4 · 0005 seed of the four class clips | Owner | **☑ 14 Oct 2026 (owner certified, D45):** parents agreed to all five channels (website, parents' LINE group, social, YouTube, print). The legacy note is set in the seed; the session-setting step at G4 · 0005 still runs. |

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
`sessions`, `families`, `guardians`, `children`, `family_contacts`, `package_purchases`, `payments`, `bookings`, `booking_cancellation_log` (D49, append-only; log table, `bigint` identity id),
`consent_texts`, `consent_records`, `guardian_consent_records` (D31), `child_health`, `family_links`, `media_assets`, `media_asset_children`,
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
| `booking_status` | `held`, `confirmed`, `attended`, `absent`, `cancelled`, `cancelled_late` (round two, D40), `cancelled_studio` (round three, D48) |
| `notice_channel` | `line`, `phone`, `teacher`, `in_person` (round three, D53; replaces the round-two pair `line`, `in_person`; no paper, no web) |
| `cancellation_outcome` (log column `outcome`) | `family_on_time`, `family_late`, `studio` (round three, D49; the statuses are `cancelled`, `cancelled_late`, `cancelled_studio`) |
| `consent_purpose` | `health_allergy`, `media_parents_group`, `media_website`, `media_social`, `media_youtube`, `media_print` (D32), `marketing_line` (guardian purpose, D31; rows only in `guardian_consent_records`, never in `consent_records`) |
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

Allergen chips (`child_health.allergens text[]`, checked list; the nine FDA major food allergens, D39, plus `flour`, D46): `milk`, `egg`, `flour`, `wheat`, `peanut` and `tree_nut` (one nut group, D46), `soy`,
`fish`, `shellfish`, `sesame`; anything else goes in `other_allergens`.

**Database functions:** `has_role(_user_id uuid, _role app_role)`, `is_staff()`, `is_owner()`, `current_app_role()`,
`set_updated_at()`, `audit_row_change()`, `prevent_update_delete()`, `check_rate_limit(p_bucket text, p_key_hash text,
p_max_per_hour int, p_max_per_day int)`, `purge_expired_records()`, `session_seats_left(p_session_id uuid)`,
`get_open_sessions(p_from date, p_to date)`, `generate_weekend_sessions(p_from date, p_weeks int, p_capacity int)`,
`child_age_years(p_birth_month date, p_on date)`, `has_active_consent(p_child_id uuid, p_purpose consent_purpose)`,
`consent_status(p_child_id uuid, p_purpose consent_purpose)` → `'granted' | 'needs_child' | 'not_granted'`,
`can_publish_media(p_asset_id uuid, p_purpose consent_purpose)`, `get_child_health(p_child_id uuid, p_include_health boolean)` (no default),
`upsert_child_health(p_child_id uuid, p_allergens text[], p_other_allergens text, p_foods_to_avoid text, p_care_notes text)`,
`list_session_health_flags(p_session_id uuid)`, `mark_inactive_families()`, `export_family_data(p_family_id uuid, p_include_health boolean)`,
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
`0004_families.sql`, `0005_consent_health.sql`, `0006a_seed_marketing_text.sql` (D31), `0006_seed_consent_texts.sql`, `0006b_seed_media_parents_group.sql`
(optional), `0007_privacy_ops.sql`, `0008_reporting.sql`, `sql/tests/rls_smoke.sql`, `sql/seed_dev.sql`.
**Apply order:** 0001 → 0002 → 0003 → 0004 → 0005 → 0006a (Stage B, G4 · 0006a) → 0007 → (0006, 0006b after G9b, Stage C) → 0008. **pg_cron jobs:** `purge-expired-records` (`15 19 * * *`),
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
| `/admin/families/$familyId/print` (P4-25, D33) | `src/routes/admin/_staff/families/$familyId_.print.tsx` (`ssr: false`, noindex; the trailing `_` keeps it outside the family page layout; `npx vite build` confirms the route id) |
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
`application/pdf` · signed URLs 60 s · admin language `localStorage` key `cherrylee-admin-lang` · `studio_settings.cancel_notice_hours` = 3 (integer, default 3, D36; round three, D53: the threshold for a family cancellation, `family_on_time` at or before session start minus this many hours; the make-up notice check is retired, D48; a column on the single-row `studio_settings` table, 10 § 6.3) · domain constant `PUBLIC_SITE_URL` = `https://cherryleeandco.com` (D37).

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
| `PUBLIC_SITE_URL` | server config: `https://cherryleeandco.com` (D37; no trailing slash; plain config, not a secret. The request-origin fallback is for local development and preview only; the live site must set it) | Owner | P1 | links in alerts, the privacy notice, Turnstile host |
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
| `child_health` | Immediately on withdrawal/refusal; otherwise 6 months after the child's last session (a `cancelled_late` booking counts, D50) | trigger + purge |
| `bookings` (attendance) | 24 months after the session date | `retain_until` |
| `booking_cancellation_log` (D49) | Not decided on 14 Oct 2026. Proposed: as `bookings`, 24 months after the session date (owner to confirm) | `retain_until` |
| `package_purchases`, `payments`, slips | 5 years after the end of the accounting year (G11) | `retain_until`; anonymised on erase |
| `consent_records`, evidence files | Life of the consent + 3 years (PDPA s.78 claims period) | purge after family deletion + 3 years |
| `guardian_consent_records` (`marketing_line`, D31) | Life of the consent + 3 years, as `consent_records` | `retain_until`; purge after family deletion + 3 years (SQL to confirm) |
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


### 13A. Answers from the owner (14 October 2026, in chat)

Recorded as given. "Plan impact" lists what must change in the plan. The last column (added 14 Oct 2026) shows what the
owner's decisions now settle, with the D-number or R-number. The original answers are unchanged.

| # | Answer | Plan impact | Status after the 14 Oct decisions |
|---|---|---|---|
| 1 | Sole proprietor (เจ้าของคนเดียว) | Privacy notice controller = the owner (name needed for the notice) | Open: the owner's name for the notice (G0 Q1, § 11.6) |
| 2 | Owner account = super admin. **Staff list and LINE-alert recipients: not answered** | Open (ask again) | Still open (not decided on 14 Oct) |
| 3 | 8 seats per session; show seats left | Capacity 8; "seats left" shown publicly | Decided: 8 seats, seats left shown (D14) |
| 4 | No package expiry; siblings may share; no credit deducted for a missed day; make-up allowed if notice given **≥ 3 hours** before | No `expires_on`; add a setting `cancel_notice_hours = 3` (not in the plan yet); site may publish the rule (owner's choice) | Decided: **D36**. Setting `studio_settings.cancel_notice_hours` = 3. Site publishing stays off until the owner asks. Its missed-day sentence is **superseded by D40**. **Round two:** item 1 → **D40** (cancellation with notice keeps the credit; absent or late cancellation uses one; overrides the missed-day sentence of D36). Item 2 → **D41** (notice by LINE, `cancel_notice_at`). |
| 5 | Payment before the class day. Deposits and refunds not answered | Payment timing set; refund rule still open (do not state one) | Payment timing set. Refund and deposit rules still open (not decided) |
| 6 | Retention in § 12 accepted | Done. The notice wording still needs approval (G9a · v1) | Decided: retention accepted (§ 12). Notice wording goes to the lawyer (**D38**) |
| 7 | No paper forms; fully online | Enrolment online (`/enrol`). Paper copies only as export (answer 18) | Decided: enrolment online. Signing export only, **D33** |
| 8 | Allergen checklist, to fill in as a list | Enum in `0005` exists; owner confirms the list | Decided: **D39** (nine FDA allergens, no enum change). **Round two:** the owner's answer is "แพ้ถั่ว" (nut group ถั่ว, with `peanut` and `tree_nut`) and flour. Item 7 → **D46** (`flour` added). Both open confirmations are closed. |
| 9 | Channels: parents' LINE group, website, Facebook/Instagram/TikTok, YouTube, print | **DECIDE:** `media_print` is **not** in the plan. Other purposes exist (`media_parents_group`, `media_website`, `media_social`, `media_youtube`) | Decided: **D32** (`media_print`, its own unticked box, default off) |
| 10 | The LINE account is the studio's and owns the provider | Done (G0 Q10) | Done (G0 Q10). No change |
| 11 | Custom domain: already has one | Domain name needed for `PUBLIC_SITE_URL`, Turnstile hostnames and JSON-LD | Decided: **D37** `https://cherryleeandco.com`. G13 done |
| 12 | No lawyer budget. Use legally compliant wording; parents must agree before any photo is used | **DECIDE:** conflicts with G9a / G9b (see below) | Decided: **D38**. Budget approved; lawyer sign-off pending. Covers G9a and G9b |
| 13 | PromptPay later. Wants a QR **and** the bank account number; PromptPay ID left blank for now | PK-07 spec first. Showing an account number publicly needs a deliberate decision | Not decided on 14 Oct. Still needs the PK-07 spec |
| 14 | Lunch break 1 hour; maximum 8 children per group | Studio facts for the FAQ (owner's approval to publish needed) | Recorded. Publishing on the site still needs the owner's approval |
| 15 | The four class clips: parents agreed to **all channels** | `legacy_consent_purposes` in `0005` changes from website-only. Keep the source of this agreement as evidence (date, form or chat) | Partly decided: **R-55** (all five channels, legacy note). G0 Q15 stays ◐ until the written source is recorded **Round two:** item 6 → **D45**; G0 Q15 ☑ (owner certified 14 Oct 2026, all five channels). |
| 16 | **Yes:** the studio's staff LINE accounts may add parents as friends | **DECIDE:** overturns the default in D26 (see below) | Decided: **D35**. D26 stands; the OA limit overrides this answer. Owner confirms in one line **Round two:** item 8 → **D47** (OA rule kept, no change). |
| 17 | Asked for the list of OWNER-APPROVE lines | List given (§ 13B). Approval pending | List given (§ 13C), with lines added 14 Oct. Approval pending |
| 18 | **G-HEALTH = system** (online, audited, deleted on withdrawal). Export to paper or PDF for signature | Needs G9b lawyer review before Stage C (see below). Export feature not in the plan | Decided: G-HEALTH = system (§ 9); export **D33**. Stage C waits for G9b (**D38**) **Round two:** item 3 → **D42** (one health route for export and print; allergen checklist on every print). |
| 19 | **G-MVP intent:** keep family records as a customer base for follow-up and sales | **DECIDE:** marketing is out of scope in the plan (§ 1, 12.5) | Decided: **D31** (opt-in, guardian only, default off, contact by hand, no bulk sends). G-MVP intent recorded **Round two:** items 4 and 5 → **D43** (label: ครอบครัวน้อง + nickname, staff only) and **D44** (one row per granted guardian). |
| 20 | Prefers "Supabase" | **CLARIFY:** Lovable Cloud already runs on Supabase. Does the owner want a Supabase account of their own, outside Lovable? | Decided: **D34**. Keep Lovable Cloud (= Supabase). No separate account |

**Round three (14 Oct 2026, the owner's third message): status of the eight items.** The original table above is kept. Items 1 and 2 (studio cancellation, late cancellation) answer answer 4: **D48** and **D49**. Item 3 (health clock) answers the § 12 retention rule: **D50**. Item 4 (print status line) answers answers 9 and 18: **D51**. Item 5 (follow-up label) answers answer 19: **D52**. Item 6 (notice channels) answers answer 4 and round-two item 2: **D53**. Item 7 (identifiers) is **D54**: kept. Item 8 (lawyer sign-off) answers answer 12: **D55**, recorded as done.

### 13B. Decisions needed before the affected stage

1. **Lawyer (answers 12, 18). Decided: D38 (budget approved, 14 Oct 2026).** The options below are kept as the record. The plan requires a Thai PDPA lawyer for the notice and consent texts (G9a / G9b) before
   Stage C. Options: (a) budget a short one-off review of the consent texts and rule D11 (a 10+ child's health refusal)
   before Stage C; (b) keep allergy information on paper until that review (G-HEALTH = paper for now). The gate G9a · v1 (notice for Stage A) also lists the lawyer. Skipping it for Stage A
   is the owner's risk decision and needs a written note in § 2.1. Recommended: (a) for Stage C. Fees must be asked of the
   lawyer; the plan does not estimate them.
2. **Sales and follow-up from family records (answer 19). Decided: D31 (opt-in, guardian only, default off, contact by hand).** The original text: the plan had no marketing purpose. Adding one means a new
   `marketing_line` purpose: a separate opt-in checkbox, default **off**, easy to withdraw, a notice update, and no use of
   children's data for sales. Superseded by D31 (14 Oct 2026): no PK-09 exists; marketing is core, as a guardian opt-in, default off. The earlier recommendation was to add it as a parked item (PK-09) that starts only after G-MVP.
3. **Print use of photos and videos (answer 9). Decided: D32 (`media_print`).** Add a `media_print` purpose with its own consent text (OWNER-APPROVE +
   lawyer), so parents can agree to each channel separately.
4. **Staff LINE accounts adding parents (answer 16). Decided: D35 (D26 stands; the OA limit overrides answer 16; the owner confirms the reading in one line).** The original text: this changes D26, which keeps family contacts off personal phones.
   If accepted, the plan needs: device lock and no screenshots of parent chats, a LINE ID stored only with consent, and the
   `/book` copy about LINE IDs rewritten (it currently says the OA cannot add a user by ID).
5. **Export for signature (answer 18). Decided: D33 (card P4-25).** A print view that saves to PDF through the browser. This needs a new card under P4
   (no new packages: use the existing `@media print` rules). Not yet in `90-task-breakdown.md`.
6. **Which Supabase (answer 20). Decided: D34 (keep Lovable Cloud).** The original options: keep Lovable Cloud (the plan as written), or a Supabase account owned by the studio.
   The second option changes gates G1 and G2 and needs research on how Lovable connects to an external project.
7. **Clip consent evidence (answer 15). Partly decided: R-55 (all five channels, legacy note). The written source is still open (G0 Q15 ◐).** On 13 October the same clips were confirmed for the website only. Please confirm
   the wider "all channels" agreement and where it is recorded, before `0005` is changed. **Round two: decided, D45** (owner certified, 14 Oct 2026).

**Round two (14 Oct 2026, second message): status of the eight items.** Decided, and applied in this plan. The original text above is kept.
- Item 1, missed day and cancellation: **decided, D40.** Cancellation with notice keeps the credit; absent or late cancellation uses one credit.
- Item 2, notice channel: **decided, D41.** LINE (`cancel_notice_at` = the time the LINE message arrived); in person also accepted; no web form.
- Item 3, health route for export and print: **decided, D42.** One route, `get_child_health`; the allergen checklist is on every print; other notes only with include health.
- Item 4, follow-up label: **decided, D43.** "ครอบครัวน้อง" + nickname, staff only. The lawyer checks the changed promise under G9b.
- Item 5, follow-up rows: **decided, D44.** One row per granted guardian.
- Item 6, class clips: **decided, D45.** G0 Q15 ☑; all five channels.
- Item 7, allergens: **decided, D46.** `flour` added; the nut group "ถั่ว" with `peanut` and `tree_nut`.
- Item 8, LINE OA rule: **decided, D47.** Kept; no change.

Still open after round two (owner, one line each; the plan stops and reports until answered where a card needs it): (a) a family with two children, or a child without a nickname: which label is used (D43, P3-19); (b) for an export, does `includeHealth` false mean no health at all (D42, the plan says yes); (c) the allergen checklist prints on every sheet without the include-health tick (D42, from the owner's words). The owner's one-line check of the printed sample is a post-build review and does not block P4-25.

**Round three (14 Oct 2026, third message): decided, and applied in this plan.** Item 1 → D48. Item 2 → D49. Item 3 → D50. Item 4 → D51. Item 5 → D52. Item 6 → D53. Item 7 → D54 (no change). Item 8 → D55 (lawyer sign-off recorded as done; written note to be filed).

**Round-two open items after round three:** (a) two or more children: **closed** by D52; a child with **no nickname** is still open. (b) an export with `includeHealth` false: **still open** (D42; the plan says no health in the file). (c) the allergen checklist without the include-health tick: **closed** by D42 and D51.

**Still open after round three (owner, one line each; the cards stop and report where marked):** (a) a child with no nickname: which label that child gets (D52; P3-19 stops and reports); (b) an export with `includeHealth` false (D42, carried from round two); (c) whether `cancelled_studio` counts for the 6-month health clock (D50; the plan says no); (d) whether `absent` counts as attending for the label (D52, literal reading: yes); (e) a withdrawn health consent shows as "refused" on the print status line (D51; the plan says yes); (f) how long `booking_cancellation_log` is kept (§ 12 and 50 § 19.1 together: the proposal is 24 months after the session; not decided); (g) whether `cancelled_late` counts in the attendance-rate denominator: D49 says only that it is not an absence; 0008 must show it and the owner decides.

**Added by the verifier pass (14 Oct 2026, round three; the same list is in 10 § 6.x open questions 21–27, 50 § 28 and 90 § 2.1):** (h) the follow-up label window: the SQL counts a non-cancelled booking from 6 months back with no upper bound, so future bookings count too; the notice says "last 6 months" (D52). Which window applies? (i) the free-text other allergies (`other_allergens`): the SQL and the print sheet now show them only with the includeHealth tick, as health content (D42, D51). Should they print on every sheet, as the allergen checklist does? (j) D49's title says "cancels late or misses": the body and the SQL treat a missed class with no notice as `absent`. Confirm, or make a miss `cancelled_late`. (k) (with a, see the nickname question) the enrolment and booking forms say the nickname is optional, while `children.nickname` is NOT NULL and the conversion refuses a child with no nickname (22023). Required on intake, or a fallback label? (l) the lawyer's written sign-off (D55) must be compared with the final nickname bullet in `0006a` (now plural, D52) and with notice §§ 3.10 and 12.5 before G4 · 0006a; if the lawyer signed the singular line, the plural line needs sign-off again. The SQL provisional readings (cancelled_studio on the health clock, attendance denominator, log retention) stay marked PROVISIONAL in the SQL comments until (c), (f) and (g) are answered.

### 13C. OWNER-APPROVE lines (answer 17): the text to approve

- **Retention wording in notice v1 (6 months, a proposal):** `30-ui.md` lines ~599 and ~735.
- **Takedown target of 7 days (R-24):** `50-security-privacy.md` lines ~475 and ~697.
- **"Tell a teacher before cooking" allergy note:** `50-security-privacy.md` line ~697.
- **/book wording on full dates and waiting lists (no promise to call when a seat opens):** `30-ui.md` lines ~732 and ~883.
- **Access log for health data ("every time someone opens the details, the system records it"):** `sql/0006_seed_consent_texts.sql` line ~41.
- **Child's health refusal (aged 10+, D11):** `30-ui.md` line ~2682. This sentence also needs the lawyer (G9b).
- **Key-change note on /enrol (an empty box keeps the earlier choice):** `30-ui.md` line ~2714.
- **Withdrawal wording:** `50-security-privacy.md` lines ~1082–1083.

Added 14 October 2026 (owner decisions; the lawyer reviews each one under D38):

- **Guardian marketing opt-in text (D31):** `sql/0006a_seed_marketing_text.sql`, `50-security-privacy.md` § 12.5 (text) and the
  notice § 3.10 (TH and EN). The promises to approve: contact is by hand, one family at a time, from the OA chat; no
  automated or bulk sends. The staff list uses the child's nickname only, for the studio's own follow-up, and no other child information is used (the D43 change; G9b).
- **Print consent text (D32):** `sql/0006` (`media_print`), `50-security-privacy.md` § 12.6 (draft). The promises to approve:
  no new prints after a withdrawal; copies already printed and handed out cannot be recalled.
- **Print channel in the notice (D32):** `50-security-privacy.md` § 11 § 3.7 (TH and EN), including the scope of "printed
  materials". The owner must list what counts as print (for example brochures, posters, booklets) before this is final.
- **Print sheet copy (D33, card P4-25):** the "include health" tick text and the signature lines in `30-ui.md`.
- **Allergen labels (D39, D46):** the Thai and English labels for the allergens, including the flour label and the nut group "ถั่ว".
- **Make-up notice (D36):** nothing to approve until the owner asks to publish the rule.

Round two changes to the approve lines (14 Oct 2026, second message):
- **Follow-up label (D43):** the promise "we never use your child's information for this" is replaced by the wording in `50-security-privacy.md` §§ 3.10, 4 and 12.5 (the staff list shows the child's nickname only, for the studio's own follow-up, for staff only, never shown to anyone else). Lawyer under G9b.
- **Notice by LINE and the credit rule (D40, D41):** `50-security-privacy.md` § 11.7, a DRAFT. Not published on `/privacy` unless the owner asks (D36).
- **Allergen checklist and flour (D42, D46):** `50-security-privacy.md` § 3.6 and § 11.7. The allergen checklist prints without the include-health tick (D42).

Round three changes to the approve lines (14 Oct 2026, third message; the lawyer sign-off is recorded as done, D55, and the written note is to be filed):
- **Print status line (D51):** `50-security-privacy.md` § 3.6 (TH and EN) and § 11.8: the health consent status line (granted, refused or not yet asked) is printed on every sheet.
- **Follow-up label (D52):** §§ 3.10, 4 and 12.5, and R-4 in § 12.2: the nicknames of all attending children, each with "น้อง" before it (or "Family of" in English).
- **Notice channels, credit and late cancellation (D48, D49, D53):** § 3.11 (TH and EN) and § 11.8: phone, LINE, telling a teacher and in person all count; a studio cancellation returns the credit; a late cancellation keeps the seat, uses one credit and is not an absence; the cancellation statistics are kept in a separate record.
- **Health clock (D50):** no text change. The lawyer checks that "6 months after your child's last session" (§§ 3.6 and 15, rule 9) covers a `cancelled_late` booking.

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
R-33 … R-48. A third round (the owner's decisions of 14 October 2026) added R-49 … R-59. A fourth round (the owner's second set of answers, 14 October 2026, items 1–8) added R-60 … R-69. A fifth round (the owner's third set of answers, 14 October 2026, items 1–8) added R-71 … R-80. This log is **authoritative**: it sits in the top file of the order of authority, so if any lower file
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
| R-49 | Lawyer review not yet budgeted; G9a/G9b unclear for every version and text (owner decision 1, 14 Oct) | Owner approved the budget (**D38**). Lawyer reviews every notice version (v1, v2, v3) and every consent text (`0006`, `0006a`), the OWNER-APPROVE lines and D11. G9b is approved before G4 · 0006a and before Stage C. No Stage C go-live before G9b. The Stage A notice goes to the lawyer before P2-08 | 00 §§ 5, 8.0, 9, 13A, 13B; 50 header and §§ 11.1, 12, 28; 90 gate tracker (cross-file) |
| R-50 | "No marketing" rules conflict with the owner's family follow-up and sales wish (owner decision 2, 14 Oct) | **D31**: `marketing_line` is a guardian-only opt-in, default off, with its own unticked box (P3-04, P3-11), changed on `/my` (P4-13, P4-22) or by staff, stored in `guardian_consent_records`. Staff follow-up list P3-19; text `0006a` (G4 · 0006a); contact by hand from the OA chat only; no bulk or automated sends; restricted families excluded (D28). The "no marketing" statements in § 1, §§ 5–6 and s.21/s.32 are replaced; 50 § 12.5 moves into the core design | 00 §§ 1, 4, 5, 6, 7, 8, 9, 10, 12, 13B; 50 §§ 10, 11, 12, 12.5, 13, 14, 16, 18.1, 25, 28; 90 P3-04, P3-11, P3-19, P3-20, P4-13, P4-22 (cross-file) |
| R-51 | Print not a consent channel (owner decision 3, 14 Oct) | **D32**: `media_print` added to `consent_purpose` (same rules as `media_social`, child-level, `media_level`, default not granted); TH/EN text in `0006` (lawyer reviewed); separate control in P4-09 on `/enrol` and `/my`; publishability matrix and admin media (P4-21); five separate channel boxes | 00 §§ 5, 6, 8, 10, 13B; 50 §§ 3.7 (notice), 11.2, 12, 12.1, 12.2, 12.3, 12.6 (new), 13, 17.2, 25; 0005 and 0006 seeds and 20/30 (cross-file) |
| R-52 | Export for signature not in the plan (owner decision 5, 14 Oct) | **D33**: card P4-25 and route `/admin/families/$familyId/print` (`ssr: false`, noindex); browser print with `@media print`, no PDF package, nothing stored; health only through the audited function when staff tick "include health"; one `audit_log` row per print (action, family id, date, never content); signature lines | 00 §§ 4, 5, 8.0, 8 P4, 10 routes, 13B; 50 §§ 5 (audit row), 15 (rule 4 exception); 20, 30, 90 (cross-file) |
| R-53 | Supabase question open (owner decision 6, 14 Oct) | **D34**: keep Lovable Cloud (= Supabase). No separate account. G1 and G2 unchanged | 00 §§ 5, 9 (G1, G2 unchanged), 13A, 13B |
| R-54 | Staff LINE accounts adding parents (owner decision 4, 14 Oct) | **D35**: D26 stands. The OA cannot add or message a user who has not messaged it. No UI copy, button or field asks staff to copy a parent's LINE ID in order to add them (remove any that exists). Staff reply only in chats the family started. The optional LINE ID hint on `/book` (D26) is not removed by these decisions; the owner is asked to confirm | 00 §§ 5, 13A, 13B; 40 § 5.10 (new); 50 § 23 item 8; 20 and 30 UI copy (cross-file) |
| R-55 | Four class clips: legacy consent seed for all channels (owner decision 7, 14 Oct; no D-number) | `legacy_consent_purposes` = all five media channels (`media_parents_group`, `media_website`, `media_social`, `media_youtube`, `media_print`). `legacy_consent_note` = "Owner statement 14 Oct 2026; written source to be recorded before G4 (G0 Q15)". The 13 Oct answer named the website only, so the written source is the open point. G0 Q15 stays ◐. The `0005` seed of these four clips must not run at G4 until the source is recorded | 00 §§ 9, 13A, 13B; 50 §§ 17.1, 17.2; 0005 seed (cross-file) |
| R-56 | Allergen list not fixed (owner decision 8, 14 Oct) | **D39**: the nine FDA major food allergens, matching the existing `0005` enum (no enum change), plus `other_allergens` and `foods_to_avoid`. Thai labels in the copy (30-ui). No claim of matching a Thai list. Owner still confirms "แพ้ทั่ว" and "แพ้แป้ง" | 00 §§ 5, 10, 13A; 30-ui and 0005 labels (cross-file); 50 § 15 (no change) |
| R-57 | Domain not set (owner decision 9, 14 Oct) | **D37**: `PUBLIC_SITE_URL` = `https://cherryleeandco.com`; Turnstile hostname `cherryleeandco.com` (covers `www.`) plus the preview host for testing; the base for JSON-LD and the notice's website field. G13 done. The JSON-LD code change is a website task, not part of this plan | 00 §§ 5, 9, 11, 13A; 40 §§ 4, 6.1, 12; 50 §§ 2, 11.3, 11.4 (website line) |
| R-58 | Cancellation and make-up rules not in the plan (owner decision 10, 14 Oct) | **D36**: packages never expire; siblings may share; a missed day deducts no credit (**superseded by D40**); make-up needs notice of at least 3 hours before the original session. `studio_settings.cancel_notice_hours` = 3 (integer, default 3), enforced in the make-up booking check (`validate_booking()` or the make-up function, 10 and 20 to confirm). The site publishes the rule only if the owner asks | 00 §§ 5, 10, 13A; 10 (`studio_settings` column, make-up check) and 20/90 (cross-file) |
| R-59 | Brief numbering collision: D30 already in use (14 Oct) | The lawyer decision is **D38**, not D30: D30 already means multi-row writes, which many files cite. The 14 Oct decisions use D31–D39. Any reference to "D30 lawyer" means D38 | 00 §§ 5, 13A; 50 header; 90 (cross-file) |
| R-60 | Missed-day rule conflicts with the owner's round-two answer (major) | **D40**: `absent` and `cancelled_late` use a credit; `cancelled` with notice at or before the threshold keeps it. A make-up uses the same notice. D36's missed-day sentence and the D16 balance rule are overridden | 00 §§ 5, 13A, 13B; 50 § 11.7; 10 (booking statuses, `consumes_credit`, balance views); 0004 (`validate_booking`, `package_balances`); 0007 and 0008 (reports, purge counter); 20 § 9.7 and 30 (booking and make-up specs); 90 P3-06 (cross-file) |
| R-61 | No record of when a cancellation notice was given (minor) | **D41**: `cancel_notice_at` (the time the LINE message arrived, from the OA chat) and `cancel_notice_channel` = `line` or `in_person`, recorded on the booking screen. No paper channel, no web notice form | 00 §§ 5, 13A; 10 (bookings columns), 20 § 9.7, 30 (booking screen), 90 P3-06, P3-04, P3-11; 50 § 11.7 |
| R-62 | Export has a plain join to `child_health` in 0007: a second health route, blocking G4 · 0007 (major) | **D42**: export and print read health only through `get_child_health` with the explicit `includeHealth`; the plain join is removed; the print sheet shows the allergen checklist always, other notes only with include health; G4 · 0007 is no longer blocked by this route | 00 §§ 5, 13A; 0007 (export function, header); 20 §§ 9.13, 9.16 (print includeHealth rule); 30 (print screen); 50 §§ 15 (rule 4 decided), 28 (Q17); 90 § 2 (G4 · 0007), P4-25 |
| R-63 | Follow-up label uses a child's nickname while `0006a` and notice § 3.10 say child information is never used (major) | **D43**: label "ครอบครัวน้อง" + nickname, staff only; `0006a` and notice § 3.10 rewritten to say so; lawyer under G9b; the D31 promise and the README rule are overridden for this one label | 00 §§ 5, 13C; 50 §§ 3.10, 11.2, 11.7, 12.5, 28 (Q18); 90 P3-19, P3-20, G9b; README golden rules; `sql/0006a` (cross-file) |
| R-64 | Follow-up list is per family, so a family with two consenting guardians shows one row (minor) | **D44**: one row per granted guardian, each with the family label; one withdrawal removes only its own row | 00 §§ 5, 13A; 0007 (`marketing_follow_up_list`), 20 § 9.5a, 30 (follow-up screen), 90 P3-19 |
| R-65 | Written source for the four clips' consent not recorded, G0 Q15 open (minor) | **D45**: owner certified 14 Oct 2026; G0 Q15 ☑; the legacy note is replaced; the lawyer checks the legacy cover under G9b. R-55's written-source condition is overridden | 00 §§ 5, 9, 13A, 13B; 50 § 28 (Q16); 0005 seed (cross-file); 90 § 2 (G0 Q15), P3-17, G9b |
| R-66 | Allergen check list lacks flour; nuts shown as two unrelated values (major for the cooking class) | **D46**: `flour` added to the check list; `wheat` kept; nut group "ถั่ว" with `peanut` and `tree_nut`; labels in P4-15 and P0-18; the enrol page (P4-08) uses the same labels | 00 §§ 5, 13A; 0005 (check list), `seed_dev` and `rls_smoke` (cross-file), 10 (enum table), 30 (labels); 50 §§ 3.6, 11.7, 15 (rule 1); 90 P0-18, P4-08, P4-15, P4-25 |
| R-67 | LINE OA rule questioned again in the owner's answer 8 round (minor) | **D47**: D26 and D35 stand; no change; the owner's "คงไว้" confirms D35's reading | 00 §§ 5, 13A; 40 § 5.10; 50 § 23 (item 10); 90 § 2 (G0) |
| R-68 | Gate tracker, gate notes and notice paragraphs not updated for round two (minor) | G0 Q15 ☑ (14 Oct 2026); a G0 round-two row; G9b covers the `0006a` nickname line; G4 · 0007 route decided; one dated § 2.1 line per item; the notice § 11.7 drafts are marked for the lawyer | 00 § 9; 90 §§ 2, 2.1; 50 § 11.7; README |
| R-69 | Stale names in the cards and in 90 § 6 (minor): the follow-up route named as a separate file; allergen values counted as nine | 90 § 6 uses `/admin/families?view=follow-up` (no route file, as P3-19 says); the allergen values are ten plus the nut group (D46) | 90 §§ 4, 5, 6; README (D31–D47); 30 (cross-file) |
| R-70 | Verifier pass on the round-two specs (14 Oct 2026, 30 issues): notice column names split between SQL and spec; `cancelled_at` and `makeup_of_booking_id` missing in SQL; `get_child_health` and `export_family_data` called without the explicit flag; allergen checklist gated by the tick, against D42; follow-up view and spec disagreed on the label columns; export health not on the tick; print audit name split (`print` / `print_record`); G0 round-two row and lawyer wording out of step with the tracker | Fixed in the SQL (0004, 0005, 0007, 0008, seed_dev, rls_smoke, 0006a Thai wording) and in the specs (00, 10, 20, 30, 50, 90, 40, README). Kept SQL column names `cancel_notice_at` / `cancel_notice_channel`. The audit action is `print_record`. The follow-up view returns label columns. Export and print health: one route, explicit flag, allergen checklist always shown. | 00 §§ 5, 9, 13A–13C, 15; 0004; 0005; 0007; 0008; 10 § 6.14; 20 §§ 9.5a, 9.7, 9.10, 9.13, 9.16; 30; 50; 90 |
| R-71 | A studio cancellation kept the credit under D40 (status `cancelled`), through the `cherrylee.studio_cancel` rule (major) | **D48**: a studio cancellation of a whole session sets `cancelled_studio` and returns the credit to the balance. Erase and the other non-cancellation paths keep their behaviour. `cherrylee.studio_cancel` is also used by `erase_family` (0007, which keeps credits), so the flag name stays unless 0004 and 0007 change together (cross-file) | 00 §§ 5, 10, 13B, 15; 10 (§ 6.14 statuses, transaction flags); 0004 (`cancel_bookings_of_cancelled_session`, `validate_booking`); 0007 (`erase_family` keeps its behaviour); 0008 (counts); 20 § 9.7; 30 (roster and sessions warning); 90 P3-06, P3-13 (cross-file where noted) |
| R-72 | The make-up rule needed an original status of `cancelled` and notice (`check_make_up_notice`, `make_up_notice_short`) (major) | **D48**: the make-up check is removed. A rebooking uses a credit still in the balance (a kept `cancelled` credit or a returned `cancelled_studio` credit), checked by `validate_booking()`. `check_make_up_notice()` and `make_up_notice_short` are retired. `makeup_of_booking_id` may stay as a reference only; no check depends on it (10 and 20 to confirm). `cancel_notice_hours` stays, as the family cancellation threshold (D53) | 00 §§ 5, 10, 13A, 15; 10 (§ 6.3, § 6.14, § 7); 0004 (remove `check_make_up_notice`); seed_dev and rls_smoke (make-up cases removed); 20 §§ 4, 9.7; 30 (MakeUpDialog removed); 90 P1-15, P3-06, § 6, § 7 |
| R-73 | No separate place for cancellation statistics; a late cancellation counted as an absence in attendance (major) | **D49**: `cancelled_late` keeps the seat counted as booked, is not an absence in `attendance_rate`, and uses one credit. New append-only table `booking_cancellation_log` (outcomes `family_on_time`, `family_late`, `studio`). The reports count cancellations from it (0008). `absent` is not logged | 00 §§ 5, 10, 12, 15; 10 (new table, enum, § 6.14); 0004 (table, written in the same transaction as the status); 0008 (reports); 20 § 9.7; 30 (booking and report screens); 50 §§ 3.11, 19.1, 25 (row 14), 28 (Q21); 90 P3-06, P3-13, § 6, § 7 (cross-file where noted) |
| R-74 | Whether a `cancelled_late` booking counts for the 6-month child_health clock was open (minor) | **D50**: it counts, for the same reason as before. Open: `cancelled_studio` (not stated; the plan says it does not count) | 00 §§ 5, 12, 13B; 50 §§ 15 (rule 9), 19.1, 3.6 (lawyer checks the "last session" wording); 0005 (`child_health` purge, cross-file) |
| R-75 | The printed sheet showed no health consent state, so a sheet could look like "no allergy" or "no consent" (major) | **D51**: a health consent status line (granted, refused, not yet asked) per child on every sheet. `includeHealth` controls content only; the allergen checklist always prints (D42). The status comes from the current `health_allergy` decision; `withdrawn` shows as refused until the owner confirms (§ 13B, e) | 00 §§ 5, 13B, 13C, 15; 50 §§ 3.6, 11.8, 15 (rule 4), 28 (Q23); 0005 (`record_family_print`, cross-file); 20 § 9.16 (cross-file); 30 (print screen, cross-file); 90 P4-25 |
| R-76 | The follow-up label used one child's nickname; a family with two attending children had no rule (major) | **D52**: the label uses the nicknames of all attending children (a non-cancelled booking in the 6-month window): "ครอบครัว" + "น้อง" + each nickname, joined by " และ " (two) or ", … และ …" (three or more); English "Family of A and B". Overrides D43's single-nickname label. D44 unchanged (two rows). A child with no nickname stays open (§ 13B, a) | 00 §§ 5, 10, 13B, 13C; 50 §§ 3.10, 4, 12.2 (R-4), 12.5, 14 (rule 7), 25 (row 13), 28 (Q18), 10-row s.21; `sql/0006a` (nickname line, plural; cross-file); 0007 (view label, cross-file); 20 § 9.5a (cross-file); 30 (follow-up screen, cross-file); 90 P3-19, P3-20, G9b, § 6, § 7 |
| R-77 | Notice channels were `line` and `in_person` only (D41); a phone call or a message to a teacher did not count (major) | **D53**: four channels (`line`, `phone`, `teacher`, `in_person`). `cancel_notice_at` = the time the notice reached the studio, from the channel that received it. D41's limits (no paper, no web form) stay. D26 unchanged; 40 § 5.10 confirms the notice time rule | 00 §§ 5, 10, 13A; 40 § 5.10; 50 §§ 3.11, 23 (item 11), 25 (row 14); 10 (`notice_channel`, booking columns, cross-file); 0004 (CHECK lists, cross-file); 20 § 9.7 (zod, cross-file); 30 (booking screen, cross-file); 90 P3-06, P3-13 |
| R-78 | The owner was asked whether identifiers in the docs should be removed (minor) | **D54**: nothing is removed; no change | 00 § 5 (D54); README (round-three list) |
| R-79 | The lawyer sign-off for the changed wording was pending (major for G9b) | **D55**: recorded as done per the owner's report of 14 Oct 2026. The written note is to be filed with the decision record. Check the final text in `0006a` and the notice against what the lawyer read before G4 · 0006a | 00 §§ 5, 9, 13C; 50 header, §§ 11.8, 12.2; 90 § 2 (G9b), § 2.1 |
| R-80 | Round-three answers that do not settle every case (minor) | Open, one line each for the owner (00 § 13B): (a) a child with no nickname (label, D52); (b) an export with `includeHealth` false (D42, carried); (c) `cancelled_studio` and the health clock (D50); (d) `absent` in the label set (D52); (e) a withdrawn health consent on the print status line (D51); (f) how long `booking_cancellation_log` is kept | 00 §§ 12, 13B; 50 §§ 19.1, 28 (Q19, Q21, Q22, Q23); 90 § 2 (G0 · round 3), P3-19, P4-25 |
| R-81 | Verifier blocker: the follow-up label named a child whose only booking was cancelled late, and the seed asserted it (blocker) | `family_label` counts a child only with a non-cancelled booking (held, confirmed, attended, absent). `child_has_recent_booking` is for the health clock only. Seed L2 flipped; L3 to L5 expectations fixed. The window (future bookings) is open, § 13B (h) | 0007 § 9; 0004 header; seed_dev § 7e; 10 §§ 6.17a, 8, § 18 (open 19, 21–27); 20 § 9.5a; 50 § 3.10 (wording already right); 90 P3-19 |
| R-82 | Verifier blocker: `erase_family` cancelled the family's future bookings to `cancelled_studio`, returned credits and wrote studio log rows, against the round-two erase rule (blocker) | Restored the round-two erase: no status change, credit kept, no log row; the family id is still detached from log rows. Seed § 8 and 10 erase rows updated; D48 corrected (the flag is removed; erase uses `allow_purge` only) | 0007 § 7 and header; seed_dev § 8; 10 §§ 8 (erase_family row), 13 (erase table); 00 D48; 90 § 2.1 log |
| R-83 | Verifier major: a family cancel with no notice was saved as `cancelled_late` and logged as `family_late`; attended and absent bookings could be cancelled (major) | `cancel_booking` refuses a family cancel with no notice (22023; staff record `absent`) and refuses any booking that is not held or confirmed (23514). `validate_booking` turns a cancellation with no notice into `absent`. Seed (4) and (C) updated; new refusal checks. The D49 "misses" wording is an owner question (§ 13B j) | 0004 §§ 1, 8b, 19 and header; seed_dev § 7d (4), § 7e (C); 20 § 9.7 tests; 10 § 6.14, § 8, § 18 (open 25); 00 D49 |
| R-84 | Verifier major: the server called `cancel_booking` with `p_by`, but the SQL takes `p_studio`; card P3-06 decided on-time vs late in TypeScript (major) | 20 § 9.7 sends `p_studio` with the notice fields; the on-time rule stays in SQL; card P3-06 no longer has `noticeInTime` or a status choice; the server reads back the status | 20 § 9.7 (cancelBooking row, tests); 90 P3-06, § 6 names; 10 § 8 |
| R-85 | Verifier major: free-text `other_allergens` was returned and printed without the includeHealth tick (major) | The SQL (`get_child_health`) returns `other_allergens` only with includeHealth true; the print sheet (30 § 4.x, P4-25) and the export follow it. The owner rules on the free text (§ 13B i) | 0005 § 9 (get_child_health); 10 §§ 6.18, 8, § 18 (open 26); 20 §§ 9.8, 9.16 (health read); 30 § 4.3 (print route); 90 P4-25 |
| R-86 | Verifier major: the marketing nickname line in `0006a` was singular and the header said round three changed nothing; § 12.5 is plural (major) | `0006a` TH and EN nickname bullets are plural (all attending children, D52); the header now says do not apply until the owner compares the final text with the lawyer's note (D55) | 0006a header and bullets; 50 § 12.5 (text already plural); 00 § 13B (l); 90 P3-20 |
| R-87 | Verifier major: card P1-15 asked for a make-up hint on the cancel-notice setting (major) | P1-15 step 5 now uses the round-three hint (family cancellation notice keeps the credit), TH and EN, no make-up wording; copy from 30 (settings.cancelNoticeHours) | 90 P1-15; 30 (settings copy, unchanged) |
| R-88 | Verifier major: a child with no nickname broke the family conversion with a raw not-null error; the docs said such a child is left out of the label (major) | The conversion refuses it with a clear error (22023); the docs no longer say "left out". The owner decides required-or-fallback (§ 13B a, k); the nickname hint and zod refuse a leading "น้อง" | 0004 § 14b; 20 §§ 9.5a, Nickname, BookingChildInput; 30 § 3.2 hint and the fieldErrors copy (nickname_prefix); 10 § 18 (open 27); 90 P3-19 |
| R-89 | Verifier minor batch: stale text and wrong references (minor) | Stale "first active child" text removed (0004 comment, 0007 header, seed comments); 0008 header marks the round-two "not attended" as superseded; `recorded_by` = staff user for the studio path (comments fixed); makeup link kept in SQL but not sent (20 § 9.7, 10, P3-06); saveSession text describes the direct trigger write; 20 reports names the real views; P4-25 takes the consent status from `get_child_health` only; G-HEALTH note updated; MarketingConsentBlock path corrected in the names table; retention references now match (§ 13B f) | 0004; 0007; 0008; seed_dev; 10; 20 §§ 9.4, 9.7, 9.16; 30 § 3.2 (hint); 90 § 2, § 6, P3-06, P4-25 |
| R-90 | Verifier: provisional readings made silently in the SQL (minor) | Marked PROVISIONAL in SQL comments (cancelled_studio on the health clock: 0005; attendance denominator: 0008; log retention: 0004) and listed as owner questions (c), (f), (g) in § 13B. The open lists in 00, 10, 50 and 90 are aligned | 0004 § 8b; 0005 § 9; 0008; seed_dev § 7e (H); 00 § 13B; 10 § 18 (open 21–27); 50 § 28; 90 § 2.1 |
