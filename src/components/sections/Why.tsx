import { useLanguage } from "@/i18n/LanguageProvider";
import { Seaweed } from "../Decor";

export function Why() {
  const { t } = useLanguage();
  const w = t.why;

  return (
    <section id="why" aria-labelledby="why-title" className="section bg-peach">
      <Seaweed className="bottom-6 right-[-28px] h-28 w-14 rotate-12 text-sage md:bottom-auto md:right-[-20px] md:top-[10%] md:h-[180px] md:w-[90px]" />
      <div className="container-site relative z-10">
        <header data-reveal className="mb-12 max-w-[760px]">
          <p className="eyebrow">{w.eyebrow}</p>
          <h2 id="why-title" className="mb-6 text-h2">
            {w.title}
          </h2>
          <p className="section-lead">{w.lead}</p>
        </header>

        <ol role="list" className="grid list-none gap-6 lg:grid-cols-3">
          {w.cards.map((card, i) => (
            <li
              key={i}
              data-reveal
              className="relative rounded-paper border-2 border-ink bg-paper px-6 pb-6 pt-8 shadow-cut-peach"
            >
              <span
                aria-hidden="true"
                className="absolute -top-[18px] left-5 grid h-10 w-10 place-items-center rounded-full border-2 border-ink bg-mustard font-display font-bold"
              >
                {i + 1}
              </span>
              <h3 className="mb-2 text-h3">{card.title}</h3>
              <p className="m-0 text-ink-soft">{card.body}</p>
            </li>
          ))}
        </ol>

        <p
          data-reveal
          className="mb-0 mt-12 text-center font-display text-[clamp(1.3rem,1.05rem+1vw,1.75rem)] font-semibold leading-normal"
        >
          {w.punch}
        </p>
      </div>
    </section>
  );
}
