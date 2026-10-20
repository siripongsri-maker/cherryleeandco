import { describe, expect, it } from "vitest";
import { canGenerateClass, classDetailsSchema, draftSchema, emptyClass } from "@/lib/class-descriptions";

describe("Teacher class drafting", () => {
  it("denies accounts without a teacher role", () => { expect(canGenerateClass([])).toBe(false); expect(canGenerateClass(["user"])).toBe(false); });
  it.each(["teacher", "admin", "super_admin"])("allows %s", role => { expect(canGenerateClass([role])).toBe(true); });
  it("requires class details before generation", () => { expect(classDetailsSchema.safeParse(emptyClass).success).toBe(false); });
  it("allows omitted optional facts without creating defaults", () => { const value = classDetailsSchema.parse({ ...emptyClass, name: "ละครนิทาน", activities: "เล่าเรื่องและแสดงละคร" }); expect(value.price).toBe(""); expect(value.schedule).toBe(""); });
  it("requires both Thai and English output", () => { expect(draftSchema.safeParse({ th: "คำอธิบาย" }).success).toBe(false); expect(draftSchema.safeParse({ th: "คำอธิบาย", en: "Description" }).success).toBe(true); });
});