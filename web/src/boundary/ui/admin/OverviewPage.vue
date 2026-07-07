<script setup lang="ts">
import { onMounted, ref } from "vue";
import { getOverview, type AdminOverview } from "@/controller/admin/getOverview";

const overview = ref<AdminOverview | null>(null);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    overview.value = await getOverview();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
});
</script>

<template>
  <h1 class="admin-title">Overview</h1>
  <p class="admin-subtitle">Live counts from the shared database.</p>

  <p v-if="error" class="admin-error">{{ error }}</p>
  <p v-else-if="!overview" class="admin-note">Loading…</p>

  <template v-else>
    <div class="admin-tiles" style="margin-bottom: 16px">
      <div class="admin-tile">
        <div class="tile-value">{{ overview.totalUsers }}</div>
        <div class="tile-label">Total accounts</div>
      </div>
      <div class="admin-tile">
        <div class="tile-value">{{ overview.freeUsers }}</div>
        <div class="tile-label">Free users</div>
      </div>
      <div class="admin-tile">
        <div class="tile-value">{{ overview.premiumUsers }}</div>
        <div class="tile-label">Premium users</div>
      </div>
      <div class="admin-tile">
        <div class="tile-value">{{ overview.experts }}</div>
        <div class="tile-label">Experts</div>
      </div>
      <div class="admin-tile">
        <div class="tile-value" :class="{ attention: overview.suspended > 0 }">{{ overview.suspended }}</div>
        <div class="tile-label">Suspended</div>
      </div>
    </div>

    <h2 class="admin-title" style="font-size: 18px">Needs attention</h2>
    <div class="admin-tiles">
      <RouterLink to="/admin/applications" class="admin-tile">
        <div class="tile-value" :class="{ attention: overview.pendingApplications > 0 }">
          {{ overview.pendingApplications }}
        </div>
        <div class="tile-label">Pending expert applications</div>
      </RouterLink>
      <RouterLink to="/admin/contact" class="admin-tile">
        <div class="tile-value" :class="{ attention: overview.openContactMessages > 0 }">
          {{ overview.openContactMessages }}
        </div>
        <div class="tile-label">Open contact messages</div>
      </RouterLink>
      <RouterLink to="/admin/testimonials" class="admin-tile">
        <div class="tile-value" :class="{ attention: overview.pendingTestimonials > 0 }">
          {{ overview.pendingTestimonials }}
        </div>
        <div class="tile-label">Pending testimonials</div>
      </RouterLink>
      <RouterLink to="/admin/feedback" class="admin-tile">
        <div class="tile-value" :class="{ attention: overview.newFeedback > 0 }">
          {{ overview.newFeedback }}
        </div>
        <div class="tile-label">New feedback</div>
      </RouterLink>
    </div>
  </template>
</template>
