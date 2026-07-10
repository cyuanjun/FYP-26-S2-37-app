<script setup lang="ts">
import { onMounted, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { getMemberSession, logoutMember, type SessionMember } from "@/controller/auth/memberSession";

const router = useRouter();
const member = ref<SessionMember | null>(null);
const checking = ref(true);

// Approved when the admin flipped the role to expert (or the profile is verified).
const isApproved = ref(false);

onMounted(async () => {
  const m = await getMemberSession();
  if (!m) {
    router.replace("/login"); // not signed in
    return;
  }
  if (m.role !== "expert" && m.expert_status === "none") {
    router.replace("/home"); // never applied as an expert
    return;
  }
  member.value = m;
  isApproved.value = m.role === "expert" || m.expert_status === "verified";
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

        <!-- Approved expert: download + a note about the in-app portal -->
        <template v-if="isApproved">
          <div class="auth-eyebrow status-ok">Application approved</div>
          <h1 class="auth-title">You're a Wise Workout expert, {{ member.first_name }}</h1>
          <p class="auth-note">
            Download the app and sign in with the same email and password. The expert
            portal (your services, requests, and clients) is built into the app.
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
        </template>

        <!-- Rejected application -->
        <template v-else-if="member.expert_status === 'rejected'">
          <div class="auth-eyebrow status-bad">Application not approved</div>
          <h1 class="auth-title">Thanks for applying, {{ member.first_name }}</h1>
          <p class="auth-note">
            Your expert application wasn't approved this time. You can still use Wise
            Workout as a member. If you think this was a mistake, contact support from
            the landing page.
          </p>
        </template>

        <!-- Pending review (default) -->
        <template v-else>
          <div class="auth-eyebrow status-pending">Application under review</div>
          <h1 class="auth-title">Thanks for applying, {{ member.first_name }}</h1>
          <p class="auth-note">
            Your expert application is being reviewed by our team. We'll verify your
            credentials and documents, then flip your account to an expert. Check back
            here after approval to download the app and access your expert portal.
          </p>
        </template>

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

.status-ok { color: #059669; }
.status-pending { color: #b45309; }
.status-bad { color: #dc2626; }

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
