import { fetchSessionMember, signOutMember } from "@/boundary/gateways/authGateway";
import type { SessionMember } from "@/boundary/gateways/authDtos";

export type { SessionMember };

/// Guard for /home and /expert/home: resolves the signed-in member, or null when
/// nobody is signed in (send them back to /login).
export async function getMemberSession(): Promise<SessionMember | null> {
  return fetchSessionMember();
}

export async function logoutMember(): Promise<void> {
  await signOutMember();
}
