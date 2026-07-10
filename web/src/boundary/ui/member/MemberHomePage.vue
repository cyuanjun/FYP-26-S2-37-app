<script setup lang="ts">
import { onMounted, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { getMemberSession, logoutMember, type SessionMember } from "@/controller/auth/memberSession";

const router = useRouter();
const member = ref<SessionMember | null>(null);
const checking = ref(true);

onMounted(async () => {
  const m = await getMemberSession();
  if (!m) {
    router.replace("/login"); // not signed in
    return;
  }
  if (m.role === "expert" || m.expert_status !== "none") {
    router.replace("/expert/home"); // experts + applicants belong on the expert home
    return;
  }
  member.value = m;
  checking.value = false;
});

async function onSignOut() {
  await logoutMember();
  router.replace("/login");
}
</script>

<template>
  <main class="auth-shell">
    <div class="auth-column">
      <section v-if="!checking && member" class="auth-card">
        <RouterLink to="/" class="auth-brand" aria-label="Wise Workout home">
          <span class="brand-mark" aria-hidden="true"></span>
          <span class="brand-name">Wise <span>Workout</span></span>
        </RouterLink>

        <div class="auth-eyebrow">You're in</div>
        <h1 class="auth-title">Welcome, {{ member.first_name }}</h1>
        <p class="auth-note">
          Your account is ready. Download the Wise Workout app and sign in with the
          same email and password to start tracking your workouts.
        </p>

        <div class="download-row">
          <button type="button" class="store-button" disabled>
            <span class="store-eyebrow">Download on the</span>
            <span class="store-name">App Store</span>
          </button>
          <button type="button" class="store-button" disabled>
            <span class="store-eyebrow">Get it on</span>
            <span class="store-name">Google Play</span>
          </button>
        </div>
        <p class="store-hint">App links coming soon.</p>

        <button type="button" class="signout" @click="onSignOut">Sign out</button>
      </section>

      <section v-else class="auth-card">
        <p class="auth-note">Checking your session…</p>
      </section>
    </div>
  </main>
</template>

<style scoped>
@import "../auth/auth.css";

.download-row {
  display: flex;
  gap: 12px;
  margin: 6px 0 8px;
  flex-wrap: wrap;
}
.store-button {
  flex: 1;
  min-width: 150px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  padding: 12px 16px;
  border-radius: 12px;
  border: none;
  background: #111318;
  color: #fff;
  cursor: not-allowed;
  opacity: 0.9;
  text-align: left;
}
.store-eyebrow {
  font-size: 11px;
  opacity: 0.8;
}
.store-name {
  font-size: 18px;
  font-weight: 700;
}
.store-hint {
  font-size: 12px;
  color: #6b7280;
  margin: 0 0 20px;
}
.signout {
  align-self: flex-start;
  background: none;
  border: none;
  padding: 0;
  color: #6d5efc;
  font-weight: 600;
  cursor: pointer;
}
</style>
