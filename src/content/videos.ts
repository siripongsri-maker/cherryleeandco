import type { Lang } from "./site";

/**
 * Clips from the studio's YouTube channel that appear on the site, picked by hand.
 *
 * Before adding a clip, watch all of it. A clip that shows children stays hidden until the
 * studio confirms that their parents or guardians agreed to its use on the website — record
 * that in `consent`. Never put children's names in titles, alt text or file names.
 * Posters live in public/images/videos (made from the clip's YouTube thumbnail).
 * Thai titles use U+2060 (word joiner) to keep names and compound words on one line.
 */

export type Spoken = "th" | "en" | "th-en";

export type Video = {
  /** YouTube video id (the part after watch?v=) */
  id: string;
  shape: "vertical" | "wide";
  /** Length as YouTube shows it */
  duration: string;
  /** Month it was posted on YouTube, YYYY-MM (we don't know when it was filmed) */
  posted: string;
  spoken: Spoken;
  showsChildren: boolean;
  /** Required when `showsChildren` is true; without it the clip is not shown */
  consent?: { confirmedOn: string; note: string };
  /** File stem in public/images/videos */
  poster: string;
  title: Record<Lang, string>;
  /** The activity a class clip comes from (matches programs.items[].key in site.tsx) */
  program?: "story" | "cooking" | "money";
};

const PARENT_CONSENT = {
  confirmedOn: "2026-10-13",
  note: "Studio confirmed parents' permission to show this clip on the website",
};

export const VIDEOS = {
  storyPlaylit: {
    id: "qBoaW6tWiJc",
    shape: "vertical",
    duration: "2:25",
    posted: "2026-05",
    spoken: "th",
    showsChildren: true,
    consent: PARENT_CONSENT,
    poster: "story-playlit-class",
    program: "story",
    title: {
      th: "ฟังนิทาน วาดภาพ แล้วลุกขึ้นมาเล่นเป็นตัว\u2060ละคร",
      en: "Listen to a story, draw it, then act it out",
    },
  },
  cookingClass: {
    id: "e-WUF2wlGqY",
    shape: "vertical",
    duration: "3:40",
    posted: "2025-06",
    spoken: "th-en",
    showsChildren: true,
    consent: PARENT_CONSENT,
    poster: "cooking-class",
    program: "cooking",
    title: {
      th: "ชวนลูกเข้าครัวกับอัง\u2060เคิล\u2060ลี",
      en: "In the kitchen with Uncle Lee",
    },
  },
  fruitStand: {
    id: "AvyI6OT88gQ",
    shape: "vertical",
    duration: "1:23",
    posted: "2026-08",
    spoken: "en",
    showsChildren: true,
    consent: PARENT_CONSENT,
    poster: "money-wise-fruit-stand",
    program: "money",
    title: {
      th: "ช้อปปิ้งที่ร้านผลไม้ของอัง\u2060เคิล\u2060ลี",
      en: "Shopping at Uncle Lee’s fruit stand",
    },
  },
  shoppingTrip: {
    id: "9z7-0PwwiI4",
    shape: "vertical",
    duration: "1:16",
    posted: "2026-05",
    spoken: "th",
    showsChildren: true,
    consent: PARENT_CONSENT,
    poster: "money-wise-shopping-trip",
    program: "money",
    title: {
      th: "ออกไปช้อปปิ้งของ\u2060จริงพร้อม\u2060ผู้\u2060ปกครอง",
      en: "A real shopping trip, with parents along",
    },
  },
  founders: {
    id: "-kH75GL_o9A",
    shape: "wide",
    duration: "5:26",
    posted: "2026-01",
    spoken: "en",
    showsChildren: false,
    poster: "founders-conversation",
    title: {
      th: "หากบอกกับตัวเองในวัยเด็กได้ จะบอกอะไร",
      en: "What would you tell your childhood self?",
    },
  },
  threeJars: {
    id: "qAx7z_rhIPo",
    shape: "vertical",
    duration: "1:20",
    posted: "2026-05",
    spoken: "en",
    showsChildren: false,
    poster: "uncle-lee-three-jars",
    title: {
      th: "อัง\u2060เคิล\u2060ลีเล่าเรื่อง “กระปุก 3 ใบ” เก็บ ใช้ แบ่งปัน",
      en: "Uncle Lee on the Three Jars: saving, spending, giving",
    },
  },
} satisfies Record<string, Video>;

/** A clip with children is only shown once consent is recorded. */
export const canShow = (video: Video) => !video.showsChildren || video.consent !== undefined;

/** The class clips, in the same order as the activity cards. */
export const CLASS_VIDEOS: Video[] = [
  VIDEOS.storyPlaylit,
  VIDEOS.cookingClass,
  VIDEOS.fruitStand,
  VIDEOS.shoppingTrip,
].filter(canShow);

const MONTHS: Record<Lang, string[]> = {
  th: [
    "ม.ค.",
    "ก.พ.",
    "มี.ค.",
    "เม.ย.",
    "พ.ค.",
    "มิ.ย.",
    "ก.ค.",
    "ส.ค.",
    "ก.ย.",
    "ต.ค.",
    "พ.ย.",
    "ธ.ค.",
  ],
  en: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
};

/** "2026-08" → "ส.ค. 2569" (Thai Buddhist year) or "Aug 2026" */
export function formatPosted(posted: string, lang: Lang) {
  const [year = 0, month = 1] = posted.split("-").map(Number);
  const name = MONTHS[lang][month - 1] ?? "";
  return `${name} ${lang === "th" ? year + 543 : year}`;
}
