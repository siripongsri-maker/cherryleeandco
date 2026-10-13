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
- **Accessibility:** touch targets ≥ 44px, visible focus rings, `role="list"` on styled lists, alt text in both languages,
  `prefers-reduced-motion` respected.
