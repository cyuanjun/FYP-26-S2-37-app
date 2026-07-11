<script setup lang="ts">
// (#) Testimonials section: an overall-rating panel plus a paged carousel of
// (#) approved member reviews.
import { computed, onMounted, ref } from "vue";
import type { TestimonialSubmission, TestimonialsSection } from "@/controller/landing/viewModels";
import { getTestimonials } from "@/controller/landing/getTestimonials";
import SectionHeading from "./SectionHeading.vue";

// (#) heading copy plus rating labels and the admin's featured id list
const props = defineProps<{ section: TestimonialsSection }>();

// (#) the approved reviews once fetched
const approved = ref<TestimonialSubmission[]>([]);
// (#) whether the reviews are still loading
const loading = ref(true);
// (#) error text if the reviews fetch fails
const loadError = ref<string | null>(null);

// (#) fetch the approved reviews, toggling the loading/error flags around it
async function load() {
  loading.value = true;
  loadError.value = null;
  try {
    approved.value = await getTestimonials();
  } catch (e) {
    loadError.value = e instanceof Error ? e.message : String(e);
  } finally {
    loading.value = false;
  }
}

// (#) how many review cards show per carousel page
const PAGE_SIZE = 3;
// (#) which carousel page is currently on screen
const pageIndex = ref(0);

// (#) Carousel reads from the curated featured set when the admin has picked any,
// preserving the chosen order. Empty featured_ids = legacy default of "all
// approved". Overall stats (below) always come from the full approved set so
// the headline numbers don't depend on what's spotlighted.
const carousel = computed<TestimonialSubmission[]>(() => {
  const featured = props.section.featured_ids ?? [];
  if (featured.length === 0) return approved.value;
  const byId = new Map(approved.value.map((t) => [t.id, t]));
  return featured
    .map((id) => byId.get(id))
    .filter((t): t is TestimonialSubmission => Boolean(t));
});

// (#) total number of carousel pages (at least 1)
const pageCount = computed(() => Math.max(1, Math.ceil(carousel.value.length / PAGE_SIZE)));
// (#) the slice of reviews shown on the current page
const visibleTestimonials = computed(() => {
  const start = pageIndex.value * PAGE_SIZE;
  return carousel.value.slice(start, start + PAGE_SIZE);
});

// (#) step back one page, stopping at the first
function prevPage() {
  if (pageIndex.value > 0) pageIndex.value--;
}
// (#) step forward one page, stopping at the last
function nextPage() {
  if (pageIndex.value < pageCount.value - 1) pageIndex.value++;
}

// (#) headline rating summary: average, star count, total and per-star bars
const aggregateStats = computed(() => {
  const list = approved.value;
  const count = list.length;
  const avg = count > 0 ? list.reduce((sum, t) => sum + t.rating, 0) / count : 0;
  // bar positions: 0 = 5★, 1 = 4★, 2 = 3★, 3 = 2★, 4 = 1★
  const percentages = [5, 4, 3, 2, 1].map((star) => {
    const matches = list.filter((t) => t.rating === star).length;
    return count > 0 ? Math.round((matches / count) * 100) : 0;
  });
  return {
    averageDisplay: count > 0 ? `${avg.toFixed(1)}/5` : "—",
    averageStars: Math.round(avg),
    reviewCount: String(count),
    percentages,
  };
});

// (#) load the reviews as soon as the section mounts
onMounted(load);
</script>

<template>
  <section id="testimonials" class="section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />
      <div class="reviews-panel">
        <div class="reviews-overview">
          <div class="reviews-label">{{ section.overall_rating_label }}</div>
          <div class="reviews-score-row">
            <div class="rating-value">{{ aggregateStats.averageDisplay }}</div>
            <div>
              <div class="rating-stars">
                <span
                  v-for="i in 5"
                  :key="i"
                  :class="{ filled: i <= aggregateStats.averageStars }"
                ></span>
              </div>
              <div class="chart-note">
                {{ section.review_count_template.replace("{count}", aggregateStats.reviewCount) }}
              </div>
            </div>
          </div>
        </div>
        <div class="rating-bars">
          <div
            v-for="(bar, index) in section.rating_distribution"
            :key="index"
            class="rating-bar-row"
          >
            <span>{{ bar.label }}</span>
            <div class="rating-track">
              <div
                class="rating-fill"
                :class="`rating-fill-${index + 1}`"
                :style="{ '--rating-width': `${aggregateStats.percentages[index] ?? 0}%` } as any"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="loading" class="reviews-loading">Loading reviews…</div>
      <div v-else-if="loadError" class="reviews-loading">Failed to load reviews: {{ loadError }}</div>
      <div v-else-if="approved.length === 0" class="reviews-loading">
        No approved reviews yet. Be the first to share your experience.
      </div>
      <template v-else>
        <div class="testimonial-grid">
          <article
            v-for="(item, index) in visibleTestimonials"
            :key="item.id"
            class="testimonial-card"
          >
            <div class="review-header">
              <div class="review-avatar">U{{ pageIndex * PAGE_SIZE + index + 1 }}</div>
              <div>
                <h3>{{ item.user_display_name }}</h3>
                <div class="testimonial-rating">
                  <span v-for="i in 5" :key="i" :class="{ filled: i <= item.rating }"></span>
                </div>
              </div>
            </div>
            <p>{{ item.feedback_text }}</p>
            <div class="testimonial-meta">
              {{ item.user_category }} / {{ item.submitted_at.slice(0, 10) }}
            </div>
          </article>
        </div>
        <div v-if="pageCount > 1" class="testimonial-pager" aria-label="Testimonial pagination">
          <button
            type="button"
            class="pager-arrow"
            :disabled="pageIndex === 0"
            aria-label="Previous reviews"
            @click="prevPage"
          >
            ‹
          </button>
          <span class="pager-status">
            {{ pageIndex + 1 }} / {{ pageCount }}
            <span class="pager-status-detail">
              · showing {{ visibleTestimonials.length }} of {{ approved.length }}
            </span>
          </span>
          <button
            type="button"
            class="pager-arrow"
            :disabled="pageIndex === pageCount - 1"
            aria-label="Next reviews"
            @click="nextPage"
          >
            ›
          </button>
        </div>
      </template>
    </div>
  </section>
</template>

<style scoped>
.testimonial-card {
  min-height: 280px;
  grid-template-rows: auto 1fr auto;
}

.testimonial-card p {
  display: -webkit-box;
  -webkit-line-clamp: 5;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin: 0;
  align-self: start;
}

.testimonial-card .review-header h3 {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.reviews-loading {
  margin-top: 32px;
  padding: 32px;
  border: 1px dashed var(--border);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.08em;
  text-align: center;
  text-transform: uppercase;
}

.testimonial-pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  margin-top: 26px;
}

.pager-arrow {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  padding: 0;
  border: 1px solid var(--accent-border);
  border-radius: 50%;
  color: var(--accent);
  background: rgba(123, 47, 247, 0.04);
  cursor: pointer;
  font-family: var(--display);
  font-size: 26px;
  line-height: 1;
}

.pager-arrow:disabled {
  cursor: not-allowed;
  opacity: 0.3;
}

.pager-arrow:hover:not(:disabled) {
  border-color: var(--accent);
  background: rgba(123, 47, 247, 0.1);
}

.pager-status {
  color: var(--accent);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.pager-status-detail {
  color: var(--muted);
  letter-spacing: 0.06em;
}

@media (max-width: 640px) {
  .pager-status-detail {
    display: none;
  }
}
</style>
