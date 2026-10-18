import { createFileRoute } from "@tanstack/react-router";
import { HomePage } from "@/components/HomePage";
import { LanguageProvider } from "@/i18n/LanguageProvider";
import type { Lang } from "@/content/site";

type HomeSearch = { lang?: Lang | undefined };

// og:image is omitted on purpose so serve-time hosting can inject the
// project's social preview (explicit og:image or latest screenshot).
// Canonical and og:url pin the page to https://cherryleeandco.com/ so
// `?lang=…` and tracking URL variants are treated as one page by Google.
export const Route = createFileRoute("/")({
  staticData: { sitemap: true },
  // `?lang=en` opens the English version (also server-rendered in English)
  validateSearch: (search: Record<string, unknown>): HomeSearch => {
    const lang = search["lang"];
    return { lang: lang === "en" || lang === "th" ? lang : undefined };
  },
  component: Index,
  head: () => ({
    meta: [
      { property: "og:url", content: "https://cherryleeandco.com/" },
      { property: "og:type", content: "website" },
    ],
    links: [{ rel: "canonical", href: "https://cherryleeandco.com/" }],
  }),
});

function Index() {
  const { lang } = Route.useSearch();
  return (
    <LanguageProvider initialLang={lang}>
      <HomePage />
    </LanguageProvider>
  );
}
