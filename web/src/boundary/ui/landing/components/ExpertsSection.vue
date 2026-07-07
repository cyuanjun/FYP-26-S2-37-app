<script setup lang="ts">
import { onMounted, ref } from "vue";
import { getFeaturedExperts } from "@/controller/landing/getFeaturedExperts";
import type { ExpertProfile, ExpertsSection } from "@/controller/landing/viewModels";
import SectionHeading from "./SectionHeading.vue";

const props = defineProps<{ section: ExpertsSection }>();

const experts = ref<ExpertProfile[]>([]);
const loadError = ref<string | null>(null);

async function hydrate() {
  loadError.value = null;
  try {
    experts.value = await getFeaturedExperts();
  } catch (e) {
    loadError.value = e instanceof Error ? e.message : String(e);
  }
}

onMounted(hydrate);

function initialsFor(name: string): string {
  const parts = (name ?? "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function isImagePath(url: string | null): boolean {
  return Boolean(url && (/^\/uploads\//.test(url) || /^https?:\/\//.test(url)));
}

function tagline(profile: ExpertProfile): string {
  if (!profile.years_coaching) return profile.title;
  const first = profile.specialties[0];
  if (!first) return `${profile.years_coaching} years coaching`;
  return `${profile.years_coaching} years coaching ${first}`;
}

</script>

<template>
  <section id="experts" class="section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />

      <div v-if="loadError" class="expert-empty">Couldn't load featured experts: {{ loadError }}</div>
      <div v-else-if="experts.length === 0" class="expert-empty">
        Verified experts will appear here soon.
      </div>

      <div v-else class="expert-grid">
        <article
          v-for="(expert, index) in experts"
          :key="expert.user_id"
          class="expert-card"
        >
          <div class="expert-photo">
            <img
              v-if="isImagePath(expert.avatar_url)"
              :src="expert.avatar_url ?? ''"
              :alt="expert.display_name"
              class="expert-image"
              loading="lazy"
              decoding="async"
            />
            <span v-else class="expert-initials">{{ initialsFor(expert.display_name) }}</span>
          </div>
          <div class="expert-category">{{ expert.title }}</div>
          <h3>{{ expert.display_name }}</h3>
          <div class="expert-experience">{{ tagline(expert) }}</div>
          <p>{{ expert.about }}</p>
          <ul class="expert-highlights">
            <li v-for="(c, i) in expert.credentials" :key="i">{{ c }}</li>
          </ul>
          <div v-if="expert.specialties.length" class="expert-specialties">
            <span v-for="s in expert.specialties" :key="s" class="expert-tag">{{ s }}</span>
          </div>
          <div class="expert-stats" v-if="expert.review_count > 0">
            <span>★ {{ expert.rating_avg.toFixed(1) }}</span>
            <span>{{ expert.review_count }} reviews</span>
            <span>{{ expert.client_count }} clients</span>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.expert-image {
  width: 100%;
  height: 100%;
  max-height: 220px;
  aspect-ratio: 4 / 3;
  object-fit: cover;
}

.expert-initials {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  max-height: 220px;
  aspect-ratio: 4 / 3;
  color: var(--accent);
  font-family: var(--display);
  font-size: 56px;
  font-weight: 800;
}

.expert-empty {
  padding: 32px;
  border: 1px dashed var(--border);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.08em;
  text-align: center;
  text-transform: uppercase;
}

.expert-specialties {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 12px;
}

.expert-tag {
  padding: 4px 10px;
  border: 1px solid var(--accent-border);
  border-radius: 999px;
  color: var(--accent);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.expert-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}
</style>
