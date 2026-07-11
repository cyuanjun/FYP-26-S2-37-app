<script setup lang="ts">
// (#) Hero section: headline, tagline and the phone app-preview media, with
// (#) the primary and secondary CTA buttons.
import { computed } from "vue";
import type { IntroSection } from "@/controller/landing/viewModels";

// (#) the intro slice of the page data (headlines, CTAs, hero media)
const props = defineProps<{ section: IntroSection }>();

// (#) true when we have an uploaded video to play instead of the placeholder
const hasVideo = computed(() => /^\/uploads\//.test(props.section.hero_media_url || ""));
</script>

<template>
  <section id="top" class="section hero">
    <div class="section-inner hero-layout">
      <div>
        <div class="eyebrow">{{ section.eyebrow }}</div>
        <h1 class="hero-title">{{ section.headline_primary }} <span>{{ section.headline_accent }}</span></h1>
        <p class="hero-subtitle">{{ section.hero_title }}</p>
        <p class="hero-description">{{ section.hero_description }}</p>
        <div class="hero-actions">
          <a class="button primary" :href="section.primary_cta_url">{{ section.primary_cta_text }}</a>
          <a class="button" :href="section.secondary_cta_url">{{ section.secondary_cta_text }}</a>
        </div>
      </div>
      <div class="phone-media" aria-label="Hero video phone preview">
        <div class="phone-frame">
          <div class="phone-speaker"></div>
          <div class="phone-screen">
            <video
              v-if="hasVideo"
              class="hero-video"
              :src="section.hero_media_url"
              autoplay
              muted
              loop
              playsinline
            ></video>
            <div v-else class="video-placeholder">
              <div class="play-button" aria-hidden="true"></div>
              <div class="video-label">App preview</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero-video {
  width: 100%;
  height: 100%;
  min-height: 540px;
  border: 1px solid var(--faint);
  border-radius: 20px;
  background: #15161b;
  object-fit: cover;
}
</style>
