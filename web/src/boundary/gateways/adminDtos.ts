export interface AdminIdentity {
  id: string;
  first_name: string;
  last_name: string;
}

export interface AdminUser {
  id: string;
  email: string;
  role: "free" | "premium" | "expert" | "admin";
  status: "suspended" | null;
  first_name: string | null;
  last_name: string | null;
  username: string | null;
  created_at: string;
}

export interface ExpertApplication {
  id: string;
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  verification_status: "pending" | "verified" | "rejected";
  profile: {
    email: string;
    first_name: string | null;
    last_name: string | null;
    created_at: string;
  };
  documents: {
    id: string;
    doc_type: "identity" | "certification";
    title: string;
    file_name: string;
    uploaded_at: string;
  }[];
}

export interface ExpertCategoryRow {
  id: string;
  label: string;
  description: string;
  is_active: boolean;
}

export interface ServiceListingRow {
  id: string;
  name: string;
  status: "draft" | "live" | "archived";
  category: string;
  price_cents: number;
  pricing_model: string;
  created_at: string;
  expert: {
    id: string;
    profile: { first_name: string | null; last_name: string | null; email: string };
  };
}

export interface TestimonialRow {
  id: string;
  user_id: string;
  display_name: string;
  user_category: string;
  rating: number;
  body: string;
  status: "pending" | "approved" | "rejected";
  admin_reply: string | null;
  submitted_at: string;
  reviewed_at: string | null;
}

export interface FeedbackRow {
  id: string;
  category: "bug" | "feature_request" | "general";
  body: string;
  status: "new" | "reviewed";
  created_at: string;
  profile: { email: string; first_name: string | null; last_name: string | null };
}

export interface ContactMessageRow {
  id: string;
  submitter_name: string;
  submitter_email: string;
  message: string;
  status: "open" | "resolved";
  response: string | null;
  created_at: string;
}

export interface PricingPlanRow {
  id: string;
  plan_key: string;
  plan_name: string;
  price_label: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
  display_order: number;
  is_active: boolean;
}
