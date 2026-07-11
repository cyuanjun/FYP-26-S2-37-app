import { readLandingSeed } from "@/boundary/gateways/landingGateway";
import type { LandingPageData } from "./viewModels";

// (#) Loads the whole landing page (site chrome + ordered sections) from the
// (#) landing gateway, which prefers live DB reads and falls back to the
// (#) bundled seed when the database is unreachable.
export async function getLandingPage(): Promise<LandingPageData> {
  return readLandingSeed() as Promise<LandingPageData>;
}
