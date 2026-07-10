<script setup lang="ts">
import { reactive, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { loginUser, EmailNotConfirmedError } from "@/controller/auth/loginUser";
import { resendVerification } from "@/controller/auth/resendVerification";

const router = useRouter();

const form = reactive({
  email: "",
  password: "",
});

const error = ref<string | null>(null);
const submitting = ref(false);

// Toggles the password field between hidden and plain text.
const showPassword = ref(false);

// Shown when login is blocked because the email isn't verified yet.
const showVerifyModal = ref(false);
const unverifiedEmail = ref("");
const resending = ref(false);
const resendNote = ref<string | null>(null);

async function onSubmit() {
  if (submitting.value) return;
  error.value = null;
  submitting.value = true;

  try {
    const result = await loginUser(form);
    await router.push(result.redirectTo);
  } catch (e) {
    if (e instanceof EmailNotConfirmedError) {
      unverifiedEmail.value = e.email;
      resendNote.value = null;
      showVerifyModal.value = true;
    } else {
      error.value = e instanceof Error ? e.message : String(e);
    }
  } finally {
    submitting.value = false;
  }
}

async function onResend() {
  if (resending.value) return;
  resending.value = true;
  resendNote.value = null;
  try {
    await resendVerification(unverifiedEmail.value);
    resendNote.value = "Verification email sent. Check your inbox.";
  } catch (e) {
    resendNote.value = e instanceof Error ? e.message : String(e);
  } finally {
    resending.value = false;
  }
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

      <div class="auth-eyebrow">Account login</div>
      <h1 class="auth-title">Sign in</h1>
      <p class="auth-note">
        Sign in with your Wise Workout account.
      </p>

      <form class="auth-form" @submit.prevent="onSubmit">
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
              autocomplete="current-password"
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

        <p v-if="error" class="auth-message error">{{ error }}</p>

        <button type="submit" class="button primary auth-submit" :disabled="submitting">
          {{ submitting ? "Signing in..." : "Sign in" }}
        </button>
      </form>

      <div class="auth-switch">
        New to Wise Workout?
        <RouterLink to="/register" class="auth-link">Create account</RouterLink>
      </div>
      </section>
    </div>

    <!-- Blocks login until the account's email is verified. -->
    <div v-if="showVerifyModal" class="modal-backdrop" @click.self="showVerifyModal = false">
      <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="verify-login-title">
        <div class="modal-icon" aria-hidden="true">✉️</div>
        <h2 id="verify-login-title" class="modal-title">Verify your email first</h2>
        <p class="modal-text">
          Please verify <strong>{{ unverifiedEmail }}</strong> before logging in.
          Check your inbox for the verification link we sent when you registered.
        </p>
        <p v-if="resendNote" class="modal-note">{{ resendNote }}</p>
        <button type="button" class="button primary modal-button" :disabled="resending" @click="onResend">
          {{ resending ? "Sending..." : "Resend verification email" }}
        </button>
        <button type="button" class="modal-dismiss" @click="showVerifyModal = false">Close</button>
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
  margin: 0 0 12px;
  font-size: 15px;
  line-height: 1.5;
  color: #4b5563;
}
.modal-note {
  margin: 0 0 16px;
  font-size: 14px;
  color: #059669;
}
.modal-button {
  width: 100%;
}
.modal-dismiss {
  margin-top: 12px;
  background: none;
  border: none;
  padding: 0;
  color: #6b7280;
  font-weight: 600;
  cursor: pointer;
}
</style>
