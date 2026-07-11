import {
  listAllTestimonials,
  listContactMessages,
  listFeedback,
  respondToContactMessage,
  reviewTestimonial,
  updateFeedbackStatus,
} from "@/boundary/gateways/adminGateway";
import type {
  ContactMessageRow,
  FeedbackRow,
  TestimonialRow,
} from "@/boundary/gateways/adminDtos";

// ---- Testimonials (US63) ----

// (#) Lists all submitted testimonials (any status) for moderation.
export async function getTestimonials(): Promise<TestimonialRow[]> {
  return listAllTestimonials();
}

// (#) Approves a testimonial so it can appear on the site, with an optional
// (#) admin reply (blank reply is stored as null).
export async function approveTestimonial(row: TestimonialRow, reply: string): Promise<void> {
  await reviewTestimonial(row.id, "approved", reply.trim() || null);
}

// (#) Rejects a testimonial, optionally attaching a reply explaining why.
export async function rejectTestimonial(row: TestimonialRow, reply: string): Promise<void> {
  await reviewTestimonial(row.id, "rejected", reply.trim() || null);
}

// ---- Feedback (US60) ----

// (#) Reads the in-app feedback submissions for the admin inbox.
export async function getFeedback(): Promise<FeedbackRow[]> {
  return listFeedback();
}

// (#) Marks a feedback item as reviewed (handled).
export async function markFeedbackReviewed(row: FeedbackRow): Promise<void> {
  await updateFeedbackStatus(row.id, "reviewed");
}

// (#) Puts a feedback item back to "new" so it shows as unhandled again.
export async function reopenFeedback(row: FeedbackRow): Promise<void> {
  await updateFeedbackStatus(row.id, "new");
}

// ---- Contact messages (US60 / #28.1) ----

// (#) Lists contact-form messages from the landing page.
export async function getContactMessages(): Promise<ContactMessageRow[]> {
  return listContactMessages();
}

// (#) Resolves a contact message by saving the admin's response (which the
// (#) UI then offers as a mailto reply). Requires at least a few characters.
export async function resolveContactMessage(row: ContactMessageRow, response: string): Promise<void> {
  if (response.trim().length < 5) throw new Error("Write a short response before resolving.");
  await respondToContactMessage(row.id, response.trim());
}
