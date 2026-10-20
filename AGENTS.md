<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## CherryLee & Co. project notes

- **Copy lives in `src/content/site.tsx`** (Thai `th` + English `en`). Components only handle layout. Change both languages together.
- **Facts only from the studio.** Programs, ages, schedule, prices, teachers and the address come from the studio's
  Facebook page. Don't invent outcomes, guarantees, group sizes, lunch arrangements or policies.
- **Tone:** warm, inclusive, non-judgmental, no fear-based messaging about shy children. Kru Cherry's Thai voice uses ค่ะ.
  Avoid the phrase "money game" (มันนี่เกม is Thai slang for a Ponzi scheme) — say board games / บอร์ดเกมการเงิน.
- **Thai line breaks:** wrap compound words and names in `<Nobr>` (or `⁠` in plain strings). Mark English inside Thai with `<En>`.
- **Brand tokens** are in `src/styles.css` (oklch). Decorative colours (`dusty`, `mustard`, `sage`, `coral`, `cherry-logo`)
  are never used for text. Keep text contrast ≥ 4.5:1 (see `design-system/cherrylee-co/MASTER.md`).
- **Scroll reveal:** elements with `data-reveal` must use keys that don't change with the language (use the index),
  otherwise they remount hidden after a language switch.
- **Videos** live in `src/content/videos.ts` (click-to-load `YouTubeVideo`, posters in `public/images/videos/`).
  A clip that shows children stays hidden until `consent` is recorded; never add one without the studio confirming
  parents' permission for website use. Never put children's names in copy, alt text or file names.
- **Accessibility:** touch targets ≥ 44px, visible focus rings, `role="list"` on styled lists, alt text in both languages,
  `prefers-reduced-motion` respected.
- Sitemap is router-derived (src/lib/sitemap.ts); every route sets staticData.sitemap — keeps /sitemap.xml in sync with routes.
- Teacher class drafting lives under the protected /admin route; every AI request validates teacher roles server-side, and drafts never update public site content automatically.
- Announcement drafting uses a separate authenticated AI server function and editable local output in /admin; short notes never publish automatically, keeping review separate from website updates.
- AI Gateway model contracts are CLI-generated and loaded through src/ai-gateway.types.ts; keep SDK inference in authenticated server-function handlers to protect credentials.
- Staff privileges live in public.user_roles and are assigned explicitly by the owner; signing up never grants a staff role.
- Homepage edits use allowlisted bilingual plain-text overrides with shipped JSX as fallback; a versioned singleton row prevents stale overwrites and is publicly readable through a server publishable client.
- Website editing derives text paths from shipped bilingual content excluding structural keys/anchors; validated public business settings share the homepage version and drive contact links, prices, maps and leaf-route structured data together. Existing video titles/visibility may change but video IDs and consent evidence stay code-controlled.
- Homepage photos are immutable uploads in private storage; public reads/signing are restricted to paths selected in homepage_content, preserving workspace public-bucket restrictions.
