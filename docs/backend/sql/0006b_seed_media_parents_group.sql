-- =============================================================================
-- 0006b_seed_media_parents_group.sql · CherryLee & Co. backend · OPTIONAL DRAFT MIGRATION (DATA)
-- -----------------------------------------------------------------------------
-- Phase:      P4 (feature F4-02b), OPTIONAL
-- Gate:       apply ONLY IF the owner confirms at G0 (question 9) that the studio really runs a private
--             parents' chat group per class where teachers share photos (review R-24: facts only from
--             the studio). Then G9b (lawyer reviews this wording), then G4 — a HUMAN applies it.
--             If there is no such group, NEVER apply this file: /enrol and /my then simply don't show the
--             "parents' group" switch (getEnrolmentForm returns consentTexts.media_parents_group = null).
-- Depends on: 0005_consent_health.sql (and 0006 applied first, so version numbers stay 1)
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- Rules: same as 0006 (immutable texts, TH + EN same version, studio voice, facts only).
--   Re-running is safe: on conflict (purpose, version, lang) do nothing.
-- =============================================================================

insert into public.consent_texts
  (purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values

-- -----------------------------------------------------------------------------
-- media_parents_group · TH
-- -----------------------------------------------------------------------------
('media_parents_group', 1, 'th',
 'รูปและวิดีโอในกลุ่มแชตส่วนตัวของผู้ปกครอง',
 $txt$ระหว่างกิจกรรม คุณครูอาจถ่ายรูปหรือวิดีโอสั้นๆ ตอนน้องๆ เล่นละคร ทำอาหาร หรือเล่นบอร์ดเกมการเงิน แล้วส่งให้คุณพ่อคุณแม่ดูใน**กลุ่มแชตส่วนตัวของผู้ปกครองในรอบเรียน**ค่ะ ข้อนี้ขออนุญาตให้มีน้องอยู่ในรูปหรือวิดีโอที่ส่งในกลุ่มนี้

- คุณพ่อคุณแม่เลือกได้ว่า **เห็นหน้าน้องได้** หรือ **ไม่ให้เห็นหน้าน้อง** ค่ะ
- คนที่อยู่ในกลุ่มคือผู้ปกครองของน้องๆ ในรอบเรียนเดียวกันและทีมงานของสตูดิโอ
- เราไม่ใส่ชื่อจริงของน้องในข้อความหรือชื่อไฟล์ค่ะ
- **ไม่บังคับค่ะ** การไม่อนุญาตไม่มีผลต่อการเรียนของน้องเลย
- น้องอายุ 10 ปีขึ้นไป คุณครูจะถามความเห็นของน้องเองด้วย เราจะส่งรูปที่มีน้องก็ต่อเมื่อทั้งคุณพ่อคุณแม่และน้องตกลงค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทาง LINE หรือบอกคุณครูที่สตูดิโอ เราจะหยุดส่งรูปของน้องทันทีค่ะ ส่วนรูปที่ส่งไปแล้วอาจมีผู้ปกครองท่านอื่นบันทึกไว้ ซึ่งเราอาจตามลบให้ได้ไม่ทั้งหมด ขอแจ้งไว้ตรงๆ นะคะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ยังใช้อยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_parents_group · EN
-- -----------------------------------------------------------------------------
('media_parents_group', 1, 'en',
 'Photos and videos in the private parents'' chat group',
 $txt$During activities, teachers may take photos or short videos of the children acting, cooking or playing money board games, and share them with families in the **private parents' chat group for that class**. This asks your permission for your child to appear in what we share there.

- You choose: **your child's face may be shown**, or **your child's face must not be shown**.
- The group includes parents of children in the same class and the studio team.
- We never put your child's real name in messages or file names.
- **This is optional.** Saying no makes no difference to your child's classes.
- For children aged 10 and over, a teacher will also ask your child. We only share photos of your child when both you and your child agree.
- **You can withdraw at any time** through your "My consents" link, on LINE, or by telling a teacher. We stop sharing photos of your child straight away. Other parents may already have saved photos shared earlier, and we may not be able to remove every copy; we want to be honest about that.
- We keep a record of this consent while it is in use and for 3 years afterwards, as evidence.$txt$,
 false, 10)

on conflict (purpose, version, lang) do nothing;

-- End of 0006b_seed_media_parents_group.sql
