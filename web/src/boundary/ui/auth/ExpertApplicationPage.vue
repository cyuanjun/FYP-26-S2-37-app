<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import { RouterLink } from "vue-router";
import {
  getExpertSpecialties,
  type ExpertSpecialtyOption,
} from "@/controller/auth/getExpertSpecialties";
import { registerExpert } from "@/controller/auth/registerExpert";

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

const error = ref<string | null>(null);
const success = ref<string | null>(null);
const submitting = ref(false);
const specialtyOptions = ref<ExpertSpecialtyOption[]>([]);

const aboutCount = computed(() => form.about.length);
const certificationSelectionLabel = computed(() => {
  const count = form.certification_documents.length;
  if (count === 0) return "No certification documents selected. Upload up to 4.";
  if (count === 1) return "1 of 4 certification documents selected.";
  return `${count} of 4 certification documents selected.`;
});

function addCredential() {
  if (form.credentials.length < 10) form.credentials.push("");
}

function removeCredential(index: number) {
  if (form.credentials.length > 1) form.credentials.splice(index, 1);
}

function toggleSpecialty(specialty: string) {
  const index = form.specialties.indexOf(specialty);
  if (index >= 0) form.specialties.splice(index, 1);
  else form.specialties.push(specialty);
}

function onIdentityDocumentChange(event: Event) {
  const input = event.target as HTMLInputElement;
  form.identity_document = input.files?.[0] ?? null;
}

function onCertificationDocumentsChange(event: Event) {
  const input = event.target as HTMLInputElement;
  form.certification_documents = Array.from(input.files ?? []).slice(0, 4);
}

function fileSizeLabel(file: File): string {
  return `${(file.size / (1024 * 1024)).toFixed(1)} MB`;
}

onMounted(async () => {
  specialtyOptions.value = await getExpertSpecialties();
});

async function onSubmit() {
  if (submitting.value) return;
  error.value = null;
  success.value = null;
  submitting.value = true;

  try {
    const result = await registerExpert(form);
    success.value = result.message;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    submitting.value = false;
  }
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
        <p v-if="success" class="auth-message success">{{ success }}</p>

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
  </main>
</template>

<style scoped>
@import "./auth.css";
</style>
