import { describe, expect, it } from "vitest";
import { announcementDraftSchema, announcementNotesSchema } from "@/lib/announcements";
import { canGenerateClass } from "@/lib/class-descriptions";

describe("Thai announcement drafting", () => {
  it("requires teacher notes", () => {
    expect(announcementNotesSchema.safeParse({ notes: "   " }).success).toBe(false);
    expect(announcementNotesSchema.parse({ notes: "  ประกาศวันหยุด  " }).notes).toBe("ประกาศวันหยุด");
  });
  it("requires Thai output without requiring English", () => {
    expect(announcementDraftSchema.safeParse({ th: "ประกาศวันหยุด" }).success).toBe(true);
    expect(announcementDraftSchema.safeParse({ en: "Holiday" }).success).toBe(false);
  });
  it("denies non-staff accounts", () => { expect(canGenerateClass([])).toBe(false); expect(canGenerateClass(["user"])).toBe(false); });
  it.each(["teacher", "admin", "super_admin"])("allows %s accounts", role => { expect(canGenerateClass([role])).toBe(true); });
});