<script setup lang="ts">
import { computed } from "vue";
import { RouterLink } from "vue-router";
import type { SiteData } from "@/controller/landing/viewModels";
import { logoutMember, type SessionMember } from "@/controller/auth/memberSession";

// site drives the brand + nav; member is null when nobody is signed in.
const props = defineProps<{ site: SiteData; member?: SessionMember | null }>();

const hasLogoImage = computed(() => {
  const url = props.site.logo_url || "";
  return /^\/uploads\//.test(url) || /^https?:\/\//.test(url);
});

// Nav items are landing-section anchors (e.g. "#features"). Route them to the
// landing page + hash so they work from the post-login pages too, not just "/".
function navTarget(url: string) {
  if (url.startsWith("#")) return { path: "/", hash: url };
  return url;
}

// Experts and pending applicants live on the expert status page; everyone else
// on the download page.
const isExpertTrack = computed(() => {
  const m = props.member;
  return !!m && (m.role === "expert" || m.expert_status !== "none");
});

const primaryRoute = computed(() => (isExpertTrack.value ? "/expert" : "/download"));

// Approved users can actually download; a pending/rejected applicant sees their
// application instead, so the button says so rather than promising a download.
const primaryLabel = computed(() => {
  const m = props.member;
  if (!m) return "Download";
  const approved = m.role === "expert" || m.expert_status === "verified";
  return isExpertTrack.value && !approved ? "My application" : "Download";
});

// Signs out then hard-navigates to the landing page so the nav reverts cleanly.
async function onLogout() {
  await logoutMember();
  window.location.href = "/";
}
</script>

<template>
  <header class="site-header">
    <RouterLink to="/" class="brand" :aria-label="site.site_name">
      <img
        v-if="hasLogoImage"
        :src="site.logo_url"
        alt=""
        class="brand-image"
        width="38"
        height="38"
        decoding="async"
      />
      <span v-else class="brand-mark" aria-hidden="true"></span>
      <span class="brand-name">{{ site.brand_first_word }} <span>{{ site.brand_second_word }}</span></span>
    </RouterLink>
    <nav class="primary-nav" aria-label="Main navigation">
      <RouterLink v-for="item in site.navigation" :key="item.url" :to="navTarget(item.url)">
        {{ item.label }}
      </RouterLink>
    </nav>
    <nav class="auth-nav" aria-label="Account navigation">
      <!-- Signed in: download (or application) + logout, in place of login/register. -->
      <template v-if="member">
        <RouterLink :to="primaryRoute" class="button primary">{{ primaryLabel }}</RouterLink>
        <button type="button" class="button logout-button" @click="onLogout">Logout</button>
      </template>
      <!-- Signed out: the usual login / register actions. -->
      <template v-else>
        <RouterLink v-for="item in site.auth_actions" :key="item.url" :to="item.url">
          {{ item.label }}
        </RouterLink>
      </template>
    </nav>
  </header>
</template>

<style scoped>
.brand-image {
  width: 38px;
  height: 38px;
  object-fit: contain;
}

.logout-button {
  cursor: pointer;
}
</style>
