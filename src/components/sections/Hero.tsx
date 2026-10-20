import { CalendarDays, MapPin, Smile, Users } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { LINE_URL } from "@/content/business";
import { LineIcon } from "../icons";
import { ExternalLink } from "../ExternalLink";
import { Flower, HeartLeaf, Sprig, Star } from "../Decor";

const FACT_ICONS = [Smile, CalendarDays, Users, MapPin];
export const HERO_SIZES = "(min-width: 1244px) 545px, (min-width: 1024px) 44vw, 92vw";

export function Hero() {
  const { lang, t, images } = useLanguage();
  const h = t.hero;

  return (
    <section
      id="top"
      aria-labelledby="hero-title"
      className="relative overflow-hidden pb-16 pt-12 md:pb-24 md:pt-16"
    >
      <Flower className="right-[-36px] top-[6%] h-[120px] w-[120px] rotate-[14deg] animate-float text-dusty lg:right-[-40px] lg:h-40 lg:w-40" />
      <Sprig className="bottom-[4%] left-[-18px] hidden h-[140px] w-[70px] -rotate-[18deg] text-mustard lg:block xl:left-[1%]" />
      <Star className="left-[46%] top-[14%] hidden h-[26px] w-[26px] text-ink lg:block" />
      <HeartLeaf className="bottom-[6%] right-[8%] hidden h-[70px] w-[70px] -rotate-[20deg] animate-float-fast text-coral opacity-90 lg:block" />

      <div className="container-site relative z-10 grid items-center gap-12 lg:grid-cols-[1.05fr_1fr] lg:gap-16">
        <div>
          <p
            lang={lang}
            className="mb-2 font-script text-[clamp(1.15rem,1rem+0.6vw,1.45rem)] text-cherry-deep"
          >
            {h.script}
          </p>
          <h1 id="hero-title" className="mb-6 text-h1 font-bold [html[lang=th]_&]:leading-[1.35]">
            {h.title}
          </h1>
          <p className="max-w-[36em] text-[1.15rem] text-ink-soft">{h.lead}</p>

          <div className="my-8 flex flex-wrap gap-x-6 gap-y-3">
            <ExternalLink href={LINE_URL} className="btn btn-primary btn-lg w-full xs:w-auto">
              <LineIcon />
              {h.ctaPrimary}
            </ExternalLink>
            <a href="#programs" className="btn btn-ghost btn-lg w-full xs:w-auto">
              {h.ctaSecondary}
            </a>
          </div>

          <div className="mb-6 flex items-center gap-4">
            <div className="flex shrink-0 -space-x-3" aria-hidden="true">
              {["kru-cherry", "uncle-lee"].map((n) => (
                <picture key={n}>
                  <source type="image/webp" srcSet={`/images/${n}-avatar.webp`} />
                  <img
                    src={`/images/${n}-avatar.jpg`}
                    width={192}
                    height={192}
                    alt=""
                    className="h-14 w-14 rounded-full border-2 border-ink bg-paper object-cover"
                  />
                </picture>
              ))}
            </div>
            <p className="m-0 text-[0.975rem] leading-relaxed text-ink-soft">{h.teachers}</p>
          </div>

          <ul role="list" aria-label={h.factsLabel} className="flex flex-wrap gap-2.5">
            {h.facts.map((fact, i) => {
              const Icon = FACT_ICONS[i % FACT_ICONS.length] ?? Smile;
              return (
                <li
                  key={i}
                  className="inline-flex items-center gap-2 rounded-full border-[1.5px] border-peach-deep bg-paper px-3.5 py-1.5 text-[0.9375rem] font-medium leading-snug"
                >
                  <Icon className="h-[1.1em] w-[1.1em] text-cherry" aria-hidden="true" />
                  {fact}
                </li>
              );
            })}
          </ul>
        </div>

        <figure className="m-0">
          <div className="relative aspect-[1456/1088] rotate-[1.2deg] overflow-hidden rounded-blob border-2 border-ink bg-paper shadow-cut-hero">
            {images['hero'] ? <img src={images['hero']} width={1100} height={822} alt={h.artAlt} fetchPriority="high" decoding="async" className="h-full w-full object-cover" /> : <picture>
              <source
                type="image/webp"
                srcSet="/images/hero-720.webp 720w, /images/hero-1100.webp 1100w, /images/hero-1456.webp 1456w"
                // Keep in sync with the hero preload in src/routes/__root.tsx
                sizes={HERO_SIZES}
              />
              <img
                src="/images/hero-1100.jpg"
                width={1100}
                height={822}
                alt={h.artAlt}
                fetchPriority="high"
                decoding="async"
                className="h-full w-full object-cover"
              />
            </picture>}
          </div>
          <figcaption className="mt-6 text-center font-script text-[1.05rem] text-ink-soft">
            {h.caption}
          </figcaption>
        </figure>
      </div>
    </section>
  );
}
