import type { ImgHTMLAttributes } from "react";

type PictureProps = {
  /** File stem in /public/images, e.g. "story-playlit" → story-playlit-480.webp, story-playlit-800.webp, story-playlit-800.jpg */
  name: string;
  widths: number[];
  /** Width of the JPG fallback (must exist as `${name}-${fallback}.jpg`) */
  fallback: number;
  sizes: string;
  alt: string;
  width: number;
  height: number;
} & Omit<
  ImgHTMLAttributes<HTMLImageElement>,
  "src" | "srcSet" | "sizes" | "alt" | "width" | "height"
>;

/** WebP srcset with a JPG fallback; width/height reserve space so nothing jumps while loading. */
export function Picture({
  name,
  widths,
  fallback,
  sizes,
  alt,
  width,
  height,
  loading = "lazy",
  ...img
}: PictureProps) {
  const srcSet = widths.map((w) => `/images/${name}-${w}.webp ${w}w`).join(", ");
  return (
    <picture>
      <source type="image/webp" srcSet={srcSet} sizes={sizes} />
      <img
        src={`/images/${name}-${fallback}.jpg`}
        alt={alt}
        width={width}
        height={height}
        loading={loading}
        decoding="async"
        {...img}
      />
    </picture>
  );
}
