import { useState, type FormEvent } from "react";
import { useServerFn } from "@tanstack/react-start";
import { Copy, Check, Sparkles, LoaderCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { classCopy } from "@/content/admin/classes";
import { classDetailsSchema, emptyClass, type ClassDraft } from "@/lib/class-descriptions";
import { generateClassDescription } from "@/lib/class-descriptions.functions";

export function ClassDescriptionEditor() {
  const generate = useServerFn(generateClassDescription);
  const [details, setDetails] = useState(emptyClass);
  const [draft, setDraft] = useState<ClassDraft | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [copied, setCopied] = useState("");
  async function submit(event: FormEvent) {
    event.preventDefault();
    if (busy) return;
    const validated = classDetailsSchema.safeParse(details);
    if (!validated.success) { setError("กรุณากรอกชื่อคลาสและกิจกรรม และตรวจความยาวข้อมูลค่ะ"); return; }
    setBusy(true); setError(""); setCopied("");
    try {
      const result = await generate({ data: validated.data });
      if (result.ok) setDraft(result.draft);
      else setError(result.error);
    } catch { setError("ไม่สามารถเชื่อมต่อได้ ข้อมูลที่กรอกยังอยู่ กรุณาลองใหม่ค่ะ"); }
    finally { setBusy(false); }
  }
  async function copy(lang: "th" | "en") {
    if (!draft) return;
    try { await navigator.clipboard.writeText(draft[lang]); setCopied(lang); }
    catch { setError("คัดลอกอัตโนมัติไม่ได้ กรุณาเลือกและคัดลอกข้อความค่ะ"); }
  }
  return (
    <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
      <section aria-labelledby="class-details-heading">
        <h2 id="class-details-heading" className="mb-6 text-xl font-semibold">{classCopy.details}</h2>
        <form onSubmit={submit} className="space-y-5">
          <fieldset disabled={busy} className="space-y-5">
            {classCopy.fields.map(field => (
              <div key={field.key} className="space-y-2">
                <Label htmlFor={field.key}>{field.label}{field.required ? " *" : ""}</Label>
                {field.multiline ? <Textarea id={field.key} required={field.required} maxLength={field.key === "activities" ? 3000 : 1500} value={details[field.key]} onChange={e => setDetails({ ...details, [field.key]: e.target.value })} className="min-h-28 bg-card leading-relaxed" /> : <Input id={field.key} required={field.required} maxLength={field.key === "name" ? 200 : 1500} value={details[field.key]} onChange={e => setDetails({ ...details, [field.key]: e.target.value })} className="h-12 bg-card" />}
              </div>
            ))}
          </fieldset>
          <Button type="submit" disabled={busy} className="min-h-12 w-full whitespace-normal">{busy ? <LoaderCircle className="motion-safe:animate-spin" /> : <Sparkles />}{busy ? classCopy.generating : classCopy.generate}</Button>
        </form>
      </section>
      <section aria-labelledby="draft-heading" className="min-w-0 border-t border-border pt-8 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
        <div className="mb-6 flex items-center justify-between"><h2 id="draft-heading" className="text-xl font-semibold">{classCopy.draft}</h2><span className="text-sm text-muted-foreground">ไทย / English</span></div>
        <div role="status" aria-live="polite">{busy && <p className="mb-4 text-muted-foreground">{classCopy.generating}</p>}</div>
        {error && <p role="alert" className="mb-5 text-destructive">{error}</p>}
        {draft ? <div className="space-y-7">{(["th", "en"] as const).map(lang => <div key={lang} className="space-y-3"><div className="flex items-center justify-between"><Label htmlFor={`draft-${lang}`}>{lang === "th" ? "ภาษาไทย" : "English"}</Label><Button type="button" variant="outline" className="min-h-11" onClick={() => copy(lang)}>{copied === lang ? <Check /> : <Copy />}{copied === lang ? "คัดลอกแล้ว" : `คัดลอก${lang === "th" ? "ภาษาไทย" : "อังกฤษ"}`}</Button></div><Textarea id={`draft-${lang}`} lang={lang} value={draft[lang]} onChange={e => { setDraft({ ...draft, [lang]: e.target.value }); setCopied(""); }} className="min-h-80 bg-card leading-relaxed" /></div>)}<p className="text-sm text-muted-foreground">ฉบับร่างยังไม่ได้เผยแพร่บนเว็บไซต์</p></div> : <div className="flex min-h-80 items-center justify-center border border-dashed border-border text-muted-foreground">ยังไม่มีฉบับร่าง</div>}
      </section>
    </div>
  );
}