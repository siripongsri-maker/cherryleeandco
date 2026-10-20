export const settingFields = [
  { key: "lineId", label: "LINE Official Account", type: "text" },
  { key: "email", label: "อีเมลติดต่อ", type: "email" },
  { key: "messenger", label: "ลิงก์ Messenger", type: "url" },
  { key: "facebook", label: "ลิงก์ Facebook", type: "url" },
  { key: "youtube", label: "ลิงก์ช่อง YouTube", type: "url" },
  { key: "instagram", label: "ลิงก์ Instagram", type: "url" },
  { key: "tiktok", label: "ลิงก์ TikTok", type: "url" },
  { key: "playlist", label: "ลิงก์ซีรีส์ละครสร้างสรรค์", type: "url" },
  { key: "mapPin", label: "ลิงก์หมุด Google Maps", type: "url" },
  { key: "lat", label: "ละติจูด", type: "number" },
  { key: "lng", label: "ลองจิจูด", type: "number" },
  { key: "single", label: "ค่าเรียน 1 ครั้ง (บาท)", type: "number" },
  { key: "four", label: "ค่าเรียน 4 ครั้ง (บาท)", type: "number" },
  { key: "eight", label: "ค่าเรียน 8 ครั้ง (บาท)", type: "number" },
  { key: "opens", label: "เวลาเปิด", type: "time" },
  { key: "closes", label: "เวลาปิด", type: "time" },
] as const;
export const dayLabels = { Monday: "จันทร์", Tuesday: "อังคาร", Wednesday: "พุธ", Thursday: "พฤหัสบดี", Friday: "ศุกร์", Saturday: "เสาร์", Sunday: "อาทิตย์" } as const;