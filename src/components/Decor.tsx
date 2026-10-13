import type { SVGProps } from "react";

/**
 * Matisse-style paper cut-outs that echo the Facebook cover art.
 * Purely decorative: always aria-hidden. Colour comes from `currentColor` (set a text-* class).
 */
type DecorProps = SVGProps<SVGSVGElement>;
const base = { "aria-hidden": true, focusable: false } as const;

export const Flower = ({ className = "", ...props }: DecorProps) => (
  <svg viewBox="0 0 100 100" className={`deco ${className}`} {...base} {...props}>
    <g fill="currentColor">
      {[0, 72, 144, 216, 288].map((r) => (
        <ellipse key={r} cx="50" cy="25" rx="15" ry="24" transform={`rotate(${r} 50 50)`} />
      ))}
    </g>
    <circle cx="50" cy="50" r="7" fill="#2A211C" />
  </svg>
);

export const Seaweed = ({ className = "", ...props }: DecorProps) => (
  <svg viewBox="0 0 100 200" className={`deco ${className}`} {...base} {...props}>
    <path
      fill="currentColor"
      d="M50 198c-3-36-22-46-14-72 6-18-12-28-4-48 6-16-6-28 6-48 6-10 12-20 12-26 10 14 14 28 8 42 12 12 4 28-2 40 14 14 10 30 2 42 12 16 6 38-2 70Z"
    />
  </svg>
);

export const Sprig = ({ className = "", ...props }: DecorProps) => (
  <svg viewBox="0 0 80 160" className={`deco ${className}`} {...base} {...props}>
    <path
      d="M39 158c1-50 1-100 2-150"
      fill="none"
      stroke="currentColor"
      strokeWidth="3"
      strokeLinecap="round"
    />
    <g fill="currentColor">
      <ellipse cx="28" cy="40" rx="8" ry="16" transform="rotate(-35 28 40)" />
      <ellipse cx="52" cy="56" rx="8" ry="16" transform="rotate(35 52 56)" />
      <ellipse cx="27" cy="76" rx="8" ry="16" transform="rotate(-35 27 76)" />
      <ellipse cx="53" cy="92" rx="8" ry="16" transform="rotate(35 53 92)" />
      <ellipse cx="27" cy="112" rx="8" ry="16" transform="rotate(-35 27 112)" />
      <ellipse cx="41" cy="14" rx="7" ry="13" />
    </g>
  </svg>
);

export const HeartLeaf = ({ className = "", ...props }: DecorProps) => (
  <svg viewBox="0 0 100 100" className={`deco ${className}`} {...base} {...props}>
    <path
      fill="currentColor"
      d="M50 90C20 68 5 48 13 29 21 12 42 12 50 31c8-19 29-19 37-2 8 19-7 39-37 61Z"
    />
    <path
      d="M50 34v48M50 50l-12-9M50 62l13-10M50 72l-10-7"
      fill="none"
      stroke="#FBF3EA"
      strokeWidth="3"
      strokeLinecap="round"
    />
  </svg>
);

export const Star = ({ className = "", ...props }: DecorProps) => (
  <svg viewBox="0 0 100 100" className={`deco ${className}`} {...base} {...props}>
    <path
      fill="currentColor"
      d="M50 0c4 38 12 46 50 50-38 4-46 12-50 50-4-38-12-46-50-50 38-4 46-12 50-50Z"
    />
  </svg>
);
