# CherryLee & Co. — website

One-page, bilingual (ไทย / English) website for **CherryLee & Co. เชอร์รี่ลีแอนด์โค**, a life-skills learning space
for kids and families built on creative drama (Soi Nawamin 117, Bangkok).

This project was built with [Lovable](https://lovable.dev) and syncs both ways with this GitHub repo:
edit in the [Lovable editor](https://lovable.dev/projects/fa9b86e9-5d99-468e-be51-3be106fa410c), or push to `main`.

Stack (Lovable's template): **TanStack Start + React 19 + TypeScript + Tailwind CSS 4**, server-rendered.

## Run it locally

```sh
npm i            # or: bun install
npm run dev
npm run build
npm run test
```

## Where things live

```
src/content/site.tsx           ← ALL copy, Thai + English side by side (edit text here)
src/content/business.ts        ← LINE / Messenger / email / social links, prices, map pin, schema.org data
src/content/videos.ts          ← YouTube clips shown on the site (+ parents' consent record)
src/components/HomePage.tsx    ← section order
src/components/sections/*.tsx  ← one file per page section
src/components/Header.tsx      ← logo, nav, TH/EN switch, mobile menu
src/i18n/LanguageProvider.tsx  ← language state (?lang=en, remembered in localStorage)
src/routes/__root.tsx          ← <head>: title, description, Open Graph, fonts, icons, JSON-LD
src/routes/index.tsx           ← the home route
src/styles.css                 ← brand colours (oklch), fonts, paper-cut shadows, buttons
public/images/                 ← logo, teacher photos, Canva illustrations, icons, og-image
public/images/videos/          ← video posters (from each clip's YouTube thumbnail)
design-system/cherrylee-co/MASTER.md  ← design rules and contrast notes
```

## Editing copy

Every string exists in both `th` and `en` in `src/content/site.tsx`. Change both.

- Wrap Thai compound words or names that must not break across lines in `<Nobr>…</Nobr>`
  (Chrome sometimes splits words like การเรียนรู้ or อังเคิลลี). In plain string fields use `⁠` (word joiner).
- Mark English words inside Thai text with `<En>…</En>` so screen readers pronounce them correctly.
- Some lists are fixed-length tuples (hero facts, details, principles, skills, plans) because each item has a matching
  icon. TypeScript will tell you if you add or remove one.

**Placeholders the studio should fill in:**

- FAQ "มีพักและอาหารกลางวันไหม?": the answer currently says to ask on LINE. Add the real break and lunch arrangement.
- FAQ "กลุ่มใหญ่แค่ไหน?": add the maximum group size if there is one.

### Prices

`src/content/business.ts` → `PRICES`. The per-session averages, savings and the schema.org offers update
automatically. Update the "ราคา ณ ตุลาคม 2569 / as of October 2026" line in `site.tsx` too.

### Booking links

The hero, header, sticky mobile bar and LINE buttons open LINE OA `@cherryleeandco`. Each pricing card opens LINE
with a message already typed for that package (`lineMessageUrl` in `business.ts`). The final CTA also links to
Messenger (`m.me/cherryleeandco`).

## Videos

Clips from the studio's YouTube channel (https://www.youtube.com/@cherryleeandco.) appear in two places:

- **"แอบดูห้องเรียนของเรา / Take a peek inside our classes"** (after the activities): four class clips.
- **"ฟังเสียงครูเชอร์รี่และอังเคิลลี"** (in Team teaching): the founders' conversation, Uncle Lee's Three Jars short and a
  link to Kru Cherry's เปิดโลกละครสร้างสรรค์ playlist.

Each clip shows a poster and loads the player from `youtube-nocookie.com` only when someone presses play, so the page
stays fast and YouTube sets nothing before that. Only one clip plays at a time.

To add or swap a clip, edit `src/content/videos.ts` and add a poster to `public/images/videos/` (360 + 540 px wide
WebP and a 540 px JPG for vertical clips; 640 + 960 WebP and a 960 JPG for 16:9). Watch the whole clip first.
**A clip that shows children is hidden until `consent` is filled in**: only add it once the studio has its parents'
or guardians' permission to show it on the website. Never put children's names in titles, alt text or file names.
The four class clips were confirmed with parents' permission on 13 October 2026.

Language labels: the founders' talk and Uncle Lee's clips are in English; the Story Playlit and shopping-trip clips are
in Thai; the cooking clip is labelled "Thai & English" from the studio's description of that class (worth a listen).
Dates show when a clip was *posted*. Some older clips mention earlier class times (e.g. Saturday 10:00–12:00), so
the site's own schedule is the one to trust.

## Publishing and social previews

Publish from Lovable (a custom domain can be added there). The home route ships no `og:image`, so Lovable's hosting
can inject the project's social preview: set it to `public/images/og-image.jpg` in the Lovable project settings.
Once the live domain is known, make the JSON-LD `image`, `logo` and both `founder[].image` paths in
`src/content/business.ts` absolute (`https://YOUR-DOMAIN/images/...`) and add `url: "https://YOUR-DOMAIN/"`.
Then test a link in a LINE chat and in the Facebook Sharing Debugger.

## Images

| File(s) in `public/images/` | Source |
|---|---|
| `logo-mark.png`, `logo-wordmark.png`, `logo-stacked.png`, `logo-mark-white.png` | Cut out from the studio's logo |
| `favicon-64.png`, `apple-touch-icon.png`, `icon-512.png`, `/favicon.ico` | Generated from the logo mark |
| `kru-cherry-*`, `uncle-lee-*` | Teacher photos supplied by the studio (4:5 crops + round avatars) |
| `hero-*`, `story-playlit-*`, `basic-cooking-*`, `money-wise-*`, `og-image.jpg` | Generated in Canva |

The Canva illustrations are saved in the design **"CherryLee Website Illustrations"**:
https://www.canva.com/d/Nfr39RoPL8zumtd

To swap in real class photos, keep the same file names and aspect ratios (square for activity cards, 4:3 for the hero)
and update the alt text in `site.tsx`. Only publish photos of children with their parents' consent.

## Third-party requests

No analytics or tracking scripts. The page loads Google Fonts and an embedded Google Maps iframe, both of which
contact Google. YouTube videos load only after a visitor presses play.

## Content sources

Facts (programs, ages 6–12, Saturday/Sunday 09:00–15:00, prices, teachers, LINE OA) come from the public Facebook page
https://www.facebook.com/cherryleeandco as of 13 October 2026.

**Address:** taken from recent posts ("CherryLee & Co. (ซอยนวมินทร์ 117)") and the Google Maps pin
(13.8134544, 100.6506617, https://maps.app.goo.gl/hQBAwFrh35s3TJSZ9). The Facebook *About* section still says
พระนคร 10200, which is a different district. Don't use that postcode, and ask the studio to update their Facebook About.
