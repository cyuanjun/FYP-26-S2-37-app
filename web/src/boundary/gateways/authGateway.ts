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

// (#) Looks up whether a user has an expert application and its review state,
// reading verification_status off expert_profiles. "none" = never applied;
// a profile's role flips to 'expert' only once an admin approves.
async function fetchExpertStatus(userId: string): Promise<ExpertStatus> {
  const { data } = await supabase
    .from("expert_profiles")
    .select("verification_status")
    .eq("id", userId)
    .maybeSingle();
  return (data?.verification_status as ExpertStatus) ?? "none";
}

// (#) Signs up a plain member through Supabase Auth; the handle_new_user()
// trigger creates their profiles row from the metadata we pass.
export async function createUserRegistration(
  input: RegisterUserRequest,
): Promise<RegistrationResult> {
  const { data, error } = await supabase.auth.signUp({
    email: input.email,
    password: input.password,
    options: {
      // (#) Send the verification link back to this site's login page, not the
      // project's default Site URL (localhost). Must be allow-listed in Supabase.
      emailRedirectTo: `${window.location.origin}/login`,
      // (#) handle_new_user() mirrors these into profiles on signup.
      data: {
        first_name: input.first_name,
        last_name: input.last_name,
        username: input.username,
      },
    },
  });
  if (error) throw new Error(error.message);
  if (!data.user) throw new Error("Registration failed. Please try again.");

  // (#) Don't keep a session on the marketing site: the account is for the app.
  await supabase.auth.signOut();
  return { id: data.user.id, role: "free", status: "created" };
}

// (#) Signs up an expert applicant: creates the auth user, then the signup
// trigger spins up a pending expert_profiles row and document metadata.
export async function createExpertApplication(
  input: RegisterExpertRequest,
): Promise<RegistrationResult> {
  const { data, error } = await supabase.auth.signUp({
    email: input.email,
    password: input.password,
    options: {
      // (#) Verification link returns to this site's login page (see note above).
      emailRedirectTo: `${window.location.origin}/login`,
      // (#) handle_new_user() also creates the PENDING expert_profiles row and the
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

  // (#) Upload the actual document files so an admin can open them during review.
  // Needs a session: on the local/demo stack signUp returns one immediately so
  // this runs; on a project with email confirmation the account has no session
  // yet, the application still succeeds and documents stay name-only until later.
  await uploadVerificationDocuments(data.user.id, input);

  await supabase.auth.signOut();
  return { id: data.user.id, role: "expert", status: "pending" };
}

// (#) Uploads each verification file to the expert-docs storage bucket, then
// writes its object path onto the matching expert_verification_documents row.
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
    if (!session) return; // (#) e.g. email confirmation pending -> name-only fallback

    for (let i = 0; i < input.verification_documents.length; i++) {
      const doc = input.verification_documents[i];
      if (!doc.file) continue;
      const safe = doc.file_name.replace(/[^a-zA-Z0-9._-]/g, "_");
      const path = `${userId}/${doc.doc_type}-${i}-${safe}`;
      const up = await supabase.storage
        .from("expert-docs")
        .upload(path, doc.file, { contentType: doc.mime_type || undefined, upsert: true });
      if (up.error) continue;
      // (#) Attach the object path to the metadata row the signup trigger created.
      await supabase
        .from("expert_verification_documents")
        .update({ storage_path: path })
        .eq("user_id", userId)
        .eq("doc_type", doc.doc_type)
        .eq("file_name", doc.file_name)
        .is("storage_path", null);
    }
  } catch {
    // (#) Best-effort: the application already exists, so degrade to name-only
    // rather than failing the whole submission.
  }
}

// (#) Sentinel message the login controller maps to a verify-your-email prompt.
export const EMAIL_NOT_CONFIRMED = "EMAIL_NOT_CONFIRMED";

// (#) Logs a member in, then reads their profiles row for role/status/name;
// throws EMAIL_NOT_CONFIRMED or a generic message on failure.
export async function authenticateUser(input: LoginRequest): Promise<LoginResult> {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });
  if (error || !data.user) {
    // (#) Tell "unverified email" apart from bad credentials so the UI can prompt.
    const unconfirmed =
      (error as { code?: string } | null)?.code === "email_not_confirmed" ||
      /not confirmed|not been confirmed|verify/i.test(error?.message ?? "");
    throw new Error(unconfirmed ? EMAIL_NOT_CONFIRMED : "Invalid email or password.");
  }

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

// (#) Resolves the signed-in member from the current session (session + profiles
// lookup), or null when nobody is signed in. Guards /download and /expert the
// way fetchAdminIdentity guards /admin.
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
  // (#) Treat a suspended account as signed-out, so the /download and /expert
  // (#) guards bounce them even if a session lingers in the browser.
  if ((profile.status ?? "active") === "suspended") return null;
  return {
    id: profile.id,
    first_name: profile.first_name ?? "Member",
    role: profile.role as SessionMember["role"],
    status: (profile.status ?? "active") as SessionMember["status"],
    expert_status: await fetchExpertStatus(profile.id),
  };
}

// (#) Ends the session (used by the header logout button on the download / expert pages).
export async function signOutMember(): Promise<void> {
  await supabase.auth.signOut();
}

// (#) Re-sends the sign-up verification email for an unverified account.
export async function resendVerificationEmail(email: string): Promise<void> {
  const { error } = await supabase.auth.resend({
    type: "signup",
    email,
    options: { emailRedirectTo: `${window.location.origin}/login` },
  });
  if (error) throw new Error(error.message);
}
