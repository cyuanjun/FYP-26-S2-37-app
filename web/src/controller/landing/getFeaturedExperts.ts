import { readTopRankedExperts } from "@/boundary/gateways/expertGateway";
import type { ExpertProfile } from "./viewModels";

export async function getFeaturedExperts(): Promise<ExpertProfile[]> {
  return readTopRankedExperts();
}
