// (#) Base for a block on the landing page. The type string tags which block it is
// (#) (hero, features, pricing...) so the boundary knows how to render it.
export interface LandingSection {
  type: string;
}
