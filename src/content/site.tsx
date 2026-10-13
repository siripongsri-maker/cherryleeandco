import type { ReactNode } from "react";
import { LINE_ID, PRICES, formatBaht } from "./business";

/**
 * All website copy, Thai + English side by side.
 * Edit text here — components only handle layout.
 * Facts come from facebook.com/cherryleeandco; don't add claims the studio hasn't published.
 * Thai tip: wrap compound words that must not split across lines in <Nobr>…</Nobr>.
 */

export type Lang = "th" | "en";

type Card = { title: string; body: ReactNode };
type Teacher = {
  role: string;
  name: string;
  fullName: string;
  photoAlt: string;
  points: [ReactNode, ReactNode, ReactNode, ReactNode];
};
type Principle = { title: string; term?: string; body: string };
type Skill = { en: string; th?: string };
type Program = {
  key: "story" | "cooking" | "money";
  kicker: ReactNode;
  title: string;
  body: ReactNode;
  ledBy: string;
  imgAlt: string;
  stories?: { label: string; list: string };
};
type Plan = { name: string; sub: string; note: string; badge?: string; lineMessage: string };

export type SiteContent = {
  meta: { title: string; description: string };
  skipLink: string;
  newTab: string;
  langChanged: string;
  brand: { homeLabel: string; topLabel: string };
  nav: {
    label: string;
    items: { href: string; label: string }[];
    cta: string;
    menuOpen: string;
    menuClose: string;
    langGroup: string;
  };
  hero: {
    script: string;
    title: ReactNode;
    lead: ReactNode;
    ctaPrimary: string;
    ctaSecondary: string;
    teachers: ReactNode;
    factsLabel: string;
    facts: [string, string, string, string];
    artAlt: string;
    caption: ReactNode;
  };
  why: { eyebrow: string; title: ReactNode; lead: ReactNode; cards: Card[]; punch: ReactNode };
  approach: {
    eyebrow: ReactNode;
    title: ReactNode;
    lead: ReactNode;
    cherry: Teacher;
    lee: Teacher;
    principles: [Principle, Principle, Principle];
  };
  programs: {
    eyebrow: string;
    title: string;
    lead: ReactNode;
    items: Program[];
    skillsTitle: string;
    skills: [Skill, Skill, Skill, Skill];
  };
  quote: { label: string; text: ReactNode; source: string; caption: ReactNode };
  pricing: {
    eyebrow: string;
    title: string;
    details: [Card, Card, Card, Card];
    plans: [Plan, Plan, Plan];
    book: string;
    includedTitle: string;
    included: string[];
    finePrint: string;
  };
  faq: { eyebrow: string; title: ReactNode; items: { q: ReactNode; a: ReactNode }[] };
  visit: {
    eyebrow: string;
    title: ReactNode;
    nameSuffix?: string;
    address: string;
    hours: string;
    directions: string;
    openPin: string;
    mapTitle: string;
  };
  cta: { title: string; body: string; line: string; messenger: string };
  footer: { tagline: string; navLabel: string; follow: string; email: string; credit: string };
  sticky: string;
};

/** Keeps a Thai compound word (or a time range) on one line. */
export const Nobr = ({ children }: { children: ReactNode }) => (
  <span className="whitespace-nowrap">{children}</span>
);
const Hl = ({ children }: { children: ReactNode }) => <span className="hl">{children}</span>;
const TeacherLink = ({ children }: { children: ReactNode }) => (
  <a href="#approach" className="whitespace-nowrap font-semibold">
    {children}
  </a>
);
const En = ({ children }: { children: ReactNode }) => <span lang="en">{children}</span>;

