<script setup lang="ts">
import { computed } from "vue";
import { RouterLink } from "vue-router";
import type { SiteData } from "@/controller/landing/viewModels";
import { logoutMember, type SessionMember } from "@/controller/auth/memberSession";
import Avatar from "./Avatar.vue";

// site drives the brand + nav; member is null when nobody is signed in.
const props = defineProps<{ site: SiteData; member?: SessionMember | null }>();

const hasLogoImage = computed(() => {
  const url = props.site.logo_url || "";
  return /^\/uploads\//.test(url) || /^https?:\/\//.test(url);
});

// Experts and pending applicants have their own home; everyone else the member home.
const homeRoute = computed(() => {
  const m = props.member;
  if (!m) return "/home";
  return m.role === "expert" || m.expert_status !== "none" ? "/expert/home" : "/home";
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
      <a v-for="item in site.navigation" :key="item.url" :href="item.url">{{ item.label }}</a>
    </nav>
    <nav class="auth-nav" aria-label="Account navigation">
      <!-- Signed in: circular profile button (home) + logout, in place of login/register. -->
      <template v-if="member">
        <RouterLink
          :to="homeRoute"
          class="profile-link"
          :aria-label="`${member.first_name} — go to your home`"
          :title="`${member.first_name} — home`"
        >
          <Avatar :name="member.first_name" :size="42" />
        </RouterLink>
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

.profile-link {
  display: inline-flex;
  align-items: center;
  border: none;
  padding: 0;
  background: none;
  border-radius: 50%;
}

.profile-link:hover :deep(.avatar) {
  border-color: var(--accent-dim);
  background: rgba(123, 47, 247, 0.16);
}

.logout-button {
  cursor: pointer;
}
</style>
