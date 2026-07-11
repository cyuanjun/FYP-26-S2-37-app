import {
  listAllCategories,
  listAllFaqs,
  listAllPricingPlans,
  listServiceListings,
  updatePricingPlan,
  updateServiceStatus,
  upsertCategory,
  upsertFaq,
} from "@/boundary/gateways/adminGateway";
import type {
  ExpertCategoryRow,
  FaqRow,
  PricingPlanRow,
  ServiceListingRow,
} from "@/boundary/gateways/adminDtos";

// (#) Shape allowed for category ids / FAQ keys: 2-30 lowercase letters,
// (#) digits and dashes.
const SLUG_REGEX = /^[a-z0-9-]{2,30}$/;

// ---- Categories (US58) ----

// (#) Lists every expert category (active and inactive) for the admin editor.
export async function getCategories(): Promise<ExpertCategoryRow[]> {
  return listAllCategories();
}

// (#) Validates a category (slug id + non-empty label/description) then
// (#) upserts it through the gateway. New rows and edits share this path.
export async function saveCategory(category: ExpertCategoryRow): Promise<void> {
  const id = category.id.trim().toLowerCase();
  if (!SLUG_REGEX.test(id)) {
    throw new Error("Category id must be a 2-30 char slug (a-z, 0-9, dashes).");
  }
  if (!category.label.trim()) throw new Error("Label is required.");
  if (!category.description.trim()) throw new Error("Description is required.");
  await upsertCategory({ ...category, id, label: category.label.trim(), description: category.description.trim() });
}

// (#) Flips a category's active flag on/off by re-upserting the row.
export async function setCategoryActive(category: ExpertCategoryRow, active: boolean): Promise<void> {
  await upsertCategory({ ...category, is_active: active });
}

// ---- Service listings (US59) ----

// (#) Fetches all expert service listings for the admin catalog view.
export async function getServiceListings(): Promise<ServiceListingRow[]> {
  return listServiceListings();
}

// (#) Takes a listing off the marketplace by setting its status to archived.
export async function archiveListing(listing: ServiceListingRow): Promise<void> {
  await updateServiceStatus(listing.id, "archived");
}

// (#) Brings an archived listing back live.
export async function restoreListing(listing: ServiceListingRow): Promise<void> {
  await updateServiceStatus(listing.id, "live");
}

// ---- Pricing (US63) ----

// (#) Lists the pricing plans (Free/Premium etc.) shown on the landing page.
export async function getPricingPlans(): Promise<PricingPlanRow[]> {
  return listAllPricingPlans();
}

// (#) Validates the label/description then saves the plan's price copy and
// (#) active flag through the gateway.
export async function savePricingPlan(plan: PricingPlanRow): Promise<void> {
  if (!plan.price_label.trim()) throw new Error("Price label is required.");
  if (!plan.description.trim()) throw new Error("Description is required.");
  await updatePricingPlan(plan.id, {
    price_label: plan.price_label.trim(),
    description: plan.description.trim(),
    is_active: plan.is_active,
  });
}

// ---- FAQs (US63) ----

// (#) Reads all landing-page FAQ entries for the admin editor.
export async function getFaqs(): Promise<FaqRow[]> {
  return listAllFaqs();
}

// (#) Validates a FAQ (slug key + non-empty question/answer) and upserts it.
// (#) Accepts a row with no id yet so new FAQs go through the same path.
export async function saveFaq(faq: Omit<FaqRow, "id"> & { id?: string }): Promise<void> {
  const key = faq.faq_key.trim().toLowerCase();
  if (!SLUG_REGEX.test(key)) {
    throw new Error("FAQ key must be a 2-30 char slug (a-z, 0-9, dashes).");
  }
  if (!faq.question.trim()) throw new Error("Question is required.");
  if (!faq.answer.trim()) throw new Error("Answer is required.");
  await upsertFaq({
    ...faq,
    faq_key: key,
    question: faq.question.trim(),
    answer: faq.answer.trim(),
  });
}
