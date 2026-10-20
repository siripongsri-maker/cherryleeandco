import { createFileRoute } from "@tanstack/react-router";
import { HomePage } from "@/components/HomePage";
import { LanguageProvider } from "@/i18n/LanguageProvider";
import type { Lang } from "@/content/site";
import { content } from "@/content/site";
import { queryOptions, useSuspenseQuery } from "@tanstack/react-query";
import { getHomepage } from "@/lib/homepage-content.functions";

const homepageQuery = queryOptions({ queryKey: ["homepage-content"], queryFn: () => getHomepage(), staleTime: 0, refetchInterval: 30 * 60 * 1000 });

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
  loader: ({ context }) => context.queryClient.ensureQueryData(homepageQuery),
  head: ({ loaderData }) => ({
    meta: [
      { title: content.th.meta.title },
      { name: "description", content: content.th.meta.description },
      { property: "og:title", content: content.th.meta.title },
      { property: "og:description", content: content.th.meta.description },
      { name: "twitter:card", content: "summary_large_image" },
      { property: "og:url", content: "https://cherryleeandco.com/" },
      { property: "og:type", content: "website" },
      ...(loaderData?.imageUrls['hero'] ? [{ property: "og:image", content: loaderData.imageUrls['hero'] }, { name: "twitter:image", content: loaderData.imageUrls['hero'] }] : []),
    ],
    links: [{ rel: "canonical", href: "https://cherryleeandco.com/" }],
  }),
});

function Index() {
  const { lang } = Route.useSearch();
  const { data: homepage } = useSuspenseQuery(homepageQuery);
  return (
    <LanguageProvider initialLang={lang} homepage={homepage}>
      <HomePage />
    </LanguageProvider>
  );
}
