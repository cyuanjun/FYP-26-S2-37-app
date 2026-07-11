import { createUserRegistration } from "@/boundary/gateways/authGateway";
import type { RegistrationViewResult, UserRegistrationForm } from "./registrationModels";

// (#) Allowed username shape: 3-30 chars, letters/numbers/underscores only.
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,30}$/;

// (#) Plain member sign-up use case: validates the form, then asks the auth gateway to
// create the account and returns a success message for the view.
export async function registerUser(form: UserRegistrationForm): Promise<RegistrationViewResult> {
  validateBaseRegistration(form);

  await createUserRegistration({
    first_name: form.first_name.trim(),
    last_name: form.last_name.trim(),
    username: form.username.trim(),
    email: form.email.trim().toLowerCase(),
    password: form.password,
  });

  return {
    message: "Account created successfully.",
  };
}

// (#) Shared registration checks used by both member and expert sign-up: names present,
// username matches the pattern, email present, password 8+ chars and matching the confirm field.
export function validateBaseRegistration(form: UserRegistrationForm): void {
  if (!form.first_name.trim() || !form.last_name.trim()) {
    throw new Error("First and last name are required.");
  }
  if (!USERNAME_REGEX.test(form.username.trim())) {
    throw new Error("Username must be 3-30 characters, letters, numbers, or underscores only.");
  }
  if (!form.email.trim()) {
    throw new Error("Email is required.");
  }
  if (form.password.length < 8) {
    throw new Error("Password must be at least 8 characters.");
  }
  if (form.password !== form.confirm) {
    throw new Error("Passwords do not match.");
  }
}
