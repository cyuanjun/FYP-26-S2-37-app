import { createExpertApplication } from "@/boundary/gateways/authGateway";
import type { ExpertRegistrationForm, RegistrationViewResult } from "./registrationModels";
import { validateBaseRegistration } from "./registerUser";

// (#) Upload cap for each verification file: 5 MB.
const MAX_DOCUMENT_BYTES = 5 * 1024 * 1024;
// (#) File types we accept for identity + certification docs.
const ALLOWED_DOCUMENT_TYPES = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
]);

// (#) Expert sign-up use case: runs the shared account checks, then the expert-only ones
// (title, years, about length, credentials, specialties, the required docs), and hands the
// whole application off to the auth gateway to create.
export async function registerExpert(
  form: ExpertRegistrationForm,
): Promise<RegistrationViewResult> {
  validateBaseRegistration(form);

  const credentials = form.credentials.map((item) => item.trim()).filter(Boolean);
  const about = form.about.trim();

  if (!form.title.trim()) {
    throw new Error("Expert title is required.");
  }
  if (!Number.isFinite(form.years_coaching) || form.years_coaching < 0) {
    throw new Error("Years of coaching must be zero or more.");
  }
  if (about.length < 30) {
    throw new Error("About must be at least 30 characters.");
  }
  if (credentials.length < 1) {
    throw new Error("Add at least one credential.");
  }
  if (form.specialties.length < 1) {
    throw new Error("Pick at least one specialty.");
  }
  if (!form.identity_document) {
    throw new Error("Upload an identity document.");
  }
  if (form.certification_documents.length < 1) {
    throw new Error("Upload at least one certification document.");
  }

  const documents = [form.identity_document, ...form.certification_documents];
  for (const document of documents) {
    validateDocument(document);
  }

  await createExpertApplication({
    first_name: form.first_name.trim(),
    last_name: form.last_name.trim(),
    username: form.username.trim(),
    email: form.email.trim().toLowerCase(),
    password: form.password,
    title: form.title.trim(),
    years_coaching: Number(form.years_coaching),
    about,
    credentials,
    specialties: form.specialties,
    verification_documents: [
      toDocumentDraft("identity", form.identity_document),
      ...form.certification_documents.map((document) =>
        toDocumentDraft("certification", document),
      ),
    ],
  });

  return {
    message: "Expert application submitted for review.",
  };
}

// (#) Rejects a document that isn't an allowed type or is over the size cap.
function validateDocument(document: File): void {
  if (!ALLOWED_DOCUMENT_TYPES.has(document.type)) {
    throw new Error("Verification documents must be PDF, JPG, PNG, or WebP files.");
  }
  if (document.size > MAX_DOCUMENT_BYTES) {
    throw new Error("Verification documents must be 5 MB or smaller.");
  }
}

// (#) Turns a picked File into the draft shape the gateway wants (type, name, size, mime, blob).
function toDocumentDraft(
  doc_type: "identity" | "certification",
  document: File,
) {
  return {
    doc_type,
    title: document.name,
    file_name: document.name,
    file_size: document.size,
    mime_type: document.type,
    file: document,
  };
}
