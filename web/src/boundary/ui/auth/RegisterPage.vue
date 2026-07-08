<script setup lang="ts">
import { reactive, ref } from "vue";
import { RouterLink } from "vue-router";
import { registerUser } from "@/controller/auth/registerUser";

const form = reactive({
  first_name: "",
  last_name: "",
  username: "",
  email: "",
  password: "",
  confirm: "",
});

const error = ref<string | null>(null);
const success = ref<string | null>(null);
const submitting = ref(false);

async function onSubmit() {
  if (submitting.value) return;
  error.value = null;
  success.value = null;
  submitting.value = true;

  try {
    const result = await registerUser(form);
    success.value = result.message;
    form.first_name = "";
    form.last_name = "";
    form.username = "";
    form.email = "";
    form.password = "";
    form.confirm = "";
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <main class="auth-shell">
    <div class="auth-column">
      <div class="auth-back-top">
        <RouterLink to="/" class="auth-link">← Back to landing page</RouterLink>
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
          <input
            v-model="form.password"
            type="password"
            minlength="8"
            autocomplete="new-password"
            required
          />
        </label>

        <label class="auth-field">
          <span>Confirm password</span>
          <input
            v-model="form.confirm"
            type="password"
            minlength="8"
            autocomplete="new-password"
            required
          />
        </label>

        <p v-if="error" class="auth-message error">{{ error }}</p>
        <p v-if="success" class="auth-message success">{{ success }}</p>

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
  </main>
</template>

<style scoped>
@import "./auth.css";
</style>
