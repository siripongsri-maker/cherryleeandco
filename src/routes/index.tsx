import { createFileRoute } from "@tanstack/react-router";
import { HomePage } from "@/components/HomePage";
import { LanguageProvider } from "@/i18n/LanguageProvider";
import type { Lang } from "@/content/site";

type HomeSearch = { lang?: Lang | undefined };

// No head() here: the home route inherits title/description/og/twitter from
// __root.tsx, and ships no og:image so serve-time hosting can inject the
// project's social preview (explicit og:image or latest screenshot).
export const Route = createFileRoute("/")({
  staticData: { sitemap: true },
  // `?lang=en` opens the English version (also server-rendered in English)
  validateSearch: (search: Record<string, unknown>): HomeSearch => {
    const lang = search["lang"];
    return { lang: lang === "en" || lang === "th" ? lang : undefined };
  },
  component: Index,
});

function Index() {
  const { lang } = Route.useSearch();
  return (
    <LanguageProvider initialLang={lang}>
      <HomePage />
    </LanguageProvider>
  );
}
