import { fetchAdminIdentity, signOutAdmin } from "@/boundary/gateways/adminGateway";
import type { AdminIdentity } from "@/boundary/gateways/adminDtos";

// (#) Guard for every /admin route: asks the admin gateway who is signed in,
// (#) returning null when there's no session or the account isn't an admin.
export async function getAdminIdentity(): Promise<AdminIdentity | null> {
  return fetchAdminIdentity();
}

// (#) Signs the admin out via the gateway (ends the Supabase auth session).
export async function logoutAdmin(): Promise<void> {
  await signOutAdmin();
}
