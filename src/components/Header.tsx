import { useEffect, useRef, useState, type FocusEvent, type MouseEvent } from "react";
import { Menu, X } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { LINE_URL } from "@/content/business";
import { content, type Lang } from "@/content/site";
import { LineIcon } from "./icons";
import { ExternalLink } from "./ExternalLink";

const LANG_OPTIONS: { code: Lang; label: string }[] = [
  { code: "th", label: "ไทย" },
  { code: "en", label: "EN" },
];
const DESKTOP_NAV = "(min-width: 1120px)"; // keep in sync with the `nav` screen in tailwind.config.ts

export function Header() {
  const { lang, setLang, t } = useLanguage();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [active, setActive] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState("");
  const headerRef = useRef<HTMLElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const navRef = useRef<HTMLElement>(null);

  // Header hairline once the page scrolls
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Highlight the nav item for the section in view; clear it over sections without a nav item
  useEffect(() => {
    if (!("IntersectionObserver" in window)) return;
    const navIds = new Set(t.nav.items.map((i) => i.href.slice(1)));
    const spy = new IntersectionObserver(
      (entries) =>
        entries.forEach((e) => {
          if (e.isIntersecting) setActive(navIds.has(e.target.id) ? e.target.id : null);
        }),
      { rootMargin: "-45% 0px -50% 0px" },
    );
    document.querySelectorAll("main > section").forEach((s) => spy.observe(s));
    return () => spy.disconnect();
  }, [t.nav.items]);

  // Mobile menu: focus first link on open; Escape, outside click or desktop width closes it
  useEffect(() => {
    if (!open) return;
    navRef.current?.querySelector<HTMLAnchorElement>("a")?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
        toggleRef.current?.focus();
      }
    };
    const onClick = (e: globalThis.MouseEvent) => {
      if (!headerRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const mq = window.matchMedia(DESKTOP_NAV);
    const onMq = () => mq.matches && setOpen(false);
    document.addEventListener("keydown", onKey);
    document.addEventListener("click", onClick);
    mq.addEventListener?.("change", onMq);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("click", onClick);
      mq.removeEventListener?.("change", onMq);
    };
  }, [open]);

  // Close the menu when keyboard focus leaves the header, so the panel never covers the focused element
  const onHeaderBlur = (e: FocusEvent<HTMLElement>) => {
    const next = e.relatedTarget as Node | null;
    if (open && next && !headerRef.current?.contains(next)) setOpen(false);
  };

  // After choosing a section from the open mobile menu, move focus to that section's heading
  const onNavClick = (e: MouseEvent<HTMLAnchorElement>) => {
    const wasOpen = open;
    setOpen(false);
    const id = e.currentTarget.getAttribute("href")?.slice(1);
    const heading = id ? document.getElementById(id)?.querySelector<HTMLElement>("h1, h2") : null;
    if (wasOpen && heading) {
      heading.setAttribute("tabindex", "-1");
      // Let the browser finish its own jump to #id first, then move focus to the heading
      window.setTimeout(() => heading.focus({ preventScroll: true }), 0);
    }
  };

  const chooseLang = (code: Lang) => {
    if (code === lang) return;
    setLang(code);
    setAnnouncement(content[code].langChanged);
  };

  return (
    <header
      ref={headerRef}
      onBlur={onHeaderBlur}
      className={`site-header sticky top-0 z-50 border-b-2 bg-cream transition-[border-color,box-shadow] duration-200 ${
        scrolled
          ? "border-peach-deep shadow-[0_6px_18px_-14px_rgba(42,33,28,.45)]"
          : "border-transparent"
      }`}
    >
      <div className="container-site flex min-h-[72px] items-center gap-4 nav:gap-6">
        <a
          href="#top"
          aria-label={t.brand.homeLabel}
          className="mr-auto inline-flex min-h-11 items-center gap-2 no-underline"
        >
          <img
            src="/images/logo-mark.png"
            width={215}
            height={226}
            alt=""
            className="h-10 w-auto xs:h-11"
          />
          <img
            src="/images/logo-wordmark.png"
            width={383}
            height={53}
            alt=""
            className="h-[15px] w-auto xs:h-[18px]"
          />
        </a>

        <nav
          id="site-nav"
          ref={navRef}
          aria-label={t.nav.label}
          className={`fixed inset-x-0 top-[72px] z-40 max-h-[calc(100vh-72px)] overflow-y-auto border-b-2 border-peach-deep bg-cream px-[clamp(1rem,0.6rem+2vw,2rem)] pb-8 pt-6 shadow-[0_18px_30px_-20px_rgba(42,33,28,.5)] transition duration-200 ease-paper supports-[height:100dvh]:max-h-[calc(100dvh-72px)] nav:visible nav:static nav:flex nav:max-h-none nav:translate-y-0 nav:items-center nav:gap-6 nav:overflow-visible nav:border-0 nav:bg-transparent nav:p-0 nav:opacity-100 nav:shadow-none nav:supports-[height:100dvh]:max-h-none ${
            open ? "visible translate-y-0 opacity-100" : "invisible -translate-y-2 opacity-0"
          }`}
        >
          <ul role="list" className="flex flex-col gap-1 nav:flex-row">
            {t.nav.items.map((item) => {
              const isActive = active === item.href.slice(1);
              return (
                <li key={item.href}>
                  <a
                    href={item.href}
                    onClick={onNavClick}
                    aria-current={isActive ? "location" : undefined}
                    className={`flex min-h-[52px] items-center whitespace-nowrap rounded-full px-4 py-2 font-display text-lg font-medium text-ink no-underline transition-colors duration-200 hover:bg-cherry-soft hover:text-ink nav:min-h-11 nav:px-3 nav:py-1 nav:font-sans nav:text-base ${
                      isActive ? "bg-cherry-soft" : ""
                    }`}
                  >
                    {item.label}
                  </a>
                </li>
              );
            })}
          </ul>
          <ExternalLink
            href={LINE_URL}
            onClick={() => {
              if (!open) return; // desktop: the nav is always visible, leave focus on the link
              setOpen(false);
              toggleRef.current?.focus();
            }}
            className="btn btn-primary btn-sm mt-4 w-full whitespace-nowrap nav:mt-0 nav:w-auto"
          >
            <LineIcon />
            {t.nav.cta}
          </ExternalLink>
        </nav>

        <div className="flex items-center gap-2">
          <div
            role="group"
            aria-label={t.nav.langGroup}
            className="inline-flex rounded-full border-2 border-ink bg-paper p-0.5"
          >
            {LANG_OPTIONS.map((opt) => (
              <button
                key={opt.code}
                type="button"
                lang={opt.code}
                aria-pressed={lang === opt.code}
                onClick={() => chooseLang(opt.code)}
                className={`min-h-11 min-w-11 cursor-pointer rounded-full px-2.5 font-display text-[0.9rem] font-semibold transition-colors duration-200 xs:px-3 ${
                  lang === opt.code ? "bg-ink text-cream" : "hover:bg-cherry-soft"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
          <button
            ref={toggleRef}
            type="button"
            aria-controls="site-nav"
            aria-expanded={open}
            aria-label={open ? t.nav.menuClose : t.nav.menuOpen}
            onClick={() => setOpen((o) => !o)}
            className="inline-flex h-12 w-12 cursor-pointer items-center justify-center rounded-[14px] border-2 border-ink bg-paper nav:hidden"
          >
            {open ? (
              <X className="h-6 w-6" aria-hidden="true" />
            ) : (
              <Menu className="h-6 w-6" aria-hidden="true" />
            )}
          </button>
        </div>
      </div>
      <p aria-live="polite" className="sr-only">
        {announcement}
      </p>
    </header>
  );
}
