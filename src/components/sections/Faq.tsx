import { ChevronDown } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";

export function Faq() {
  const { t } = useLanguage();
  const f = t.faq;

  return (
    <section id="faq" aria-labelledby="faq-title" className="section bg-peach">
      <div className="container-site relative z-10">
        <div className="mx-auto max-w-[820px]">
          <header data-reveal className="mx-auto mb-12 text-center">
            <p className="eyebrow">{f.eyebrow}</p>
            <h2 id="faq-title" className="mb-0 text-h2">
              {f.title}
            </h2>
          </header>

          <div className="grid gap-2">
            {f.items.map((item, i) => (
              <details
                key={i}
                data-reveal
                className="group rounded-[20px] border-2 border-ink bg-paper transition-shadow duration-200 open:shadow-cut-faq"
              >
                <summary className="flex min-h-14 cursor-pointer list-none items-center justify-between gap-6 rounded-[18px] px-5 py-3 font-display text-[1.075rem] font-semibold leading-snug hover:text-cherry-deep">
                  {item.q}
                  <ChevronDown
                    className="h-5 w-5 shrink-0 transition-transform duration-200 group-open:rotate-180"
                    aria-hidden="true"
                  />
                </summary>
                <div className="px-5 pb-5 text-ink-soft">
                  <p className="m-0">{item.a}</p>
                </div>
              </details>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
