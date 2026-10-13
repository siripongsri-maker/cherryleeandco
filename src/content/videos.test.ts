import { existsSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";

import { CLASS_VIDEOS, VIDEOS, canShow, formatPosted, type Video } from "./videos";

const all: Video[] = Object.values(VIDEOS);

describe("videos", () => {
  it("never shows a clip with children unless consent is recorded", () => {
    for (const video of all) {
      expect(canShow(video)).toBe(!video.showsChildren || video.consent !== undefined);
    }
    for (const video of CLASS_VIDEOS) {
      expect(!video.showsChildren || video.consent !== undefined).toBe(true);
    }
  });

  it("hides a clip with children when consent is missing", () => {
    const { consent: _consent, ...withoutConsent } = VIDEOS.fruitStand;
    expect(canShow(withoutConsent)).toBe(false);
  });

  it("has a poster for every clip", () => {
    for (const video of all) {
      const sizes =
        video.shape === "vertical"
          ? ["360.webp", "540.webp", "540.jpg"]
          : ["640.webp", "960.webp", "960.jpg"];
      for (const size of sizes) {
        const file = path.resolve("public/images/videos", `${video.poster}-${size}`);
        expect(existsSync(file), file).toBe(true);
      }
    }
  });

  it("uses YouTube video ids and m:ss durations", () => {
    for (const video of all) {
      expect(video.id).toMatch(/^[\w-]{11}$/);
      expect(video.duration).toMatch(/^\d+:\d{2}$/);
      expect(video.posted).toMatch(/^\d{4}-(0[1-9]|1[0-2])$/);
    }
  });

  it("formats the posted month in Thai (Buddhist year) and English", () => {
    expect(formatPosted("2026-08", "th")).toBe("ส.ค. 2569");
    expect(formatPosted("2026-08", "en")).toBe("Aug 2026");
  });
});
