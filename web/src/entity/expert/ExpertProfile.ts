// (#) One expert's public-facing card: who they are plus their social-proof numbers.
export interface PublicExpertProfile {
  id: string;
  displayName: string;
  title: string;
  ratingAverage: number;
  reviewCount: number;
  clientCount: number;
  verificationStatus: "pending" | "verified" | "rejected"; // (#) only verified ones surface publicly
}
