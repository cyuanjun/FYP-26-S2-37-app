import testimonialSeed from "./seed/testimonials.seed.json";
import type { GatewayTestimonialSubmission } from "./landingDtos";
import { supabase } from "./supabaseClient";

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

export async function readApprovedTestimonials(): Promise<GatewayTestimonialSubmission[]> {
  try {
    // RLS only exposes approved rows to anon; the filter is belt-and-braces.
    const { data, error } = await supabase
      .from("public_testimonials")
      .select("*")
      .eq("status", "approved")
      .order("rating", { ascending: false });
    if (error) throw error;
    return (data as TestimonialRow[]).map((row) => ({
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
    // Offline / unreachable database: fall back to the bundled seed.
    return (testimonialSeed as GatewayTestimonialSubmission[])
      .filter((testimonial) => testimonial.status === "approved")
      .sort((a, b) => b.rating - a.rating);
  }
}
