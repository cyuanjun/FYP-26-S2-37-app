import {
  listExpertApplications,
  reviewExpertApplication,
} from "@/boundary/gateways/adminGateway";
import type { ExpertApplication } from "@/boundary/gateways/adminDtos";

export async function getPendingApplications(): Promise<ExpertApplication[]> {
  return listExpertApplications();
}

export async function approveApplication(application: ExpertApplication): Promise<void> {
  await reviewExpertApplication(application.id, true);
}

export async function rejectApplication(application: ExpertApplication): Promise<void> {
  await reviewExpertApplication(application.id, false);
}
