<script setup lang="ts">
import { computed } from "vue";
import type { StatisticsSection } from "@/controller/landing/viewModels";
import { formatGrowth, getGrowthClass, isGrowthNotable } from "@/utils/format";
import SectionHeading from "./SectionHeading.vue";

const props = defineProps<{ section: StatisticsSection }>();

const hasChartImage = computed(() =>
  /^\/uploads\//.test(props.section.overview_chart_image_url || ""),
);

// Real platform activity from landing_activity_series() — rendered as a
// lightweight inline SVG (no chart package), same convention as the app.
const W = 720;
const H = 240;
const PAD = { top: 16, right: 12, bottom: 26, left: 12 };

const series = computed(() => props.section.activity_series ?? []);

function points(values: number[]): string {
  const max = Math.max(1, ...values);
  const innerW = W - PAD.left - PAD.right;
  const innerH = H - PAD.top - PAD.bottom;
  const step = values.length > 1 ? innerW / (values.length - 1) : 0;
  return values
    .map(
      (v, i) =>
        `${(PAD.left + i * step).toFixed(1)},${(PAD.top + innerH * (1 - v / max)).toFixed(1)}`,
    )
    .join(" ");
}

const sessionPoints = computed(() => points(series.value.map((w) => w.session_count)));
const minutePoints = computed(() => points(series.value.map((w) => w.active_minutes)));
const totalSessions = computed(() => series.value.reduce((a, w) => a + w.session_count, 0));
const totalMinutes = computed(() => series.value.reduce((a, w) => a + w.active_minutes, 0));

function weekLabel(index: number): string {
  const w = series.value[index];
  if (!w) return "";
  const d = new Date(w.week_start);
  return `${d.getDate()}/${d.getMonth() + 1}`;
}
</script>

<template>
  <section id="statistics" class="section">
    <div class="section-inner">
      <SectionHeading
        :eyebrow="section.eyebrow"
        :title="section.title"
        :description="section.section_description"
      />
      <div class="segment-grid statistics-user-base">
        <article v-for="(item, index) in section.user_base" :key="index" class="segment-card">
          <div class="segment-metric-row">
            <div class="segment-count">{{ item.segment_count }}</div>
            <div
              v-if="isGrowthNotable(item.growth_percentage)"
              class="segment-growth"
              :class="getGrowthClass(item.growth_percentage)"
            >
              {{ formatGrowth(item.growth_percentage) }}
            </div>
          </div>
          <h3>{{ item.segment_name }}</h3>
          <p>{{ item.segment_description }}</p>
        </article>
      </div>
      <div class="chart-panel statistics-graph-panel">
        <div class="chart-area">
          <svg
            v-if="series.length"
            class="activity-chart"
            :viewBox="`0 0 ${W} ${H}`"
            role="img"
            aria-label="Weekly platform activity"
          >
            <polyline :points="minutePoints" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" />
            <polyline :points="sessionPoints" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linejoin="round" />
            <text v-for="i in [0, series.length - 1]" :key="i"
              :x="i === 0 ? PAD.left : W - PAD.right" :y="H - 8"
              :text-anchor="i === 0 ? 'start' : 'end'" class="chart-axis-label">
              {{ weekLabel(i) }}
            </text>
          </svg>
          <img
            v-else-if="hasChartImage"
            :src="section.overview_chart_image_url"
            alt="Overview chart"
            class="chart-image"
            loading="lazy"
            decoding="async"
          />
          <span v-else>Platform activity chart</span>
          <div class="line-legend">
            <template v-if="series.length">
              <span :style="{ '--metric-color': '#10b981' } as any">
                Sessions / week ({{ totalSessions }} total)
              </span>
              <span :style="{ '--metric-color': '#2563eb' } as any">
                Active minutes / week ({{ totalMinutes.toLocaleString() }} total)
              </span>
            </template>
            <span
              v-for="(item, index) in series.length ? [] : section.items"
              :key="index"
              :style="{ '--metric-color': item.line_color } as any"
            >
              {{ item.metric_label }}
            </span>
          </div>
        </div>
      </div>
      <div class="stat-grid">
        <article
          v-for="(item, index) in section.items"
          :key="index"
          class="stat-card"
          :style="{ '--metric-color': item.line_color } as any"
        >
          <div class="stat-metric-row">
            <div class="stat-value">{{ item.metric_value }}</div>
            <div
              v-if="isGrowthNotable(item.growth_percentage)"
              class="metric-growth"
              :class="getGrowthClass(item.growth_percentage)"
            >
              {{ formatGrowth(item.growth_percentage) }}
            </div>
          </div>
          <h3>{{ item.metric_label }}</h3>
          <div class="chart-note metric-line-key"></div>
          <p>{{ item.chart_data_summary }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.activity-chart {
  width: 100%;
  max-width: 900px;
  height: auto;
  justify-self: center;
}

.chart-axis-label {
  fill: var(--muted);
  font-size: 11px;
}

.chart-image {
  width: 100%;
  max-width: 900px;
  max-height: 420px;
  aspect-ratio: 16 / 9;
  object-fit: contain;
  align-self: center;
  justify-self: center;
}
</style>
