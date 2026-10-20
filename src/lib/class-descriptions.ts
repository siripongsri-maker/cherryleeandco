import { z } from "zod";

const optionalText = z.string().trim().max(1500);
export const classDetailsSchema = z.object({
  name: z.string().trim().min(1).max(200),
  ages: optionalText,
  activities: z.string().trim().min(1).max(3000),
  goals: optionalText,
  schedule: optionalText,
  price: optionalText,
  location: optionalText,
  notes: optionalText,
}).strict();
export type ClassDetails = z.infer<typeof classDetailsSchema>;
export const draftSchema = z.object({ th: z.string().trim().min(1).max(12000), en: z.string().trim().min(1).max(12000) }).strict();
export type ClassDraft = z.infer<typeof draftSchema>;
export const emptyClass: ClassDetails = { name: "", ages: "", activities: "", goals: "", schedule: "", price: "", location: "", notes: "" };
export function canGenerateClass(roles: readonly string[]) {
  return roles.some(role => ["teacher", "admin", "super_admin"].includes(role));
}