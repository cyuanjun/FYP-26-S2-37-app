import { readApprovedTestimonials } from "@/boundary/gateways/testimonialGateway";
import type { TestimonialSubmission } from "./viewModels";

export async function getTestimonials(): Promise<TestimonialSubmission[]> {
  return readApprovedTestimonials();
}
