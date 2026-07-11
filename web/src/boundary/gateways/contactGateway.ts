import type { ContactMessageInput } from "./landingDtos";
import { supabase } from "./supabaseClient";

// (#) Writes a visitor's contact-form submission into contact_messages for the
// admin inbox to pick up.
export async function insertContactMessage(input: ContactMessageInput): Promise<void> {
  // (#) contact_messages accepts anon inserts by design (init schema); the
  // admin portal triages them on #28.1.
  const { error } = await supabase.from("contact_messages").insert({
    submitter_name: input.submitter_name,
    submitter_email: input.submitter_email,
    message: input.message,
  });
  if (error) throw new Error("Could not send your message. Please try again.");
}
