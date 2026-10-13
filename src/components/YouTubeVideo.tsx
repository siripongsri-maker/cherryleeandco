import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { Play } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import type { Video } from "@/content/videos";
import { Picture } from "./Picture";

// Only one video plays at a time: starting one turns any other back into its poster.
let activeId: string | null = null;
const listeners = new Set<() => void>();
const subscribe = (listener: () => void) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};
const play = (id: string) => {
  activeId = id;
  listeners.forEach((listener) => listener());
};

const SHAPE = {
  vertical: { widths: [360, 540], fallback: 540, width: 540, height: 960, aspect: "aspect-[9/16]" },
  wide: { widths: [640, 960], fallback: 960, width: 960, height: 540, aspect: "aspect-video" },
} as const;

/**
 * A YouTube clip that shows a poster until someone presses play, then loads the player from
 * youtube-nocookie.com. The page stays light and YouTube sets nothing before that click.
 * `frameClassName` styles the visible frame (border, radius, shadow).
 */
export function YouTubeVideo({
  video,
  sizes,
  frameClassName = "",
}: {
  video: Video;
  sizes: string;
  frameClassName?: string;
}) {
  const { lang, t } = useLanguage();
  const playing = useSyncExternalStore(
    subscribe,
    () => activeId === video.id,
    () => false,
  );
  // Player language is fixed when play is pressed, so switching language doesn't restart it
  const [playerLang, setPlayerLang] = useState(lang);
  const frameRef = useRef<HTMLIFrameElement>(null);
  const shape = SHAPE[video.shape];
  const title = video.title[lang];

  // Keep keyboard focus on the video once the poster button is replaced by the player
  useEffect(() => {
    if (playing) frameRef.current?.focus();
  }, [playing]);

  const frame = `absolute inset-0 h-full w-full overflow-hidden bg-ink ${frameClassName}`;

  return (
    <div className={`relative ${shape.aspect}`}>
      {playing ? (
        <iframe
          ref={frameRef}
          src={`https://www.youtube-nocookie.com/embed/${video.id}?autoplay=1&rel=0&playsinline=1&hl=${playerLang}`}
          title={`YouTube: ${title}`}
          allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
          allowFullScreen
          referrerPolicy="strict-origin-when-cross-origin"
          className={`${frame} border-0`}
        />
      ) : (
        <button
          type="button"
          onClick={() => {
            setPlayerLang(lang);
            play(video.id);
          }}
          className={`group block cursor-pointer p-0 ${frame}`}
        >
          <Picture
            name={`videos/${video.poster}`}
            widths={[...shape.widths]}
            fallback={shape.fallback}
            sizes={sizes}
            width={shape.width}
            height={shape.height}
            alt=""
            className="h-full w-full object-cover transition-transform duration-300 ease-paper group-hover:scale-[1.03]"
          />
          <span
            aria-hidden="true"
            className="absolute left-1/2 top-1/2 grid h-16 w-16 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full border-2 border-ink bg-cherry text-white shadow-[0_4px_0_var(--ink)] transition-transform duration-200 ease-paper group-hover:scale-110"
          >
            <Play className="ml-1 h-7 w-7 fill-current" />
          </span>
          <span className="sr-only">
            {t.videos.play}: {title}
          </span>
        </button>
      )}
    </div>
  );
}