const th: SiteContent = {
  meta: {
    title: "เรียนภาษาอังกฤษผ่านละคร เด็ก 6–12 ปี นวมินทร์ | CherryLee & Co.",
    description:
      "Witty English Weekends สำหรับเด็ก 6–12 ปี ฝึกภาษาอังกฤษแบบไม่กลัวผิดผ่านละครนิทาน ทำอาหาร และบอร์ดเกมการเงิน กับครูเชอร์รี่และอังเคิลลี ทุกเสาร์และอาทิตย์ ซอยนวมินทร์ 117 กรุงเทพฯ",
  },
  skipLink: "ข้ามไปยังเนื้อหาหลัก",
  newTab: " (เปิดในหน้าต่างใหม่)",
  langChanged: "เปลี่ยนเป็นภาษาไทยแล้ว",
  brand: { homeLabel: "CherryLee & Co. หน้าแรก", topLabel: "CherryLee & Co. กลับขึ้นด้านบน" },
  nav: {
    label: "เมนูหลัก",
    items: [
      { href: "#approach", label: "แนวทางของเรา" },
      { href: "#programs", label: "กิจกรรม" },
      { href: "#pricing", label: "ค่าเรียน" },
      { href: "#faq", label: "คำถามที่พบบ่อย" },
      { href: "#visit", label: "ที่ตั้ง" },
    ],
    cta: "จองที่นั่ง",
    menuOpen: "เปิดเมนู",
    menuClose: "ปิดเมนู",
    langGroup: "เลือกภาษา / Choose language",
  },
  hero: {
    script: "เรียนรู้ทักษะชีวิตสำหรับเด็กและครอบครัว",
    title: (
      <>
        <Nobr>ภาษาอังกฤษ</Nobr>ที่<Nobr>เริ่มจาก</Nobr>
        <Nobr>
          <Hl>ความกล้า</Hl>
        </Nobr>{" "}
        <Nobr>ไม่ใช่ความกลัว</Nobr>
      </>
    ),
    lead: (
      <>
        <strong className="text-ink" lang="en">
          Witty English Weekends
        </strong>{" "}
        พื้นที่ให้เด็ก <Nobr>6–12 ปี</Nobr> ได้ใช้<Nobr>ภาษาอังกฤษ</Nobr>ผ่าน<Nobr>ละครนิทาน</Nobr>{" "}
        <Nobr>ทำอาหาร</Nobr> และ<Nobr>บอร์ดเกมการเงิน</Nobr> กับครูไทยและ
        <Nobr>ครูเจ้าของภาษา</Nobr> ในบรรยากาศบ้านที่อบอุ่น พูดผิดก็ไม่มีใครหัวเราะ
      </>
    ),
    ctaPrimary: "จองที่นั่งทาง LINE",
    ctaSecondary: "ดูกิจกรรมทั้งหมด",
    teachers: (
      <>
        สอนโดย <TeacherLink>ครูเชอร์รี่</TeacherLink> ครูละครประสบการณ์กว่า 20 ปี และ{" "}
        <TeacherLink>อังเคิลลี</TeacherLink> อดีตเชฟจากแคนาดา
      </>
    ),
    factsLabel: "ข้อมูลคลาสโดยย่อ",
    facts: [
      "อายุ 6–12 ปี",
      "เสาร์หรืออาทิตย์ 09:00–15:00 น.",
      "กลุ่มเล็ก ดูแลใกล้ชิด",
      "ซอยนวมินทร์ 117",
    ],
    artAlt:
      "ภาพประกอบตัดกระดาษ เด็กสองคนสวมหน้ากากนกกระเรียนและนกกระสาเล่นละคร ส่วนอีกคนถือหนังสือนิทานเล่าเรื่อง ล้อมรอบด้วยดอกไม้และใบไม้หลากสี",
    caption: (
      <>
        นิทานเรื่อง <em lang="en">The Crane &amp; the Heron</em> ในคลาส <En>Story Playlit</En>
      </>
    ),
  },
  why: {
    eyebrow: "ทำไมลูกถึงเงียบ",
    title: (
      <>
        เรียนภาษาอังกฤษมาหลายปี แต่พอเจอ<Nobr>ชาวต่างชาติ</Nobr> ลูกกลับเงียบ?
      </>
    ),
    lead: (
      <>
        ความเงียบไม่ได้แปลว่าลูก “ไม่รู้” เสมอไป <Nobr>หลายครั้ง</Nobr>เด็กแค่ยังไม่
        <Nobr>รู้สึกปลอดภัย</Nobr> <Nobr>นักภาษาศาสตร์</Nobr> <En>Stephen Krashen</En>{" "}
        อธิบายเรื่องนี้ไว้ในสมมติฐาน <strong lang="en">Affective Filter</strong> ว่า
        เมื่อเด็กรู้สึกกังวล ภาษาที่ได้ยินจะ<Nobr>ซึมเข้าไป</Nobr>ได้ยากขึ้น
      </>
    ),
    cards: [
      {
        title: "ตามไม่ทัน",
        body: (
          <>
            รอบตัวมีแต่ภาษาที่ยังไม่คุ้น สมองแปลตามไม่ทัน เด็กเลยเลือก <Nobr>“เงียบไว้ก่อน”</Nobr>{" "}
            เพื่อให้<Nobr>ตัวเอง</Nobr>
            <Nobr>รู้สึกปลอดภัย</Nobr>
          </>
        ),
      },
      {
        title: "กลัวพูดผิด",
        body: (
          <>
            ถ้ารู้สึกว่ามีคนคอยฟังว่าสำเนียงชัดไหม <Nobr>แกรมมาร์</Nobr>ผิดตรงไหน การไม่พูดเลยก็ดู
            <Nobr>ปลอดภัยกว่า</Nobr>
          </>
        ),
      },
      {
        title: "ไม่มีใครช่วยอธิบาย",
        body: (
          <>
            พอติดแล้วไม่มีใครช่วยอธิบายเป็นภาษาไทย เด็กก็ไม่รู้จะไปต่ออย่างไร{" "}
            <Nobr>เลยเงียบไว้ก่อน</Nobr>
          </>
        ),
      },
    ],
    punch: (
      <>
        สิ่งที่ช่วยได้คือ
        <Hl>
          ครูที่<Nobr>อธิบาย</Nobr>เป็น<Nobr>ภาษาไทย</Nobr>ได้
        </Hl>{" "}
        <Nobr>ทันทีที่ลูกติด</Nobr>
      </>
    ),
  },
  approach: {
    eyebrow: (
      <>
        ครูคู่ (<En>Team Teaching</En>)
      </>
    ),
    title: (
      <>
        ครูไทยกับ<Nobr>ครูเจ้าของภาษา</Nobr> <Nobr>สอนคู่กัน</Nobr>
      </>
    ),
    lead: (
      <>
        CherryLee &amp; Co. ก่อตั้งโดย<Nobr>ครูเชอร์รี่</Nobr>และ<Nobr>อังเคิลลี</Nobr>{" "}
        เราเชื่อว่าเด็กวัย <Nobr>6–12 ปี</Nobr>
        เรียนภาษาได้ดีที่สุดเมื่อรู้สึก<Nobr>ปลอดภัยทางใจ</Nobr> <Nobr>ครูเชอร์รี่</Nobr>จึงคอย
        <Nobr>ดูแล</Nobr>ความรู้สึกและช่วยอธิบายเป็นภาษาไทย ส่วน<Nobr>อังเคิลลี</Nobr>ชวนเด็กๆ ใช้
        <Nobr>ภาษาอังกฤษ</Nobr>ผ่าน<Nobr>การลงมือทำจริง</Nobr>
      </>
    ),
    cherry: {
      role: "ครูไทย · เซฟโซนของเด็กๆ",
      name: "ครูเชอร์รี่",
      fullName: "ญาณี เหล่าวิริยะรัตน์ ลาฟฟึ่น",
      photoAlt: "ครูเชอร์รี่ ผมสีรุ้ง สวมแว่น ยิ้มกอดอกในเสื้อยืดสีขาวลายโลโก้ CherryLee & Co.",
      points: [
        <>
          <En>Drama Educator</En> ประสบการณ์สอนกว่า 20 ปี
        </>,
        "อ่านภาษากายและเข้าใจจิตวิทยาเด็ก",
        "อธิบายจุดที่ติดเป็นภาษาไทยอย่างอ่อนโยน",
        "ใช้ละครสร้างสรรค์ช่วยให้เด็กๆ หายเกร็ง",
      ],
    },
    lee: {
      role: "ครูเจ้าของภาษา · ชวนใช้ภาษาจริงแบบไม่กดดัน",
      name: "อังเคิลลี",
      fullName: "Lee Laffan",
      photoAlt: "อังเคิลลี ยิ้มอย่างเป็นกันเองในเสื้อยืดสีชมพูลายโลโก้ CherryLee & Co.",
      points: [
        "อดีตเชฟมืออาชีพจากแคนาดา",
        <>
          ผู้ออกแบบหลักสูตร <En>Money Wise</En>
        </>,
        "ชวนใช้ภาษาผ่านการลงมือทำจริง",
        "ไม่จับผิดสำเนียง ไม่ตัดสิน",
      ],
    },
    principles: [
      {
        title: "รู้สึกปลอดภัยก่อน แล้วค่อยกล้าพูด",
        term: "Psychological Safety",
        body: "บรรยากาศที่เด็กรู้ว่า พูดผิดก็ไม่มีใครหัวเราะ",
      },
      {
        title: "เรียนด้วยการลงมือทำ",
        term: "Hands-on Learning",
        body: "ใช้ภาษาตอนมือเปื้อนแป้ง ตอนเล่นเกมซื้อขาย และตอนเล่นเป็นตัวละคร",
      },
      {
        title: "สำเนียงคือตัวตน",
        term: "Accent Is Identity",
        body: "เน้นพูดให้ชัดและกล้าพูด มากกว่าพยายามพูดให้เหมือนใคร",
      },
    ],
  },
  programs: {
    eyebrow: "Witty English Weekends",
    title: "3 กิจกรรมซิกเนเจอร์ที่เด็กๆ หลงรัก",
    lead: (
      <>
        เด็กๆ ได้ใช้<Nobr>ภาษาอังกฤษ</Nobr>ตอนเล่นละคร <Nobr>ทำอาหาร</Nobr> และเล่นเกม
        แทนการนั่งท่องศัพท์ <Nobr>ครั้งละ 6 ชั่วโมง</Nobr>
      </>
    ),
    items: [
      {
        key: "story",
        kicker: (
          <>
            ละครสร้างสรรค์จากนิทาน<Nobr>ภาษาอังกฤษ</Nobr>
          </>
        ),
        title: "Story Playlit",
        body: (
          <>
            เด็กๆ สวมบทเป็นตัวละครจากนิทาน<Nobr>ภาษาอังกฤษ</Nobr> แล้วเล่นเป็นละครสั้นด้วยกัน
            ได้ใช้จินตนาการ <Nobr>กล้าแสดงออก</Nobr> และพูดภาษาอังกฤษไปพร้อมกัน
          </>
        ),
        ledBy: "นำกิจกรรมโดย ครูเชอร์รี่",
        imgAlt:
          "ภาพประกอบตัดกระดาษ เด็กสองคนสวมชุดเสือและที่คาดผมหูกระต่าย เล่นละครบนเวทีเล็กๆ โดยมีตุ๊กตาสัตว์นั่งดู",
        stories: {
          label: "นิทานที่เคยเล่น:",
          list: "The Crane & the Heron · Gracie Grabbit & the Tiger",
        },
      },
      {
        key: "cooking",
        kicker: "ทำอาหารแสนอร่อย",
        title: "Basic Cooking",
        body: (
          <>
            ลงมือทำอาหารจริงกับอังเคิลลีที่เคยเป็นเชฟ ได้จับ ดม และชิมวัตถุดิบ จำ
            <Nobr>คำศัพท์</Nobr>ในครัวกับ
            <Nobr>ขั้นตอนการทำ</Nobr>ไปพร้อมกัน
          </>
        ),
        ledBy: "นำกิจกรรมโดย อังเคิลลี",
        imgAlt: "ภาพประกอบตัดกระดาษ เชฟตัวน้อยสองคนสวมหมวกเชฟ กำลังนวดแป้งและแต่งคุกกี้บนโต๊ะไม้",
      },
      {
        key: "money",
        kicker: "การเงินสำหรับเด็ก",
        title: "Money Wise",
        body: (
          <>
            เล่นบอร์ดเกมและเกมจำลองการซื้อขาย ได้เรียนรู้<Nobr>คุณค่าของเงิน</Nobr> วางแผนการใช้เงิน
            และฝึก<Nobr>ใช้เหตุผล</Nobr>
            โดยใช้<Nobr>ภาษาอังกฤษ</Nobr>ระหว่างเล่น
          </>
        ),
        ledBy: "นำกิจกรรมโดย อังเคิลลี",
        imgAlt:
          "ภาพประกอบตัดกระดาษ เด็กสามคนนั่งเล่นบอร์ดเกมการเงิน นับเหรียญและธนบัตรของเล่น และหยอดเหรียญลงกระปุกออมสินหมู",
      },
    ],
    skillsTitle: "ทักษะ 4C ที่ติดตัวลูกไป",
    skills: [
      { en: "Creativity", th: "ความคิดสร้างสรรค์" },
      { en: "Critical Thinking", th: "การคิดวิเคราะห์" },
      { en: "Communication", th: "การสื่อสาร" },
      { en: "Collaboration", th: "การทำงานร่วมกัน" },
    ],
  },
  quote: {
    label: "แนวคิดเรื่องสำเนียง",
    text: (
      <>
        “สำเนียงภาษาแม่ไม่ใช่<Nobr>ข้อบกพร่อง</Nobr> แต่เป็นหลักฐานว่าลูกพูดได้
        <Nobr>อย่างน้อยสองภาษา</Nobr>”
      </>
    ),
    source: "CherryLee & Co.",
    caption: (
      <>
        คนที่พูด<Nobr>ภาษาอังกฤษ</Nobr>ทั่วโลกส่วนใหญ่ไม่ใช่<Nobr>เจ้าของภาษา</Nobr>{" "}
        สิ่งที่ทำให้คุยกันรู้เรื่องคือพูดชัดและ
        <Nobr>กล้าพูด</Nobr> สำเนียงไทยของลูกจึงไม่ใช่เรื่องที่ต้อง<Nobr>ลบทิ้ง</Nobr>
      </>
    ),
  },
  pricing: {
    eyebrow: "รายละเอียดและค่าเรียน",
    title: "เลือกแพ็กเกจที่เหมาะกับครอบครัว",
    details: [
      { title: "อายุ 6–12 ปี", body: "รับกลุ่มเล็ก ดูแลทั่วถึง" },
      { title: "ทุกเสาร์และอาทิตย์", body: "มาวันไหนก็ได้ตามสะดวก" },
      { title: "09:00–15:00 น.", body: "เรียนเต็มอิ่ม 6 ชั่วโมงต่อครั้ง" },
      { title: "ซอยนวมินทร์ 117", body: "บรรยากาศบ้านที่อบอุ่น" },
    ],
    plans: [
      {
        name: "1 ครั้ง",
        sub: "มาลองสัมผัสบรรยากาศก่อน",
        note: "ต่อครั้ง",
        lineMessage: "สวัสดีครับ/ค่ะ สนใจ Witty English Weekends แบบ 1 ครั้ง ขอดูวันที่ว่างหน่อย",
      },
      {
        name: "4 ครั้ง",
        sub: "มาเรียนต่อเนื่อง 4 ครั้ง",
        note: `เฉลี่ย ${formatBaht(PRICES.four / 4)} ต่อครั้ง\u00a0· ประหยัด ${formatBaht(PRICES.single * 4 - PRICES.four)}`,
        lineMessage:
          "สวัสดีครับ/ค่ะ สนใจ Witty English Weekends แพ็กเกจ 4 ครั้ง ขอดูวันที่ว่างหน่อย",
      },
      {
        name: "8 ครั้ง",
        sub: "เรียนต่อเนื่อง 8 ครั้ง ค่อยๆ สร้างความมั่นใจ",
        note: `เฉลี่ย ${formatBaht(PRICES.eight / 8)} ต่อครั้ง\u00a0· ประหยัด ${formatBaht(PRICES.single * 8 - PRICES.eight)}`,
        badge: "คุ้มที่สุด",
        lineMessage:
          "สวัสดีครับ/ค่ะ สนใจ Witty English Weekends แพ็กเกจ 8 ครั้ง ขอดูวันที่ว่างหน่อย",
      },
    ],
    book: "จองทาง LINE",
    includedTitle: "ทุกแพ็กเกจรวมแล้ว",
    included: ["อุปกรณ์ทำกิจกรรม", "อุปกรณ์ละคร", "วัตถุดิบคลาสทำอาหาร", "ครูไทยและครูเจ้าของภาษา"],
    finePrint:
      "ราคา ณ ตุลาคม 2569 ทักถามตารางเรียนและที่\u2060นั่ง\u2060ว่างล่าสุดทาง LINE ได้เลยค่ะ",
  },
  faq: {
    eyebrow: "คำถามที่พบบ่อย",
    title: (
      <>
        คุณพ่อคุณแม่และ<Nobr>ผู้ปกครอง</Nobr>มักถามเราว่า…
      </>
    ),
    items: [
      {
        q: (
          <>
            ลูกขี้อาย ไม่ค่อยกล้าพูด<Nobr>ภาษาอังกฤษ</Nobr> เหมาะไหม?
          </>
        ),
        a: "เหมาะค่ะ ครูเชอร์รี่คอยดูว่าเด็กแต่ละคนรู้สึกอย่างไร อธิบายเป็นภาษาไทยเมื่อติด และใช้เกมละครช่วยให้หายเกร็ง ให้ลูกค่อยๆ กล้าพูดตามจังหวะของตัวเองค่ะ",
      },
      {
        q: "เรียนวันไหน กี่โมง?",
        a: (
          <>
            ทุกวันเสาร์และอาทิตย์ <Nobr>09:00–15:00 น.</Nobr> <Nobr>(6 ชั่วโมง)</Nobr> มาวันไหนก็ได้
            <Nobr>ตามสะดวกค่ะ</Nobr>
          </>
        ),
      },
      {
        q: "ค่าเรียนรวมอะไรบ้าง?",
        a: "รวมอุปกรณ์ทำกิจกรรม อุปกรณ์ละคร และวัตถุดิบคลาสทำอาหารแล้วค่ะ",
      },
      {
        q: (
          <>
            เรียน 6 ชั่วโมง มีพักและ<Nobr>อาหารกลางวัน</Nobr>ไหม?
          </>
        ),
        a: "ทักถามรายละเอียดช่วงพักและอาหารกลางวันของแต่ละรอบทาง LINE ได้เลยค่ะ",
      },
      {
        q: "กลุ่มใหญ่แค่ไหน?",
        a: (
          <>
            เรารับเป็นกลุ่มเล็กค่ะ ครูทั้งสองคนจะได้<Nobr>ดูแล</Nobr>เด็กๆ ได้ทั่วถึง สอบถาม
            <Nobr>ที่นั่งว่าง</Nobr>ของแต่ละวันได้ทาง LINE ค่ะ
          </>
        ),
      },
      {
        q: "จองที่นั่งอย่างไร?",
        a: (
          <>
            ทักมาที่ LINE OA <strong>{LINE_ID}</strong> (มี @ ด้วยนะคะ) หรือส่งข้อความทางเพจ
            Facebook <Nobr>ได้เลยค่ะ</Nobr>
          </>
        ),
      },
    ],
  },
  visit: {
    eyebrow: "มาเยี่ยมเรา",
    title: (
      <>
        <Nobr>บ้านแห่งการเรียนรู้</Nobr> <Nobr>ย่านนวมินทร์</Nobr>
      </>
    ),
    nameSuffix: "(เชอร์รี่ลีแอนด์โค)",
    address: "ซอยนวมินทร์ 117 กรุงเทพมหานคร",
    hours: "คลาสวันเสาร์และอาทิตย์ 09:00–15:00 น.",
    directions: "นำทางด้วย Google Maps",
    openPin: "เปิดหมุดในแผนที่",
    mapTitle: "แผนที่ CherryLee & Co. ซอยนวมินทร์ 117 กรุงเทพฯ",
  },
  cta: {
    title: "พาลูกมาเรียนกับเราสักวันไหมคะ",
    body: "ทักมาคุยกับเราได้เลย เราช่วยดูตารางเรียนและที่\u2060นั่ง\u2060ว่างให้ค่ะ",
    line: `แอดไลน์ ${LINE_ID}`,
    messenger: "ทักทาง Messenger",
  },
  footer: {
    tagline: "เรียนรู้ทักษะชีวิตสำหรับเด็กและครอบครัว ผ่านกระบวนการละคร",
    navLabel: "ลิงก์ส่วนท้าย",
    follow: "ติดตามเรา",
    email: "อีเมล",
    credit: "ภาพประกอบสร้างด้วย Canva",
  },
  sticky: "จองที่นั่งทาง LINE",
};

