import { readApprovedTestimonials } from "@/boundary/gateways/testimonialGateway";
import type { TestimonialSubmission } from "./viewModels";

// (#) Returns only the admin-approved testimonials for public display, via the
// (#) testimonial gateway.
export async function getTestimonials(): Promise<TestimonialSubmission[]> {
  return readApprovedTestimonials();
}
