import { supabase } from "./supabaseClient";
import type {
  AdminIdentity,
  FaqRow,
  AdminUser,
  ContactMessageRow,
  ExpertApplication,
  ExpertCategoryRow,
  FeedbackRow,
  PricingPlanRow,
  ServiceListingRow,
  TestimonialRow,
} from "./adminDtos";

// (#) All reads/writes here ride on is_admin() RLS policies (and the
// review_expert_application RPC): a non-admin session gets empty
// results or errors, never data.

// (#) Reads the current session and its profiles row; returns the admin
// identity only when that row's role is 'admin', otherwise null.
export async function fetchAdminIdentity(): Promise<AdminIdentity | null> {
  const { data: sessionData } = await supabase.auth.getSession();
  const user = sessionData.session?.user;
  if (!user) return null;
  const { data, error } = await supabase
    .from("profiles")
    .select("id, role, first_name, last_name")
    .eq("id", user.id)
    .single();
  if (error || !data || data.role !== "admin") return null;
  return { id: data.id, first_name: data.first_name ?? "Admin", last_name: data.last_name ?? "" };
}

// (#) Ends the admin's Supabase auth session (logout).
export async function signOutAdmin(): Promise<void> {
  await supabase.auth.signOut();
}

// ---- Users (US56/US61/US62) ----

// (#) Lists every profiles row (newest first) for the admin users table.
export async function listUsers(): Promise<AdminUser[]> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email, role, status, first_name, last_name, username, created_at")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as AdminUser[];
}

