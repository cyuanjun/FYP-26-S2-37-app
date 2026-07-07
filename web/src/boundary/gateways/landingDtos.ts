export interface ContactMessageInput {
  submitter_name: string;
  submitter_email: string;
  message: string;
}

export interface GatewayExpertProfile {
  user_id: string;
  display_name: string;
  email: string;
  avatar_url: string | null;
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  rating_avg: number;
  review_count: number;
  client_count: number;
  verification_status: "pending" | "verified" | "rejected";
}

export interface GatewayExpertCategory {
  id: string;
  label: string;
  description: string;
  is_active: boolean;
}

export interface GatewayTestimonialSubmission {
  id: string;
  rating: number;
  created_at: string;
  feedback_text: string;
  user_display_name: string;
  user_category: string;
  status: "pending" | "approved" | "rejected";
  submitted_at: string;
  admin_reply: string | null;
  reviewed_at: string | null;
}
