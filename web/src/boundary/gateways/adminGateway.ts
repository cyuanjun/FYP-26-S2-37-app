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

// All reads/writes here ride on is_admin() RLS policies (and the
// review_expert_application RPC) — a non-admin session gets empty
// results or errors, never data.

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

export async function signOutAdmin(): Promise<void> {
  await supabase.auth.signOut();
}

// ---- Users (US56/US61/US62) ----

export async function listUsers(): Promise<AdminUser[]> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email, role, status, first_name, last_name, username, created_at")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as AdminUser[];
}

export async function updateUserStatus(id: string, status: "suspended" | null): Promise<void> {
  const { error } = await supabase.from("profiles").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

export async function updateUserRole(id: string, role: "free" | "premium"): Promise<void> {
  const { error } = await supabase.from("profiles").update({ role }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Expert applications (US52/US57) ----

export async function listExpertApplications(): Promise<ExpertApplication[]> {
  const { data, error } = await supabase
    .from("expert_profiles")
    .select(
      "id, title, years_coaching, about, credentials, specialties, verification_status, " +
        "profile:profiles!expert_profiles_id_fkey(email, first_name, last_name, created_at), " +
        "documents:expert_verification_documents(id, doc_type, title, file_name, uploaded_at)",
    )
    .eq("verification_status", "pending");
  if (error) throw new Error(error.message);
  return data as unknown as ExpertApplication[];
}

export async function reviewExpertApplication(expertId: string, approve: boolean): Promise<void> {
  const { error } = await supabase.rpc("review_expert_application", {
    p_expert: expertId,
    p_approve: approve,
  });
  if (error) throw new Error(error.message);
}

// ---- Categories (US58) ----

export async function listAllCategories(): Promise<ExpertCategoryRow[]> {
  const { data, error } = await supabase.from("expert_categories").select("*").order("label");
  if (error) throw new Error(error.message);
  return data as ExpertCategoryRow[];
}

export async function upsertCategory(category: ExpertCategoryRow): Promise<void> {
  const { error } = await supabase.from("expert_categories").upsert(category);
  if (error) throw new Error(error.message);
}

// ---- Service listings (US59) ----

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

export async function updateServiceStatus(
  id: string,
  status: "live" | "archived",
): Promise<void> {
  const { error } = await supabase.from("expert_services").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Testimonials (US63) ----

export async function listAllTestimonials(): Promise<TestimonialRow[]> {
  const { data, error } = await supabase
    .from("public_testimonials")
    .select("*")
    .order("submitted_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as TestimonialRow[];
}

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

export async function listFeedback(): Promise<FeedbackRow[]> {
  const { data, error } = await supabase
    .from("feedback")
    .select("id, category, body, status, created_at, profile:profiles(email, first_name, last_name)")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as unknown as FeedbackRow[];
}

export async function updateFeedbackStatus(id: string, status: "new" | "reviewed"): Promise<void> {
  const { error } = await supabase.from("feedback").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Contact messages (US60 / #28.1) ----

export async function listContactMessages(): Promise<ContactMessageRow[]> {
  const { data, error } = await supabase
    .from("contact_messages")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data as ContactMessageRow[];
}

export async function respondToContactMessage(id: string, response: string): Promise<void> {
  const { error } = await supabase
    .from("contact_messages")
    .update({ response, status: "resolved" })
    .eq("id", id);
  if (error) throw new Error(error.message);
}

// ---- Pricing (US63) ----

export async function listAllPricingPlans(): Promise<PricingPlanRow[]> {
  const { data, error } = await supabase
    .from("landing_pricing_plans")
    .select("*")
    .order("display_order");
  if (error) throw new Error(error.message);
  return data as PricingPlanRow[];
}

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

export async function listAllFaqs(): Promise<FaqRow[]> {
  const { data, error } = await supabase.from("landing_faqs").select("*").order("display_order");
  if (error) throw new Error(error.message);
  return data as FaqRow[];
}

export async function upsertFaq(faq: Omit<FaqRow, "id"> & { id?: string }): Promise<void> {
  const row = { ...faq, updated_at: new Date().toISOString() };
  if (!row.id) delete row.id;
  const { error } = await supabase.from("landing_faqs").upsert(row, { onConflict: "faq_key" });
  if (error) throw new Error(error.message);
}
