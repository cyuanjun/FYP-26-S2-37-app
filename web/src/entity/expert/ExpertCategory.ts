// (#) A coaching category shown on the public experts page (e.g. Strength, Running).
export interface PublicExpertCategory {
  id: string;
  label: string;
  description: string;
  isActive: boolean; // (#) hidden from the site when false
}
