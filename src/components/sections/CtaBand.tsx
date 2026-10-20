import { useLanguage } from "@/i18n/LanguageProvider";
import { LineIcon, MessengerIcon } from "../icons";
import { ExternalLink } from "../ExternalLink";
import { Flower, Seaweed } from "../Decor";

export function CtaBand() {
  const { t, business, images } = useLanguage();
  const c = t.cta;

  return (
    <section
      id="book"
      aria-labelledby="book-title"
      className="relative overflow-hidden bg-cherry py-16 text-center text-white md:py-24 [&_:focus-visible]:outline-white"
    >
      <Flower className="left-[-40px] top-[-30px] h-40 w-40 animate-float text-cherry-light" />
      <Seaweed className="bottom-[-30px] right-[2%] h-[180px] w-[90px] -rotate-[8deg] text-[#C9506F]" />
      <div className="container-site relative z-10">
        <div data-reveal className="mx-auto max-w-[760px]">
          <img
            src={images['logo-mark-white'] ?? "/images/logo-mark-white.png"}
            width={215}
            height={226}
            alt=""
            loading="lazy"
            className="mx-auto mb-6 h-16 w-auto"
          />
          <h2 id="book-title" className="mb-6 text-h2 text-white">
            {c.title}
          </h2>
          <p className="text-lg text-[#FFF1F4]">{c.body}</p>
          <div className="mt-8 flex flex-wrap justify-center gap-x-6 gap-y-3">
            <ExternalLink href={business.lineUrl} className="btn btn-light btn-lg">
              <LineIcon />
              {c.line}
            </ExternalLink>
            <ExternalLink href={business.messenger} className="btn btn-outline-light btn-lg">
              <MessengerIcon />
              {c.messenger}
            </ExternalLink>
          </div>
        </div>
      </div>
    </section>
  );
}
