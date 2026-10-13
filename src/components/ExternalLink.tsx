import type { AnchorHTMLAttributes, ReactNode } from "react";
import { useLanguage } from "@/i18n/LanguageProvider";

type ExternalLinkProps = AnchorHTMLAttributes<HTMLAnchorElement> & {
  href: string;
  children: ReactNode;
};

/** Opens in a new tab and tells screen-reader users so (LINE, Messenger, Maps, Facebook). */
export function ExternalLink({ children, ...props }: ExternalLinkProps) {
  const { t } = useLanguage();
  return (
    <a target="_blank" rel="noopener noreferrer" {...props}>
      {children}
      <span className="sr-only">{t.newTab}</span>
    </a>
  );
}
