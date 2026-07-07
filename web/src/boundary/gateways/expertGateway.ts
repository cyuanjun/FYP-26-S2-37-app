import expertSeed from "./seed/experts.seed.json";
import categorySeed from "./seed/expert-categories.seed.json";
import type { GatewayExpertCategory, GatewayExpertProfile } from "./landingDtos";
import { supabase } from "./supabaseClient";

interface FeaturedExpertRow {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  rating_avg: number;
  review_count: number;
  client_count: number;
}

export async function readTopRankedExperts(): Promise<GatewayExpertProfile[]> {
  try {
    // SECURITY DEFINER function: verified, non-suspended experts only,
    // ranked by rating weighted with log review volume. No email exposed.
    const { data, error } = await supabase.rpc("landing_featured_experts", { p_limit: 3 });
    if (error) throw error;
    return (data as FeaturedExpertRow[]).map((row) => ({
      user_id: row.user_id,
      display_name: row.display_name,
      email: "",
      avatar_url: row.avatar_url,
      title: row.title,
      years_coaching: row.years_coaching,
      about: row.about,
      credentials: row.credentials,
      specialties: row.specialties,
      rating_avg: Number(row.rating_avg),
      review_count: row.review_count,
      client_count: row.client_count,
      verification_status: "verified",
    }));
  } catch {
    return seedTopRankedExperts();
  }
}

function seedTopRankedExperts(): GatewayExpertProfile[] {
  return (expertSeed as GatewayExpertProfile[])
    .filter((expert) => expert.verification_status === "verified")
    .map((expert) => ({
      expert,
      score: expert.rating_avg * Math.log(expert.review_count + 1),
    }))
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      if (b.expert.review_count !== a.expert.review_count) {
        return b.expert.review_count - a.expert.review_count;
      }
      if (b.expert.rating_avg !== a.expert.rating_avg) {
        return b.expert.rating_avg - a.expert.rating_avg;
      }
      return b.expert.client_count - a.expert.client_count;
    })
    .slice(0, 3)
    .map(({ expert }) => expert);
}

export async function readActiveExpertCategories(): Promise<GatewayExpertCategory[]> {
  try {
    const { data, error } = await supabase
      .from("expert_categories")
      .select("*")
      .eq("is_active", true)
      .order("label");
    if (error) throw error;
    return data as GatewayExpertCategory[];
  } catch {
    return (categorySeed as GatewayExpertCategory[])
      .filter((category) => category.is_active)
      .sort((a, b) => a.label.localeCompare(b.label));
  }
}
