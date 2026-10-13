import { CalendarDays, Check, Clock, MapPin, Smile } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { PRICES, formatBaht, lineMessageUrl } from "@/content/business";
import { LineIcon } from "../icons";
import { ExternalLink } from "../ExternalLink";
import { Sprig } from "../Decor";

const DETAIL_ICONS = [Smile, CalendarDays, Clock, MapPin];
const PLAN_PRICES = [PRICES.single, PRICES.four, PRICES.eight];

export function Pricing() {
  const { t } = useLanguage();
  const p = t.pricing;

  return (
    <section id="pricing" aria-labelledby="pricing-title" className="section">
      <Sprig className="left-[2%] top-[6%] h-32 w-16 -rotate-[10deg] text-mustard" />
      <div className="container-site relative z-10">
        <header data-reveal className="mx-auto mb-12 max-w-[760px] text-center">
          <p className="eyebrow">{p.eyebrow}</p>
          <h2 id="pricing-title" className="mb-0 text-h2">
            {p.title}
          </h2>
        </header>

        <ul
          role="list"
          data-reveal
          className="mb-12 grid list-none gap-2 sm:grid-cols-2 lg:grid-cols-4"
        >
          {p.details.map((d, i) => {
            const Icon = DETAIL_ICONS[i % DETAIL_ICONS.length] ?? Smile;
            return (
              <li
                key={i}
                className="flex items-start gap-3 rounded-[18px] border-[1.5px] border-peach-deep bg-paper px-4 py-3.5"
              >
                <Icon
                  className="mt-0.5 h-[26px] w-[26px] shrink-0 text-cherry"
                  aria-hidden="true"
                />
                <div>
                  <strong className="block font-display font-semibold leading-snug">
                    {d.title}
                  </strong>
                  <span className="block text-[0.9375rem] leading-normal text-ink-soft">
                    {d.body}
                  </span>
                </div>
              </li>
            );
          })}
        </ul>

        <div className="grid items-stretch gap-8 lg:grid-cols-3 lg:items-end">
          {p.plans.map((plan, i) => {
            const best = Boolean(plan.badge);
            return (
              <article
                key={i}
                data-reveal
                className={`relative flex flex-col rounded-paper border-2 border-ink px-6 pb-6 text-center ${
                  best ? "bg-cherry-soft pt-12 shadow-cut-cherry" : "bg-paper pt-8 shadow-cut-peach"
                }`}
              >
                <h3 className="mb-1 text-2xl">{plan.name}</h3>
                {/* After the heading in the DOM so heading navigation announces it; positioned on the card edge */}
                {plan.badge && (
                  <p className="absolute -top-4 left-1/2 m-0 -translate-x-1/2 -rotate-3 whitespace-nowrap rounded-full border-2 border-ink bg-mustard px-4 py-1 font-display text-[0.95rem] font-bold">
                    {plan.badge}
                  </p>
                )}
                <p className="mb-6 text-[0.9375rem] text-ink-soft">{plan.sub}</p>
                <p className="mb-1 font-display text-[clamp(2.2rem,1.8rem+1.5vw,2.8rem)] font-bold leading-none tracking-[-0.02em]">
                  {formatBaht(PLAN_PRICES[i] ?? PRICES.single)}
                </p>
                <p
                  className={`mb-6 min-h-[1.6em] text-[0.9375rem] lg:max-xl:min-h-[3.5em] ${best ? "font-medium text-ink" : "text-ink-soft"}`}
                >
                  {plan.note}
                </p>
                <ExternalLink
                  href={lineMessageUrl(plan.lineMessage)}
                  className={`btn mt-auto w-full ${best ? "btn-primary" : "btn-ghost"}`}
                >
                  <LineIcon />
                  {p.book}
                  <span className="sr-only"> ({plan.name})</span>
                </ExternalLink>
              </article>
            );
          })}
        </div>

        <div data-reveal className="mt-12 rounded-paper-alt bg-sage-soft px-6 py-6 sm:px-8">
          <h3 className="mb-4 text-lg">{p.includedTitle}</h3>
          <ul
            role="list"
            className="grid list-none gap-x-6 gap-y-2.5 [grid-template-columns:repeat(auto-fit,minmax(210px,1fr))]"
          >
            {p.included.map((item, i) => (
              <li key={i} className="flex items-start gap-2.5 leading-relaxed">
                <Check
                  className="mt-[0.3em] h-[1.1em] w-[1.1em] shrink-0 text-leaf"
                  strokeWidth={2.5}
                  aria-hidden="true"
                />
                {item}
              </li>
            ))}
          </ul>
          <p className="mb-0 mt-6 text-sm text-ink-soft">{p.finePrint}</p>
        </div>
      </div>
    </section>
  );
}
