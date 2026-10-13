import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { StickyCta } from "@/components/StickyCta";
import { Hero } from "@/components/sections/Hero";
import { Why } from "@/components/sections/Why";
import { Approach } from "@/components/sections/Approach";
import { Programs } from "@/components/sections/Programs";
import { Videos } from "@/components/sections/Videos";
import { Quote } from "@/components/sections/Quote";
import { Pricing } from "@/components/sections/Pricing";
import { Faq } from "@/components/sections/Faq";
import { Visit } from "@/components/sections/Visit";
import { CtaBand } from "@/components/sections/CtaBand";
import { useLanguage } from "@/i18n/LanguageProvider";
import { useReveal } from "@/hooks/useReveal";

/** The one-page site. Section order lives here; copy lives in src/content/site.tsx. */
export function HomePage() {
  const { lang, t } = useLanguage();
  useReveal(lang);

  return (
    <>
      <a
        href="#main"
        className="absolute top-[-100px] left-4 z-[100] rounded-full bg-ink px-5 py-3 font-semibold text-cream no-underline transition-[top] duration-200 focus:top-4 focus:text-cream"
      >
        {t.skipLink}
      </a>
      <Header />
      <main id="main" tabIndex={-1} className="outline-none">
        <Hero />
        <Why />
        <Approach />
        <Programs />
        <Videos />
        <Quote />
        <Pricing />
        <Faq />
        <Visit />
        <CtaBand />
      </main>
      <Footer />
      <StickyCta />
    </>
  );
}
