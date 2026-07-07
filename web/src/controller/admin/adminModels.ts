// View-model types for the admin boundary — re-exported from the gateway
// DTOs so UI components depend on the controller layer only (BCE rule).
export type {
  AdminIdentity,
  AdminUser,
  ContactMessageRow,
  ExpertApplication,
  ExpertCategoryRow,
  FaqRow,
  FeedbackRow,
  PricingPlanRow,
  ServiceListingRow,
  TestimonialRow,
} from "@/boundary/gateways/adminDtos";
