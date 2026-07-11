<script setup lang="ts">
import { onMounted, ref } from "vue";
import { getFeedback, markFeedbackReviewed, reopenFeedback } from "@/controller/admin/moderateContent";
import type { FeedbackRow } from "@/controller/admin/adminModels";

// (#) Admin triage page for in-app feedback - mark items reviewed or reopen them.

// (#) All feedback rows submitted from the app.
const rows = ref<FeedbackRow[]>([]);
// (#) Error text if something fails.
const error = ref<string | null>(null);
// (#) Id of the feedback row currently being acted on.
const busyId = ref<string | null>(null);

// (#) Fetch the feedback list again.
async function reload() {
  try {
    rows.value = await getFeedback();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

// (#) Load feedback on mount.
onMounted(reload);

// (#) Shared helper: run an action against a row, handle errors, then reload.
async function run(row: FeedbackRow, action: () => Promise<void>) {
  error.value = null;
  busyId.value = row.id;
  try {
    await action();
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

// (#) Display name for who sent the feedback, falling back to email then a dash.
function sender(row: FeedbackRow) {
  return [row.profile?.first_name, row.profile?.last_name].filter(Boolean).join(" ") || row.profile?.email || "—";
}

// (#) Pretty labels for the feedback category codes.
const categoryLabels: Record<string, string> = {
  bug: "Bug",
  feature_request: "Feature request",
  general: "General",
};
</script>

<template>
  <h1 class="admin-title">Feedback</h1>
  <p class="admin-subtitle">In-app feedback triage (US60) — submitted from the app's Profile cluster.</p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <table class="admin-table">
      <thead>
        <tr><th>From</th><th>Category</th><th>Feedback</th><th>Status</th><th>Actions</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in rows" :key="row.id">
          <td>{{ sender(row) }}</td>
          <td>{{ categoryLabels[row.category] ?? row.category }}</td>
          <td>{{ row.body }}</td>
          <td><span class="pill" :class="row.status === 'new' ? 'pending' : 'ok'">{{ row.status }}</span></td>
          <td>
            <button
              v-if="row.status === 'new'"
              class="admin-btn primary"
              :disabled="busyId === row.id"
              @click="run(row, () => markFeedbackReviewed(row))"
            >
              Mark reviewed
            </button>
            <button
              v-else
              class="admin-btn"
              :disabled="busyId === row.id"
              @click="run(row, () => reopenFeedback(row))"
            >
              Reopen
            </button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-if="!rows.length" class="admin-empty">No feedback submitted yet.</p>
  </div>
</template>
