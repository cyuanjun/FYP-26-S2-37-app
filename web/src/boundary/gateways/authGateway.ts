import type {
  LoginRequest,
  LoginResult,
  RegisterExpertRequest,
  RegisterUserRequest,
  RegistrationResult,
} from "./authDtos";

export async function createUserRegistration(
  _input: RegisterUserRequest,
): Promise<RegistrationResult> {
  // Later: Supabase Auth sign-up + profiles insert/update.
  return {
    id: crypto.randomUUID(),
    role: "free",
    status: "created",
  };
}

export async function createExpertApplication(
  _input: RegisterExpertRequest,
): Promise<RegistrationResult> {
  // Later: Supabase Auth sign-up + profiles + expert_profiles + verification docs.
  return {
    id: crypto.randomUUID(),
    role: "expert",
    status: "pending",
  };
}

export async function authenticateUser(_input: LoginRequest): Promise<LoginResult> {
  // Later: Supabase Auth sign-in + profiles lookup.
  return {
    id: crypto.randomUUID(),
    role: "free",
    status: "active",
    first_name: "Member",
  };
}
