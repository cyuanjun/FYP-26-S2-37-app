import type {
  ExpertStatus,
  LoginRequest,
  LoginResult,
  RegisterExpertRequest,
  RegisterUserRequest,
  RegistrationResult,
  SessionMember,
} from "./authDtos";
import { supabase } from "./supabaseClient";

// Looks up whether a user has an expert application and its review state.
// "none" = never applied; a profile's role flips to 'expert' only once an admin approves.
async function fetchExpertStatus(userId: string): Promise<ExpertStatus> {
  const { data } = await supabase
    .from("expert_profiles")
    .select("verification_status")
    .eq("id", userId)
    .maybeSingle();
  return (data?.verification_status as ExpertStatus) ?? "none";
}

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

  // Upload the actual document files so an admin can open them during review.
  // Needs a session: on the local/demo stack signUp returns one immediately so
  // this runs; on a project with email confirmation the account has no session
  // yet — the application still succeeds, documents stay name-only until later.
  await uploadVerificationDocuments(data.user.id, input);

  await supabase.auth.signOut();
  return { id: data.user.id, role: "expert", status: "pending" };
}

async function uploadVerificationDocuments(
  userId: string,
  input: RegisterExpertRequest,
): Promise<void> {
  try {
    let session = (await supabase.auth.getSession()).data.session;
    if (!session) {
      const signIn = await supabase.auth.signInWithPassword({
        email: input.email,
        password: input.password,
      });
      session = signIn.data.session;
    }
    if (!session) return; // e.g. email confirmation pending → name-only fallback

    for (let i = 0; i < input.verification_documents.length; i++) {
      const doc = input.verification_documents[i];
      if (!doc.file) continue;
      const safe = doc.file_name.replace(/[^a-zA-Z0-9._-]/g, "_");
      const path = `${userId}/${doc.doc_type}-${i}-${safe}`;
      const up = await supabase.storage
        .from("expert-docs")
        .upload(path, doc.file, { contentType: doc.mime_type || undefined, upsert: true });
      if (up.error) continue;
      // Attach the object path to the metadata row the signup trigger created.
      await supabase
        .from("expert_verification_documents")
        .update({ storage_path: path })
        .eq("user_id", userId)
        .eq("doc_type", doc.doc_type)
        .eq("file_name", doc.file_name)
        .is("storage_path", null);
    }
  } catch {
    // Best-effort: the application already exists, so degrade to name-only
    // rather than failing the whole submission.
  }
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
    expert_status: await fetchExpertStatus(profile.id),
  };
}

// Resolves the signed-in member from the current session, or null when nobody
// is signed in. Guards /home and /expert/home the way fetchAdminIdentity guards /admin.
export async function fetchSessionMember(): Promise<SessionMember | null> {
  const { data: sessionData } = await supabase.auth.getSession();
  const user = sessionData.session?.user;
  if (!user) return null;
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("id, role, status, first_name")
    .eq("id", user.id)
    .single();
  if (error || !profile) return null;
  return {
    id: profile.id,
    first_name: profile.first_name ?? "Member",
    role: profile.role as SessionMember["role"],
    status: (profile.status ?? "active") as SessionMember["status"],
    expert_status: await fetchExpertStatus(profile.id),
  };
}

// Ends the session (used by the /home and /expert/home sign-out buttons).
export async function signOutMember(): Promise<void> {
  await supabase.auth.signOut();
}
