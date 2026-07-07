import {
  listUsers,
  updateUserRole,
  updateUserStatus,
} from "@/boundary/gateways/adminGateway";
import type { AdminUser } from "@/boundary/gateways/adminDtos";

export async function getUsers(): Promise<AdminUser[]> {
  return listUsers();
}

export async function suspendUser(user: AdminUser): Promise<void> {
  if (user.role === "admin") throw new Error("Admins cannot be suspended from here.");
  await updateUserStatus(user.id, "suspended");
}

export async function reactivateUser(user: AdminUser): Promise<void> {
  await updateUserStatus(user.id, null);
}

/// Role management is free ↔ premium only. Expert comes from application
/// approval; admin is never granted from the portal.
export async function setUserTier(user: AdminUser, role: "free" | "premium"): Promise<void> {
  if (user.role === "admin" || user.role === "expert") {
    throw new Error("Only free/premium tiers can be switched here.");
  }
  await updateUserRole(user.id, role);
}
