// (#) Fields the plain sign-up form collects, including the confirm-password box.
export interface UserRegistrationForm {
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  password: string;
  confirm: string;
}

// (#) Expert sign-up form: the base account fields plus the extra profile and the
// verification files an application needs.
export interface ExpertRegistrationForm extends UserRegistrationForm {
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  identity_document: File | null;
  certification_documents: File[];
}

// (#) What a registration hands back to the view: just the message to show.
export interface RegistrationViewResult {
  message: string;
}
