import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { content, type Lang, type SiteContent } from "@/content/site";
import { applyHomepage, type HomepageData } from "@/lib/homepage-content";
import { applyBusinessCopy, resolveBusiness, resolveVideos } from "@/lib/website-settings";

const STORAGE_KEY = "cherrylee-lang";
const LANGS: readonly Lang[] = ["th", "en"];

type LanguageContextValue = {
  lang: Lang;
  setLang: (lang: Lang) => void;
  t: SiteContent;
  images: Record<string, string>;
  business: ReturnType<typeof resolveBusiness>;
  videos: ReturnType<typeof resolveVideos>;
  hiddenVideos: string[];
};

const LanguageContext = createContext<LanguageContextValue | null>(null);

function readStored(): Lang | null {
  try {
    const v = window.localStorage.getItem(STORAGE_KEY);
    return LANGS.includes(v as Lang) ? (v as Lang) : null;
  } catch {
    return null;
  }
}

type LanguageProviderProps = {
  children: ReactNode;
  /** From the `?lang=` search param, so the server and the first client render agree. */
  initialLang?: Lang | undefined;
  homepage?: HomepageData & { imageUrls: Record<string,string> };
};

export function LanguageProvider({ children, initialLang, homepage }: LanguageProviderProps) {
  const [lang, setLangState] = useState<Lang>(initialLang ?? "th");

  // After hydration, honour a saved choice when the URL doesn't pick a language
  useEffect(() => {
    if (initialLang) return;
    const stored = readStored();
    if (stored) setLangState(stored);
  }, [initialLang]);

  const setLang = useCallback((next: Lang) => {
    setLangState(next);
    try {
      window.localStorage.setItem(STORAGE_KEY, next);
    } catch {
      /* storage unavailable (private mode) — the toggle still works for this visit */
    }
    // A shared ?lang= link shouldn't override the visitor's own choice on reload
    try {
      const url = new URL(window.location.href);
      if (url.searchParams.has("lang")) {
        url.searchParams.set("lang", next);
        window.history.replaceState(window.history.state, "", url);
      }
    } catch {
      /* ignore */
    }
  }, []);

  const t = useMemo(() => applyHomepage(applyBusinessCopy(content[lang], lang, homepage?.settings ?? {}, Object.keys(homepage?.texts ?? {})), lang, homepage?.texts ?? {}), [lang, homepage?.texts, homepage?.settings]);
  const images = homepage?.imageUrls ?? {};
  const business = useMemo(() => resolveBusiness(homepage?.settings), [homepage?.settings]);
  const videos = useMemo(() => resolveVideos(homepage?.settings), [homepage?.settings]);
  const hiddenVideos = homepage?.settings.hiddenVideos ?? [];

  // Keep <html lang>, the tab title and the meta description in the active language
  useEffect(() => {
    document.documentElement.lang = lang;
    document.title = t.meta.title;
    document.querySelector('meta[name="description"]')?.setAttribute("content", t.meta.description);
  }, [lang, t]);

  const value = useMemo(() => ({ lang, setLang, t, images, business, videos, hiddenVideos }), [lang, setLang, t, images, business, videos, hiddenVideos]);
  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used inside <LanguageProvider>");
  return ctx;
}
