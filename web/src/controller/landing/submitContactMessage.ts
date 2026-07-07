import { insertContactMessage } from "@/boundary/gateways/contactGateway";
import type { ContactMessageInput } from "./viewModels";

export async function submitContactMessage(input: ContactMessageInput): Promise<void> {
  const name = input.submitter_name.trim();
  const email = input.submitter_email.trim();
  const message = input.message.trim();

  if (!name || !email || !message) {
    throw new Error("Please complete all contact fields.");
  }

  await insertContactMessage({ submitter_name: name, submitter_email: email, message });
}
