<script setup lang="ts">
// (#) Member sign-up page: creates the account, then asks the user to verify their email.
import { reactive, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { registerUser } from "@/controller/auth/registerUser";

const router = useRouter();

// (#) The new-account fields bound to the registration inputs.
const form = reactive({
  first_name: "",
  last_name: "",
  username: "",
  email: "",
  password: "",
  confirm: "",
});

// (#) Error text shown when sign-up fails (e.g. taken username).
const error = ref<string | null>(null);
// (#) True while the sign-up request is running.
const submitting = ref(false);

// (#) Toggles for the password and confirm-password fields.
const showPassword = ref(false);
const showConfirm = ref(false);

// (#) Shown after a successful sign-up: prompt to verify email before logging in.
const showVerifyModal = ref(false);
// (#) The email we just registered, echoed back in the modal.
const registeredEmail = ref("");

// (#) Registers the account; on success clears the form and opens the verify modal.
async function onSubmit() {
  if (submitting.value) return;
  error.value = null;
  submitting.value = true;

  try {
    await registerUser(form);
    registeredEmail.value = form.email.trim().toLowerCase();
    form.first_name = "";
    form.last_name = "";
    form.username = "";
    form.email = "";
    form.password = "";
    form.confirm = "";
    showVerifyModal.value = true;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    submitting.value = false;
  }
}

// (#) Closes the modal and sends the user to the login page.
function goToLogin() {
  showVerifyModal.value = false;
  router.push("/login");
}
</script>

<template>
  <main class="auth-shell">
    <div class="auth-column">
      <div class="auth-back-top">
        <RouterLink to="/" class="auth-back-link"><span aria-hidden="true">←</span> Back to landing</RouterLink>
      </div>
      <section class="auth-card">
      <RouterLink to="/" class="auth-brand" aria-label="Wise Workout home">
        <span class="brand-mark" aria-hidden="true"></span>
        <span class="brand-name">Wise <span>Workout</span></span>
      </RouterLink>

      <div class="auth-eyebrow">Member registration</div>
      <h1 class="auth-title">Create account</h1>
      <p class="auth-note">
        Create your Wise Workout account to track workouts, view progress, and access expert support.
      </p>

      <form class="auth-form" @submit.prevent="onSubmit">
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

        <label class="auth-field">
          <span>Password</span>
          <div class="password-wrap">
            <input
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              minlength="8"
              autocomplete="new-password"
              required
            />
            <button
              type="button"
              class="password-peek"
              :aria-label="showPassword ? 'Hide password' : 'Show password'"
              @click="showPassword = !showPassword"
            >
              {{ showPassword ? "Hide" : "Show" }}
            </button>
          </div>
        </label>

        <label class="auth-field">
          <span>Confirm password</span>
          <div class="password-wrap">
            <input
              v-model="form.confirm"
              :type="showConfirm ? 'text' : 'password'"
              minlength="8"
              autocomplete="new-password"
              required
            />
            <button
              type="button"
              class="password-peek"
              :aria-label="showConfirm ? 'Hide password' : 'Show password'"
              @click="showConfirm = !showConfirm"
            >
              {{ showConfirm ? "Hide" : "Show" }}
            </button>
          </div>
        </label>

        <p v-if="error" class="auth-message error">{{ error }}</p>

        <button type="submit" class="button primary auth-submit" :disabled="submitting">
          {{ submitting ? "Creating..." : "Create account" }}
        </button>
      </form>

      <div class="auth-switch">
        Applying as an expert?
        <RouterLink to="/expert-application" class="auth-link">Submit expert application</RouterLink>
      </div>
      </section>
    </div>

    <!-- Verify-email popup shown after a successful sign-up. -->
    <div v-if="showVerifyModal" class="modal-backdrop" @click.self="goToLogin">
      <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="verify-title">
        <div class="modal-icon" aria-hidden="true">✉️</div>
        <h2 id="verify-title" class="modal-title">Check your email</h2>
        <p class="modal-text">
          We've sent a verification link to
          <strong>{{ registeredEmail }}</strong>. Please verify your email before
          logging in.
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
