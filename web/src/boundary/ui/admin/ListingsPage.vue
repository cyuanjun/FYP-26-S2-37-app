<script setup lang="ts">
import { onMounted, ref } from "vue";
import { archiveListing, getServiceListings, restoreListing } from "@/controller/admin/manageCatalog";
import type { ServiceListingRow } from "@/controller/admin/adminModels";

const listings = ref<ServiceListingRow[]>([]);
const error = ref<string | null>(null);
const busyId = ref<string | null>(null);

async function reload() {
  try {
    listings.value = await getServiceListings();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

onMounted(reload);

async function run(row: ServiceListingRow, action: () => Promise<void>) {
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

function expertName(row: ServiceListingRow) {
  const p = row.expert?.profile;
  return p ? [p.first_name, p.last_name].filter(Boolean).join(" ") || p.email : "—";
}

function price(row: ServiceListingRow) {
  if (!row.price_cents) return "—";
  const dollars = row.price_cents / 100;
  return `$${Number.isInteger(dollars) ? dollars : dollars.toFixed(2)}`;
}

function statusClass(status: string) {
  return status === "live" ? "ok" : status === "archived" ? "muted" : "pending";
}
</script>

<template>
  <h1 class="admin-title">Service listings</h1>
  <p class="admin-subtitle">
    Marketplace monitoring (US59). Archiving hides a listing from the app immediately;
    the expert can see it as archived in their portal.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <table class="admin-table">
      <thead>
        <tr><th>Service</th><th>Expert</th><th>Category</th><th>Price</th><th>Status</th><th>Actions</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in listings" :key="row.id">
          <td>{{ row.name }}</td>
          <td>{{ expertName(row) }}</td>
          <td>{{ row.category }}</td>
          <td>{{ price(row) }}</td>
          <td><span class="pill" :class="statusClass(row.status)">{{ row.status }}</span></td>
          <td>
            <div class="admin-actions">
              <button
                v-if="row.status === 'live'"
                class="admin-btn danger"
                :disabled="busyId === row.id"
                @click="run(row, () => archiveListing(row))"
              >
                Archive
              </button>
              <button
                v-if="row.status === 'archived'"
                class="admin-btn"
                :disabled="busyId === row.id"
                @click="run(row, () => restoreListing(row))"
              >
                Restore
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-if="!listings.length" class="admin-empty">No service listings yet.</p>
  </div>
</template>
