import { fetchSessionMember, signOutMember } from "@/boundary/gateways/authGateway";
import type { SessionMember } from "@/boundary/gateways/authDtos";

// (#) Re-export the session type so views can import it straight from the controller.
export type { SessionMember };

// (#) Guard for /download and /expert: resolves the signed-in member, or null when
// nobody is signed in (send them back to /login). Asks the auth gateway for the session.
export async function getMemberSession(): Promise<SessionMember | null> {
  return fetchSessionMember();
}

// (#) Logout use case: tells the auth gateway to sign the member out.
export async function logoutMember(): Promise<void> {
  await signOutMember();
}
