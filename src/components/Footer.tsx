import { Mail } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import {
  EMAIL,
  FACEBOOK_URL,
  INSTAGRAM_URL,
  LINE_URL,
  TIKTOK_URL,
  YOUTUBE_URL,
} from "@/content/business";
import { FacebookIcon, InstagramIcon, LineIcon, TikTokIcon, YouTubeIcon } from "./icons";

export function Footer() {
  const { t } = useLanguage();
  const f = t.footer;
  const links = t.nav.items.filter((i) => i.href !== "#faq");
  const social = [
    { href: LINE_URL, label: "LINE", Icon: LineIcon, external: true },
    { href: FACEBOOK_URL, label: "Facebook", Icon: FacebookIcon, external: true },
    { href: YOUTUBE_URL, label: "YouTube", Icon: YouTubeIcon, external: true },
    { href: INSTAGRAM_URL, label: "Instagram", Icon: InstagramIcon, external: true },
    { href: TIKTOK_URL, label: "TikTok", Icon: TikTokIcon, external: true },
    { href: `mailto:${EMAIL}`, label: f.email, Icon: Mail, external: false },
  ];

  return (
    <footer className="bg-ink pb-8 pt-12 text-[#E9E2DA] [&_:focus-visible]:outline-cherry-soft">
      <div className="container-site grid gap-8 sm:grid-cols-[1.6fr_1fr_1fr]">
        <div>
          <a href="#top" aria-label={t.brand.topLabel} className="mb-2 inline-block">
            <img
              src="/images/logo-stacked.png"
              width={395}
              height={317}
              alt=""
              loading="lazy"
              className="h-auto w-[150px]"
            />
          </a>
          <p className="max-w-[30em] text-ink-muted">{f.tagline}</p>
        </div>
        <nav aria-label={f.navLabel}>
          <ul role="list" className="grid list-none gap-0.5">
            {links.map((l) => (
              <li key={l.href}>
                <a
                  href={l.href}
                  className="inline-flex min-h-11 min-w-11 items-center text-white no-underline hover:text-white hover:underline"
                >
                  {l.label}
                </a>
              </li>
            ))}
          </ul>
        </nav>
        <div>
          <p className="mb-2 font-display font-semibold text-white">{f.follow}</p>
          <ul role="list" className="flex max-w-[168px] list-none flex-wrap gap-2">
            {social.map(({ href, label, Icon, external }) => (
              <li key={label}>
                <a
                  href={href}
                  aria-label={external ? `${label}${t.newTab}` : label}
                  {...(external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                  className="grid h-12 w-12 place-items-center rounded-full border-2 border-[#6B5C53] text-white transition-colors duration-200 hover:border-cherry hover:bg-cherry hover:text-white"
                >
                  <Icon className="h-[22px] w-[22px]" aria-hidden="true" />
                </a>
              </li>
            ))}
          </ul>
        </div>
      </div>
      <div className="container-site mt-12 flex flex-wrap justify-between gap-2 border-t border-ink-line pt-6 text-sm text-ink-muted">
        <p className="m-0">© {new Date().getFullYear()} CherryLee &amp; Co.</p>
        <p className="m-0">{f.credit}</p>
      </div>
    </footer>
  );
}
