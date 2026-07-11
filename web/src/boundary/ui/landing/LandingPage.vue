<script setup lang="ts">
// (#) Top-level landing page: fetches the page data and renders each section
// (#) in order, wrapped by the shared site header and footer.
import { onMounted, ref } from "vue";
import type { Component } from "vue";
import SiteHeader from "@/boundary/ui/common/SiteHeader.vue";
import SiteFooter from "@/boundary/ui/common/SiteFooter.vue";
import { getLandingPage } from "@/controller/landing/getLandingPage";
import { getMemberSession, type SessionMember } from "@/controller/auth/memberSession";
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

// (#) the whole page payload once it loads, null while still fetching
const data = ref<LandingPageData | null>(null);
// (#) holds the error text if the page fetch throws
const error = ref<string | null>(null);
// (#) Signed-in member (if any) so the header shows the profile + logout instead of login/register.
const member = ref<SessionMember | null>(null);

// (#) maps each section type coming from the data to the component that draws it
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

// (#) look up which component should render a given section
function componentFor(section: PageSection) {
  return sectionComponent[section.type];
}

// (#) on load, pull the page content, then check for a signed-in member
onMounted(async () => {
  try {
    data.value = await getLandingPage();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
  // (#) Best-effort: a failed session lookup just leaves the header logged-out.
  try {
    member.value = await getMemberSession();
  } catch {
    member.value = null;
  }
});
</script>

<template>
  <div v-if="error" class="page-status">
    <p>Failed to load page content: {{ error }}</p>
  </div>
  <div v-else-if="!data" class="page-status">Loading…</div>
  <div v-else class="site-shell">
    <SiteHeader :site="data.site" :member="member" />
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
  color: var(--accent);
  font-family: var(--mono);
}
</style>
