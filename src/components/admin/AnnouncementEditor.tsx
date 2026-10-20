import { useState, type FormEvent } from "react";
import { useServerFn } from "@tanstack/react-start";
import { Check, Copy, LoaderCircle, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { announcementCopy as copy } from "@/content/admin/announcements";
import { announcementNotesSchema } from "@/lib/announcements";
import { generateAnnouncement } from "@/lib/announcements.functions";

export function AnnouncementEditor() {
  const generate = useServerFn(generateAnnouncement);
  const [notes, setNotes] = useState("");
  const [draft, setDraft] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [copied, setCopied] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (busy) return;
    const validated = announcementNotesSchema.safeParse({ notes });
    if (!validated.success) { setError(copy.invalid); return; }
    setBusy(true); setError(""); setCopied(false);
    try {
      const result = await generate({ data: validated.data });
      if (result.ok) setDraft(result.draft.th);
      else setError(result.error);
    } catch { setError(copy.connection); }
    finally { setBusy(false); }
  }
  async function copyDraft() {
    if (!draft) return;
    try { await navigator.clipboard.writeText(draft); setCopied(true); }
    catch { setError(copy.clipboard); }
  }

  return <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
    <section aria-labelledby="announcement-notes-heading" className="min-w-0">
      <h2 id="announcement-notes-heading" className="mb-6 text-xl font-semibold">{copy.title}</h2>
      <form onSubmit={submit} className="space-y-5">
        <div className="space-y-2"><Label htmlFor="announcement-notes">{copy.notes}</Label><Textarea id="announcement-notes" lang="th" required maxLength={3000} disabled={busy} value={notes} onChange={event => setNotes(event.target.value)} placeholder={copy.placeholder} className="min-h-64 bg-card leading-relaxed" /></div>
        <Button type="submit" disabled={busy} className="min-h-12 w-full whitespace-normal">{busy ? <LoaderCircle className="motion-safe:animate-spin" /> : <Sparkles />}{busy ? copy.generating : copy.generate}</Button>
      </form>
    </section>
    <section aria-labelledby="announcement-draft-heading" className="min-w-0 border-t border-border pt-8 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3"><h2 id="announcement-draft-heading" className="text-xl font-semibold">{copy.draft}</h2>{draft !== null && <Button type="button" variant="outline" disabled={busy || !draft.trim()} className="min-h-11" onClick={copyDraft}>{copied ? <Check /> : <Copy />}{copied ? copy.copied : copy.copy}</Button>}</div>
      <div role="status" aria-live="polite">{busy && <p className="mb-4 text-muted-foreground">{copy.generating}</p>}</div>
      {error && <p role="alert" className="mb-5 text-destructive">{error}</p>}
      {draft !== null ? <div className="space-y-3"><Label htmlFor="announcement-draft" className="sr-only">{copy.draft}</Label><Textarea id="announcement-draft" lang="th" disabled={busy} maxLength={12000} value={draft} onChange={event => { setDraft(event.target.value); setCopied(false); }} className="min-h-96 bg-card leading-relaxed" /><p className="text-sm text-muted-foreground">{copy.unpublished}</p></div> : <div className="flex min-h-80 items-center justify-center border border-dashed border-border text-muted-foreground">{copy.empty}</div>}
    </section>
  </div>;
}