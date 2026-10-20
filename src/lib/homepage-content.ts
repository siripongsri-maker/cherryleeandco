import { isValidElement, type ReactNode } from "react";
import { z } from "zod";
import { content, type Lang, type SiteContent } from "@/content/site";
import { homepageSections, imageSlots } from "@/content/admin/homepage";
import { websiteSettingsSchema } from "./website-settings";

export const editablePaths = homepageSections.flatMap(section => [...section.paths]);
const pairSchema = z.object({ th: z.string().trim().max(6000), en: z.string().trim().max(6000) }).strict();
export const homepageSchema = z.object({
  texts: z.record(z.string(), pairSchema).refine(value => Object.entries(value).every(([key,pair]) => editablePaths.includes(key) && (["th","en"] as const).every(lang => !defaultText(key,lang) || pair[lang].length > 0)), "Unknown or empty text field"),
  images: z.record(z.string(), z.string().regex(/^[a-f0-9-]{36}\.(jpg|png|webp)$/)).refine(value => Object.keys(value).every(key => imageSlots.some(slot => slot.key === key)), "Unknown image slot"),
  version: z.number().int().min(0),
  settings: websiteSettingsSchema.default({}),
}).strict();
export type HomepageData = z.infer<typeof homepageSchema>;
export const homepageSaveSchema = homepageSchema.extend({ imagePermissionConfirmed: z.boolean() });
export const emptyHomepage: HomepageData = { texts: {}, images: {}, settings: {}, version: 0 };
export function readPath(value: unknown, path: string): unknown {
  let current = value;
  for (const key of path.split(".")) {
    if (!current || typeof current !== "object") return undefined;
    current = Reflect.get(current, key);
  }
  return current;
}
export function plainText(value: unknown): string {
  if (typeof value === "string" || typeof value === "number") return String(value);
  if (Array.isArray(value)) return value.map(plainText).join("");
  if (isValidElement<{ children?: ReactNode }>(value)) return plainText(value.props.children);
  return "";
}
export function defaultText(path: string, lang: Lang) { return plainText(readPath(content[lang], path)); }
export function applyHomepage(base: SiteContent, lang: Lang, texts: HomepageData["texts"]): SiteContent {
  // Clone only traversed containers: untouched React elements keep their original markup.
  const result = { ...base };
  for (const path of editablePaths) {
    const value = texts[path]?.[lang];
    if (value === undefined) continue;
    const keys = path.split(".");
    let target: object = result;
    keys.forEach((key, index) => {
      if (index === keys.length - 1) { Reflect.set(target, key, value); return; }
      const child: unknown = Reflect.get(target, key);
      if (!child || typeof child !== "object") return;
      const cloned = Array.isArray(child) ? [...child] : { ...child };
      Reflect.set(target, key, cloned);
      target = cloned;
    });
  }
  return result;
}
export const uploadMimeTypes = ["image/jpeg", "image/png", "image/webp"];
export function validHomepageImage(file: { type: string; size: number }) { return uploadMimeTypes.includes(file.type) && file.size > 0 && file.size <= 5 * 1024 * 1024; }