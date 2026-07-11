import { resendVerificationEmail } from "@/boundary/gateways/authGateway";

// (#) Re-sends the verification email to an unverified account from the login prompt.
// Cleans up the email, checks it's not empty, then calls the auth gateway to resend.
export async function resendVerification(email: string): Promise<void> {
  const clean = email.trim().toLowerCase();
  if (!clean) {
    throw new Error("Email is required.");
  }
  await resendVerificationEmail(clean);
}
