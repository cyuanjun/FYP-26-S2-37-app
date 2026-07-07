import testimonialSeed from "./seed/testimonials.seed.json";
import type { GatewayTestimonialSubmission } from "./landingDtos";

export async function readApprovedTestimonials(): Promise<GatewayTestimonialSubmission[]> {
  return (testimonialSeed as GatewayTestimonialSubmission[])
    .filter((testimonial) => testimonial.status === "approved")
    .sort((a, b) => b.rating - a.rating);
}
