export interface UserRegistrationForm {
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  password: string;
  confirm: string;
}

export interface ExpertRegistrationForm extends UserRegistrationForm {
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  identity_document: File | null;
  certification_documents: File[];
}

export interface RegistrationViewResult {
  message: string;
}
