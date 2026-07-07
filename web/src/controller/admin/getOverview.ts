import {
  listAllTestimonials,
  listContactMessages,
  listExpertApplications,
  listFeedback,
  listUsers,
} from "@/boundary/gateways/adminGateway";

export interface AdminOverview {
  totalUsers: number;
  freeUsers: number;
  premiumUsers: number;
  experts: number;
  suspended: number;
  pendingApplications: number;
  openContactMessages: number;
  pendingTestimonials: number;
  newFeedback: number;
}

export async function getOverview(): Promise<AdminOverview> {
  const [users, applications, contact, testimonials, feedback] = await Promise.all([
    listUsers(),
    listExpertApplications(),
    listContactMessages(),
    listAllTestimonials(),
    listFeedback(),
  ]);
  return {
    totalUsers: users.length,
    freeUsers: users.filter((u) => u.role === "free").length,
    premiumUsers: users.filter((u) => u.role === "premium").length,
    experts: users.filter((u) => u.role === "expert").length,
    suspended: users.filter((u) => u.status === "suspended").length,
    pendingApplications: applications.length,
    openContactMessages: contact.filter((m) => m.status === "open").length,
    pendingTestimonials: testimonials.filter((t) => t.status === "pending").length,
    newFeedback: feedback.filter((f) => f.status === "new").length,
  };
}
