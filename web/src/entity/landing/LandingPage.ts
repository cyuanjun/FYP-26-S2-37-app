import type { LandingSection } from "./LandingSection";

// (#) The whole marketing landing page: a site name plus its ordered list of sections.
export interface LandingPage {
  siteName: string;
  sections: LandingSection[];
}
