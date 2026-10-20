import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { queryOptions, useSuspenseQuery } from "@tanstack/react-query";
import { LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ClassDescriptionEditor } from "@/components/admin/ClassDescriptionEditor";
import { getTeacherAccess } from "@/lib/class-descriptions.functions";
import { supabase } from "@/integrations/supabase/client";
import { classCopy } from "@/content/admin/classes";

const accessQuery = queryOptions({ queryKey: ["teacher-access"], queryFn: () => getTeacherAccess() });
export const Route = createFileRoute("/_authenticated/admin")({
  staticData: { sitemap: false },
  head: () => ({ meta: [{ title: "ร่างคำอธิบายคลาส | CherryLee & Co." }, { name: "description", content: "พื้นที่คุณครูสำหรับร่างคำอธิบายคลาสสองภาษา" }, { property: "og:title", content: "พื้นที่คุณครู | CherryLee & Co." }, { property: "og:description", content: "คำอธิบายคลาสภาษาไทยและอังกฤษ" }, { property: "og:type", content: "website" }, { name: "twitter:card", content: "summary" }, { name: "robots", content: "noindex, nofollow" }] }),
  loader: ({ context }) => context.queryClient.ensureQueryData(accessQuery),
  component: AdminPage,
});
function AdminPage() {
  const { data: access } = useSuspenseQuery(accessQuery);
  const navigate = useNavigate();
  return <div className="min-h-screen bg-background text-foreground">
    <header className="border-b border-border bg-card"><div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-4"><Link to="/"><img src="/images/logo-stacked.png" alt="CherryLee & Co." className="h-16 w-auto" /></Link><div className="flex items-center gap-3"><span>{access.name}</span><Button variant="outline" className="min-h-11" onClick={async () => { await supabase.auth.signOut(); await navigate({ to: "/auth" }); }}><LogOut />ออกจากระบบ</Button></div></div></header>
    <main className="mx-auto max-w-6xl px-5 py-10"><p className="mb-2 text-sm text-muted-foreground">พื้นที่คุณครู</p><h1 className="mb-10 font-display text-3xl">{classCopy.title}</h1>{access.allowed ? <ClassDescriptionEditor /> : <div role="status" className="border-t border-border py-8"><h2 className="text-xl font-semibold">รอสิทธิ์คุณครู</h2><p className="mt-3">บัญชีนี้ยังไม่ได้รับสิทธิ์ กรุณาให้เจ้าของสตูดิโออนุมัติก่อนค่ะ</p></div>}</main>
  </div>;
}