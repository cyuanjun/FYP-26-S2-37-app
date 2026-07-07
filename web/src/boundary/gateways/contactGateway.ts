import type { ContactMessageInput } from "./landingDtos";

export async function insertContactMessage(_input: ContactMessageInput): Promise<void> {
  // Supabase insert will be wired here when the shared database is connected.
}
