import { z } from "zod";
import { BUSINESS_JSON_LD, CREATIVE_DRAMA_PLAYLIST_URL, EMAIL, FACEBOOK_URL, INSTAGRAM_URL, LINE_ID, MAP, MESSENGER_URL, PRICES, TIKTOK_URL, YOUTUBE_URL, formatBaht } from "@/content/business";
import { VIDEOS, type Video } from "@/content/videos";
import type { Lang, SiteContent } from "@/content/site";

const channelUrl = (hosts: string[]) => z.string().url().max(1000).refine(value => {
  const url = new URL(value);
  return url.protocol === "https:" && !url.username && !url.password && hosts.includes(url.hostname);
}, "Invalid channel URL");
export const websiteSettingsSchema = z.object({
  lineId: z.string().regex(/^@[A-Za-z0-9._-]{1,80}$/).optional(),
  email: z.string().email().max(254).optional(),
  messenger: channelUrl(["m.me", "www.messenger.com"]).optional(),
  facebook: channelUrl(["facebook.com", "www.facebook.com"]).optional(),
  youtube: channelUrl(["youtube.com", "www.youtube.com"]).optional(),
  instagram: channelUrl(["instagram.com", "www.instagram.com"]).optional(),
  tiktok: channelUrl(["tiktok.com", "www.tiktok.com"]).optional(),
  playlist: channelUrl(["youtube.com", "www.youtube.com"]).optional(),
  mapPin: channelUrl(["maps.app.goo.gl", "www.google.com", "maps.google.com", "goo.gl"]).optional(),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  single: z.number().int().min(0).max(1000000).optional(),
  four: z.number().int().min(0).max(1000000).optional(),
  eight: z.number().int().min(0).max(1000000).optional(),
  opens: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
  closes: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
  days: z.array(z.enum(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])).min(1).max(7).refine(days => new Set(days).size === days.length).optional(),
  hiddenVideos: z.array(z.string()).max(6).refine(keys => keys.every(key => Object.hasOwn(VIDEOS, key))).optional(),
  videoTitles: z.record(z.string(), z.object({ th: z.string().trim().min(1).max(300), en: z.string().trim().min(1).max(300) }).strict()).refine(value => Object.keys(value).every(key => Object.hasOwn(VIDEOS, key))).optional(),
}).strict();
export type WebsiteSettings = z.infer<typeof websiteSettingsSchema>;
export const businessDefaults = { lineId: LINE_ID, email: EMAIL, messenger: MESSENGER_URL, facebook: FACEBOOK_URL, youtube: YOUTUBE_URL, instagram: INSTAGRAM_URL, tiktok: TIKTOK_URL, playlist: CREATIVE_DRAMA_PLAYLIST_URL, mapPin: MAP.pinUrl, lat: MAP.lat, lng: MAP.lng, ...PRICES, opens: "09:00", closes: "15:00", days: ["Saturday", "Sunday"] as NonNullable<WebsiteSettings["days"]> };
export function resolveBusiness(settings: WebsiteSettings = {}) {
  const values = { ...businessDefaults, ...settings };
  return { ...values,
    lineUrl: `https://line.me/R/ti/p/${values.lineId}`,
    lineMessageUrl: (text: string) => `https://line.me/R/oaMessage/${encodeURIComponent(values.lineId)}/?${encodeURIComponent(text)}`,
    directionsUrl: `https://www.google.com/maps/dir/?api=1&destination=${values.lat},${values.lng}`,
    embedUrl: (lang: string) => `https://www.google.com/maps?q=${values.lat},${values.lng}&z=16&hl=${lang}&output=embed`,
  };
}
const thaiDays: Record<string,string> = { Monday: "จันทร์", Tuesday: "อังคาร", Wednesday: "พุธ", Thursday: "พฤหัสบดี", Friday: "ศุกร์", Saturday: "เสาร์", Sunday: "อาทิตย์" };
export function applyBusinessCopy(base: SiteContent, lang: Lang, settings: WebsiteSettings, overridden: string[]): SiteContent {
  const b = resolveBusiness(settings);
  const result = { ...base, cta: { ...base.cta }, pricing: { ...base.pricing, plans: base.pricing.plans.map(plan => ({ ...plan })) as SiteContent["pricing"]["plans"] }, visit: { ...base.visit } };
  if (settings.lineId && !overridden.includes("cta.line")) result.cta.line = lang === "th" ? `แอดไลน์ ${b.lineId}` : `Add LINE ${b.lineId}`;
  if (settings.single !== undefined || settings.four !== undefined || settings.eight !== undefined) {
    [1,2].forEach(index => {
      if (overridden.includes(`pricing.plans.${index}.note`)) return;
      const count = index === 1 ? 4 : 8; const price = index === 1 ? b.four : b.eight;
      const saving = b.single * count - price;
      const average = lang === "th" ? `เฉลี่ย ${formatBaht(price/count)} ต่อครั้ง` : `Avg. ${formatBaht(price/count)} per session`;
      result.pricing.plans[index].note = saving > 0 ? `${average} · ${lang === "th" ? "ประหยัด" : "save"} ${formatBaht(saving)}` : average;
    });
  }
  if ((settings.days || settings.opens || settings.closes) && !overridden.includes("visit.hours")) result.visit.hours = `${lang === "th" ? b.days.map(day => thaiDays[day]).join(" / ") : b.days.join(" / ")} ${b.opens}–${b.closes}${lang === "th" ? " น." : ""}`;
  return result;
}
export function resolveVideos(settings: WebsiteSettings = {}) {
  return Object.fromEntries(Object.entries(VIDEOS).map(([key, video]) => [key, { ...video, title: settings.videoTitles?.[key] ?? video.title }])) as Record<keyof typeof VIDEOS, Video>;
}
export function websiteJsonLd(settings: WebsiteSettings, t: SiteContent, images: Record<string,string>) {
  const b = resolveBusiness(settings);
  return { ...BUSINESS_JSON_LD, description: t.meta.description, email: b.email,
    address: { ...BUSINESS_JSON_LD.address, streetAddress: t.visit.address },
    geo: { "@type": "GeoCoordinates", latitude: b.lat, longitude: b.lng }, hasMap: b.mapPin,
    openingHoursSpecification: [{ "@type": "OpeningHoursSpecification", dayOfWeek: b.days, opens: b.opens, closes: b.closes }],
    sameAs: [b.facebook,b.youtube,b.instagram,b.tiktok],
    founder: BUSINESS_JSON_LD.founder.map((person,index) => { const teacher = index === 0 ? t.approach.cherry : t.approach.lee; return { ...person, name: teacher.fullName, jobTitle: teacher.role, image: images[index === 0 ? "kru-cherry" : "uncle-lee"] ?? person.image }; }),
    makesOffer: BUSINESS_JSON_LD.makesOffer.map((offer,index) => ({ ...offer, price: String([b.single,b.four,b.eight][index]) })),
  };
}