const en: SiteContent = {
  meta: {
    title: "Weekend English through drama for kids 6–12, Bangkok | CherryLee & Co.",
    description:
      "Witty English Weekends for kids aged 6–12: confident, mistake-friendly English through story drama, cooking and money board games with Kru Cherry and Uncle Lee. Every Saturday and Sunday at Soi Nawamin 117, Bangkok.",
  },
  skipLink: "Skip to main content",
  newTab: " (opens in a new tab)",
  langChanged: "Page switched to English",
  brand: { homeLabel: "CherryLee & Co. home", topLabel: "CherryLee & Co. back to top" },
  nav: {
    label: "Main menu",
    items: [
      { href: "#approach", label: "Our approach" },
      { href: "#programs", label: "Activities" },
      { href: "#pricing", label: "Pricing" },
      { href: "#faq", label: "FAQ" },
      { href: "#visit", label: "Location" },
    ],
    cta: "Book a seat",
    menuOpen: "Open menu",
    menuClose: "Close menu",
    langGroup: "เลือกภาษา / Choose language",
  },
  hero: {
    script: "Life Skills Learning for Kids and Families",
    title: (
      <>
        English that starts with <Hl>courage</Hl>, not fear
      </>
    ),
    lead: (
      <>
        <strong className="text-ink">Witty English Weekends</strong> gives kids aged 6–12 a place to
        use English through story drama, cooking and money board games, guided by a Thai drama
        educator and a native English speaker in a warm, home-like studio. Mistakes are welcome
        here.
      </>
    ),
    ctaPrimary: "Book via LINE",
    ctaSecondary: "See the activities",
    teachers: (
      <>
        Taught by <TeacherLink>Kru Cherry</TeacherLink>, a drama educator with 20+ years’
        experience, and <TeacherLink>Uncle Lee</TeacherLink>, a former chef from Canada
      </>
    ),
    factsLabel: "Class at a glance",
    facts: ["Ages 6–12", "Sat or Sun, 9am–3pm", "Small groups", "Soi Nawamin 117"],
    artAlt:
      "Paper-cutout illustration: two children in crane and heron masks act out a story while a third reads from a picture book, surrounded by colourful flowers and leaves",
    caption: (
      <>
        <em>The Crane &amp; the Heron</em> in a Story Playlit class
      </>
    ),
  },
  why: {
    eyebrow: "When kids go quiet",
    title:
      "Years of English lessons, but your child goes quiet when someone speaks English to them?",
    lead: (
      <>
        Silence doesn’t always mean a child doesn’t know. Often they just don’t feel safe yet.
        Linguist Stephen Krashen’s <strong>Affective Filter</strong> hypothesis describes this: when
        a learner feels anxious, new language has a harder time getting in.
      </>
    ),
    cards: [
      {
        title: "Too much, too fast",
        body: "When the language around them moves faster than they can follow, many kids go quiet to feel safe.",
      },
      {
        title: "Worried about mistakes",
        body: "If it feels like someone is grading every accent and grammar slip, staying silent feels safer.",
      },
      {
        title: "No one to explain",
        body: "When they get stuck and no one can explain in Thai, kids don’t know how to carry on, so they wait in silence.",
      },
    ],
    punch: (
      <>
        What helps is <Hl>a teacher who can explain in Thai</Hl> the moment your child gets stuck.
      </>
    ),
  },
  approach: {
    eyebrow: "Team teaching",
    title: "A Thai teacher and a native English speaker, teaching side by side",
    lead: (
      <>
        CherryLee &amp; Co. was founded by Kru Cherry and Uncle Lee. We believe children aged 6–12
        learn language best when they feel safe, so Kru Cherry looks after feelings and explains in
        Thai, while Uncle Lee gets kids using English through hands-on activities.
      </>
    ),
    cherry: {
      role: "Thai teacher · the safe zone",
      name: "Kru Cherry",
      fullName: "ญาณี เหล่าวิริยะรัตน์ ลาฟฟึ่น",
      photoAlt:
        "Kru Cherry, with rainbow-coloured hair and glasses, smiling with arms crossed in a white CherryLee & Co. T-shirt",
      points: [
        "Drama educator with 20+ years of teaching",
        "Reads body language and understands child psychology",
        "Gently explains tricky moments in Thai",
        "Uses creative drama to ease nerves",
      ],
    },
    lee: {
      role: "Native English speaker · real English, no pressure",
      name: "Uncle Lee",
      fullName: "Lee Laffan",
      photoAlt: "Uncle Lee smiling warmly in a pink CherryLee & Co. T-shirt",
      points: [
        "Former professional chef from Canada",
        "Creator of the Money Wise curriculum",
        "Gets kids using English by doing",
        "Never nitpicks accents, never judges",
      ],
    },
    principles: [
      { title: "Psychological Safety", body: "A space where kids know nobody laughs at mistakes." },
      {
        title: "Hands-on Learning",
        body: "Using English with flour on their hands, while playing a shop game, or in character.",
      },
      {
        title: "Accent Is Identity",
        body: "Speaking clearly and confidently matters more than sounding like someone else.",
      },
    ],
  },
  programs: {
    eyebrow: "Witty English Weekends",
    title: "Three signature activities kids love",
    lead: "Kids use English while they act, cook and play, instead of memorising word lists. Each session runs six hours.",
    items: [
      {
        key: "story",
        kicker: "Creative drama from English stories",
        title: "Story Playlit",
        body: "Kids step into characters from English picture books and act the story out together, using their imagination and speaking English as they play.",
        ledBy: "Led by Kru Cherry",
        imgAlt:
          "Paper-cutout illustration of two children dressed as a tiger and a rabbit performing on a small stage for an audience of plush toys",
        stories: {
          label: "Stories we’ve played:",
          list: "The Crane & the Heron · Gracie Grabbit & the Tiger",
        },
      },
      {
        key: "cooking",
        kicker: "Little chefs in the kitchen",
        title: "Basic Cooking",
        body: "Cook a real dish with Uncle Lee, a former chef. Kids touch, smell and taste as they go, picking up kitchen words and recipe steps along the way.",
        ledBy: "Led by Uncle Lee",
        imgAlt:
          "Paper-cutout illustration of two little chefs in chef hats kneading dough and decorating cookies at a wooden table",
      },
      {
        key: "money",
        kicker: "Money skills for kids",
        title: "Money Wise",
        body: "Board games and buy-and-sell simulations where kids learn what money is worth, plan their spending and practise reasoning, using English as they play.",
        ledBy: "Led by Uncle Lee",
        imgAlt:
          "Paper-cutout illustration of three children playing a money board game, counting play coins and notes and dropping a coin into a piggy bank",
      },
    ],
    skillsTitle: "The 4Cs your child takes home",
    skills: [
      { en: "Creativity" },
      { en: "Critical Thinking" },
      { en: "Communication" },
      { en: "Collaboration" },
    ],
  },
  quote: {
    label: "Our view on accents",
    text: "“A mother-tongue accent isn’t a flaw. It’s proof your child speaks at least two languages.”",
    source: "CherryLee & Co.",
    caption:
      "Most people who speak English around the world aren’t native speakers. What makes conversation work is speaking clearly and with confidence, so there’s no need to erase your child’s Thai accent.",
  },
  pricing: {
    eyebrow: "Details & pricing",
    title: "Pick the package that fits your family",
    details: [
      { title: "Ages 6–12", body: "Small groups, close care" },
      { title: "Every Saturday and Sunday", body: "Come on whichever day suits you" },
      { title: "9am–3pm", body: "Six full hours per session" },
      { title: "Soi Nawamin 117", body: "A warm, home-like studio" },
    ],
    plans: [
      {
        name: "1 session",
        sub: "Come and try a day",
        note: "per session",
        lineMessage:
          "Hi! I'm interested in Witty English Weekends (1 session). Could you share available dates?",
      },
      {
        name: "4 sessions",
        sub: "A steady weekend rhythm",
        note: `Avg. ${formatBaht(PRICES.four / 4)} per session\u00a0· save ${formatBaht(PRICES.single * 4 - PRICES.four)}`,
        lineMessage:
          "Hi! I'm interested in the Witty English Weekends 4-session package. Could you share available dates?",
      },
      {
        name: "8 sessions",
        sub: "8 sessions to build confidence step by step",
        note: `Avg. ${formatBaht(PRICES.eight / 8)} per session\u00a0· save ${formatBaht(PRICES.single * 8 - PRICES.eight)}`,
        badge: "Best value",
        lineMessage:
          "Hi! I'm interested in the Witty English Weekends 8-session package. Could you share available dates?",
      },
    ],
    book: "Book via LINE",
    includedTitle: "Every package includes",
    included: [
      "Activity materials",
      "Drama props",
      "Cooking ingredients",
      "A Thai teacher and a native English speaker",
    ],
    finePrint:
      "Prices as of October 2026. Message us on LINE for the latest schedule and open seats.",
  },
  faq: {
    eyebrow: "FAQ",
    title: "Parents often ask us…",
    items: [
      {
        q: "My child is shy about speaking English. Is this a good fit?",
        a: "Yes. Kru Cherry watches how each child is feeling, explains in Thai when they get stuck, and uses drama games to ease nerves, so children find their voice at their own pace.",
      },
      {
        q: "When are classes?",
        a: "Every Saturday and Sunday, 9am–3pm (six hours). Come on whichever day suits your family.",
      },
      {
        q: "What does the price include?",
        a: "Activity materials, drama props and cooking ingredients are all included.",
      },
      {
        q: "Is there a lunch break in the six hours?",
        a: "Message us on LINE and we’ll share the break and lunch details for your date.",
      },
      {
        q: "How big are the groups?",
        a: "We keep groups small so both teachers can give every child close attention. Ask on LINE about open seats for each date.",
      },
      {
        q: "How do I book?",
        a: (
          <>
            Message our LINE Official Account <strong>{LINE_ID}</strong> (don’t forget the @), or
            send us a message on Facebook.
          </>
        ),
      },
    ],
  },
  visit: {
    eyebrow: "Come visit",
    title: "Our home-like studio in Nawamin",
    address: "Soi Nawamin 117, Bangkok, Thailand",
    hours: "Weekend classes, 9am–3pm",
    directions: "Get directions",
    openPin: "Open the map pin",
    mapTitle: "Map of CherryLee & Co., Soi Nawamin 117, Bangkok",
  },
  cta: {
    title: "Come and spend a Saturday or Sunday with us",
    body: "Say hello. We’ll help you find a date and check open seats.",
    line: `Add LINE ${LINE_ID}`,
    messenger: "Message on Messenger",
  },
  footer: {
    tagline: "Life skills learning for kids and families, through drama.",
    navLabel: "Footer links",
    follow: "Follow us",
    email: "Email",
    credit: "Illustrations made with Canva",
  },
  sticky: "Book via LINE",
};

export const content: Record<Lang, SiteContent> = { th, en };
