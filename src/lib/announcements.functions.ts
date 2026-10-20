import { createServerFn } from "@tanstack/react-start";
import { generateResponse, GatewayError } from "@lovable.dev/ai-gateway";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { canGenerateClass } from "./class-descriptions";
import { announcementDraftSchema, announcementInstructions, announcementNotesSchema } from "./announcements";
import { announcementCopy as copy } from "@/content/admin/announcements";

export const generateAnnouncement = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => announcementNotesSchema.parse(input))
  .handler(async ({ data, context }) => {
    const { data: roles, error } = await context.supabase.from("user_roles").select("role").eq("user_id", context.userId);
    if (error || !canGenerateClass((roles ?? []).map(row => row.role))) return { ok: false as const, error: copy.denied };
    try {
      const response = await generateResponse({
        model: "openai/gpt-6-astra",
        instructions: announcementInstructions,
        input: JSON.stringify(data),
        text: { format: { type: "json_schema", name: "thai_announcement", strict: true, schema: { type: "object", properties: { th: { type: "string" } }, required: ["th"], additionalProperties: false } } },
      });
      if (response.status !== "completed") return { ok: false as const, error: copy.incomplete };
      let text = "";
      for (const item of response.output) {
        if (item.type !== "message") continue;
        for (const part of item.content) {
          if (part.type === "refusal") return { ok: false as const, error: copy.refusal };
          if (part.type === "output_text") text += part.text;
        }
      }
      return { ok: true as const, draft: announcementDraftSchema.parse(JSON.parse(text)) };
    } catch (error) {
      if (error instanceof GatewayError) {
        console.error("Announcement Gateway failure", { code: error.code, outcome: error.outcome, httpStatus: error.httpStatus, ids: error.ids });
        return { ok: false as const, error: error.code === "payment_required" ? copy.credits : error.code === "permission_denied" ? copy.permission : error.code === "rate_limited" ? copy.rate : copy.failed };
      }
      console.error("Invalid announcement response");
      return { ok: false as const, error: copy.failed };
    }
  });