import { useEffect, useRef, useState, type FormEvent } from "react";
import { useServerFn } from "@tanstack/react-start";
import { queryOptions, useQueryClient, useSuspenseQuery } from "@tanstack/react-query";
import { Save, Upload, RotateCcw, LoaderCircle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { supabase } from "@/integrations/supabase/client";
import { homepageSections, fieldLabels, imageSlots } from "@/content/admin/homepage";
import { defaultText, editablePaths, homepageSchema, validHomepageImage, type HomepageData } from "@/lib/homepage-content";
import { getHomepage, saveHomepage } from "@/lib/homepage-content.functions";
import { BusinessSettingsFields } from "./BusinessSettingsFields";

export const homepageQuery = queryOptions({ queryKey: ["homepage-content"], queryFn: () => getHomepage(), staleTime: 0 });
export function HomepageEditor() {
  const { data: saved } = useSuspenseQuery(homepageQuery);
  const [form, setForm] = useState<HomepageData>(saved);
  const [section, setSection] = useState(0);
  const [busy, setBusy] = useState(false);
  const [uploading, setUploading] = useState("");
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [confirmed, setConfirmed] = useState(false);
  const [previews, setPreviews] = useState<Record<string,string>>({});
  const previewRefs = useRef<string[]>([]);
  const save = useServerFn(saveHomepage);
  const queryClient = useQueryClient();
  useEffect(() => () => { previewRefs.current.forEach(url => URL.revokeObjectURL(url)); }, []);
  function edit(path: string, lang: "th" | "en", value: string) {
    const pair = form.texts[path] ?? { th: defaultText(path, "th"), en: defaultText(path, "en") };
    setForm({ ...form, texts: { ...form.texts, [path]: { ...pair, [lang]: value } } }); setNotice("");
  }
  async function upload(slot: string, file: File | undefined) {
    if (!file) return;
    if (!confirmed) { setError("กรุณายืนยันสิทธิ์เผยแพร่รูปก่อนค่ะ"); return; }
    if (!validHomepageImage(file)) { setError("ใช้ไฟล์ JPG, PNG หรือ WebP ขนาดไม่เกิน 5 MB ค่ะ"); return; }
    setUploading(slot); setError(""); setNotice("");
    const extension = file.type === "image/jpeg" ? "jpg" : file.type === "image/png" ? "png" : "webp";
    const path = `${crypto.randomUUID()}.${extension}`;
    try {
      const { error: uploadError } = await supabase.storage.from("homepage-images").upload(path, file, { contentType: file.type, upsert: false });
      if (uploadError) throw uploadError;
      const url = URL.createObjectURL(file); previewRefs.current.push(url);
      setPreviews(current => ({ ...current, [slot]: url }));
      setForm(current => ({ ...current, images: { ...current.images, [slot]: path } }));
    } catch { setError("อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่ค่ะ"); }
    finally { setUploading(""); }
  }
  async function submit(event: FormEvent) {
    event.preventDefault();
    if (busy || uploading) return;
    const parsed = homepageSchema.safeParse({ texts: form.texts, images: form.images, settings: form.settings, version: form.version });
    if (!parsed.success) { setError("กรุณาตรวจข้อความสองภาษา ลิงก์ติดต่อ ค่าเรียน และเวลาเปิดให้ถูกต้องค่ะ"); return; }
    setBusy(true); setError(""); setNotice("");
    try {
      const result = await save({ data: { ...parsed.data, imagePermissionConfirmed: confirmed } });
      if (!result.ok) { setError(result.error); return; }
      setForm(current => ({ ...current, version: result.version }));
      await queryClient.invalidateQueries({ queryKey: ["homepage-content"] });
      setNotice("บันทึกแล้ว การเปลี่ยนแปลงแสดงบนหน้าแรกค่ะ");
    } catch { setError("บันทึกไม่สำเร็จ ข้อมูลที่แก้ไขยังอยู่ค่ะ"); }
    finally { setBusy(false); }
  }
  async function reload() {
    if (!window.confirm("โหลดข้อมูลล่าสุดและทิ้งสิ่งที่ยังไม่ได้บันทึกหรือไม่คะ?")) return;
    setBusy(true); setError("");
    try { const latest = await queryClient.fetchQuery(homepageQuery); setForm(latest); setPreviews({}); setNotice("โหลดข้อมูลล่าสุดแล้วค่ะ"); }
    catch { setError("โหลดข้อมูลไม่สำเร็จค่ะ"); } finally { setBusy(false); }
  }
  return <form onSubmit={submit} className="space-y-8">
    <div className="flex flex-wrap items-center justify-between gap-3"><h2 className="text-xl font-semibold">จัดการข้อมูลเว็บไซต์</h2><div className="flex flex-wrap gap-2"><Button type="button" variant="outline" disabled={busy || !!uploading} className="min-h-11" onClick={reload}><RefreshCw />โหลดข้อมูลล่าสุด</Button><Button type="submit" disabled={busy || !!uploading} className="min-h-11">{busy ? <LoaderCircle className="motion-safe:animate-spin" /> : <Save />}บันทึกข้อมูลเว็บไซต์</Button></div></div>
    {error && <p role="alert" className="text-destructive">{error}</p>}<p role="status" aria-live="polite" className="text-primary">{notice}</p>
    <div role="tablist" aria-label="ส่วนของเว็บไซต์" className="flex flex-wrap gap-2 border-b border-border pb-4">{[...homepageSections.map(item => item.label), "รูปภาพ", "ค่าเรียน ช่องทางติดต่อ และวิดีโอ"].map((label,index) => <Button key={label} type="button" role="tab" id={`home-tab-${index}`} aria-controls="home-panel" aria-selected={section === index} variant={section === index ? "default" : "outline"} className="min-h-11 whitespace-normal" onClick={() => setSection(index)}>{label}</Button>)}</div>
    <fieldset disabled={busy || !!uploading} id="home-panel" role="tabpanel" aria-labelledby={`home-tab-${section}`} className="space-y-8 min-w-0">
      {section === homepageSections.length + 1 ? <BusinessSettingsFields value={form.settings} onChange={settings => { setForm({ ...form, settings }); setNotice(""); }} /> : section < homepageSections.length ? homepageSections[section]?.paths.filter(path => editablePaths.includes(path)).map((path,index) => {
        const parts = path.split("."); const last = parts.at(-1) ?? ""; const label = fieldLabels[last] ?? (parts.includes("facts") ? "ข้อมูลคลาส" : "ประสบการณ์คุณครู");
        return <div key={path} className="space-y-4 border-b border-border pb-7"><div className="flex flex-wrap items-center justify-between gap-2"><h3 className="text-base font-semibold">{label} {index + 1}</h3><Button type="button" variant="ghost" aria-label={`คืนข้อความเดิม ${label} ${index + 1}`} title="คืนข้อความเดิม" className="h-11 w-11" onClick={() => { const texts = { ...form.texts }; delete texts[path]; setForm({ ...form, texts }); setNotice(""); }}><RotateCcw /></Button></div><div className="grid gap-5 md:grid-cols-2">{(["th","en"] as const).map(lang => <div key={lang} className="space-y-2"><Label htmlFor={`${path}-${lang}`}>{lang === "th" ? "ภาษาไทย" : "English"}</Label><Textarea id={`${path}-${lang}`} lang={lang} maxLength={6000} value={form.texts[path]?.[lang] ?? defaultText(path,lang)} onChange={e => edit(path,lang,e.target.value)} className="min-h-28 bg-card leading-relaxed" /></div>)}</div></div>;
      }) : <><label className="flex min-h-11 items-start gap-3"><input type="checkbox" checked={confirmed} onChange={e => setConfirmed(e.target.checked)} className="mt-1 h-5 w-5 accent-primary" /><span>ฉันมีสิทธิ์เผยแพร่รูปเหล่านี้ และหากมีเด็กในรูป ได้รับอนุญาตจากผู้ปกครองให้ใช้บนเว็บไซต์แล้ว</span></label><div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">{imageSlots.map(slot => <div key={slot.key} className="space-y-3"><h3 className="font-semibold">{slot.label}</h3><img src={previews[slot.key] ?? (form.images[slot.key] ? saved.imageUrls[slot.key] : undefined) ?? slot.fallback} alt={slot.label} className="aspect-[4/3] w-full rounded-md border border-border bg-card object-cover" /><div className="flex gap-2"><Button type="button" asChild variant="outline" className="min-h-11 flex-1"><label className="cursor-pointer"><Upload />{uploading === slot.key ? "กำลังอัปโหลด…" : "เปลี่ยนรูป"}<input type="file" className="sr-only" aria-label={`เปลี่ยนรูป ${slot.label}`} accept="image/jpeg,image/png,image/webp" disabled={!confirmed || !!uploading || busy} onChange={e => { void upload(slot.key,e.target.files?.[0]); e.target.value = ""; }} /></label></Button><Button type="button" variant="ghost" title="คืนรูปเดิม" aria-label={`คืนรูปเดิม ${slot.label}`} className="h-11 w-11" onClick={() => { const images = { ...form.images }; delete images[slot.key]; const nextPreviews = { ...previews }; delete nextPreviews[slot.key]; setPreviews(nextPreviews); setForm({ ...form, images }); setNotice(""); }}><RotateCcw /></Button></div></div>)}</div><p className="text-sm text-muted-foreground">JPG, PNG, WebP · ไม่เกิน 5 MB ต่อรูป</p></>}
    </fieldset>
  </form>;
}