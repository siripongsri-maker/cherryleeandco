export const homepageSections = [
  { label: "ส่วนบนของหน้า", paths: ["hero.script", "hero.title", "hero.lead", "hero.ctaPrimary", "hero.ctaSecondary", "hero.teachers", "hero.caption", "hero.artAlt", "hero.facts.0", "hero.facts.1", "hero.facts.2", "hero.facts.3"] },
  { label: "แนวคิดการเรียนรู้", paths: ["why.eyebrow", "why.title", "why.lead", "why.punch", ...[0,1,2].flatMap(i => [`why.cards.${i}.title`, `why.cards.${i}.body`])] },
  { label: "คุณครู", paths: ["approach.eyebrow", "approach.title", "approach.lead", ...["cherry", "lee"].flatMap(id => ["role", "name", "fullName", "photoAlt", ...[0,1,2,3].map(i => `points.${i}`)].map(key => `approach.${id}.${key}`))] },
  { label: "กิจกรรม", paths: ["programs.eyebrow", "programs.title", "programs.lead", ...[0,1,2].flatMap(i => ["kicker", "title", "body", "ledBy", "imgAlt"].map(key => `programs.items.${i}.${key}`))] },
  { label: "คำถามที่พบบ่อย", paths: ["faq.title", ...[0,1,2,3,4,5].flatMap(i => [`faq.items.${i}.q`, `faq.items.${i}.a`])] },
  { label: "ที่ตั้งและการติดต่อ", paths: ["visit.title", "visit.address", "visit.hours", "visit.directions", "cta.title", "cta.body", "footer.tagline"] },
] as const;
export const fieldLabels: Record<string, string> = { script: "ข้อความเกริ่น", title: "หัวข้อ", lead: "คำอธิบาย", body: "รายละเอียด", caption: "คำบรรยาย", artAlt: "คำอธิบายรูป", imgAlt: "คำอธิบายรูป", photoAlt: "คำอธิบายรูป", ctaPrimary: "ปุ่มหลัก", ctaSecondary: "ปุ่มรอง", teachers: "ข้อความแนะนำคุณครู", eyebrow: "ข้อความเหนือหัวข้อ", punch: "ข้อความสรุป", role: "บทบาท", name: "ชื่อ", fullName: "ชื่อเต็ม", kicker: "ชื่อกิจกรรมย่อย", ledBy: "ผู้สอน", q: "คำถาม", a: "คำตอบ", address: "ที่อยู่", hours: "เวลาเปิด", directions: "การเดินทาง", tagline: "ข้อความท้ายหน้า" };
export const imageSlots = [
  { key: "hero", label: "รูปหลัก", fallback: "/images/hero-1100.jpg" },
  { key: "story-playlit", label: "ละครนิทาน", fallback: "/images/story-playlit-800.jpg" },
  { key: "basic-cooking", label: "ทำอาหาร", fallback: "/images/basic-cooking-800.jpg" },
  { key: "money-wise", label: "บอร์ดเกมการเงิน", fallback: "/images/money-wise-800.jpg" },
  { key: "kru-cherry", label: "ครูเชอร์รี่", fallback: "/images/kru-cherry-800.jpg" },
  { key: "uncle-lee", label: "อังเคิลลี", fallback: "/images/uncle-lee-800.jpg" },
] as const;