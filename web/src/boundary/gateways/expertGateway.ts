import expertSeed from "./seed/experts.seed.json";
import categorySeed from "./seed/expert-categories.seed.json";
import type { GatewayExpertCategory, GatewayExpertProfile } from "./landingDtos";

export async function readTopRankedExperts(): Promise<GatewayExpertProfile[]> {
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
  return (categorySeed as GatewayExpertCategory[])
    .filter((category) => category.is_active)
    .sort((a, b) => a.label.localeCompare(b.label));
}
