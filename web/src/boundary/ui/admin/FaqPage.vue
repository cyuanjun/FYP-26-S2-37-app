<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import { getFaqs, saveFaq } from "@/controller/admin/manageCatalog";
import type { FaqRow } from "@/controller/admin/adminModels";

// (#) Admin editor for the public FAQ - edit entries, reorder them, hide/show, and add new.

// (#) The FAQ entries, in display order.
const faqs = ref<FaqRow[]>([]);
// (#) Error text if a save fails.
const error = ref<string | null>(null);
// (#) Id of the row that just saved, so we can flash "Saved" on its button.
const savedId = ref<string | null>(null);
// (#) Id of the row mid-save ("new" while adding), disables buttons.
const busyId = ref<string | null>(null);
// (#) Fields for a new FAQ before it's added.
const draft = reactive({ faq_key: "", question: "", answer: "" });

// (#) Fetch the FAQ list again.
async function reload() {
  try {
    faqs.value = await getFaqs();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

// (#) Load the FAQs when the page mounts.
onMounted(reload);

// (#) Save a single edited FAQ row and mark it as just-saved.
async function save(row: FaqRow) {
  error.value = null;
  savedId.value = null;
  busyId.value = row.id;
  try {
    await saveFaq(row);
    savedId.value = row.id;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

// (#) Flip an entry's shown/hidden flag and persist it.
async function toggle(row: FaqRow) {
  row.is_active = !row.is_active;
  await save(row);
}

// (#) Add the draft as a new FAQ at the bottom of the order, then clear and reload.
async function addFaq() {
  error.value = null;
  busyId.value = "new";
  try {
    await saveFaq({
      ...draft,
      display_order: (faqs.value[faqs.value.length - 1]?.display_order ?? 0) + 1,
      is_active: true,
    });
    draft.faq_key = ""; draft.question = ""; draft.answer = "";
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

// (#) Move a row up or down by swapping display_order with its neighbour.
async function move(row: FaqRow, direction: -1 | 1) {
  const index = faqs.value.indexOf(row);
  const other = faqs.value[index + direction];
  if (!other) return;
  error.value = null;
  busyId.value = row.id;
  try {
    const a = row.display_order;
    await saveFaq({ ...row, display_order: other.display_order });
    await saveFaq({ ...other, display_order: a });
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}
</script>

<template>
  <h1 class="admin-title">FAQ</h1>
  <p class="admin-subtitle">
    The public FAQ section (US63). Edits go live on the landing page immediately;
    hidden entries stay here but disappear from the site.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div v-for="(row, i) in faqs" :key="row.id" class="admin-card">
    <div class="app-head">
      <code style="font-size: 12px">{{ row.faq_key }}</code>
      <div class="admin-actions">
        <button class="admin-btn" :disabled="i === 0 || busyId === row.id" @click="move(row, -1)">↑</button>
        <button class="admin-btn" :disabled="i === faqs.length - 1 || busyId === row.id" @click="move(row, 1)">↓</button>
        <span class="pill" :class="row.is_active ? 'ok' : 'muted'">{{ row.is_active ? "shown" : "hidden" }}</span>
      </div>
    </div>
    <div style="display: grid; gap: 8px; margin-top: 10px">
      <input v-model="row.question" class="admin-field" placeholder="Question" />
      <textarea v-model="row.answer" class="admin-field" rows="3" placeholder="Answer"></textarea>
      <div class="admin-actions">
        <button class="admin-btn primary" :disabled="busyId === row.id" @click="save(row)">
          {{ savedId === row.id ? "Saved ✓" : "Save" }}
        </button>
        <button class="admin-btn" :class="{ danger: row.is_active }" :disabled="busyId === row.id" @click="toggle(row)">
          {{ row.is_active ? "Hide" : "Show" }}
        </button>
      </div>
    </div>
  </div>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Add FAQ</h2>
    <div style="display: grid; gap: 8px; margin-top: 10px">
      <input v-model="draft.faq_key" class="admin-field" style="max-width: 220px" placeholder="key e.g. data-privacy" />
      <input v-model="draft.question" class="admin-field" placeholder="Question" />
      <textarea v-model="draft.answer" class="admin-field" rows="3" placeholder="Answer"></textarea>
      <div>
        <button class="admin-btn primary" :disabled="busyId === 'new'" @click="addFaq">Add</button>
      </div>
    </div>
  </div>
</template>
