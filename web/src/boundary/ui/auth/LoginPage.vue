<script setup lang="ts">
import { reactive, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { loginUser } from "@/controller/auth/loginUser";

const router = useRouter();

const form = reactive({
  email: "",
  password: "",
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
    const result = await loginUser(form);
    if (result.redirectTo === "/admin") {
      await router.push("/admin");
      return;
    }
    success.value = `${result.message} Continue to ${result.redirectTo}.`;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <main class="auth-shell">
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
          <input
            v-model="form.password"
            type="password"
            autocomplete="current-password"
            required
          />
        </label>

        <p v-if="error" class="auth-message error">{{ error }}</p>
        <p v-if="success" class="auth-message success">{{ success }}</p>

        <button type="submit" class="button primary auth-submit" :disabled="submitting">
          {{ submitting ? "Signing in..." : "Sign in" }}
        </button>
      </form>

      <div class="auth-switch">
        New to Wise Workout?
        <RouterLink to="/register" class="auth-link">Create account</RouterLink>
      </div>
    </section>
  </main>
</template>

<style scoped>
@import "./auth.css";
</style>
