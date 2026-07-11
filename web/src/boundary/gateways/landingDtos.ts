// (#) Payload shape sent to the backend when a visitor submits Contact Us.
export interface ContactMessageInput {
  submitter_name: string;
  submitter_email: string;
  message: string;
}

// (#) Raw expert profile row from the DB (snake_case) before we map it to the entity.
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

// (#) Expert category as it comes back from the landing_* read functions.
export interface GatewayExpertCategory {
  id: string;
  label: string;
  description: string;
  is_active: boolean;
}

// (#) A testimonial row as stored, including its moderation state and admin reply.
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
