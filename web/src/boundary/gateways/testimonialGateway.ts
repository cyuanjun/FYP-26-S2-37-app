import testimonialSeed from "./seed/testimonials.seed.json";
import type { GatewayTestimonialSubmission } from "./landingDtos";
import { supabase } from "./supabaseClient";

// (#) Raw shape of a public_testimonials row as read from the database.
interface TestimonialRow {
  id: string;
  rating: number;
  created_at: string;
  body: string;
  display_name: string;
  user_category: string;
  status: "pending" | "approved" | "rejected";
  submitted_at: string;
  admin_reply: string | null;
  reviewed_at: string | null;
}

// (#) Reads approved public_testimonials, ranks them by rating with a recency
// bonus, and maps to the UI shape; falls back to the seed when offline.
export async function readApprovedTestimonials(): Promise<GatewayTestimonialSubmission[]> {
  try {
    // (#) RLS only exposes approved rows to anon; the filter is belt-and-braces.
    const { data, error } = await supabase
      .from("public_testimonials")
      .select("*")
      .eq("status", "approved")
      .order("submitted_at", { ascending: false });
    if (error) throw error;
    // (#) Displayed testimonials are ORDERED BY ALGORITHM, not hand-picked:
    // score = rating + e^(−age_days / 45)   (rating dominates; among equal
    // ratings, fresher testimonials float up, the bonus halves ~every month).
    const now = Date.now();
    const scored = (data as TestimonialRow[]).map((row) => {
      const ageDays = Math.max(0, (now - Date.parse(row.submitted_at)) / 86_400_000);
      return { row, score: row.rating + Math.exp(-ageDays / 45) };
    });
    scored.sort((a, b) => b.score - a.score);
    console.info(
      "[landing] TESTIMONIALS ranked by rating + recency decay " +
        "(score = rating + e^(−age_days/45)):",
      scored.map((s) => `${s.row.display_name} ★${s.row.rating} → ${s.score.toFixed(3)}`),
    );
    return scored.map(({ row }) => ({
      id: row.id,
      rating: row.rating,
      created_at: row.created_at,
      feedback_text: row.body,
      user_display_name: row.display_name,
      user_category: row.user_category,
      status: row.status,
      submitted_at: row.submitted_at,
      admin_reply: row.admin_reply,
      reviewed_at: row.reviewed_at,
    }));
  } catch {
    // (#) Offline / unreachable database: fall back to the bundled seed.
    return (testimonialSeed as GatewayTestimonialSubmission[])
      .filter((testimonial) => testimonial.status === "approved")
      .sort((a, b) => b.rating - a.rating);
  }
}
