<script setup lang="ts">
import { onMounted, ref } from "vue";
import { getPricingPlans, savePricingPlan } from "@/controller/admin/manageCatalog";
import type { PricingPlanRow } from "@/controller/admin/adminModels";

// (#) Admin editor for the public pricing section - display copy only, not the real checkout price.

// (#) The pricing plans shown on the landing page.
const plans = ref<PricingPlanRow[]>([]);
// (#) Error text if a load or save fails.
const error = ref<string | null>(null);
// (#) plan_key of the plan that just saved, for the "Saved" flash.
const savedKey = ref<string | null>(null);
// (#) Id of the plan currently saving.
const busyId = ref<string | null>(null);

// (#) Load the pricing plans when the page mounts.
onMounted(async () => {
  try {
    plans.value = await getPricingPlans();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
});

// (#) Save one edited plan and flag it as just-saved.
async function save(plan: PricingPlanRow) {
  error.value = null;
  savedKey.value = null;
  busyId.value = plan.id;
  try {
    await savePricingPlan(plan);
    savedKey.value = plan.plan_key;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}
</script>

<template>
  <h1 class="admin-title">Pricing plans</h1>
  <p class="admin-subtitle">
    Display copy for the public pricing section (US63). Display text only — the app's
    simulated checkout uses its own settled price.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div v-for="plan in plans" :key="plan.id" class="admin-card">
    <div class="app-head">
      <h3 style="margin: 0">{{ plan.plan_name }} <code style="font-size: 12px">({{ plan.plan_key }})</code></h3>
      <span class="pill" :class="plan.is_active ? 'ok' : 'muted'">{{ plan.is_active ? "active" : "hidden" }}</span>
    </div>
    <div class="admin-actions" style="margin-top: 12px">
      <input v-model="plan.price_label" class="admin-field" style="max-width: 140px" placeholder="$9.99/mth" />
      <input v-model="plan.description" class="admin-field" style="flex: 1" placeholder="Description" />
      <label class="admin-note" style="display: flex; align-items: center; gap: 6px">
        <input v-model="plan.is_active" type="checkbox" /> shown
      </label>
      <button class="admin-btn primary" :disabled="busyId === plan.id" @click="save(plan)">
        {{ savedKey === plan.plan_key ? "Saved ✓" : "Save" }}
      </button>
    </div>
  </div>
</template>
