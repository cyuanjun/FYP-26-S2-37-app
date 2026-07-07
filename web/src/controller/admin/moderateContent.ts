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

export async function getTestimonials(): Promise<TestimonialRow[]> {
  return listAllTestimonials();
}

export async function approveTestimonial(row: TestimonialRow, reply: string): Promise<void> {
  await reviewTestimonial(row.id, "approved", reply.trim() || null);
}

export async function rejectTestimonial(row: TestimonialRow, reply: string): Promise<void> {
  await reviewTestimonial(row.id, "rejected", reply.trim() || null);
}

// ---- Feedback (US60) ----

export async function getFeedback(): Promise<FeedbackRow[]> {
  return listFeedback();
}

export async function markFeedbackReviewed(row: FeedbackRow): Promise<void> {
  await updateFeedbackStatus(row.id, "reviewed");
}

export async function reopenFeedback(row: FeedbackRow): Promise<void> {
  await updateFeedbackStatus(row.id, "new");
}

// ---- Contact messages (US60 / #28.1) ----

export async function getContactMessages(): Promise<ContactMessageRow[]> {
  return listContactMessages();
}

export async function resolveContactMessage(row: ContactMessageRow, response: string): Promise<void> {
  if (response.trim().length < 5) throw new Error("Write a short response before resolving.");
  await respondToContactMessage(row.id, response.trim());
}
