<script setup lang="ts">
import type { PricingSection } from "@/controller/landing/viewModels";
import { formatPrice } from "@/utils/format";
import SectionHeading from "./SectionHeading.vue";

defineProps<{ section: PricingSection }>();
</script>

<template>
  <section id="pricing" class="section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />
      <div class="pricing-grid">
        <article v-for="(item, index) in section.items" :key="index" class="price-card">
          <h3>{{ item.plan_name }}</h3>
          <div class="price-value">{{ formatPrice(item.price) }}</div>
          <p>{{ item.description }}</p>
          <ul class="price-feature-list">
            <li v-for="(feature, i) in item.features" :key="i">{{ feature }}</li>
          </ul>
          <a class="button" :href="item.button_url">{{ item.button_text }}</a>
        </article>
      </div>
    </div>
  </section>
</template>
