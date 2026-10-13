import type { ComponentType } from "react";
import { Check, ChefHat, Hand, MessageCircle, ShieldCheck } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import type { SiteContent } from "@/content/site";
import { CREATIVE_DRAMA_PLAYLIST_URL } from "@/content/business";
import { VIDEOS, formatPosted, type Video } from "@/content/videos";
import { DramaIcon } from "../icons";
import { Flower } from "../Decor";
import { ExternalLink } from "../ExternalLink";
import { Picture } from "../Picture";
import { YouTubeVideo } from "../YouTubeVideo";

type TeacherKey = "cherry" | "lee";

const TEACHER_STYLE: Record<
  TeacherKey,
  {
    photo: string;
    card: string;
    tilt: string;
    badge: string;
    role: string;
    Icon: ComponentType<{ className?: string }>;
  }
> = {
  cherry: {
    photo: "kru-cherry",
    card: "rounded-paper shadow-cut-cherry-soft",
    tilt: "-rotate-[1.5deg] shadow-[6px_6px_0_#F6D3DC]",
    badge: "bg-cherry-soft text-cherry-deep",
    role: "text-cherry-deep",
    Icon: DramaIcon,
  },
  lee: {
    photo: "uncle-lee",
    card: "rounded-paper-alt shadow-cut-blue-soft",
    tilt: "rotate-[1.5deg] shadow-[6px_6px_0_#DCE4F4]",
    badge: "bg-dusty-soft text-dusty-ink",
    role: "text-dusty-ink",
    Icon: ChefHat,
  },
};

function TeacherCard({
  id,
  teacher,
}: {
  id: TeacherKey;
  teacher: SiteContent["approach"]["cherry"];
}) {
  const s = TEACHER_STYLE[id];
  return (
    <article data-reveal className={`relative border-2 border-ink bg-paper p-6 pt-6 ${s.card}`}>
      <figure
        className={`relative m-0 mb-6 overflow-hidden rounded-[18px] border-2 border-ink bg-cream ${s.tilt}`}
      >
        <Picture
          name={s.photo}
          widths={[480, 800]}
          fallback={800}
          sizes="(min-width: 1024px) 420px, 88vw"
          width={800}
          height={1000}
          alt={teacher.photoAlt}
          className="aspect-square h-auto w-full object-cover object-top"
        />
        <span
          aria-hidden="true"
          className={`absolute bottom-3 right-3 grid h-14 w-14 place-items-center rounded-full border-2 border-ink ${s.badge}`}
        >
          <s.Icon className="h-7 w-7" />
        </span>
      </figure>
      <p className={`mb-1 text-[0.9375rem] font-semibold tracking-[0.02em] ${s.role}`}>
        {teacher.role}
      </p>
      <h3 className="mb-0 text-[clamp(1.5rem,1.2rem+1vw,1.9rem)]">{teacher.name}</h3>
      <p lang={id === "cherry" ? "th" : "en"} className="mb-6 text-[0.9375rem] text-ink-soft">
        {teacher.fullName}
      </p>
      <ul role="list" className="grid list-none gap-2.5">
        {teacher.points.map((p, i) => (
          <li key={i} className="flex items-start gap-2.5 leading-relaxed">
            <Check
              className="mt-[0.3em] h-[1.1em] w-[1.1em] shrink-0 text-leaf"
              strokeWidth={2.5}
              aria-hidden="true"
            />
            <span>{p}</span>
          </li>
        ))}
      </ul>
    </article>
  );
}

function VideoCaption({ video }: { video: Video }) {
  const { lang, t } = useLanguage();
  return (
    <figcaption className="mt-4">
      <p className="mb-1 font-display font-semibold leading-snug">{video.title[lang]}</p>
      <p className="m-0 text-sm text-ink-soft">
        {video.duration} · {t.videos.spoken[video.spoken]} · {t.videos.posted}{" "}
        {formatPosted(video.posted, lang)}
      </p>
    </figcaption>
  );
}

