import { describe, expect, it } from "vitest";
import { content } from "@/content/site";
import { applyHomepage, homepageSchema, homepageSaveSchema, emptyHomepage, defaultText, validHomepageImage } from "@/lib/homepage-content";

describe("Homepage editor rules", () => {
  it("requires an explicit image permission decision when saving", () => { expect(homepageSaveSchema.safeParse(emptyHomepage).success).toBe(false); expect(homepageSaveSchema.safeParse({ ...emptyHomepage, imagePermissionConfirmed: true }).success).toBe(true); });
  it("requires paired Thai and English edits", () => { expect(homepageSchema.safeParse({ ...emptyHomepage, texts: { "hero.title": { th: "ใหม่", en: "" } } }).success).toBe(false); });
  it("rejects paths outside the homepage allowlist", () => { expect(homepageSchema.safeParse({ ...emptyHomepage, texts: { "__proto__": { th: "ใหม่", en: "New" }, "meta.title": { th: "ใหม่", en: "New" } } }).success).toBe(false); });
  it("applies both languages without changing defaults", () => { const texts = { "hero.title": { th: "ข้อความใหม่", en: "New title" } }; expect(applyHomepage(content.th,"th",texts).hero.title).toBe("ข้อความใหม่"); expect(applyHomepage(content.en,"en",texts).hero.title).toBe("New title"); expect(content.th.hero.title).not.toBe("ข้อความใหม่"); expect(applyHomepage(content.th,"th",{}).hero.title).toBe(content.th.hero.title); });
  it("extracts existing text without HTML", () => { expect(defaultText("hero.title","th")).toContain("ภาษาอังกฤษ"); expect(defaultText("hero.title","th")).not.toContain("<span"); });
  it("accepts only known image slots and storage paths", () => { expect(homepageSchema.safeParse({ ...emptyHomepage, images: { hero: "https://example.com/image.jpg" } }).success).toBe(false); expect(homepageSchema.safeParse({ ...emptyHomepage, images: { hero: "12345678-1234-1234-1234-123456789012.jpg" } }).success).toBe(true); });
  it("limits uploads to 5 MB and JPG PNG WebP", () => { expect(validHomepageImage({ type: "image/jpeg", size: 5*1024*1024 })).toBe(true); expect(validHomepageImage({ type: "image/jpeg", size: 5*1024*1024+1 })).toBe(false); expect(validHomepageImage({ type: "image/svg+xml", size: 100 })).toBe(false); });
});