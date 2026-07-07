<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  approveTestimonial,
  getTestimonials,
  rejectTestimonial,
} from "@/controller/admin/moderateContent";
import type { TestimonialRow } from "@/controller/admin/adminModels";

const rows = ref<TestimonialRow[]>([]);
const error = ref<string | null>(null);
const busyId = ref<string | null>(null);
const replies = ref<Record<string, string>>({});

const pending = computed(() => rows.value.filter((r) => r.status === "pending"));
const decided = computed(() => rows.value.filter((r) => r.status !== "pending"));

async function reload() {
  try {
    rows.value = await getTestimonials();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

onMounted(reload);

async function review(row: TestimonialRow, approve: boolean) {
  error.value = null;
  busyId.value = row.id;
  try {
    const reply = replies.value[row.id] ?? "";
    await (approve ? approveTestimonial(row, reply) : rejectTestimonial(row, reply));
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

function stars(n: number) {
  return "★".repeat(n) + "☆".repeat(5 - n);
}
</script>

<template>
  <h1 class="admin-title">Testimonials</h1>
  <p class="admin-subtitle">
    Public landing-page testimonials (US63). Only approved entries appear on the site.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Pending ({{ pending.length }})</h2>
    <p v-if="!pending.length" class="admin-empty">Nothing waiting for review.</p>

    <div v-for="row in pending" :key="row.id" class="app-row">
      <div class="app-head">
        <h3>{{ row.display_name }} · {{ row.user_category }}</h3>
        <span class="admin-note">{{ stars(row.rating) }}</span>
      </div>
      <p style="margin: 0">{{ row.body }}</p>
      <div class="admin-actions">
        <input v-model="replies[row.id]" class="admin-field" style="flex: 1" placeholder="Optional admin reply" />
        <button class="admin-btn primary" :disabled="busyId === row.id" @click="review(row, true)">Approve</button>
        <button class="admin-btn danger" :disabled="busyId === row.id" @click="review(row, false)">Reject</button>
      </div>
    </div>
  </div>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Decided</h2>
    <table class="admin-table">
      <thead>
        <tr><th>Name</th><th>Rating</th><th>Excerpt</th><th>Status</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in decided" :key="row.id">
          <td>{{ row.display_name }}</td>
          <td>{{ stars(row.rating) }}</td>
          <td>{{ row.body.slice(0, 80) }}{{ row.body.length > 80 ? "…" : "" }}</td>
          <td><span class="pill" :class="row.status === 'approved' ? 'ok' : 'warn'">{{ row.status }}</span></td>
        </tr>
      </tbody>
    </table>
    <p v-if="!decided.length" class="admin-empty">No decided testimonials.</p>
  </div>
</template>
