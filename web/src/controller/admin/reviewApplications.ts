import {
  listExpertApplications,
  reviewExpertApplication,
} from "@/boundary/gateways/adminGateway";
import type { ExpertApplication } from "@/boundary/gateways/adminDtos";

// (#) Lists the pending expert applications waiting for admin review.
export async function getPendingApplications(): Promise<ExpertApplication[]> {
  return listExpertApplications();
}

// (#) Approves an application (gateway calls the review_expert_application RPC,
// (#) which promotes the applicant to the expert role).
export async function approveApplication(application: ExpertApplication): Promise<void> {
  await reviewExpertApplication(application.id, true);
}

// (#) Rejects an application via the same review RPC with approve=false.
export async function rejectApplication(application: ExpertApplication): Promise<void> {
  await reviewExpertApplication(application.id, false);
}
