import { useEffect } from "react";

/**
 * Fades [data-reveal] elements in as they scroll into view.
 * Content stays visible when JS, IntersectionObserver or motion is unavailable:
 * elements are only hidden after `reveal-ready` is added to <html>.
 * Pass a value that changes when the page re-renders new content (e.g. the language)
 * so freshly mounted elements are picked up too.
 */
export function useReveal(rescanKey?: unknown) {
  useEffect(() => {
    const root = document.documentElement;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce || !("IntersectionObserver" in window)) return;

    const els = Array.from(document.querySelectorAll<HTMLElement>("[data-reveal]"));
    // Stagger siblings that share a parent
    const groups = new Map<Element | null, HTMLElement[]>();
    els.forEach((el) => {
      const list = groups.get(el.parentElement) ?? [];
      list.push(el);
      groups.set(el.parentElement, list);
    });
    groups.forEach((list) =>
      list.forEach((el, i) => el.style.setProperty("--reveal-delay", `${Math.min(i * 60, 300)}ms`)),
    );

    // Anything already on screen (or above it) shows immediately
    els.forEach((el) => {
      if (el.getBoundingClientRect().top < window.innerHeight) el.classList.add("is-visible");
    });

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.12 },
    );
    els.forEach((el) => {
      if (!el.classList.contains("is-visible")) observer.observe(el);
    });
    root.classList.add("reveal-ready");

    // Safety net: never leave content hidden (e.g. jump links, print)
    const reveal = () =>
      document
        .querySelectorAll<HTMLElement>("[data-reveal]")
        .forEach((el) => el.classList.add("is-visible"));
    window.addEventListener("hashchange", reveal);
    window.addEventListener("beforeprint", reveal);

    return () => {
      observer.disconnect();
      window.removeEventListener("hashchange", reveal);
      window.removeEventListener("beforeprint", reveal);
      root.classList.remove("reveal-ready");
    };
  }, [rescanKey]);
}
