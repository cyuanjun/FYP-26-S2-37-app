<script setup lang="ts">
import type { FeaturesSection } from "@/controller/landing/viewModels";
import SectionHeading from "./SectionHeading.vue";

defineProps<{ section: FeaturesSection }>();

function isImagePath(url: string): boolean {
  return /^\/uploads\//.test(url || "");
}
</script>

<template>
  <section id="features" class="section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />
      <div class="feature-grid">
        <article v-for="(item, index) in section.items" :key="index" class="feature-card">
          <div class="feature-media">
            <img
              v-if="isImagePath(item.icon_url)"
              :src="item.icon_url"
              :alt="item.title"
              class="feature-image"
            />
            <span v-else>{{ item.icon_url || "Feature image" }} {{ index + 1 }}</span>
          </div>
          <h3>{{ item.title }}</h3>
          <p>{{ item.description }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.feature-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top;
}
</style>
