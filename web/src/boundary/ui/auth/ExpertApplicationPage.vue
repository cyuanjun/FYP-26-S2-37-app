<script setup lang="ts">
// (#) Expert sign-up page: collects account + profile + verification docs and submits the application for review.
import { computed, onMounted, reactive, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import {
  getExpertSpecialties,
  type ExpertSpecialtyOption,
} from "@/controller/auth/getExpertSpecialties";
import { registerExpert } from "@/controller/auth/registerExpert";

const router = useRouter();

// (#) All the fields for the whole application, bound to the form inputs.
const form = reactive({
  first_name: "",
  last_name: "",
  username: "",
  email: "",
  password: "",
  confirm: "",
  title: "",
  years_coaching: 0,
  about: "",
  credentials: [""] as string[],
  specialties: [] as string[],
  identity_document: null as File | null,
  certification_documents: [] as File[],
});

// (#) Error message to show if the submit fails.
const error = ref<string | null>(null);
// (#) True while the request is in flight so we can disable the button.
const submitting = ref(false);
// (#) Shown after a successful submit: prompt to verify email before login/review.
const showVerifyModal = ref(false);
// (#) The email we just registered, echoed back in the modal.
const registeredEmail = ref("");
// (#) The specialty chips loaded from the backend.
const specialtyOptions = ref<ExpertSpecialtyOption[]>([]);

// (#) Live character count for the about box (limit is 1000).
const aboutCount = computed(() => form.about.length);
// (#) Friendly caption telling the user how many cert files they picked.
const certificationSelectionLabel = computed(() => {
  const count = form.certification_documents.length;
  if (count === 0) return "No certification documents selected. Upload up to 4.";
  if (count === 1) return "1 of 4 certification documents selected.";
  return `${count} of 4 certification documents selected.`;
});

// (#) Adds another empty credential row, capped at 10.
function addCredential() {
  if (form.credentials.length < 10) form.credentials.push("");
}

// (#) Drops a credential row, but always keeps at least one.
function removeCredential(index: number) {
  if (form.credentials.length > 1) form.credentials.splice(index, 1);
}

// (#) Flips a specialty chip on or off in the selection.
function toggleSpecialty(specialty: string) {
  const index = form.specialties.indexOf(specialty);
  if (index >= 0) form.specialties.splice(index, 1);
  else form.specialties.push(specialty);
}

// (#) Grabs the chosen identity file from the file input.
function onIdentityDocumentChange(event: Event) {
  const input = event.target as HTMLInputElement;
  form.identity_document = input.files?.[0] ?? null;
}

// (#) Grabs the chosen certification files, keeping at most 4.
function onCertificationDocumentsChange(event: Event) {
  const input = event.target as HTMLInputElement;
  form.certification_documents = Array.from(input.files ?? []).slice(0, 4);
}

// (#) Formats a file's byte size as a readable MB string.
function fileSizeLabel(file: File): string {
  return `${(file.size / (1024 * 1024)).toFixed(1)} MB`;
}

// (#) On load, fetch the specialty options for the chip grid.
onMounted(async () => {
  specialtyOptions.value = await getExpertSpecialties();
});

// (#) Submits the application and shows the success or error message.
async function onSubmit() {
  if (submitting.value) return;
  error.value = null;
  submitting.value = true;

  try {
    await registerExpert(form);
    registeredEmail.value = form.email.trim().toLowerCase();
    showVerifyModal.value = true;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    submitting.value = false;
  }
}

// (#) Closes the modal and sends the applicant to the login page.
function goToLogin() {
  showVerifyModal.value = false;
  router.push("/login");
}
</script>

<template>
  <main class="auth-shell">
    <div class="auth-column wide">
      <div class="auth-back-top">
        <RouterLink to="/" class="auth-back-link"><span aria-hidden="true">←</span> Back to landing</RouterLink>
      </div>
      <section class="auth-card">
      <RouterLink to="/" class="auth-brand" aria-label="Wise Workout home">
        <span class="brand-mark" aria-hidden="true"></span>
        <span class="brand-name">Wise <span>Workout</span></span>
      </RouterLink>

      <div class="auth-eyebrow">Expert registration</div>
      <h1 class="auth-title">Apply as expert</h1>
      <p class="auth-note">
        Submit your profile for review and join the verified expert network.
      </p>

      <form class="auth-form" @submit.prevent="onSubmit">
        <h2 class="form-section">Account</h2>
        <div class="auth-row">
          <label class="auth-field">
            <span>First name</span>
            <input v-model="form.first_name" type="text" maxlength="60" autocomplete="given-name" required />
          </label>
          <label class="auth-field">
            <span>Last name</span>
            <input v-model="form.last_name" type="text" maxlength="60" autocomplete="family-name" required />
          </label>
        </div>

        <div class="auth-row">
          <label class="auth-field">
            <span>Username</span>
            <input
              v-model="form.username"
              type="text"
              maxlength="30"
              autocomplete="username"
              pattern="[A-Za-z0-9_]{3,30}"
              required
            />
          </label>
          <label class="auth-field">
            <span>Email</span>
            <input v-model="form.email" type="email" autocomplete="email" required />
          </label>
        </div>

        <div class="auth-row">
          <label class="auth-field">
            <span>Password</span>
            <input v-model="form.password" type="password" minlength="8" autocomplete="new-password" required />
          </label>
          <label class="auth-field">
            <span>Confirm password</span>
            <input v-model="form.confirm" type="password" minlength="8" autocomplete="new-password" required />
          </label>
        </div>

        <h2 class="form-section">Expert profile</h2>
        <label class="auth-field">
          <span>Profile title</span>
          <input v-model="form.title" type="text" maxlength="100" placeholder="Strength Coach" required />
        </label>

        <label class="auth-field">
          <span>Years coaching</span>
          <input v-model.number="form.years_coaching" type="number" min="0" max="80" required />
        </label>

        <label class="auth-field">
          <span>About</span>
          <textarea
            v-model="form.about"
            rows="5"
            minlength="30"
            maxlength="1000"
            placeholder="Tell members what you specialise in and how you coach."
            required
          ></textarea>
          <span class="field-hint">{{ aboutCount }} / 1000</span>
        </label>

        <div class="auth-field">
          <span>Credentials</span>
          <div v-for="(_, index) in form.credentials" :key="index" class="inline-row">
            <input v-model="form.credentials[index]" type="text" maxlength="160" :placeholder="`Credential ${index + 1}`" />
            <button
              v-if="form.credentials.length > 1"
              type="button"
              class="mini-button"
              aria-label="Remove credential"
              @click="removeCredential(index)"
            >
              Remove
            </button>
          </div>
          <button v-if="form.credentials.length < 10" type="button" class="button" @click="addCredential">
            Add credential
          </button>
        </div>

        <div class="auth-field">
          <span>Specialties</span>
          <div class="chip-grid">
            <button
              v-for="specialty in specialtyOptions"
              :key="specialty.value"
              type="button"
              class="chip"
              :class="{ active: form.specialties.includes(specialty.value) }"
              @click="toggleSpecialty(specialty.value)"
            >
              {{ specialty.label }}
            </button>
          </div>
        </div>

        <h2 class="form-section">Verification documents</h2>
        <p class="field-note">
          Upload PDF or image files. Each file must be 5 MB or smaller.
        </p>

        <label class="auth-field file-field">
          <span>Identity document</span>
          <input
            type="file"
            accept="application/pdf,image/jpeg,image/png,image/webp"
            required
            @change="onIdentityDocumentChange"
          />
          <span v-if="form.identity_document" class="field-hint">
            {{ form.identity_document.name }} / {{ fileSizeLabel(form.identity_document) }}
          </span>
        </label>

        <label class="auth-field file-field">
          <span>Certification documents</span>
          <input
            type="file"
            accept="application/pdf,image/jpeg,image/png,image/webp"
            multiple
            required
            @change="onCertificationDocumentsChange"
          />
          <span class="field-hint">
            {{ certificationSelectionLabel }}
          </span>
        </label>

        <ul v-if="form.certification_documents.length" class="file-list">
          <li v-for="file in form.certification_documents" :key="`${file.name}-${file.size}`">
            {{ file.name }} / {{ fileSizeLabel(file) }}
          </li>
        </ul>

        <p v-if="error" class="auth-message error">{{ error }}</p>

        <button type="submit" class="button primary auth-submit" :disabled="submitting">
          {{ submitting ? "Submitting..." : "Submit application" }}
        </button>
      </form>

      <div class="auth-switch">
        Just tracking workouts?
        <RouterLink to="/register" class="auth-link">Register as member</RouterLink>
      </div>
      </section>
    </div>

    <!-- Verify-email popup shown after a successful application. -->
    <div v-if="showVerifyModal" class="modal-backdrop" @click.self="goToLogin">
      <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="expert-verify-title">
        <div class="modal-icon" aria-hidden="true">✉️</div>
        <h2 id="expert-verify-title" class="modal-title">Application submitted</h2>
        <p class="modal-text">
          We've sent a verification link to <strong>{{ registeredEmail }}</strong>.
          Verify your email, then our team reviews your application. You can log in
          once your email is verified.
        </p>
        <button type="button" class="button primary modal-button" @click="goToLogin">
          Go to login
        </button>
      </div>
    </div>
  </main>
</template>

<style scoped>
@import "./auth.css";

.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 17, 24, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  z-index: 100;
}
.modal-card {
  background: #fff;
  border-radius: 18px;
  padding: 32px 28px;
  max-width: 380px;
  width: 100%;
  text-align: center;
  box-shadow: 0 24px 60px rgba(15, 17, 24, 0.25);
}
.modal-icon {
  font-size: 40px;
  margin-bottom: 8px;
}
.modal-title {
  margin: 0 0 10px;
  font-size: 22px;
  font-weight: 700;
  color: #111318;
}
.modal-text {
  margin: 0 0 22px;
  font-size: 15px;
  line-height: 1.5;
  color: #4b5563;
}
.modal-button {
  width: 100%;
}
</style>
