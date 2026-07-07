export interface PublicExpertProfile {
  id: string;
  displayName: string;
  title: string;
  ratingAverage: number;
  reviewCount: number;
  clientCount: number;
  verificationStatus: "pending" | "verified" | "rejected";
}
