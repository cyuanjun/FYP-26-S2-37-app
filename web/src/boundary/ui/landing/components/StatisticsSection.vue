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
// Sessions and active-minutes have very different magnitudes, so each gets
// its OWN axis: sessions (green) on the left, minutes (blue) on the right.
const SESSION_COLOR = "#10b981";
const MINUTE_COLOR = "#2563eb";

const W = 760;
const H = 320;
const PAD = { top: 28, right: 60, bottom: 46, left: 54 };
const INNER_W = W - PAD.left - PAD.right;
const INNER_H = H - PAD.top - PAD.bottom;
const TICKS = 4;

const series = computed(() => props.section.activity_series ?? []);

// Round a max up to a "nice" ceiling (1/2/5 × 10ⁿ) so axis ticks are clean.
function niceMax(value: number): number {
  if (value <= 0) return 1;
  const exp = Math.floor(Math.log10(value));
  const frac = value / Math.pow(10, exp);
  const nf = frac <= 1 ? 1 : frac <= 2 ? 2 : frac <= 5 ? 5 : 10;
  return nf * Math.pow(10, exp);
}

const sessionMax = computed(() =>
  niceMax(Math.max(1, ...series.value.map((w) => w.session_count))),
);
const minuteMax = computed(() =>
  niceMax(Math.max(1, ...series.value.map((w) => w.active_minutes))),
);

function xAt(i: number): number {
  const n = series.value.length;
  const step = n > 1 ? INNER_W / (n - 1) : 0;
  return PAD.left + i * step;
}

function yAt(value: number, max: number): number {
  return PAD.top + INNER_H * (1 - value / max);
}

const sessionPoints = computed(() =>
  series.value
    .map((w, i) => `${xAt(i).toFixed(1)},${yAt(w.session_count, sessionMax.value).toFixed(1)}`)
    .join(" "),
);
const minutePoints = computed(() =>
  series.value
    .map((w, i) => `${xAt(i).toFixed(1)},${yAt(w.active_minutes, minuteMax.value).toFixed(1)}`)
    .join(" "),
);

// Shared horizontal gridlines: left label = sessions scale, right = minutes.
const gridRows = computed(() =>
  Array.from({ length: TICKS + 1 }, (_, t) => {
    const frac = t / TICKS;
    return {
      y: PAD.top + INNER_H * (1 - frac),
      sessions: Math.round(sessionMax.value * frac).toString(),
      minutes: Math.round(minuteMax.value * frac).toLocaleString(),
    };
  }),
);

// Up to 6 evenly spaced week labels along the x-axis.
const xTicks = computed(() => {
  const n = series.value.length;
  if (!n) return [];
  const count = Math.min(n, 6);
  const seen = new Set<number>();
  const out: { x: number; label: string }[] = [];
  for (let k = 0; k < count; k++) {
    const i = Math.round((k * (n - 1)) / Math.max(1, count - 1));
    if (seen.has(i)) continue;
    seen.add(i);
    out.push({ x: xAt(i), label: weekLabel(i) });
  }
  return out;
});

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
          <template v-if="series.length">
            <svg
              class="activity-chart"
              :viewBox="`0 0 ${W} ${H}`"
              role="img"
              aria-label="Weekly platform activity — sessions and active minutes"
            >
              <!-- axis titles -->
              <text :x="PAD.left" :y="PAD.top - 12" text-anchor="start" class="axis-title" :fill="SESSION_COLOR">
                SESSIONS / WK
              </text>
              <text :x="W - PAD.right" :y="PAD.top - 12" text-anchor="end" class="axis-title" :fill="MINUTE_COLOR">
                MINUTES / WK
              </text>

              <!-- gridlines + dual y-axis labels -->
              <g v-for="(row, i) in gridRows" :key="'g' + i">
                <line :x1="PAD.left" :x2="W - PAD.right" :y1="row.y" :y2="row.y" class="grid-line" />
                <text :x="PAD.left - 10" :y="row.y + 4" text-anchor="end" class="axis-label" :fill="SESSION_COLOR">
                  {{ row.sessions }}
                </text>
                <text :x="W - PAD.right + 10" :y="row.y + 4" text-anchor="start" class="axis-label" :fill="MINUTE_COLOR">
                  {{ row.minutes }}
                </text>
              </g>

              <!-- axis frame -->
              <line :x1="PAD.left" :x2="PAD.left" :y1="PAD.top" :y2="H - PAD.bottom" class="axis-line" />
              <line :x1="W - PAD.right" :x2="W - PAD.right" :y1="PAD.top" :y2="H - PAD.bottom" class="axis-line" />
              <line :x1="PAD.left" :x2="W - PAD.right" :y1="H - PAD.bottom" :y2="H - PAD.bottom" class="axis-line" />

              <!-- data lines -->
              <polyline
                :points="minutePoints"
                fill="none"
                :stroke="MINUTE_COLOR"
                stroke-width="2.5"
                stroke-linejoin="round"
                stroke-linecap="round"
              />
              <polyline
                :points="sessionPoints"
                fill="none"
                :stroke="SESSION_COLOR"
                stroke-width="2.5"
                stroke-linejoin="round"
                stroke-linecap="round"
              />

              <!-- data points -->
              <circle
                v-for="(w, i) in series"
                :key="'m' + i"
                :cx="xAt(i)"
                :cy="yAt(w.active_minutes, minuteMax)"
                r="3"
                :fill="MINUTE_COLOR"
              />
              <circle
                v-for="(w, i) in series"
                :key="'s' + i"
                :cx="xAt(i)"
                :cy="yAt(w.session_count, sessionMax)"
                r="3"
                :fill="SESSION_COLOR"
              />

              <!-- x-axis week labels -->
              <text
                v-for="(tick, i) in xTicks"
                :key="'x' + i"
                :x="tick.x"
                :y="H - PAD.bottom + 20"
                text-anchor="middle"
                class="axis-label"
              >
                {{ tick.label }}
              </text>
            </svg>

            <div class="chart-legend">
              <span class="legend-item">
                <span class="legend-swatch" :style="{ background: SESSION_COLOR }"></span>
                Sessions / week — {{ totalSessions.toLocaleString() }} in the last 12 weeks
              </span>
              <span class="legend-item">
                <span class="legend-swatch" :style="{ background: MINUTE_COLOR }"></span>
                Active minutes / week — {{ totalMinutes.toLocaleString() }} in the last 12 weeks
              </span>
            </div>
          </template>

          <img
            v-else-if="hasChartImage"
            :src="section.overview_chart_image_url"
            alt="Overview chart"
            class="chart-image"
            loading="lazy"
            decoding="async"
          />
          <span v-else>Platform activity chart</span>
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

.grid-line {
  stroke: var(--faint);
  stroke-width: 1;
}

.axis-line {
  stroke: var(--muted);
  stroke-width: 1;
  opacity: 0.35;
}

.axis-label {
  fill: var(--muted);
  font-size: 11px;
}

.axis-title {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.06em;
}

.chart-legend {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px 24px;
  margin-top: 16px;
}

.legend-item {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: var(--muted);
  font-size: 13px;
}

.legend-swatch {
  width: 22px;
  height: 3px;
  border-radius: 999px;
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
