import { useLanguage } from "@/i18n/LanguageProvider";
import { YOUTUBE_URL } from "@/content/business";
import { CLASS_VIDEOS, formatPosted } from "@/content/videos";
import { ExternalLink } from "../ExternalLink";
import { YouTubeVideo } from "../YouTubeVideo";
import { YouTubeIcon } from "../icons";
import { Star } from "../Decor";

const FRAME_STYLE = [
  "rounded-paper shadow-cut-blue",
  "rounded-paper-alt shadow-cut-mustard",
  "rounded-paper shadow-cut-sage",
  "rounded-paper-alt shadow-cut-peach",
];

export function Videos() {
  const { lang, t } = useLanguage();
  const v = t.videos;

  if (CLASS_VIDEOS.length === 0) return null;

  return (
    <section id="videos" aria-labelledby="videos-title" className="section">
      <Star className="right-4 top-6 h-[30px] w-[30px] text-mustard lg:right-[6%] lg:top-[10%]" />
      <div className="container-site relative z-10">
        <header data-reveal className="mx-auto mb-12 max-w-[760px] text-center">
          <p className="eyebrow">{v.eyebrow}</p>
          <h2 id="videos-title" className="mb-6 text-h2">
            {v.title}
          </h2>
          <p className="section-lead">{v.lead}</p>
        </header>

        <ul
          role="list"
          className="grid list-none grid-cols-2 gap-x-4 gap-y-10 sm:gap-x-8 lg:grid-cols-4"
        >
          {CLASS_VIDEOS.map((video, i) => {
            const program = t.programs.items.find((p) => p.key === video.program)?.title;
            return (
              <li key={video.id} data-reveal className="flex flex-col">
                <YouTubeVideo
                  video={video}
                  sizes="(min-width: 1024px) 270px, 45vw"
                  frameClassName={`border-2 border-ink ${FRAME_STYLE[i % FRAME_STYLE.length] ?? ""}`}
                />
                <div className="mt-5">
                  {program && (
                    <p
                      lang="en"
                      className="mb-2 inline-block rounded-full bg-cherry-soft px-3 py-0.5 text-sm font-semibold text-cherry-deep"
                    >
                      {program}
                    </p>
                  )}
                  <h3 className="mb-1 text-[1.0625rem] leading-snug sm:text-lg">
                    {video.title[lang]}
                  </h3>
                  <p className="m-0 text-sm text-ink-soft">
                    {video.duration} · {v.spoken[video.spoken]} · {v.posted}{" "}
                    {formatPosted(video.posted, lang)}
                  </p>
                </div>
              </li>
            );
          })}
        </ul>

        <div data-reveal className="mt-12 flex flex-col items-center gap-4 text-center">
          <ExternalLink href={YOUTUBE_URL} className="btn btn-ghost">
            <YouTubeIcon />
            {v.more}
          </ExternalLink>
          <p className="m-0 max-w-[42em] text-sm text-ink-soft">{v.note}</p>
        </div>
      </div>
    </section>
  );
}
