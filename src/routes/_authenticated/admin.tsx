import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { queryOptions, useSuspenseQuery, useQueryClient } from "@tanstack/react-query";
import { LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ClassDescriptionEditor } from "@/components/admin/ClassDescriptionEditor";
import { getTeacherAccess } from "@/lib/class-descriptions.functions";
import { supabase } from "@/integrations/supabase/client";
import { classCopy } from "@/content/admin/classes";
import { useState, Suspense } from "react";
import { HomepageEditor } from "@/components/admin/HomepageEditor";
import { AnnouncementEditor } from "@/components/admin/AnnouncementEditor";
import { announcementCopy } from "@/content/admin/announcements";

const accessQuery = queryOptions({ queryKey: ["teacher-access"], queryFn: () => getTeacherAccess() });
export const Route = createFileRoute("/_authenticated/admin")({
  staticData: { sitemap: false },
  head: () => ({ meta: [{ title: "จัดการเว็บไซต์ | CherryLee & Co." }, { name: "description", content: "พื้นที่คุณครูสำหรับแก้ไขหน้าแรก ร่างคำอธิบายคลาสและประกาศภาษาไทย" }, { property: "og:title", content: "พื้นที่คุณครู | CherryLee & Co." }, { property: "og:description", content: "จัดการหน้าแรกและร่างข้อมูลสำหรับผู้ปกครอง" }, { property: "og:type", content: "website" }, { name: "twitter:card", content: "summary" }, { name: "robots", content: "noindex, nofollow" }] }),
  loader: ({ context }) => context.queryClient.ensureQueryData(accessQuery),
  component: AdminPage,
});
function AdminPage() {
  const [tab, setTab] = useState("homepage");
  const { data: access } = useSuspenseQuery(accessQuery);
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  return <div className="min-h-screen bg-background text-foreground">
    <header className="border-b border-border bg-card"><div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-4"><Link to="/"><img src="/images/logo-stacked.png" alt="CherryLee & Co." className="h-16 w-auto" /></Link><div className="flex items-center gap-3"><span>{access.name}</span><Button variant="outline" className="min-h-11" onClick={async () => { await queryClient.cancelQueries(); queryClient.clear(); await supabase.auth.signOut(); await navigate({ to: "/auth", replace: true }); }}><LogOut />ออกจากระบบ</Button></div></div></header>
    <main className="mx-auto max-w-6xl px-5 py-10"><p className="mb-2 text-sm text-muted-foreground">พื้นที่คุณครู</p><h1 className="mb-7 font-display text-3xl">จัดการเว็บไซต์</h1>{access.allowed ? <><div className="mb-8 flex flex-wrap gap-3 border-b border-border pb-5"><Button variant={tab === "homepage" ? "default" : "outline"} className="min-h-11" onClick={() => setTab("homepage")}>ข้อมูลเว็บไซต์ทั้งหมด</Button><Button variant={tab === "ai" ? "default" : "outline"} className="min-h-11" onClick={() => setTab("ai")}>{classCopy.title}</Button><Button variant={tab === "announcement" ? "default" : "outline"} className="min-h-11" onClick={() => setTab("announcement")}>{announcementCopy.title}</Button></div><div hidden={tab !== "homepage"}><Suspense fallback={<p role="status">กำลังโหลดข้อมูลเว็บไซต์…</p>}><HomepageEditor /></Suspense></div><div hidden={tab !== "ai"}><ClassDescriptionEditor /></div><div hidden={tab !== "announcement"}><AnnouncementEditor /></div></> : <div role="status" className="border-t border-border py-8"><h2 className="text-xl font-semibold">รอสิทธิ์คุณครู</h2><p className="mt-3">บัญชีนี้ยังไม่ได้รับสิทธิ์ กรุณาให้เจ้าของสตูดิโออนุมัติก่อนค่ะ</p></div>}</main>
  </div>;
}