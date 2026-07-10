<script setup lang="ts">
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import SiteHeader from "@/boundary/ui/common/SiteHeader.vue";
import SiteFooter from "@/boundary/ui/common/SiteFooter.vue";
import { getLandingPage } from "@/controller/landing/getLandingPage";
import { getMemberSession, type SessionMember } from "@/controller/auth/memberSession";
import type { SiteData } from "@/controller/landing/viewModels";

const router = useRouter();
const site = ref<SiteData | null>(null);
const member = ref<SessionMember | null>(null);
const ready = ref(false);

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
  try {
    site.value = (await getLandingPage()).site;
  } catch {
    site.value = null;
  }
  ready.value = true;
});
</script>

<template>
  <div v-if="ready && site && member" class="site-shell">
    <SiteHeader :site="site" :member="member" />
    <main>
      <section class="section hub">
        <div class="hub-card">
          <div class="hub-eyebrow">You're in</div>
          <h1 class="hub-title">Welcome, {{ member.first_name }}</h1>
          <p class="hub-note">
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
        </div>
      </section>
    </main>
    <SiteFooter :site="site" />
  </div>
  <div v-else class="page-status">Loading…</div>
</template>

<style scoped>
.hub {
  display: grid;
  place-items: center;
}
.hub-card {
  width: 100%;
  max-width: 560px;
  padding: 40px 36px;
  border: 1px solid var(--border);
  border-radius: 20px;
  background: var(--bg2);
  text-align: center;
}
.hub-eyebrow {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--accent);
  margin-bottom: 10px;
}
.hub-title {
  margin: 0 0 12px;
  font-size: 30px;
  font-weight: 800;
  color: var(--ink);
}
.hub-note {
  margin: 0 0 24px;
  font-size: 16px;
  line-height: 1.55;
  color: var(--muted);
}
.download-row {
  display: flex;
  gap: 12px;
  justify-content: center;
  flex-wrap: wrap;
}
.store-button {
  flex: 1;
  min-width: 170px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  padding: 12px 18px;
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
  font-size: 13px;
  color: var(--muted);
  margin: 14px 0 0;
}
.page-status {
  display: grid;
  min-height: 60vh;
  place-items: center;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}
</style>
