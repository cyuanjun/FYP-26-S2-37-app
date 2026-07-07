import { fetchAdminIdentity, signOutAdmin } from "@/boundary/gateways/adminGateway";
import type { AdminIdentity } from "@/boundary/gateways/adminDtos";

/// Guard for every /admin route: resolves the signed-in admin or null
/// (not signed in, or signed in without the admin role).
export async function getAdminIdentity(): Promise<AdminIdentity | null> {
  return fetchAdminIdentity();
}

export async function logoutAdmin(): Promise<void> {
  await signOutAdmin();
}
