import { authenticateUser, EMAIL_NOT_CONFIRMED } from "@/boundary/gateways/authGateway";
import type { LoginForm, LoginViewResult } from "./loginModels";

// Thrown when the account exists but its email hasn't been verified yet.
// The login page catches this to show the "check your email" prompt.
export class EmailNotConfirmedError extends Error {
  constructor(public email: string) {
    super("Please verify your email before logging in.");
    this.name = "EmailNotConfirmedError";
  }
}

export async function loginUser(form: LoginForm): Promise<LoginViewResult> {
  const email = form.email.trim().toLowerCase();

  if (!email) {
    throw new Error("Email is required.");
  }
  if (!form.password) {
    throw new Error("Password is required.");
  }

  let user;
  try {
    user = await authenticateUser({ email, password: form.password });
  } catch (e) {
    if (e instanceof Error && e.message === EMAIL_NOT_CONFIRMED) {
      throw new EmailNotConfirmedError(email);
    }
    throw e;
  }

  if (user.status === "suspended") {
    throw new Error("This account is suspended.");
  }

  return {
    message: `Welcome back, ${user.first_name}.`,
    redirectTo: routeForUser(user.role, user.expert_status),
  };
}

// Admins go to the portal; approved experts and anyone with an expert application
// (role stays 'free' while pending) go to the expert home; everyone else to the member home.
function routeForUser(
  role: "free" | "premium" | "expert" | "admin",
  expertStatus: "none" | "pending" | "verified" | "rejected",
): string {
  if (role === "admin") return "/admin";
  if (role === "expert" || expertStatus !== "none") return "/expert/home";
  return "/home";
}
