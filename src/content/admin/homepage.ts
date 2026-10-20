import { isValidElement } from "react";
import { content } from "@/content/site";

function textPaths(value: unknown, prefix: string): string[] {
  if (typeof value === "string" || isValidElement(value)) return [prefix];
  if (!value || typeof value !== "object") return [];
  return Object.entries(value).flatMap(([key, child]) => ["href", "key"].includes(key) ? [] : textPaths(child, `${prefix}.${key}`));
}
function paths(...keys: string[]) {
  return [...new Set(keys.flatMap(key => ["th", "en"].flatMap(lang => textPaths(Reflect.get(content[lang as "th" | "en"], key), key))))];
}
export const homepageSections = [
  { label: "ส่วนบนของหน้า", paths: paths("hero") },
  { label: "แนวคิดการเรียนรู้", paths: paths("why") },
  { label: "คุณครูและแนวทาง", paths: paths("approach") },
  { label: "กิจกรรมและทักษะ", paths: paths("programs") },
  { label: "ค่าเรียนและแพ็กเกจ", paths: paths("pricing") },
  { label: "วิดีโอ", paths: paths("videos") },
  { label: "ข้อความแนวคิด", paths: paths("quote") },
  { label: "คำถามที่พบบ่อย", paths: paths("faq") },
  { label: "ที่ตั้งและการติดต่อ", paths: paths("visit", "cta") },
  { label: "เมนูและท้ายหน้า", paths: paths("nav", "brand", "footer", "sticky", "skipLink", "newTab", "langChanged") },
  { label: "ข้อมูลสำหรับ Google", paths: paths("meta") },
];
export const fieldLabels: Record<string, string> = { script: "ข้อความเกริ่น", title: "หัวข้อ", lead: "คำอธิบาย", body: "รายละเอียด", caption: "คำบรรยาย", artAlt: "คำอธิบายรูป", imgAlt: "คำอธิบายรูป", photoAlt: "คำอธิบายรูป", ctaPrimary: "ปุ่มหลัก", ctaSecondary: "ปุ่มรอง", teachers: "ข้อความแนะนำคุณครู", eyebrow: "ข้อความเหนือหัวข้อ", punch: "ข้อความสรุป", role: "บทบาท", name: "ชื่อ", fullName: "ชื่อเต็ม", kicker: "ชื่อกิจกรรมย่อย", ledBy: "ผู้สอน", q: "คำถาม", a: "คำตอบ", address: "ที่อยู่", hours: "เวลาเปิด", directions: "การเดินทาง", tagline: "ข้อความท้ายหน้า" };
export const imageSlots = [
  { key: "hero", label: "รูปหลัก", fallback: "/images/hero-1100.jpg" },
  { key: "story-playlit", label: "ละครนิทาน", fallback: "/images/story-playlit-800.jpg" },
  { key: "basic-cooking", label: "ทำอาหาร", fallback: "/images/basic-cooking-800.jpg" },
  { key: "money-wise", label: "บอร์ดเกมการเงิน", fallback: "/images/money-wise-800.jpg" },
  { key: "kru-cherry", label: "ครูเชอร์รี่", fallback: "/images/kru-cherry-800.jpg" },
  { key: "uncle-lee", label: "อังเคิลลี", fallback: "/images/uncle-lee-800.jpg" },
  { key: "logo-mark", label: "สัญลักษณ์โลโก้", fallback: "/images/logo-mark.png" },
  { key: "logo-wordmark", label: "ชื่อโลโก้", fallback: "/images/logo-wordmark.png" },
  { key: "logo-stacked", label: "โลโก้ท้ายหน้า", fallback: "/images/logo-stacked.png" },
  { key: "logo-mark-white", label: "โลโก้บนพื้นสี", fallback: "/images/logo-mark-white.png" },
  ...["story-playlit-class", "cooking-class", "money-wise-fruit-stand", "money-wise-shopping-trip", "founders-conversation", "uncle-lee-three-jars"].map((poster,index) => ({ key: `videos/${poster}`, label: `ภาพปกวิดีโอ ${index+1}`, fallback: `/images/videos/${poster}-480.jpg` })),
] as const;