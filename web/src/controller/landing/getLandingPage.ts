import { readLandingSeed } from "@/boundary/gateways/landingGateway";
import type { LandingPageData } from "./viewModels";

export async function getLandingPage(): Promise<LandingPageData> {
  return readLandingSeed() as Promise<LandingPageData>;
}
