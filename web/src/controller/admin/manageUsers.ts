import {
  listUsers,
  updateUserRole,
  updateUserStatus,
} from "@/boundary/gateways/adminGateway";
import type { AdminUser } from "@/boundary/gateways/adminDtos";

// (#) Lists every account for the admin users table.
export async function getUsers(): Promise<AdminUser[]> {
  return listUsers();
}

// (#) Suspends a user via the gateway. Guards against suspending an admin.
export async function suspendUser(user: AdminUser): Promise<void> {
  if (user.role === "admin") throw new Error("Admins cannot be suspended from here.");
  await updateUserStatus(user.id, "suspended");
}

// (#) Clears a suspension (null status) so the account is active again.
export async function reactivateUser(user: AdminUser): Promise<void> {
  await updateUserStatus(user.id, null);
}

// (#) Switches a user's tier, free to premium only. Expert comes from
// (#) application approval and admin is never granted from the portal, so
// (#) those roles are rejected here.
export async function setUserTier(user: AdminUser, role: "free" | "premium"): Promise<void> {
  if (user.role === "admin" || user.role === "expert") {
    throw new Error("Only free/premium tiers can be switched here.");
  }
  await updateUserRole(user.id, role);
}
