<script setup lang="ts">
import { onMounted, ref } from "vue";
import type { Component } from "vue";
import SiteHeader from "@/boundary/ui/common/SiteHeader.vue";
import SiteFooter from "@/boundary/ui/common/SiteFooter.vue";
import { getLandingPage } from "@/controller/landing/getLandingPage";
import type { LandingPageData, PageSection } from "@/controller/landing/viewModels";
import HeroSection from "./components/HeroSection.vue";
import FeaturesSection from "./components/FeaturesSection.vue";
import StatisticsSection from "./components/StatisticsSection.vue";
import ExpertsSection from "./components/ExpertsSection.vue";
import PricingSection from "./components/PricingSection.vue";
import TestimonialsSection from "./components/TestimonialsSection.vue";
import CtaRowSection from "./components/CtaRowSection.vue";
import FaqSection from "./components/FaqSection.vue";
import ContactSection from "./components/ContactSection.vue";

const data = ref<LandingPageData | null>(null);
const error = ref<string | null>(null);

const sectionComponent: Record<PageSection["type"], Component> = {
  intro: HeroSection,
  features: FeaturesSection,
  statistics: StatisticsSection,
  featuredExperts: ExpertsSection,
  pricing: PricingSection,
  testimonials: TestimonialsSection,
  ctaRow: CtaRowSection,
  faq: FaqSection,
  contactSection: ContactSection,
};

function componentFor(section: PageSection) {
  return sectionComponent[section.type];
}

onMounted(async () => {
  try {
    data.value = await getLandingPage();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
});
</script>

<template>
  <div v-if="error" class="page-status">
    <p>Failed to load page content: {{ error }}</p>
  </div>
  <div v-else-if="!data" class="page-status">Loading…</div>
  <div v-else class="site-shell">
    <SiteHeader :site="data.site" />
    <main>
      <component
        v-for="(section, index) in data.sections"
        :key="`${section.type}-${index}`"
        :is="componentFor(section)"
        :section="section"
      />
    </main>
    <SiteFooter :site="data.site" />
  </div>
</template>

<style scoped>
.page-status {
  display: grid;
  min-height: 60vh;
  align-content: center;
  justify-items: center;
  gap: 8px;
  padding: 32px;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.page-status code {
  color: var(--lime);
  font-family: var(--mono);
}
</style>
