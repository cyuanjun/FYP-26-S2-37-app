<script setup lang="ts">
import { computed } from "vue";
import { RouterLink } from "vue-router";
import type { SiteData } from "@/controller/landing/viewModels";

const props = defineProps<{ site: SiteData }>();

const hasLogoImage = computed(() => {
  const url = props.site.logo_url || "";
  return /^\/uploads\//.test(url) || /^https?:\/\//.test(url);
});
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
      <RouterLink
        v-for="item in site.auth_actions"
        :key="item.url"
        :to="item.url"
      >
        {{ item.label }}
      </RouterLink>
    </nav>
  </header>
</template>

<style scoped>
.brand-image {
  width: 38px;
  height: 38px;
  object-fit: contain;
}

.auth-identity {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 6px 14px 6px 6px;
  border: 1px solid var(--lime-border);
  background: rgba(184, 255, 0, 0.04);
  color: var(--ink);
}

.auth-greeting {
  color: var(--ink);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.auth-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 42px;
  padding: 10px 16px;
  border: 1px solid var(--lime-border);
  color: var(--ink);
  background: rgba(255, 255, 255, 0.035);
  cursor: pointer;
  font-family: var(--display);
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
  text-decoration: none;
  text-transform: uppercase;
}

.auth-pill:hover {
  border-color: var(--lime);
  color: var(--lime);
}

.auth-logout {
  border-color: var(--lime);
  color: #0b0c09;
  background: var(--lime);
  clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 0 100%);
}

.auth-logout:hover {
  color: #0b0c09;
  background: var(--lime);
}
</style>
