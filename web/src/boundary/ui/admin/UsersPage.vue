<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getUsers, reactivateUser, setUserTier, suspendUser } from "@/controller/admin/manageUsers";
import type { AdminUser } from "@/controller/admin/adminModels";

// (#) Admin user-management page - search accounts, switch free/premium tier, suspend/reactivate.

// (#) All accounts loaded from the backend.
const users = ref<AdminUser[]>([]);
// (#) The live search box text.
const query = ref("");
// (#) Error text if a load or action fails.
const error = ref<string | null>(null);
// (#) Id of the user currently being acted on.
const busyId = ref<string | null>(null);

// (#) Users filtered by the search box (name, email, or username); all when empty.
const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return users.value;
  return users.value.filter((u) =>
    [u.email, u.first_name, u.last_name, u.username].some((v) => v?.toLowerCase().includes(q)),
  );
});

// (#) Fetch the account list again.
async function reload() {
  try {
    users.value = await getUsers();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}

// (#) Load users on mount.
onMounted(reload);

// (#) Shared helper: run a tier/suspend action on a user, then reload the list.
async function run(user: AdminUser, action: () => Promise<void>) {
  error.value = null;
  busyId.value = user.id;
  try {
    await action();
    await reload();
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    busyId.value = null;
  }
}

// (#) Display name from first/last, or a dash if both are missing.
function name(u: AdminUser) {
  return [u.first_name, u.last_name].filter(Boolean).join(" ") || "—";
}
</script>

<template>
  <h1 class="admin-title">Users</h1>
  <p class="admin-subtitle">
    Accounts, tiers, and access (US56/US61/US62). Expert role comes from application approval;
    tier switches here are free ↔ premium only.
  </p>

  <p v-if="error" class="admin-error">{{ error }}</p>

  <div class="admin-card">
    <input v-model="query" class="admin-field" placeholder="Search by name, email, or username" style="margin-bottom: 14px" />

    <table class="admin-table">
      <thead>
        <tr><th>Name</th><th>Email</th><th>Username</th><th>Role</th><th>Status</th><th>Actions</th></tr>
      </thead>
      <tbody>
        <tr v-for="u in filtered" :key="u.id">
          <td>{{ name(u) }}</td>
          <td>{{ u.email }}</td>
          <td>{{ u.username ? "@" + u.username : "—" }}</td>
          <td><span class="pill" :class="u.role">{{ u.role }}</span></td>
          <td>
            <span v-if="u.status === 'suspended'" class="pill warn">suspended</span>
            <span v-else class="pill ok">active</span>
          </td>
          <td>
            <div class="user-actions">
              <span class="action-slot">
                <button
                  v-if="u.role === 'free'"
                  class="admin-btn"
                  :disabled="busyId === u.id"
                  @click="run(u, () => setUserTier(u, 'premium'))"
                >
                  Make Premium
                </button>
                <button
                  v-else-if="u.role === 'premium'"
                  class="admin-btn"
                  :disabled="busyId === u.id"
                  @click="run(u, () => setUserTier(u, 'free'))"
                >
                  Make Free
                </button>
              </span>
              <span class="action-slot">
                <button
                  v-if="u.status === 'suspended'"
                  class="admin-btn primary"
                  :disabled="busyId === u.id"
                  @click="run(u, () => reactivateUser(u))"
                >
                  Reactivate
                </button>
                <button
                  v-else-if="u.role !== 'admin'"
                  class="admin-btn danger"
                  :disabled="busyId === u.id"
                  @click="run(u, () => suspendUser(u))"
                >
                  Suspend
                </button>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-if="!filtered.length" class="admin-empty">No accounts match.</p>
  </div>
</template>

<style scoped>
.user-actions {
  display: grid;
  grid-template-columns: 132px 110px;
  gap: 8px;
}

.action-slot .admin-btn {
  width: 100%;
}
</style>