// (#) Suspends or un-suspends a user by writing status on their profiles row.
export async function updateUserStatus(id: string, status: "suspended" | null): Promise<void> {
  const { error } = await supabase.from("profiles").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

// (#) Flips a user between the free and premium roles on profiles.
export async function updateUserRole(id: string, role: "free" | "premium"): Promise<void> {
  const { error } = await supabase.from("profiles").update({ role }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Expert applications (US52/US57) ----

// (#) Pulls the pending expert_profiles rows plus their applicant profile and
// uploaded verification documents, for the admin review queue.
export async function listExpertApplications(): Promise<ExpertApplication[]> {
  const { data, error } = await supabase
    .from("expert_profiles")
    .select(
      "id, title, years_coaching, about, credentials, specialties, verification_status, " +
        "profile:profiles!expert_profiles_id_fkey(email, first_name, last_name, created_at), " +
        "documents:expert_verification_documents(id, doc_type, title, file_name, uploaded_at, storage_path)",
    )
    .eq("verification_status", "pending");
  if (error) throw new Error(error.message);
  const apps = data as unknown as ExpertApplication[];

  // (#) Mint short-lived signed URLs so the admin can open each private document.
  await Promise.all(
    apps.flatMap((app) =>
      app.documents.map(async (doc) => {
        if (!doc.storage_path) {
          doc.signed_url = null;
          return;
        }
        const { data: signed } = await supabase.storage
          .from("expert-docs")
          .createSignedUrl(doc.storage_path, 600);
        doc.signed_url = signed?.signedUrl ?? null;
      }),
    ),
  );
  return apps;
}

// (#) Approves or rejects an application via the review_expert_application RPC,
// which also flips the profile's role to 'expert' on approval.
export async function reviewExpertApplication(expertId: string, approve: boolean): Promise<void> {
  const { error } = await supabase.rpc("review_expert_application", {
    p_expert: expertId,
    p_approve: approve,
  });
  if (error) throw new Error(error.message);
}

// ---- Categories (US58) ----

// (#) Lists all expert_categories (active and hidden) sorted by label, for the
// category manager.
export async function listAllCategories(): Promise<ExpertCategoryRow[]> {
  const { data, error } = await supabase.from("expert_categories").select("*").order("label");
  if (error) throw new Error(error.message);
  return data as ExpertCategoryRow[];
}

// (#) Inserts a new category or updates an existing one in expert_categories.
export async function upsertCategory(category: ExpertCategoryRow): Promise<void> {
  const { error } = await supabase.from("expert_categories").upsert(category);
  if (error) throw new Error(error.message);
}

// ---- Service listings (US59) ----

// (#) Lists every expert_services row (newest first) joined to the owning
// expert and their profile, for the listings moderation table.
export async function listServiceListings(): Promise<ServiceListingRow[]> {
  const { data, error } = await supabase
    .from("expert_services")
    .select(
      "id, name, status, category, price_cents, pricing_model, created_at, " +
        "expert:expert_profiles!expert_services_expert_user_id_fkey(" +
        "id, profile:profiles!expert_profiles_id_fkey(first_name, last_name, email))",
    )
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as unknown as ServiceListingRow[];
}

// (#) Publishes or archives a listing by setting status on its expert_services row.
export async function updateServiceStatus(
  id: string,
  status: "live" | "archived",
): Promise<void> {
  const { error } = await supabase.from("expert_services").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Testimonials (US63) ----

// (#) Lists every public_testimonials row (newest first), all statuses, for the
// admin moderation queue.
export async function listAllTestimonials(): Promise<TestimonialRow[]> {
  const { data, error } = await supabase
    .from("public_testimonials")
    .select("*")
    .order("submitted_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as TestimonialRow[];
}

// (#) Approves or rejects a testimonial and stamps the reply plus review time
// onto its public_testimonials row.
export async function reviewTestimonial(
  id: string,
  status: "approved" | "rejected",
  adminReply: string | null,
): Promise<void> {
  const { error } = await supabase
    .from("public_testimonials")
    .update({ status, admin_reply: adminReply, reviewed_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Feedback (US60) ----

// (#) Lists in-app feedback rows (newest first) with the submitter's profile,
// for the admin feedback inbox.
export async function listFeedback(): Promise<FeedbackRow[]> {
  const { data, error } = await supabase
    .from("feedback")
    .select("id, category, body, status, created_at, profile:profiles(email, first_name, last_name)")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as unknown as FeedbackRow[];
}

// (#) Marks a feedback item as new or reviewed in the feedback table.
export async function updateFeedbackStatus(id: string, status: "new" | "reviewed"): Promise<void> {
  const { error } = await supabase.from("feedback").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Contact messages (US60 / #28.1) ----

// (#) Lists the public contact-form submissions (newest first) for the admin inbox.
export async function listContactMessages(): Promise<ContactMessageRow[]> {
  const { data, error } = await supabase
    .from("contact_messages")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as ContactMessageRow[];
}

// (#) Saves the admin's reply on a contact message and marks it resolved.
export async function respondToContactMessage(id: string, response: string): Promise<void> {
  const { error } = await supabase
    .from("contact_messages")
    .update({ response, status: "resolved" })
    .eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Pricing (US63) ----

// (#) Lists all landing_pricing_plans in display order for the pricing editor.
export async function listAllPricingPlans(): Promise<PricingPlanRow[]> {
  const { data, error } = await supabase
    .from("landing_pricing_plans")
    .select("*")
    .order("display_order");
  if (error) throw new Error(error.message);
  return data as PricingPlanRow[];
}

// (#) Updates a pricing plan's editable fields (price label, description, active
// flag) and bumps updated_at on landing_pricing_plans.
export async function updatePricingPlan(
  id: string,
  fields: Partial<Pick<PricingPlanRow, "price_label" | "description" | "is_active">>,
): Promise<void> {
  const { error } = await supabase
    .from("landing_pricing_plans")
    .update({ ...fields, updated_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- FAQs (US63) ----

// (#) Lists all landing_faqs in display order for the FAQ editor.
export async function listAllFaqs(): Promise<FaqRow[]> {
  const { data, error } = await supabase.from("landing_faqs").select("*").order("display_order");
  if (error) throw new Error(error.message);
  return data as FaqRow[];
}

// (#) Inserts or updates a FAQ in landing_faqs (matched on faq_key); a missing
// id means a fresh insert, so we drop it and let the database mint one.
export async function upsertFaq(faq: Omit<FaqRow, "id"> & { id?: string }): Promise<void> {
  const row = { ...faq, updated_at: new Date().toISOString() };
  if (!row.id) delete row.id;
  const { error } = await supabase.from("landing_faqs").upsert(row, { onConflict: "faq_key" });
  if (error) throw new Error(error.message);
}
