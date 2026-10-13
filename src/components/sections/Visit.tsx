import { CalendarDays, Mail, Navigation, SquareArrowOutUpRight } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { EMAIL, LINE_ID, LINE_URL, MAP } from "@/content/business";
import { LineIcon } from "../icons";
import { ExternalLink } from "../ExternalLink";

export function Visit() {
  const { lang, t } = useLanguage();
  const v = t.visit;

  return (
    <section id="visit" aria-labelledby="visit-title" className="section">
      <div className="container-site relative z-10 grid items-center gap-12 lg:grid-cols-[1fr_1.15fr]">
        <div data-reveal>
          <p className="eyebrow">{v.eyebrow}</p>
          <h2 id="visit-title" className="mb-6 text-h2">
            {v.title}
          </h2>
          <address className="mb-6 text-lg not-italic leading-relaxed">
            <strong>CherryLee &amp; Co.{v.nameSuffix ? ` ${v.nameSuffix}` : ""}</strong>
            <br />
            {v.address}
          </address>
          <ul role="list" className="mb-8 grid list-none gap-1">
            <li className="flex min-h-11 items-center gap-2.5">
              <CalendarDays className="h-5 w-5 shrink-0 text-cherry" aria-hidden="true" />
              {v.hours}
            </li>
            <li className="flex items-center gap-2.5">
              <LineIcon className="h-5 w-5 shrink-0 text-cherry" />
              <ExternalLink href={LINE_URL} className="inline-flex min-h-11 items-center">
                LINE {LINE_ID}
              </ExternalLink>
            </li>
            <li className="flex items-center gap-2.5">
              <Mail className="h-5 w-5 shrink-0 text-cherry" aria-hidden="true" />
              <a href={`mailto:${EMAIL}`} className="inline-flex min-h-11 items-center">
                {EMAIL}
              </a>
            </li>
          </ul>
          <div className="flex flex-wrap gap-x-6 gap-y-3">
            <ExternalLink href={MAP.directionsUrl} className="btn btn-primary">
              <Navigation aria-hidden="true" />
              {v.directions}
            </ExternalLink>
            <ExternalLink href={MAP.pinUrl} className="btn btn-ghost">
              <SquareArrowOutUpRight aria-hidden="true" />
              {v.openPin}
            </ExternalLink>
          </div>
        </div>

        <div
          data-reveal
          className="aspect-[4/3] overflow-hidden rounded-paper-alt border-2 border-ink bg-dusty-soft shadow-cut-sage-ink"
        >
          <iframe
            key={lang}
            src={MAP.embedUrl(lang)}
            title={v.mapTitle}
            loading="lazy"
            referrerPolicy="strict-origin-when-cross-origin"
            allowFullScreen
            className="h-full w-full border-0"
          />
        </div>
      </div>
    </section>
  );
}
