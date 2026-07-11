import { readTopRankedExperts } from "@/boundary/gateways/expertGateway";
import type { ExpertProfile } from "./viewModels";

// (#) Fetches the top-ranked verified experts (by rating/reviews) to feature
// (#) in the landing page's experts section, via the expert gateway.
export async function getFeaturedExperts(): Promise<ExpertProfile[]> {
  return readTopRankedExperts();
}
