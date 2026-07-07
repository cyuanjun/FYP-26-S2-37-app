export interface RegisterUserRequest {
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  password: string;
}

export interface RegisterExpertRequest extends RegisterUserRequest {
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  verification_documents: ExpertVerificationDocumentDraft[];
}

export interface ExpertVerificationDocumentDraft {
  doc_type: "identity" | "certification";
  title: string;
  file_name: string;
  file_size: number;
  mime_type: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegistrationResult {
  id: string;
  role: "free" | "expert";
  status: "pending" | "created";
}

export interface LoginResult {
  id: string;
  role: "free" | "premium" | "expert" | "admin";
  status: "active" | "suspended";
  first_name: string;
}
