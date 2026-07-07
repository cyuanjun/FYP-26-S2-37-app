import { authenticateUser } from "@/boundary/gateways/authGateway";
import type { LoginForm, LoginViewResult } from "./loginModels";

export async function loginUser(form: LoginForm): Promise<LoginViewResult> {
  const email = form.email.trim().toLowerCase();

  if (!email) {
    throw new Error("Email is required.");
  }
  if (!form.password) {
    throw new Error("Password is required.");
  }

  const user = await authenticateUser({
    email,
    password: form.password,
  });

  if (user.status === "suspended") {
    throw new Error("This account is suspended.");
  }

  return {
    message: `Welcome back, ${user.first_name}.`,
    redirectTo: routeForRole(user.role),
  };
}

function routeForRole(role: "free" | "premium" | "expert" | "admin"): string {
  if (role === "admin") return "/admin";
  if (role === "expert") return "/expert/home";
  return "/home";
}
