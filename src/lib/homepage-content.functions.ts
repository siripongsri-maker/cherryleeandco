import { createServerFn } from "@tanstack/react-start";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { canGenerateClass } from "./class-descriptions";
import { emptyHomepage, homepageSchema } from "./homepage-content";

export const getHomepage = createServerFn({ method: "GET" }).handler(async () => {
  const url = process.env["SUPABASE_URL"];
  const key = process.env["SUPABASE_PUBLISHABLE_KEY"];
  if (!url || !key) throw new Error("ไม่สามารถโหลดข้อมูลเว็บไซต์ได้ค่ะ");
  const client = createClient<Database>(url, key, { auth: { persistSession: false, autoRefreshToken: false }, global: { fetch: (input, init) => { const headers = new Headers(init?.headers); if (key.startsWith("sb_") && headers.get("Authorization") === `Bearer ${key}`) headers.delete("Authorization"); headers.set("apikey", key); return fetch(input, { ...init, headers }); } } });
  const { data, error } = await client.from("homepage_content").select("texts,images,version").eq("id", "homepage").maybeSingle();
  if (error) throw new Error("โหลดข้อมูลหน้าแรกไม่สำเร็จค่ะ");
  const value = data ? homepageSchema.parse(data) : emptyHomepage;
  const imageUrls: Record<string, string> = {};
  const entries = Object.entries(value.images);
  if (entries.length) {
    const { data: signed, error: signError } = await client.storage.from("homepage-images").createSignedUrls(entries.map(([,path]) => path), 3600);
    if (signError) throw new Error("โหลดรูปหน้าแรกไม่สำเร็จค่ะ");
    entries.forEach(([slot], index) => {
      const signedUrl = signed?.[index]?.signedUrl;
      if (signedUrl) imageUrls[slot] = signedUrl.replace(url, import.meta.env['VITE_SUPABASE_URL']);
    });
  }
  return { ...value, imageUrls };
});

export const saveHomepage = createServerFn({ method: "POST" }).middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => homepageSchema.parse(input))
  .handler(async ({ data, context }) => {
    const { data: roles, error: roleError } = await context.supabase.from("user_roles").select("role").eq("user_id", context.userId);
    if (roleError || !canGenerateClass((roles ?? []).map(row => row.role))) return { ok: false as const, error: "บัญชีนี้ยังไม่ได้รับสิทธิ์แก้ไขค่ะ" };
    for (const path of Object.values(data.images)) {
      const { data: files, error } = await context.supabase.storage.from("homepage-images").list("", { search: path });
      if (error || !files?.some(file => file.name === path)) return { ok: false as const, error: "ไม่พบรูปที่อัปโหลด กรุณาอัปโหลดใหม่ค่ะ" };
    }
    const row = { id: "homepage", texts: data.texts, images: data.images, version: data.version + 1, updated_at: new Date().toISOString() };
    const result = data.version === 0 ? await context.supabase.from("homepage_content").insert(row).select("version").single() : await context.supabase.from("homepage_content").update(row).eq("id", "homepage").eq("version", data.version).select("version").maybeSingle();
    if (result.error || !result.data) return { ok: false as const, error: "บันทึกไม่สำเร็จ หรือมีคุณครูท่านอื่นแก้ไขแล้ว กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกค่ะ" };
    return { ok: true as const, version: result.data.version };
  });