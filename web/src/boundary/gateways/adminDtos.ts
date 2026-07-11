// (#) Barebones name/id of an admin, used where we just need to label who acted.
export interface AdminIdentity {
  id: string;
  first_name: string;
  last_name: string;
}

// (#) One row in the admin Users table: account, its role and whether it's suspended.
export interface AdminUser {
  id: string;
  email: string;
  role: "free" | "premium" | "expert" | "admin";
  status: "suspended" | null; // (#) null means the account is active
  first_name: string | null;
  last_name: string | null;
  username: string | null;
  created_at: string;
}

// (#) A pending expert sign-up as the admin reviews it: their pitch plus uploaded proof.
export interface ExpertApplication {
  id: string;
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  verification_status: "pending" | "verified" | "rejected";
  // (#) the user account behind the application
  profile: {
    email: string;
    first_name: string | null;
    last_name: string | null;
    created_at: string;
  };
  // (#) ID / certification files the applicant attached
  documents: {
    id: string;
    doc_type: "identity" | "certification";
    title: string;
    file_name: string;
    uploaded_at: string;
    storage_path: string | null;
    signed_url?: string | null; // (#) minted by the gateway for admin viewing
  }[];
}

// (#) An expert category as stored in the DB (snake_case), for the admin editor.
export interface ExpertCategoryRow {
  id: string;
  label: string;
  description: string;
  is_active: boolean;
}

// (#) A marketplace service listing in the admin table, with its owning expert.
export interface ServiceListingRow {
  id: string;
  name: string;
  status: "draft" | "live" | "archived";
  category: string;
  price_cents: number;
  pricing_model: string;
  created_at: string;
  // (#) the expert who owns this listing, denormalised for display
  expert: {
    id: string;
    profile: { first_name: string | null; last_name: string | null; email: string };
  };
}

// (#) A user-submitted testimonial the admin moderates before it can show publicly.
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
  reviewed_at: string | null; // (#) null until an admin acts on it
}

// (#) In-app feedback (bug / idea / general) landing in the admin inbox.
export interface FeedbackRow {
  id: string;
  category: "bug" | "feature_request" | "general";
  body: string;
  status: "new" | "reviewed";
  created_at: string;
  // (#) who sent it
  profile: { email: string; first_name: string | null; last_name: string | null };
}

// (#) A Contact Us message in the admin inbox, plus any reply we've sent back.
export interface ContactMessageRow {
  id: string;
  submitter_name: string;
  submitter_email: string;
  message: string;
  status: "open" | "resolved";
  response: string | null;
  created_at: string;
}

// (#) A pricing tier the admin can edit; drives the public pricing section.
export interface PricingPlanRow {
  id: string;
  plan_key: string;
  plan_name: string;
  price_label: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
  display_order: number; // (#) sort position on the pricing grid
  is_active: boolean;
}

// (#) A single FAQ entry the admin manages; renders in the landing FAQ accordion.
export interface FaqRow {
  id: string;
  faq_key: string;
  question: string;
  answer: string;
  display_order: number; // (#) where it sits in the list
  is_active: boolean;
}
