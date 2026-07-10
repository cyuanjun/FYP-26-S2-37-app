import { resendVerificationEmail } from "@/boundary/gateways/authGateway";

// Re-sends the verification email to an unverified account from the login prompt.
export async function resendVerification(email: string): Promise<void> {
  const clean = email.trim().toLowerCase();
  if (!clean) {
    throw new Error("Email is required.");
  }
  await resendVerificationEmail(clean);
}
