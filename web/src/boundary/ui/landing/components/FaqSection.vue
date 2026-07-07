<script setup lang="ts">
import type { FaqSectionData } from "@/controller/landing/viewModels";
import SectionHeading from "./SectionHeading.vue";

defineProps<{ section: FaqSectionData }>();
</script>

<template>
  <section id="faq" class="section faq-section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />
      <div class="faq-grid">
        <details
          v-for="(item, index) in section.items"
          :key="index"
          class="faq-item"
          :open="index === 0"
        >
          <summary>
            <span>{{ item.question }}</span>
            <span class="faq-toggle" aria-hidden="true"></span>
          </summary>
          <p>{{ item.answer }}</p>
        </details>
      </div>
    </div>
  </section>
</template>
