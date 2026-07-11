<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import { getCategories, saveCategory, setCategoryActive } from "@/controller/admin/manageCatalog";
import type { ExpertCategoryRow } from "@/controller/admin/adminModels";

// (#) Admin page for the expert-category catalog - add new ones and retire/reactivate.

// (#) All categories in the catalog, active or retired.
const categories = ref<ExpertCategoryRow[]>([]);
// (#) Error text to surface if a save/toggle blows up.
const error = ref<string | null>(null);
// (#) Which row is mid-action ("new" while adding), used to disable buttons.
const busyId = ref<string | null>(null);
// (#) The form fields for a brand new category before it's saved.
const draft = reactive({ id: "", label: "", description: "" });

// (#) Fetch the whole category list again.
async function reload() {
  try {
    categories.value = await getCategories();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

// (#) Load categories when the page opens.
onMounted(reload);

// (#) Save the draft as a new active category, then clear the form and reload.
async function addCategory() {
  error.value = null;
  busyId.value = "new";
  try {
    await saveCategory({ ...draft, is_active: true });
    draft.id = ""; draft.label = ""; draft.description = "";
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

// (#) Flip a category between active and retired.
async function toggle(row: ExpertCategoryRow) {
  error.value = null;
  busyId.value = row.id;
  try {
    await setCategoryActive(row, !row.is_active);
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}
</script>

<template>
  <h1 class="admin-title">Expert categories</h1>
  <p class="admin-subtitle">
    The catalog behind marketplace chips and expert specialties (US58). Retiring hides a
    category from pickers but keeps existing labels resolving.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <table class="admin-table">
      <thead>
        <tr><th>Slug</th><th>Label</th><th>Description</th><th>Status</th><th>Actions</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in categories" :key="row.id">
          <td><code>{{ row.id }}</code></td>
          <td>{{ row.label }}</td>
          <td>{{ row.description }}</td>
          <td>
            <span class="pill" :class="row.is_active ? 'ok' : 'muted'">
              {{ row.is_active ? "active" : "retired" }}
            </span>
          </td>
          <td>
            <button class="admin-btn" :class="{ danger: row.is_active }" :disabled="busyId === row.id" @click="toggle(row)">
              {{ row.is_active ? "Retire" : "Reactivate" }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="admin-card">
    <h2 class="admin-title" style="font-size: 16px">Add category</h2>
    <div class="admin-actions" style="margin-top: 10px">
      <input v-model="draft.id" class="admin-field" style="max-width: 160px" placeholder="slug e.g. pilates" />
      <input v-model="draft.label" class="admin-field" style="max-width: 200px" placeholder="Label" />
      <input v-model="draft.description" class="admin-field" style="flex: 1" placeholder="Description" />
      <button class="admin-btn primary" :disabled="busyId === 'new'" @click="addCategory">Add</button>
    </div>
  </div>
</template>
