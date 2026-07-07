<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getContactMessages, resolveContactMessage } from "@/controller/admin/moderateContent";
import type { ContactMessageRow } from "@/controller/admin/adminModels";

const rows = ref<ContactMessageRow[]>([]);
const error = ref<string | null>(null);
const busyId = ref<string | null>(null);
const responses = ref<Record<string, string>>({});

const open = computed(() => rows.value.filter((r) => r.status === "open"));
const resolved = computed(() => rows.value.filter((r) => r.status === "resolved"));

async function reload() {
  try {
    rows.value = await getContactMessages();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

onMounted(reload);

async function resolve(row: ContactMessageRow) {
  error.value = null;
  busyId.value = row.id;
  try {
    await resolveContactMessage(row, responses.value[row.id] ?? "");
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

/// Opens the admin's own mail client with the reply drafted — the site has no
/// outbound mailer, so the actual send stays with the human.
function mailtoHref(row: ContactMessageRow) {
  const subject = encodeURIComponent("Re: your message to Wise Workout");
  const drafted = responses.value[row.id] ?? "";
  const body = encodeURIComponent(
    `Hi ${row.submitter_name},\n\n${drafted}\n\n— Wise Workout team\n\n` +
      `> ${row.message.replace(/\n/g, "\n> ")}`,
  );
  return `mailto:${row.submitter_email}?subject=${subject}&body=${body}`;
}
</script>

<template>
  <h1 class="admin-title">Contact inbox</h1>
  <p class="admin-subtitle">
    Messages from the public contact form (#28.1). Responses are recorded against the message —
    actually emailing the sender stays a manual step.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Open ({{ open.length }})</h2>
    <p v-if="!open.length" class="admin-empty">Inbox zero.</p>

    <div v-for="row in open" :key="row.id" class="app-row">
      <div class="app-head">
        <h3>{{ row.submitter_name }}</h3>
        <span class="admin-note">{{ row.submitter_email }}</span>
      </div>
      <p style="margin: 0">{{ row.message }}</p>
      <div class="admin-actions">
        <input v-model="responses[row.id]" class="admin-field" style="flex: 1" placeholder="Write the reply here…" />
        <a class="admin-btn" :href="mailtoHref(row)">Reply via email</a>
        <button class="admin-btn primary" :disabled="busyId === row.id" @click="resolve(row)">
          Record &amp; resolve
        </button>
      </div>
    </div>
  </div>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Resolved</h2>
    <table class="admin-table">
      <thead>
        <tr><th>From</th><th>Message</th><th>Response</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in resolved" :key="row.id">
          <td>{{ row.submitter_name }}</td>
          <td>{{ row.message.slice(0, 60) }}{{ row.message.length > 60 ? "…" : "" }}</td>
          <td>{{ row.response ?? "—" }}</td>
        </tr>
      </tbody>
    </table>
    <p v-if="!resolved.length" class="admin-empty">Nothing resolved yet.</p>
  </div>
</template>
