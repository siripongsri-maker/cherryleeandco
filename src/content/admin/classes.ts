export const classCopy = {
  title: "ร่างคำอธิบายคลาส",
  details: "รายละเอียดคลาส",
  generate: "สร้างคำอธิบายสองภาษา",
  generating: "กำลังร่างคำอธิบาย…",
  draft: "ฉบับร่าง",
  fields: [
    { key: "name", label: "ชื่อคลาส", required: true, multiline: false },
    { key: "ages", label: "ช่วงอายุ", required: false, multiline: false },
    { key: "activities", label: "กิจกรรมในคลาส", required: true, multiline: true },
    { key: "goals", label: "สิ่งที่ได้ฝึก", required: false, multiline: true },
    { key: "schedule", label: "วัน เวลา และระยะเวลา", required: false, multiline: false },
    { key: "price", label: "ราคาและสิ่งที่รวม", required: false, multiline: false },
    { key: "location", label: "สถานที่", required: false, multiline: false },
    { key: "notes", label: "รายละเอียดเพิ่มเติม", required: false, multiline: true },
  ],
} as const;