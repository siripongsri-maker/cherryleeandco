# Design System Master File — CherryLee & Co.

> **LOGIC:** When building a specific page, first check `design-system/cherrylee-co/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file. If not, follow the rules below.

---

**Project:** CherryLee & Co. (เชอร์รี่ลีแอนด์โค) — life-skills learning for kids & families through creative drama
**Generated:** 2026-10-13 with `ui-ux-pro-max --design-system` (query: "kids education creative drama family learning warm playful")
**Category:** Kids Learning
**Design Dials:** Variance 6/10 (Balanced / Modern) | Motion 4/10 (Standard) | Density 3/10 (Spacious)

## Brand overrides (why this file differs from the raw search output)

The database returned a generic kids-app system (learning blue `#2563EB` + yellow + pink, Baloo 2 / Comic Neue,
Claymorphism, "Trust & Authority" pattern). CherryLee & Co. already has a strong visual identity on its
Facebook page — a cream background, Matisse-style paper-cutout botanicals and a cherry-pink line logo — so
**brand beats database defaults**:

| Raw recommendation | Override | Reason |
|---|---|---|
| Blue/yellow/pink palette | Cream + cherry + cutout palette (below) | Matches the existing cover art and logo |
| Baloo 2 + Comic Neue | Fredoka + Mitr (display), Anuphan (body), Sriracha (script accents) | Neither suggested font has Thai glyphs; the audience reads Thai first |
| Claymorphism | **Paper Cut-out Collage** (flat colour, irregular radii, solid offset "paper" shadows, grain texture) | Same playful, chunky, rounded feel, but in the brand's own Matisse cutout language |
| Trust & Authority + Conversion | Kept: credibility (20+ yrs drama educator), transparent pricing, one low-friction CTA (LINE) | Fits a small local studio well |

## Implementation (React + Tailwind)

- Tokens live in `tailwind.config.ts` (`cream`, `peach`, `paper`, `ink`, `cherry`, `dusty`, `mustard`, `sage`, `leaf`, `coral`,
  radii `rounded-paper` / `rounded-paper-alt` / `rounded-blob`, shadows `shadow-cut-*`). Shared pieces (`.btn`, `.eyebrow`, `.hl`,
  `.deco`, scroll reveal) are in `src/index.css`.
- Breakpoints: `xs` 420 · `sm` 640 · `md` 768 · `lg` 1024 (two-column layouts, sticky bar off) · `nav` 1120 (full desktop nav —
  the Thai labels need ~984px) · `xl` 1280.
- Brand marks: the studio's own logo cut-outs in `public/images/logo-*.png`; logo pink `#FF4873` (`cherry-logo`) is for graphics only.

## Color tokens

| Role | Hex | CSS variable | Notes |
|------|-----|--------------|-------|
| Background | `#FBF3EA` | `--cream` | Page background (cover-art cream) |
| Band | `#F6E4D4` | `--peach` | Alternating section background |
| Card | `#FFFDF9` | `--paper` | Cards, panels |
| Foreground | `#2A211C` | `--ink` | 14.3:1 on cream |
| Muted text | `#5E5049` | `--ink-soft` | 7.0:1 on cream |
| Primary / CTA | `#B8395F` | `--cherry` | White text on it: 5.5:1 |
| Primary hover / text on peach | `#9E2D50` | `--cherry-deep` | 5.8:1 on peach |
| Cherry tint | `#F6D3DC` | `--cherry-soft` | Chips, highlights |
| Dusty blue (decor) | `#9DB1D9` | `--blue` | Cutout flowers |
| Blue text | `#3B5491` | `--blue-ink` | 6.7:1 on cream |
| Mustard (decor) | `#E8B23A` | `--mustard` | Sprigs, badges (ink text 8.2:1) |
| Sage (decor) | `#A9C79B` | `--sage` | Seaweed leaves |
| Leaf text | `#3F6E45` | `--leaf` | 5.4:1 on cream |
| Coral (decor) | `#D9533F` | `--coral` | Heart leaves (decorative only) |

Rule: decorative colours (`--blue`, `--mustard`, `--sage`, `--coral`) are **never** used for text on cream.

## Typography

- **Display:** `"Fredoka", "Mitr", system-ui, sans-serif` — Latin glyphs from Fredoka, Thai glyphs fall through to Mitr
- **Body:** `"Anuphan", system-ui, sans-serif` — Thai + Latin, 17px base, line-height 1.75 for Thai vowels/tone marks
- **Script accents:** `"Sriracha", cursive` — echoes the hand-lettered tagline on the cover; eyebrows and quotes only
- Google Fonts: `family=Anuphan:wght@400;500;600&family=Fredoka:wght@500;600;700&family=Mitr:wght@500;600;700&family=Sriracha&display=swap`
  (Fredoka has no Thai glyphs, so Thai headings render in Mitr — load the 600/700 weights to avoid faux bold)

## Spacing (Density 3 — spacious)

`--space-xs 4px · --space-sm 8px · --space-md 24px · --space-lg 32px · --space-xl 48px · --space-2xl 64px · --space-3xl 96px`

## Components

- **Buttons:** pill, min-height 48px, `--cherry` fill + white text, 3px solid offset shadow in `--cherry-deep`
  that collapses on `:active` (paper press). Secondary = `--paper` fill, 2px `--ink` border.
- **Cards:** `--paper`, irregular radius `28px 22px 30px 20px / 22px 30px 20px 28px`, 2px ink border,
  `6px 6px 0` solid shadow in a cutout colour. Hover lifts 3px (transform only, no layout shift).
- **Chips:** small pill, tinted background, ink text.
- **Icons:** Lucide line icons (stroke 2) and Simple Icons for LINE / Facebook / Messenger. No emoji icons.
- **Decor:** inline SVG cutouts (flower, seaweed, sprig, heart leaf, 4-point star, cherries), `aria-hidden`.

## Motion

- Scroll reveal: opacity + translateY(16px), 450ms `cubic-bezier(.2,.8,.2,1)`, 60ms stagger; JS-only (content visible without JS).
- Decor float: 6–9s gentle loop.
- `prefers-reduced-motion: reduce` → all of the above disabled; final state rendered immediately.

## Content rules

- Thai first, English toggle (TH | EN) on every visible string; image alt and aria-labels switch too.
- Warm, non-judgmental, no fear-based messaging. Frame shyness as normal, not a deficit.
- Only state facts the studio has published (programs, ages, schedule, prices, location, teachers).

## Pre-Delivery Checklist

- [ ] No emojis used as icons (SVG only)
- [ ] `cursor: pointer` on all clickable elements
- [ ] Hover/focus transitions 150–300ms; visible `:focus-visible` rings
- [ ] Text contrast ≥ 4.5:1 (see table)
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive at 375 / 768 / 1024 / 1440px, no horizontal scroll
- [ ] Touch targets ≥ 44×44px
- [ ] No content hidden behind the sticky header or mobile CTA bar
