<script setup lang="ts">
import { computed } from "vue";
import type { StatisticsSection } from "@/controller/landing/viewModels";
import { formatGrowth, getGrowthClass, isGrowthNotable } from "@/utils/format";
import SectionHeading from "./SectionHeading.vue";

const props = defineProps<{ section: StatisticsSection }>();

const hasChartImage = computed(() =>
  /^\/uploads\//.test(props.section.overview_chart_image_url || ""),
);
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
          <img
            v-if="hasChartImage"
            :src="section.overview_chart_image_url"
            alt="Overview chart"
            class="chart-image"
            loading="lazy"
            decoding="async"
          />
          <span v-else>Platform activity chart</span>
          <div class="line-legend">
            <span
              v-for="(item, index) in section.items"
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
          <div class="chart-note metric-line-key">{{ item.line_color }}</div>
          <p>{{ item.chart_data_summary }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
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
