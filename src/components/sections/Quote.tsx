import { useLanguage } from "@/i18n/LanguageProvider";
import { Star } from "../Decor";

export function Quote() {
  const { t } = useLanguage();
  const q = t.quote;

  return (
    <section
      aria-label={q.label}
      className="relative overflow-hidden bg-dusty-ink py-16 text-cream md:py-24"
    >
      <Star className="left-4 top-4 h-[34px] w-[34px] text-mustard xl:left-[8%] xl:top-[18%]" />
      <Star className="bottom-4 right-4 h-[22px] w-[22px] text-mustard xl:bottom-[20%] xl:right-[10%]" />
      <div className="container-site relative z-10">
        <figure data-reveal className="mx-auto my-0 max-w-[860px] text-center">
          <blockquote className="m-0 mb-4">
            <p className="m-0 font-script text-[clamp(1.45rem,1.1rem+1.6vw,2.25rem)] leading-[1.55]">
              {q.text}
            </p>
          </blockquote>
          <figcaption className="mx-auto max-w-[640px] text-[#E9E2DA]">
            <cite className="mb-4 block font-display text-base font-semibold not-italic text-mustard-soft">
              — {q.source}
            </cite>
            {q.caption}
          </figcaption>
        </figure>
      </div>
    </section>
  );
}
