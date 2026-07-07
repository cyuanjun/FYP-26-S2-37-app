<script setup lang="ts">
import { onMounted, ref } from "vue";
import {
  approveApplication,
  getPendingApplications,
  rejectApplication,
} from "@/controller/admin/reviewApplications";
import type { ExpertApplication } from "@/controller/admin/adminModels";

const applications = ref<ExpertApplication[]>([]);
const error = ref<string | null>(null);
const busyId = ref<string | null>(null);
const loaded = ref(false);

async function reload() {
  try {
    applications.value = await getPendingApplications();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    loaded.value = true;
  }
}

onMounted(reload);

async function review(app: ExpertApplication, approve: boolean) {
  error.value = null;
  busyId.value = app.id;
  try {
    await (approve ? approveApplication(app) : rejectApplication(app));
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

function name(app: ExpertApplication) {
  return [app.profile.first_name, app.profile.last_name].filter(Boolean).join(" ") || app.profile.email;
}
</script>

<template>
  <h1 class="admin-title">Expert applications</h1>
  <p class="admin-subtitle">
    Approving verifies the expert profile and flips the account to the expert role (US52/US57).
    Document files are metadata-only — verify credentials out-of-band before approving.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <p v-if="loaded && !applications.length" class="admin-empty">No pending applications.</p>

    <div v-for="app in applications" :key="app.id" class="app-row">
      <div class="app-head">
        <h3>{{ name(app) }} — {{ app.title }}</h3>
        <span class="pill pending">pending</span>
      </div>
      <div class="admin-note">
        {{ app.profile.email }} · {{ app.years_coaching }} yrs coaching ·
        specialties: {{ app.specialties.join(", ") || "—" }}
      </div>
      <p style="margin: 0">{{ app.about || "No about text." }}</p>
      <div class="admin-note">Credentials: {{ app.credentials.join(" · ") || "—" }}</div>
      <div>
        <span v-for="doc in app.documents" :key="doc.id" class="doc-chip">
          {{ doc.doc_type === "identity" ? "🪪" : "📜" }} {{ doc.title }}
        </span>
        <span v-if="!app.documents.length" class="admin-note">No documents recorded.</span>
      </div>
      <div class="admin-actions">
        <button class="admin-btn primary" :disabled="busyId === app.id" @click="review(app, true)">
          Approve — verify &amp; grant expert role
        </button>
        <button class="admin-btn danger" :disabled="busyId === app.id" @click="review(app, false)">
          Reject
        </button>
      </div>
    </div>
  </div>
</template>
