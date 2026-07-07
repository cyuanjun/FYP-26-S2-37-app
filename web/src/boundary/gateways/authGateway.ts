import type {
  LoginRequest,
  LoginResult,
  RegisterExpertRequest,
  RegisterUserRequest,
  RegistrationResult,
} from "./authDtos";
import { supabase } from "./supabaseClient";

export async function createUserRegistration(
  input: RegisterUserRequest,
): Promise<RegistrationResult> {
  const { data, error } = await supabase.auth.signUp({
    email: input.email,
    password: input.password,
    options: {
      // handle_new_user() mirrors these into profiles on signup.
      data: {
        first_name: input.first_name,
        last_name: input.last_name,
        username: input.username,
      },
    },
  });
  if (error) throw new Error(error.message);
  if (!data.user) throw new Error("Registration failed. Please try again.");

  // Don't keep a session on the marketing site — the account is for the app.
  await supabase.auth.signOut();
  return { id: data.user.id, role: "free", status: "created" };
}

export async function createExpertApplication(
  input: RegisterExpertRequest,
): Promise<RegistrationResult> {
  const { data, error } = await supabase.auth.signUp({
    email: input.email,
    password: input.password,
    options: {
      // handle_new_user() also creates the PENDING expert_profiles row and the
      // verification-document metadata; role stays 'free' until admin approval.
      data: {
        first_name: input.first_name,
        last_name: input.last_name,
        username: input.username,
        expert_application: {
          title: input.title,
          years_coaching: input.years_coaching,
          about: input.about,
          credentials: input.credentials,
          specialties: input.specialties,
          documents: input.verification_documents.map((doc) => ({
            doc_type: doc.doc_type,
            title: doc.title,
            file_name: doc.file_name,
          })),
        },
      },
    },
  });
  if (error) throw new Error(error.message);
  if (!data.user) throw new Error("Application failed. Please try again.");

  await supabase.auth.signOut();
  return { id: data.user.id, role: "expert", status: "pending" };
}

export async function authenticateUser(input: LoginRequest): Promise<LoginResult> {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });
  if (error || !data.user) throw new Error("Invalid email or password.");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, role, status, first_name")
    .eq("id", data.user.id)
    .single();
  if (profileError || !profile) throw new Error("Could not load your profile.");

  return {
    id: profile.id,
    role: profile.role as LoginResult["role"],
    status: (profile.status ?? "active") as LoginResult["status"],
    first_name: profile.first_name ?? "Member",
  };
}
