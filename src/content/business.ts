// Facts and links — the single place to update contact details, prices and the map pin.
// Source: facebook.com/cherryleeandco (checked 13 October 2026).

export const LINE_ID = "@cherryleeandco";
export const LINE_URL = "https://line.me/R/ti/p/@cherryleeandco";
/** Opens a chat with the LINE Official Account with `text` already typed (LINE URL scheme). */
export const lineMessageUrl = (text: string) =>
  `https://line.me/R/oaMessage/%40cherryleeandco/?${encodeURIComponent(text)}`;
export const MESSENGER_URL = "https://m.me/cherryleeandco";
export const FACEBOOK_URL = "https://www.facebook.com/cherryleeandco";
export const EMAIL = "cherryleeandco@gmail.com";

// Channels listed in the studio's YouTube video descriptions (checked 13 October 2026).
// The YouTube handle is "@cherryleeandco." with a full stop, so link by channel id instead.
export const YOUTUBE_URL = "https://www.youtube.com/channel/UC0uGoq-JR18GX-ari735WuA";
export const INSTAGRAM_URL = "https://www.instagram.com/cherryleeandco";
export const TIKTOK_URL = "https://www.tiktok.com/@cherryleeandco";
/** Kru Cherry's Thai series on creative drama ("เปิดโลกละครสร้างสรรค์") */
export const CREATIVE_DRAMA_PLAYLIST_URL =
  "https://www.youtube.com/playlist?list=PLDN5_6XhvsKfwJp__3VUtNJIdb9LfTGI0";

export const MAP = {
  lat: 13.8134544,
  lng: 100.6506617,
  pinUrl: "https://maps.app.goo.gl/hQBAwFrh35s3TJSZ9",
  directionsUrl: "https://www.google.com/maps/dir/?api=1&destination=13.8134544,100.6506617",
  embedUrl: (lang: string) =>
    `https://www.google.com/maps?q=13.8134544,100.6506617&z=16&hl=${lang}&output=embed`,
};

export const PRICES = {
  single: 3900,
  four: 14400,
  eight: 26400,
} as const;

export const formatBaht = (n: number) => `฿${n.toLocaleString("en-US")}`;

/** schema.org data for search engines (rendered in <head> by src/routes/__root.tsx). Make image URLs absolute once the domain is known. */
export const BUSINESS_JSON_LD = {
  "@context": "https://schema.org",
  "@type": ["LocalBusiness", "EducationalOrganization"],
  name: "CherryLee & Co.",
  alternateName: "เชอร์รี่ลีแอนด์โค",
  description:
    "พื้นที่การเรียนรู้ทักษะชีวิตสำหรับเด็กและครอบครัวผ่านกระบวนการละคร ก่อตั้งโดยครูเชอร์รี่ ญาณี และอังเคิลลี ลาฟฟึ่น",
  image: "/images/og-image.jpg",
  logo: "/images/icon-512.png",
  email: EMAIL,
  priceRange: "฿฿",
  address: {
    "@type": "PostalAddress",
    streetAddress: "ซอยนวมินทร์ 117",
    addressLocality: "กรุงเทพมหานคร",
    addressCountry: "TH",
  },
  geo: { "@type": "GeoCoordinates", latitude: MAP.lat, longitude: MAP.lng },
  hasMap: MAP.pinUrl,
  openingHoursSpecification: [
    {
      "@type": "OpeningHoursSpecification",
      dayOfWeek: ["Saturday", "Sunday"],
      opens: "09:00",
      closes: "15:00",
    },
  ],
  founder: [
    {
      "@type": "Person",
      name: "ญาณี เหล่าวิริยะรัตน์ ลาฟฟึ่น",
      alternateName: "Kru Cherry",
      jobTitle: "Drama Educator",
      image: "/images/kru-cherry-800.jpg",
    },
    {
      "@type": "Person",
      name: "Lee Laffan",
      alternateName: "Uncle Lee",
      jobTitle: "Native English teacher, former chef",
      image: "/images/uncle-lee-800.jpg",
    },
  ],
  sameAs: [FACEBOOK_URL, YOUTUBE_URL, INSTAGRAM_URL, TIKTOK_URL, "https://mez.ink/cherryleeandco"],
  makesOffer: [
    {
      "@type": "Offer",
      name: "Witty English Weekends, 1 session",
      price: String(PRICES.single),
      priceCurrency: "THB",
    },
    {
      "@type": "Offer",
      name: "Witty English Weekends, 4 sessions",
      price: String(PRICES.four),
      priceCurrency: "THB",
    },
    {
      "@type": "Offer",
      name: "Witty English Weekends, 8 sessions",
      price: String(PRICES.eight),
      priceCurrency: "THB",
    },
  ],
};
