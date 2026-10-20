import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { lovable } from "@/integrations/lovable";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/auth")({
  staticData: { sitemap: false },
  head: () => ({ meta: [{ title: "เข้าสู่ระบบคุณครู | CherryLee & Co." }, { name: "description", content: "เข้าสู่พื้นที่คุณครู CherryLee & Co." }, { property: "og:title", content: "เข้าสู่ระบบคุณครู | CherryLee & Co." }, { property: "og:description", content: "พื้นที่สำหรับคุณครูที่ได้รับสิทธิ์" }, { property: "og:type", content: "website" }, { name: "twitter:card", content: "summary" }, { name: "robots", content: "noindex, nofollow" }] }),
  component: AuthPage,
});
function AuthPage() {
  const navigate = useNavigate();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  useEffect(() => { void supabase.auth.getUser().then(({ data }) => { if (data.user) void navigate({ to: "/admin" }); }); }, [navigate]);
  async function signIn(provider: "google" | "lovable") {
    setBusy(true); setError("");
    try {
      const result = await lovable.auth.signInWithOAuth(provider, { redirect_uri: `${window.location.origin}/auth` });
      if (result.error) setError("เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่ค่ะ");
      else if (!result.redirected) await navigate({ to: "/admin" });
    } catch { setError("เชื่อมต่อการเข้าสู่ระบบไม่ได้ กรุณาลองใหม่ค่ะ"); }
    finally { setBusy(false); }
  }
  return <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-6 px-6 py-12"><Link to="/"><img src="/images/logo-stacked.png" alt="CherryLee & Co." className="mx-auto h-28 w-auto" /></Link><h1 className="text-center font-display text-3xl">เข้าสู่ระบบคุณครู</h1><Button disabled={busy} className="min-h-12" onClick={() => signIn("google")}>เข้าสู่ระบบด้วย Google</Button><Button disabled={busy} variant="outline" className="min-h-12" onClick={() => signIn("lovable")}>เข้าสู่ระบบด้วย Lovable</Button>{error && <p role="alert" className="text-destructive">{error}</p>}<p className="text-center text-sm text-muted-foreground">สำหรับคุณครูที่ได้รับสิทธิ์จากสตูดิโอ</p><Button asChild variant="link" className="min-h-11"><Link to="/">กลับหน้าเว็บไซต์</Link></Button></main>;
}