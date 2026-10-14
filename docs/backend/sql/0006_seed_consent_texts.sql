-- =============================================================================
-- 0006_seed_consent_texts.sql · CherryLee & Co. backend · DRAFT MIGRATION (DATA)
-- -----------------------------------------------------------------------------
-- Phase:      P4 (feature F4-02)
-- Gate:       G9b FIRST (owner + Thai PDPA lawyer review this wording and decision D11),
--             THEN G4 — a HUMAN applies it through Lovable chat. Implementers never run it.
-- Status:     *** DRAFT pending G9b legal review — DO NOT APPLY BEFORE G9b IS MARKED DONE ***
-- Purpose:    version 1 of the consent wording, Thai + English, for five purposes:
--             health_allergy (explicit, PDPA s.26), media_website, media_social, media_youtube,
--             media_print (added 14 Oct 2026, decision 3; LAWYER REVIEW, default NOT granted).
--             media_parents_group moved to the OPTIONAL file 0006b_seed_media_parents_group.sql (review R-24:
--             apply it only if the owner confirms the private parents' group exists, G0 Q9).
--             The marketing_line text (guardian scope, decision 2) is NOT here: it is in 0006a_seed_marketing_text.sql.
-- Owner approval (review R-24): sentences marked "-- OWNER-APPROVE" below describe what the studio will do;
--             the owner confirms them at G9b together with the lawyer, or the builder edits them first.
-- G-HEALTH (00-overview § 9, review R-29): if the owner chose the PAPER allergy form, the builder deletes the
--             two health_allergy rows BEFORE G4: from the dashed comment line just above "-- health_allergy · TH"
--             down to, but not including, the dashed comment line just above "-- media_website · TH". The rows are
--             comma-separated and the last row
--             (media_youtube EN) has no trailing comma, so the VALUES list stays valid. Without a health text no
--             health consent can be granted, so child_health can never receive data.
-- Depends on: 0005_consent_health.sql
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- Rules:
--   * consent_texts are IMMUTABLE once inserted (trigger). If the lawyer changes the wording,
--     edit THIS FILE before applying. After applying, changes = a new version, never an UPDATE: either a
--     new reviewed SQL draft like this one (G9b + G4), or the owner runs publish_consent_text() in
--     Cloud → SQL editor (00-overview § 8.0). The /admin/settings publishing screen is PARKED (card PK-03).
--   * G-HEALTH = paper: publish_consent_text() refuses to create the FIRST health_allergy text (R-35), so
--     health storage can only be switched on by a reviewed SQL draft after a new G-HEALTH decision.
--   * TH and EN keep the same version number. Studio voice: warm, ends with ค่ะ, no fear wording.
--   * Facts only: nothing here may promise group sizes, outcomes or policies the studio hasn't set.
--   * Re-running is safe: on conflict (purpose, version, lang) do nothing.
-- =============================================================================

insert into public.consent_texts
  (purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values

-- -----------------------------------------------------------------------------
-- health_allergy · TH
-- OWNER-APPROVE: "ทุกครั้งที่มีคนเปิดดูรายละเอียด ระบบจะบันทึกไว้" (true: get_child_health audits),
--   "คุณครูจะชวนน้องคุยในวันแรก" (a studio process, D11; lawyer question G9b).
-- -----------------------------------------------------------------------------
('health_allergy', 1, 'th',
 'ข้อมูลการแพ้อาหารและการดูแลของน้อง (ขอความยินยอมโดยชัดแจ้ง)',
 $txt$ในคลาส Basic Cooking น้องๆ ได้ลงมือทำอาหารจริงกับอังเคิลลีค่ะ เพื่อให้คุณครูวางแผนกิจกรรมทำอาหารได้อย่างปลอดภัย เราขออนุญาตเก็บข้อมูลต่อไปนี้ของน้องค่ะ

- อาหารที่น้องแพ้
- อาหารที่น้องต้องหลีกเลี่ยง (ไม่ต้องบอกเหตุผลค่ะ)
- วิธีดูแลเบื้องต้นที่คุณครูควรรู้

**ใครเห็นข้อมูลนี้:** เฉพาะคุณครูและทีมงานของสตูดิโอค่ะ ทุกครั้งที่มีคนเปิดดูรายละเอียด ระบบจะบันทึกไว้ว่าใครเปิดดูเมื่อไร

**เราไม่ส่งข้อมูลนี้ทาง LINE** และไม่ใช้เพื่อเรื่องอื่นนอกจากการดูแลน้องระหว่างกิจกรรมค่ะ

**เก็บนานเท่าไร:** จนกว่าคุณพ่อคุณแม่จะถอนความยินยอม หรือครบ 6 เดือนหลังรอบเรียนล่าสุดของน้อง แล้วระบบจะลบให้อัตโนมัติค่ะ

**เก็บที่ไหน:** ในระบบหลังบ้านของเว็บไซต์ ซึ่งใช้ผู้ให้บริการคลาวด์ในภูมิภาคเอเชียแปซิฟิก (อยู่นอกประเทศไทย) ค่ะ

**ไม่บังคับค่ะ** ถ้ายังไม่สะดวกให้ข้อมูลตอนนี้ ไม่เป็นไรเลยค่ะ บอกคุณครูได้ทุกเมื่อก่อนคลาสทำอาหารนะคะ

**ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทักเราทาง LINE หรือบอกคุณครูที่สตูดิโอก็ได้ค่ะ เมื่อถอนแล้ว เราจะลบข้อมูลสุขภาพของน้องทันที

สำหรับน้องอายุ 10 ปีขึ้นไป คุณครูจะชวนน้องคุยและถามความเห็นของน้องด้วยในวันแรกที่มาเรียน ถ้าน้องไม่สะดวก เราจะลบข้อมูลนี้และคุยกับคุณพ่อคุณแม่ต่อค่ะ

เมื่อติ๊กช่องนี้ คุณพ่อคุณแม่**ยินยอมโดยชัดแจ้ง**ให้ CherryLee & Co. เก็บและใช้ข้อมูลการแพ้อาหาร อาหารที่ต้องหลีกเลี่ยง และวิธีดูแลเบื้องต้นของน้อง เพื่อให้คุณครูและอังเคิลลีวางแผนกิจกรรมทำอาหารได้อย่างปลอดภัยค่ะ$txt$,
 true, 10),

-- -----------------------------------------------------------------------------
-- health_allergy · EN
-- -----------------------------------------------------------------------------
('health_allergy', 1, 'en',
 'Your child''s food allergies and care notes (explicit consent)',
 $txt$In Basic Cooking, children really cook with Uncle Lee. To plan cooking activities safely, we would like to keep the following about your child:

- foods your child is allergic to
- foods your child needs to avoid (no need to tell us why)
- first-aid or care notes the teachers should know

**Who can see it:** only the studio's teachers and staff. Every time someone opens the details, the system records who looked and when.

**We never send this information on LINE**, and we use it only to look after your child during activities.

**How long we keep it:** until you withdraw your consent, or 6 months after your child's most recent session. Then the system deletes it automatically.

**Where it is stored:** in the website's back office, which uses a cloud provider in the Asia Pacific region (outside Thailand).

**This is optional.** If you'd rather not share it now, that's fine. You can tell a teacher any time before a cooking session.

**You can withdraw at any time** through your "My consents" link, by messaging us on LINE, or by telling a teacher at the studio. When you withdraw, we delete your child's health information straight away.

For children aged 10 and over, a teacher will also talk with your child and ask what they think on their first day. If your child isn't comfortable, we will delete this information and talk with you.

By ticking this box, you give **explicit consent** for CherryLee & Co. to keep and use your child's food allergies, foods to avoid and care notes, so the teachers and Uncle Lee can plan cooking activities safely.$txt$,
 true, 10),

-- -----------------------------------------------------------------------------
-- media_website · TH
-- -----------------------------------------------------------------------------
('media_website', 1, 'th',
 'รูปและวิดีโอบนเว็บไซต์ของสตูดิโอ',
 $txt$เราชอบเล่าเรื่องราวของสตูดิโอผ่านภาพบรรยากาศตอนน้องๆ เล่นละคร ทำอาหาร และเล่นบอร์ดเกมการเงินค่ะ ข้อนี้ขออนุญาตใช้รูปและวิดีโอที่มีน้องอยู่**บนเว็บไซต์ของ CherryLee & Co.** ซึ่งใครก็เปิดดูได้

- คุณพ่อคุณแม่เลือกได้ว่า **เห็นหน้าน้องได้** หรือ **ไม่ให้เห็นหน้าน้อง** ค่ะ
- เราไม่ใส่ชื่อน้องในคำบรรยาย คำอธิบายภาพ หรือชื่อไฟล์ค่ะ
- **ไม่บังคับค่ะ** การไม่อนุญาตไม่มีผลต่อการเรียนของน้องเลย
- น้องอายุ 10 ปีขึ้นไป คุณครูจะถามความเห็นของน้องเองด้วย เราจะใช้รูปที่มีน้องก็ต่อเมื่อทั้งคุณพ่อคุณแม่และน้องตกลงค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทาง LINE หรือบอกคุณครูที่สตูดิโอ เราจะหยุดใช้ทันทีและนำออกจากเว็บไซต์โดยเร็วค่ะ ส่วนสำเนาที่คนอื่นบันทึกหรือแชร์ต่อไปแล้ว เราอาจตามลบให้ได้ไม่ทั้งหมด ขอแจ้งไว้ตรงๆ นะคะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ยังใช้อยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_website · EN
-- -----------------------------------------------------------------------------
('media_website', 1, 'en',
 'Photos and videos on the studio''s website',
 $txt$We love telling the studio's story with moments of children acting, cooking and playing money board games. This asks your permission to use photos and videos that include your child **on the CherryLee & Co. website**, which anyone can visit.

- You choose: **your child's face may be shown**, or **your child's face must not be shown**.
- We never put your child's name in captions, image descriptions or file names.
- **This is optional.** Saying no makes no difference to your child's classes.
- For children aged 10 and over, a teacher will also ask your child. We only use photos of your child when both you and your child agree.
- **You can withdraw at any time** through your "My consents" link, on LINE, or by telling a teacher. We stop using it straight away and remove it from the website as soon as we can. Copies other people have already saved or shared may not all be removable; we want to be honest about that.
- We keep a record of this consent while it is in use and for 3 years afterwards, as evidence.$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_social · TH
-- -----------------------------------------------------------------------------
('media_social', 1, 'th',
 'รูปและวิดีโอบน Facebook, Instagram และ TikTok ของสตูดิโอ',
 $txt$ข้อนี้ขออนุญาตใช้รูปและวิดีโอที่มีน้องอยู่ บนเพจ **Facebook, Instagram และ TikTok ของ CherryLee & Co.** ค่ะ แพลตฟอร์มเหล่านี้เป็นของบริษัทต่างประเทศ และใครก็เข้าไปดูได้

- คุณพ่อคุณแม่เลือกได้ว่า **เห็นหน้าน้องได้** หรือ **ไม่ให้เห็นหน้าน้อง** ค่ะ
- เราไม่ใส่ชื่อน้องในคำบรรยาย แฮชแท็ก หรือการแท็กค่ะ
- **ไม่บังคับค่ะ** การไม่อนุญาตไม่มีผลต่อการเรียนของน้องเลย
- น้องอายุ 10 ปีขึ้นไป คุณครูจะถามความเห็นของน้องเองด้วย เราจะโพสต์รูปที่มีน้องก็ต่อเมื่อทั้งคุณพ่อคุณแม่และน้องตกลงค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทาง LINE หรือบอกคุณครูที่สตูดิโอ เราจะหยุดโพสต์ทันทีและลบออกจากเพจของสตูดิโอโดยเร็วค่ะ ส่วนสำเนาที่คนอื่นแชร์ต่อไปแล้ว เราอาจตามลบให้ได้ไม่ทั้งหมด ขอแจ้งไว้ตรงๆ นะคะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ยังใช้อยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_social · EN
-- -----------------------------------------------------------------------------
('media_social', 1, 'en',
 'Photos and videos on the studio''s Facebook, Instagram and TikTok',
 $txt$This asks your permission to use photos and videos that include your child on **CherryLee & Co.'s Facebook, Instagram and TikTok** pages. These platforms are run by companies outside Thailand, and anyone can see what is posted.

- You choose: **your child's face may be shown**, or **your child's face must not be shown**.
- We never put your child's name in captions, hashtags or tags.
- **This is optional.** Saying no makes no difference to your child's classes.
- For children aged 10 and over, a teacher will also ask your child. We only post photos of your child when both you and your child agree.
- **You can withdraw at any time** through your "My consents" link, on LINE, or by telling a teacher. We stop posting straight away and remove it from the studio's pages as soon as we can. Copies other people have already shared may not all be removable; we want to be honest about that.
- We keep a record of this consent while it is in use and for 3 years afterwards, as evidence.$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_youtube · TH
-- -----------------------------------------------------------------------------
('media_youtube', 1, 'th',
 'วิดีโอบนช่อง YouTube ของสตูดิโอ',
 $txt$ข้อนี้ขออนุญาตใช้วิดีโอที่มีน้องอยู่ บน**ช่อง YouTube ของ CherryLee & Co.** ค่ะ YouTube เป็นแพลตฟอร์มของบริษัทต่างประเทศ และใครก็เข้าไปดูได้ วิดีโอบางคลิปอาจนำมาแสดงบนเว็บไซต์ของสตูดิโอด้วย (ซึ่งเราขออนุญาตแยกอีกข้อหนึ่งค่ะ)

- คุณพ่อคุณแม่เลือกได้ว่า **เห็นหน้าน้องได้** หรือ **ไม่ให้เห็นหน้าน้อง** ค่ะ
- เราไม่ใส่ชื่อน้องในชื่อคลิป คำอธิบาย หรือคำบรรยายค่ะ
- **ไม่บังคับค่ะ** การไม่อนุญาตไม่มีผลต่อการเรียนของน้องเลย
- น้องอายุ 10 ปีขึ้นไป คุณครูจะถามความเห็นของน้องเองด้วย เราจะใช้วิดีโอที่มีน้องก็ต่อเมื่อทั้งคุณพ่อคุณแม่และน้องตกลงค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทาง LINE หรือบอกคุณครูที่สตูดิโอ เราจะหยุดใช้ทันทีและนำคลิปออกจากช่องของสตูดิโอโดยเร็วค่ะ ส่วนสำเนาที่คนอื่นบันทึกหรือแชร์ต่อไปแล้ว เราอาจตามลบให้ได้ไม่ทั้งหมด ขอแจ้งไว้ตรงๆ นะคะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ยังใช้อยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_youtube · EN
-- -----------------------------------------------------------------------------
('media_youtube', 1, 'en',
 'Videos on the studio''s YouTube channel',
 $txt$This asks your permission to use videos that include your child on **CherryLee & Co.'s YouTube channel**. YouTube is run by a company outside Thailand, and anyone can watch. Some clips may also appear on the studio's website (we ask about that separately).

- You choose: **your child's face may be shown**, or **your child's face must not be shown**.
- We never put your child's name in video titles, descriptions or captions.
- **This is optional.** Saying no makes no difference to your child's classes.
- For children aged 10 and over, a teacher will also ask your child. We only use videos of your child when both you and your child agree.
- **You can withdraw at any time** through your "My consents" link, on LINE, or by telling a teacher. We stop using it straight away and remove the clip from the studio's channel as soon as we can. Copies other people have already saved or shared may not all be removable; we want to be honest about that.
- We keep a record of this consent while it is in use and for 3 years afterwards, as evidence.$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_print · TH   (decision 3, 14 Oct 2026 · LAWYER REVIEW · default not granted)
-- OWNER-APPROVE: the kinds of printed material named here (โปสเตอร์ แผ่นพับ เอกสารประชาสัมพันธ์) are the
--   studio's; the owner confirms the list at G9b. Remove any kind the owner does not use.
-- -----------------------------------------------------------------------------
('media_print', 1, 'th',
 'รูปและวิดีโอในสื่อสิ่งพิมพ์ของสตูดิโอ',
 $txt$ข้อนี้ขออนุญาตใช้รูปที่มีน้องอยู่ ใน**สื่อสิ่งพิมพ์ของ CherryLee & Co.** เช่น โปสเตอร์ แผ่นพับ หรือเอกสารประชาสัมพันธ์ค่ะ สื่อที่พิมพ์ออกมาแล้วคนทั่วไปอาจเห็นได้

- คุณพ่อคุณแม่เลือกได้ว่า **เห็นหน้าน้องได้** หรือ **ไม่ให้เห็นหน้าน้อง** ค่ะ
- เราไม่ใส่ชื่อน้องในคำบรรยายหรือชื่อของสื่อค่ะ
- **ไม่บังคับค่ะ** การไม่อนุญาตไม่มีผลต่อการเรียนของน้องเลย
- น้องอายุ 10 ปีขึ้นไป คุณครูจะถามความเห็นของน้องเองด้วย เราจะใช้รูปที่มีน้องก็ต่อเมื่อทั้งคุณพ่อคุณแม่และน้องตกลงค่ะ
- **ถอนความยินยอมได้ทุกเมื่อ** ผ่านลิงก์ "ความยินยอมของฉัน" ทาง LINE หรือบอกคุณครูที่สตูดิโอ เมื่อถอนแล้ว เราจะไม่พิมพ์สื่อใหม่ที่มีน้อง และจะนำน้องออกจากสื่อที่ยังใช้อยู่เท่าที่ทำได้ค่ะ สำเนาที่พิมพ์ไปแล้วอาจเรียกคืนไม่ได้ทั้งหมด ขอแจ้งไว้ตรงๆ นะคะ
- เราเก็บบันทึกการยินยอมนี้ไว้ระหว่างที่ยังใช้อยู่ และต่ออีก 3 ปีหลังจากนั้นเพื่อเป็นหลักฐานค่ะ$txt$,
 false, 10),

-- -----------------------------------------------------------------------------
-- media_print · EN   (decision 3, 14 Oct 2026 · LAWYER REVIEW · default not granted)
-- -----------------------------------------------------------------------------
('media_print', 1, 'en',
 'Photos and videos in the studio''s printed materials',
 $txt$This asks your permission to use photos that include your child in **CherryLee & Co.'s printed materials**, such as posters, leaflets or promotional handouts. Printed material can be seen by anyone who picks it up.

- You choose: **your child's face may be shown**, or **your child's face must not be shown**.
- We never put your child's name in captions or image descriptions.
- **This is optional.** Saying no makes no difference to your child's classes.
- For children aged 10 and over, a teacher will also ask your child. We only use photos of your child when both you and your child agree.
- **You can withdraw at any time** through your "My consents" link, on LINE, or by telling a teacher. From then on we will not print new material with your child in it, and we will take your child out of printed material still in use, as far as we can. Printed copies that are already out may not all be recoverable; we want to be honest about that.
- We keep a record of this consent while it is in use and for 3 years afterwards, as evidence.$txt$,
 false, 10)

on conflict (purpose, version, lang) do nothing;

-- End of 0006_seed_consent_texts.sql
