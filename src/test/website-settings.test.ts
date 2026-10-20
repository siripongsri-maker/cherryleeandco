import { describe, expect, it } from "vitest";
import { content } from "@/content/site";
import { VIDEOS, canShow } from "@/content/videos";
import { isValidElement } from "react";
import { editablePaths, applyHomepage, homepageSchema, emptyHomepage } from "@/lib/homepage-content";
import { applyBusinessCopy, resolveBusiness, resolveVideos, websiteJsonLd, websiteSettingsSchema } from "@/lib/website-settings";

describe("Complete website administration", () => {
  it("covers all existing text leaves while excluding structural URLs and keys", () => {
    function leaves(value: unknown, path = ""): string[] {
      if (typeof value === "string" || isValidElement(value)) return [path];
      if (!value || typeof value !== "object") return [];
      return Object.entries(value).flatMap(([key,child]) => ["key","href"].includes(key) ? [] : leaves(child, path ? `${path}.${key}` : key));
    }
    expect([...new Set([...leaves(content.th),...leaves(content.en)])].filter(path => !editablePaths.includes(path))).toEqual([]);
  });
  it("applies package and team data in both languages", () => {
    const texts = { "pricing.plans.0.name": { th: "แพ็กเกจทดลอง", en: "Trial package" }, "approach.cherry.fullName": { th: "ชื่อครู", en: "Teacher name" } };
    expect(applyHomepage(content.th,"th",texts).approach.cherry.fullName).toBe("ชื่อครู");
    expect(applyHomepage(content.en,"en",texts).pricing.plans[0].name).toBe("Trial package");
  });
  it("preserves the studio's current prices as defaults", () => { const b=resolveBusiness(); expect([b.single,b.four,b.eight]).toEqual([3900,14400,26400]); });
  it("updates public prices, calculated package savings and search offers together", () => {
    const settings={single:4000,four:15000,eight:28000}; const t=applyBusinessCopy(content.en,"en",settings,[]);
    expect(resolveBusiness(settings).four).toBe(15000);
    expect(t.pricing.plans[1].note).toBe("Avg. ฿3,750 per session · save ฿1,000");
    expect(websiteJsonLd(settings,t,{}).makesOffer.map(offer=>offer.price)).toEqual(["4000","15000","28000"]);
  });
  it("uses the same LINE id for general and prefilled booking links", () => { const b=resolveBusiness({lineId:"@studio"}); expect(b.lineUrl).toBe("https://line.me/R/ti/p/@studio"); expect(b.lineMessageUrl("Hi")).toBe("https://line.me/R/oaMessage/%40studio/?Hi"); });
  it("rejects script, external-host and credential-bearing contact destinations", () => {
    for (const facebook of ["javascript:alert(1)","https://facebook.com.evil.example/x","https://user:pass@facebook.com/x"]) expect(websiteSettingsSchema.safeParse({facebook}).success).toBe(false);
    expect(websiteSettingsSchema.safeParse({facebook:"https://www.facebook.com/studio"}).success).toBe(true);
  });
  it("keeps staff privileges outside website settings", () => { expect(websiteSettingsSchema.safeParse({role:"super_admin"}).success).toBe(false); });
  it("updates maps and search coordinates from the same values", () => { const settings={lat:14,lng:101}; expect(resolveBusiness(settings).embedUrl("th")).toContain("q=14,101"); expect(websiteJsonLd(settings,content.th,{}).geo.latitude).toBe(14); });
  it("validates opening times and days", () => { expect(websiteSettingsSchema.safeParse({opens:"25:00"}).success).toBe(false); expect(websiteSettingsSchema.safeParse({days:[]}).success).toBe(false); expect(websiteSettingsSchema.safeParse({days:["Sunday"],opens:"10:00"}).success).toBe(true); });
  it("keeps existing video ids and consent unchanged when editing titles", () => {
    const result=resolveVideos({videoTitles:{storyPlaylit:{th:"ชื่อคลิปใหม่",en:"Updated title"}}});
    expect(result.storyPlaylit.id).toBe(VIDEOS.storyPlaylit.id); expect(result.storyPlaylit.consent).toEqual(VIDEOS.storyPlaylit.consent);
    expect(result.storyPlaylit.title.en).toBe("Updated title"); const withoutConsent = { ...result.storyPlaylit }; delete withoutConsent.consent; expect(canShow(withoutConsent)).toBe(false);
    expect(websiteSettingsSchema.safeParse({videoTitles:{unknown:{th:"คลิป",en:"Clip"}}}).success).toBe(false);
  });
  it("allows restoring optional fields while requiring existing bilingual text", () => {
    expect(homepageSchema.safeParse({...emptyHomepage,texts:{"pricing.plans.0.badge":{th:"",en:""}}}).success).toBe(false);
    expect(homepageSchema.safeParse({...emptyHomepage,texts:{"visit.nameSuffix":{th:"ชื่อเพิ่มเติม",en:""}}}).success).toBe(true);
  });
});