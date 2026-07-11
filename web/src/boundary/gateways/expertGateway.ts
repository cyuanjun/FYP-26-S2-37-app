import expertSeed from "./seed/experts.seed.json";
import categorySeed from "./seed/expert-categories.seed.json";
import type { GatewayExpertCategory, GatewayExpertProfile } from "./landingDtos";
import { supabase } from "./supabaseClient";

// (#) Shape of a row returned by the landing_featured_experts RPC (includes the
// database-computed ranking score).
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
  score: number;
}

// (#) Fetches the top 3 experts for the landing page via the
// landing_featured_experts RPC; falls back to the bundled seed if it fails.
export async function readTopRankedExperts(): Promise<GatewayExpertProfile[]> {
  try {
    // (#) SECURITY DEFINER function: verified, non-suspended experts only.
    // Ranking = IMDb-style Bayesian weighted rating, computed in the database
    // (single source of truth): WR = (v/(v+m))·R + (m/(v+m))·C with m = 10 and
    // C = mean rating across verified experts; ties broken by review_count,
    // then client_count. No email exposed.
    const { data, error } = await supabase.rpc("landing_featured_experts", { p_limit: 3 });
    if (error) throw error;
    const rows = data as FeaturedExpertRow[];
    console.info(
      "[landing] FEATURED EXPERTS ranked by Bayesian weighted rating " +
        "WR = (v/(v+m))·R + (m/(v+m))·C (m=10, C=mean verified rating; ties: reviews, clients):",
      rows.map((r) => `${r.display_name} R=${r.rating_avg} v=${r.review_count} → WR=${r.score}`),
    );
    return rows.map((row) => ({
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

// (#) Offline fallback: ranks the bundled verified experts with the same
// rating-times-log(reviews) idea and returns the top 3.
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

// (#) Reads the active expert_categories (alphabetical by label); on failure
// returns the active seed categories instead.
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
