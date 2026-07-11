// (#) Fields the register form collects for a plain member sign-up.
export interface RegisterUserRequest {
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  password: string;
}

// (#) An expert sign-up: everything a normal user gives plus their coaching pitch
// (#) and the verification files an admin will vet.
export interface RegisterExpertRequest extends RegisterUserRequest {
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  verification_documents: ExpertVerificationDocumentDraft[];
}

// (#) One file an applying expert attaches, before it's uploaded to storage.
export interface ExpertVerificationDocumentDraft {
  doc_type: "identity" | "certification";
  title: string;
  file_name: string;
  file_size: number;
  mime_type: string;
  file: File; // (#) the actual upload - stored in the private expert-docs bucket
}

// (#) Email + password sent when a member logs in.
export interface LoginRequest {
  email: string;
  password: string;
}

// (#) What signup hands back: the new id and whether they're live or awaiting review.
export interface RegistrationResult {
  id: string;
  role: "free" | "expert";
  status: "pending" | "created";
}

// (#) Where a user sits in the expert pipeline; "none" until they ever apply.
export type ExpertStatus = "none" | "pending" | "verified" | "rejected";

// (#) The profile we resolve right after a successful login.
export interface LoginResult {
  id: string;
  role: "free" | "premium" | "expert" | "admin";
  status: "active" | "suspended";
  first_name: string;
  expert_status: ExpertStatus;
}

// (#) The signed-in member resolved from the current session (guards /download + /expert).
export interface SessionMember {
  id: string;
  first_name: string;
  role: "free" | "premium" | "expert" | "admin";
  status: "active" | "suspended";
  expert_status: ExpertStatus;
}
