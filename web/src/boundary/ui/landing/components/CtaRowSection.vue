<script setup lang="ts">
import type { CtaRowSection } from "@/controller/landing/viewModels";

defineProps<{ section: CtaRowSection }>();
</script>

<template>
  <section id="register" class="section cta-band">
    <div class="section-inner cta-layout">
      <article
        v-for="(item, index) in section.items"
        :key="index"
        class="cta-panel"
        :class="`${item.panel_variant}-cta`"
      >
        <div class="eyebrow">{{ item.eyebrow }}</div>
        <h3>{{ item.title }}</h3>
        <p class="section-description">{{ item.description }}</p>
        <div class="cta-actions">
          <a class="button primary" :href="item.button_url">{{ item.button_text }}</a>
        </div>
      </article>
    </div>
  </section>
</template>
