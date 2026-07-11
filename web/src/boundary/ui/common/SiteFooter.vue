<script setup lang="ts">
// (#) Site-wide footer: brand line, copyright, and the footer nav links.
import { computed } from "vue";
import type { SiteData } from "@/controller/landing/viewModels";

// (#) site supplies the brand words and footer links to render.
const props = defineProps<{ site: SiteData }>();

// (#) Joins the two brand words into one display name.
const brandName = computed(() =>
  `${props.site.brand_first_word} ${props.site.brand_second_word}`.trim(),
);
// (#) This year, for the copyright line.
const currentYear = new Date().getFullYear();
</script>

<template>
  <footer class="site-footer">
    <div class="footer-brand">{{ brandName }}</div>
    <div>© {{ currentYear }} {{ brandName }}. All rights reserved.</div>
    <nav class="footer-links" aria-label="Footer navigation">
      <a v-for="item in site.footer.links" :key="item.url" :href="item.url">{{ item.label }}</a>
    </nav>
  </footer>
</template>