/** The founders' conversation (16:9) beside Uncle Lee's short (9:16), at the same height. */
function TeacherVoices({ voices }: { voices: SiteContent["approach"]["voices"] }) {
  return (
    <div
      data-reveal
      className="mt-12 rounded-paper-alt border-2 border-dashed border-ink bg-paper p-6 sm:p-8"
    >
      <h3 className="mb-6 text-h3">{voices.title}</h3>
      <div className="grid items-start gap-8 sm:grid-cols-[minmax(0,3.16fr)_minmax(0,1fr)] sm:gap-6">
        <figure className="m-0">
          <YouTubeVideo
            video={VIDEOS.founders}
            sizes="(min-width: 1244px) 780px, (min-width: 640px) 68vw, 88vw"
            frameClassName="rounded-[18px] border-2 border-ink"
          />
          <VideoCaption video={VIDEOS.founders} />
        </figure>
        <figure className="m-0 mx-auto w-full max-w-[240px] sm:max-w-none">
          <YouTubeVideo
            video={VIDEOS.threeJars}
            sizes="(min-width: 1244px) 250px, (min-width: 640px) 22vw, 240px"
            frameClassName="rounded-[18px] border-2 border-ink"
          />
          <VideoCaption video={VIDEOS.threeJars} />
        </figure>
      </div>
      <p className="mb-0 mt-6 border-t-2 border-dashed border-peach-deep pt-5">
        {voices.series.lead}{" "}
        <ExternalLink href={CREATIVE_DRAMA_PLAYLIST_URL} className="font-semibold">
          {voices.series.link}
        </ExternalLink>{" "}
        {voices.series.note}
      </p>
    </div>
  );
}

const PRINCIPLE_FALLBACK = { Icon: ShieldCheck, cls: "bg-dusty-soft text-dusty-ink" };
const PRINCIPLE_STYLE = [
  { Icon: ShieldCheck, cls: "bg-dusty-soft text-dusty-ink" },
  { Icon: Hand, cls: "bg-mustard-soft text-mustard-ink" },
  { Icon: MessageCircle, cls: "bg-sage-soft text-leaf" },
];

export function Approach() {
  const { t } = useLanguage();
  const a = t.approach;

  return (
    <section id="approach" aria-labelledby="approach-title" className="section">
      <Flower className="bottom-[8%] left-[-50px] h-[130px] w-[130px] -rotate-12 animate-float text-dusty opacity-85" />
      <div className="container-site relative z-10">
        <header data-reveal className="mb-12 max-w-[760px]">
          <p className="eyebrow">{a.eyebrow}</p>
          <h2 id="approach-title" className="mb-6 text-h2">
            {a.title}
          </h2>
          <p className="section-lead">{a.lead}</p>
        </header>

        <div className="grid items-stretch gap-8 lg:grid-cols-[1fr_auto_1fr] lg:gap-6">
          <TeacherCard id="cherry" teacher={a.cherry} />
          <div aria-hidden="true" className="hidden place-items-center lg:grid">
            <img
              src="/images/logo-mark.png"
              width={215}
              height={226}
              alt=""
              loading="lazy"
              className="h-auto w-20"
            />
          </div>
          <TeacherCard id="lee" teacher={a.lee} />
        </div>

        <TeacherVoices voices={a.voices} />

        <ul role="list" className="mt-12 grid list-none gap-6 lg:grid-cols-3">
          {a.principles.map((p, i) => {
            const { Icon, cls } = PRINCIPLE_STYLE[i % PRINCIPLE_STYLE.length] ?? PRINCIPLE_FALLBACK;
            return (
              <li
                data-reveal
                key={i}
                className="flex items-start gap-6 rounded-paper-alt bg-peach p-6 lg:flex-col lg:gap-4"
              >
                <span
                  aria-hidden="true"
                  className={`grid h-[52px] w-[52px] shrink-0 place-items-center rounded-[16px_20px_14px_22px] border-2 border-ink ${cls}`}
                >
                  <Icon className="h-[26px] w-[26px]" />
                </span>
                <div>
                  <h3 className="mb-1 text-h3">{p.title}</h3>
                  {p.term && (
                    <p
                      lang="en"
                      className="mb-2 font-display text-[0.9375rem] font-medium text-ink-soft"
                    >
                      {p.term}
                    </p>
                  )}
                  <p className="m-0 text-ink-soft">{p.body}</p>
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
