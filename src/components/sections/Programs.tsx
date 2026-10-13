import { ChefHat, Lightbulb, MessageCircle, Puzzle, Users } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageProvider";
import { DramaIcon } from "../icons";
import { HeartLeaf } from "../Decor";
import { Picture } from "../Picture";

const PROGRAM_STYLE = {
  story: { image: "story-playlit", card: "rounded-paper shadow-cut-blue", Lead: DramaIcon },
  cooking: { image: "basic-cooking", card: "rounded-paper-alt shadow-cut-mustard", Lead: ChefHat },
  money: { image: "money-wise", card: "rounded-paper shadow-cut-sage", Lead: ChefHat },
} as const;

const SKILL_ICONS = [Lightbulb, Puzzle, MessageCircle, Users];

export function Programs() {
  const { t } = useLanguage();
  const p = t.programs;

  return (
    <section id="programs" aria-labelledby="programs-title" className="section bg-peach">
      <HeartLeaf className="right-2.5 top-1.5 h-[52px] w-[52px] rotate-[18deg] animate-float-slow text-coral sm:right-[4%] sm:top-3 sm:h-[90px] sm:w-[90px]" />
      <div className="container-site relative z-10">
        <header data-reveal className="mx-auto mb-12 max-w-[760px] text-center">
          <p lang="en" className="eyebrow">
            {p.eyebrow}
          </p>
          <h2 id="programs-title" className="mb-6 text-h2">
            {p.title}
          </h2>
          <p className="section-lead">{p.lead}</p>
        </header>

        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {p.items.map((item, i) => {
            const s = PROGRAM_STYLE[item.key];
            const isLastOdd = i === p.items.length - 1 && p.items.length % 2 === 1;
            return (
              <article
                key={item.key}
                data-reveal
                className={`flex flex-col overflow-hidden border-2 border-ink bg-paper ${s.card} ${
                  isLastOdd
                    ? "sm:col-span-2 sm:mx-auto sm:w-[calc(50%-1rem)] lg:col-span-1 lg:w-auto"
                    : ""
                }`}
              >
                <div className="aspect-square overflow-hidden border-b-2 border-ink">
                  <Picture
                    name={s.image}
                    widths={[480, 800]}
                    fallback={800}
                    sizes="(min-width: 1024px) 30vw, (min-width: 640px) 45vw, 92vw"
                    width={800}
                    height={800}
                    alt={item.imgAlt}
                    className="h-full w-full object-cover"
                  />
                </div>
                <div className="flex flex-1 flex-col p-6">
                  <p className="mb-1 text-[0.9375rem] font-semibold text-cherry-deep">
                    {item.kicker}
                  </p>
                  <h3 lang="en" className="mb-2 text-[1.6rem]">
                    {item.title}
                  </h3>
                  <p className="text-ink-soft">{item.body}</p>
                  {item.stories && (
                    <p className="mb-4 rounded-[14px] bg-dusty-soft px-3.5 py-2.5 text-[0.9375rem] leading-relaxed">
                      <span className="mr-1.5 font-semibold">{item.stories.label}</span>
                      <em lang="en">{item.stories.list}</em>
                    </p>
                  )}
                  <p className="mb-0 mt-auto inline-flex items-center gap-2 pt-2 text-[0.9375rem] font-semibold">
                    <s.Lead className="h-5 w-5 text-cherry" aria-hidden="true" />
                    {item.ledBy}
                  </p>
                </div>
              </article>
            );
          })}
        </div>

        <div
          data-reveal
          className="mt-12 rounded-paper-alt border-2 border-dashed border-ink bg-paper p-6 text-center"
        >
          <p className="mb-6 font-display text-xl font-semibold">{p.skillsTitle}</p>
          <ul role="list" className="grid list-none grid-cols-2 gap-6 sm:grid-cols-4">
            {p.skills.map((skill, i) => {
              const Icon = SKILL_ICONS[i % SKILL_ICONS.length] ?? Lightbulb;
              return (
                <li
                  key={skill.en}
                  className="flex flex-col items-center gap-1 font-display font-semibold leading-tight"
                >
                  <Icon className="mb-1 h-[30px] w-[30px] text-cherry" aria-hidden="true" />
                  <span lang="en">{skill.en}</span>
                  {skill.th && (
                    <small className="font-sans text-sm font-normal text-ink-soft">
                      {skill.th}
                    </small>
                  )}
                </li>
              );
            })}
          </ul>
        </div>
      </div>
    </section>
  );
}
