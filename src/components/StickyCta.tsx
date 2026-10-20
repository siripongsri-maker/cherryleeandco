import { useEffect, useState } from "react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { LineIcon } from "./icons";
import { ExternalLink } from "./ExternalLink";

/** Mobile-only booking bar. Hidden while the hero, the big CTA or the footer is on screen. */
export function StickyCta() {
  const { t, business } = useLanguage();
  const [hidden, setHidden] = useState(true);

  useEffect(() => {
    if (!("IntersectionObserver" in window)) {
      setHidden(false);
      return;
    }
    const targets = [
      document.getElementById("top"),
      document.getElementById("book"),
      document.querySelector("footer"),
    ].filter(Boolean) as Element[];
    const visible = new Set<Element>();
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) =>
          e.isIntersecting ? visible.add(e.target) : visible.delete(e.target),
        );
        setHidden(visible.size > 0);
      },
      { threshold: 0.15 },
    );
    targets.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return (
    <div
      aria-hidden={hidden}
      className={`sticky-cta fixed inset-x-0 bottom-0 z-40 border-t-2 border-peach-deep bg-cream px-[clamp(1rem,0.6rem+2vw,2rem)] pb-[calc(0.75rem+env(safe-area-inset-bottom))] pt-3 transition duration-200 ease-paper lg:hidden ${
        hidden ? "invisible translate-y-[110%]" : "visible translate-y-0"
      }`}
    >
      <ExternalLink
        href={business.lineUrl}
        tabIndex={hidden ? -1 : undefined}
        className="btn btn-primary w-full"
      >
        <LineIcon />
        {t.sticky}
      </ExternalLink>
    </div>
  );
}
