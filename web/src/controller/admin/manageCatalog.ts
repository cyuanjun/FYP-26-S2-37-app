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

const SLUG_REGEX = /^[a-z0-9-]{2,30}$/;

// ---- Categories (US58) ----

export async function getCategories(): Promise<ExpertCategoryRow[]> {
  return listAllCategories();
}

export async function saveCategory(category: ExpertCategoryRow): Promise<void> {
  const id = category.id.trim().toLowerCase();
  if (!SLUG_REGEX.test(id)) {
    throw new Error("Category id must be a 2-30 char slug (a-z, 0-9, dashes).");
  }
  if (!category.label.trim()) throw new Error("Label is required.");
  if (!category.description.trim()) throw new Error("Description is required.");
  await upsertCategory({ ...category, id, label: category.label.trim(), description: category.description.trim() });
}

export async function setCategoryActive(category: ExpertCategoryRow, active: boolean): Promise<void> {
  await upsertCategory({ ...category, is_active: active });
}

// ---- Service listings (US59) ----

export async function getServiceListings(): Promise<ServiceListingRow[]> {
  return listServiceListings();
}

export async function archiveListing(listing: ServiceListingRow): Promise<void> {
  await updateServiceStatus(listing.id, "archived");
}

export async function restoreListing(listing: ServiceListingRow): Promise<void> {
  await updateServiceStatus(listing.id, "live");
}

// ---- Pricing (US63) ----

export async function getPricingPlans(): Promise<PricingPlanRow[]> {
  return listAllPricingPlans();
}

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

export async function getFaqs(): Promise<FaqRow[]> {
  return listAllFaqs();
}

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
