-- =============================================================================
-- 0006a_seed_marketing_text.sql · CherryLee & Co. backend · DRAFT MIGRATION (DATA)
-- -----------------------------------------------------------------------------
-- Phase:      P3 (card P3-20 "apply 0006a"); decision 2 of 14 Oct 2026 (family records for follow-up).
-- Gate:       G9b FIRST (owner + Thai PDPA lawyer review this wording), THEN G4 · 0006a: a HUMAN applies this
--             file through Lovable chat, in Stage B, BEFORE the family create screens (P3-04, P3-11) go live.
--             Implementers never run it.
-- Status:     *** DRAFT pending G9b legal review — DO NOT APPLY BEFORE G9b IS MARKED DONE ***
-- Purpose:    version 1 of the marketing_line wording, Thai + English. marketing_line is a GUARDIAN purpose:
--             the parent's own separate opt-in to follow-up messages from the studio about classes, by LINE.
--             It is stored in guardian_consent_records (0005 section 5b), never in consent_records (per child).
--             Rules the wording must keep (decision 2):
--               * a SEPARATE checkbox with the full text above it; never pre-ticked; "not now" = not granted;
--               * withdrawing is as easy as giving (a new 'withdrawn' record, no deletion);
--               * the follow-up list shows the child's NICKNAME only, to staff only, for the studio's own follow-up,
--                 and the wording says exactly that (round two, brief item 4, 14 Oct 2026). Lawyer: G9b line.
--               * contact is by hand from the LINE OA chat, one family at a time: no automated bulk sends.
-- Depends on: 0005_consent_health.sql (enum value marketing_line, consent_texts, guardian_consent_records).
--             Apply after 0005 and 0007, before any family screen that asks the question goes live.
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- Rules:
--   * consent_texts are IMMUTABLE once inserted (trigger). If the lawyer changes the wording, edit THIS FILE
--     before applying. After applying, changes = a new version (publish_consent_text, owner, Cloud SQL editor).
--   * TH and EN keep the same version number. Studio voice: warm, ends with ค่ะ, no fear wording.
--   * Facts only: no frequency promises, no discounts, no outcomes. The studio's LINE OA is @cherryleeandco.
--   * Re-running is safe: on conflict (purpose, version, lang) do nothing.
-- =============================================================================

insert into public.consent_texts
  (purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values

-- -----------------------------------------------------------------------------
-- marketing_line · TH   (LAWYER-REVIEW G9b: whole text, and especially the child-nickname bullet (brief item 4); OWNER-APPROVE: "ข้อเสนอเกี่ยวกับคอร์สเรียน", "ทีละครอบครัว")
-- -----------------------------------------------------------------------------
('marketing_line', 1, 'th',
 'รับข่าวคลาสทาง LINE จากทีมงาน CherryLee & Co.',
 $txt$ข้อนี้เป็น**ความยินยอมแยกต่างหากค่ะ** ไม่เกี่ยวกับการสมัครเรียนของน้อง และไม่เกี่ยวกับความยินยอมเรื่องรูปภาพหรือข้อมูลการแพ้อาหาร

เราอยากส่งข้อมูลเกี่ยวกับ**คลาส รอบเรียนที่เปิดรับ และข้อเสนอเกี่ยวกับคอร์สเรียน**ให้คุณผู้ปกครองทาง LINE ค่ะ

- ทีมงานจะติดต่อคุณผู้ปกครองผ่านแชทของ LINE Official Account **@cherryleeandco** ทีละครอบครัว เราจะไม่ส่งข้อความอัตโนมัติจำนวนมากให้ทุกคนพร้อมกันค่ะ
- **ไม่บังคับค่ะ** ถ้าไม่ติ๊กช่องนี้ ไม่มีผลต่อการเรียนหรือการจองคลาสของน้องเลยค่ะ
- **รายชื่อภายในของทีมงานใช้ชื่อเล่นของน้องค่ะ** เพื่อเรียกชื่อครอบครัว เช่น "ครอบครัวน้อง…" รายชื่อนี้ใช้เพื่อการติดต่อของสตูดิโอเอง แสดงให้เฉพาะทีมงานเท่านั้น ไม่แสดงต่อสาธารณะ และในรายชื่อนี้ไม่มีชื่อจริง อายุ หรือข้อมูลสุขภาพของน้องค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ง่ายเท่ากับตอนให้ความยินยอม ผ่านลิงก์ "ความยินยอมของฉัน" ทักมาบอกเราทาง LINE หรือบอกทีมงานที่สตูดิโอก็ได้ค่ะ หลังจากนั้นเราจะไม่ติดต่อเรื่องนี้อีกค่ะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ครอบครัวยังใช้บริการอยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, null),

-- -----------------------------------------------------------------------------
-- marketing_line · EN   (same meaning as the TH text)
-- -----------------------------------------------------------------------------
('marketing_line', 1, 'en',
 'Follow-up messages about classes from the studio on LINE',
 $txt$This is a **separate choice**. It is not part of your child's enrolment, and it does not depend on the consents for photos or food allergies.

We would like to send you information about classes, upcoming class times and offers for class packages, by LINE.

- A teacher will contact you through the chat of the LINE Official Account **@cherryleeandco**, one family at a time. We will not send bulk messages to everyone at once.
- **This is optional.** If you leave it unticked, nothing changes for your child's classes or bookings.
- **The staff follow-up list uses your child's nickname only.** It shows a label such as "Family of …" so staff can find your family. The list is for the studio's own follow-up, is visible to staff only, and is never shown publicly. It does not include your child's full name, age, health information or photos.
- **You can withdraw at any time**, as easily as you gave consent: use your "My consents" link, message us on LINE, or tell a teacher at the studio. After you withdraw, we will not contact you about this again.
- We keep a record of this choice while your family is with us, and for 3 years afterwards, as evidence.$txt$,
 false, null)

on conflict (purpose, version, lang) do nothing;

-- End of 0006a_seed_marketing_text.sql
