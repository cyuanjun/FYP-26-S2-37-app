<script setup lang="ts">
import { onMounted, ref } from "vue";
import { RouterLink, RouterView, useRouter } from "vue-router";
import { getAdminIdentity, logoutAdmin } from "@/controller/admin/adminSession";
import type { AdminIdentity } from "@/controller/admin/adminModels";
import "./admin.css";

// (#) Shell around the whole admin portal: sidebar nav + the routed page.
// (#) Also the guard that bounces you to login if you're not an admin.

const router = useRouter();
// (#) The signed-in admin's identity, null until we've checked.
const admin = ref<AdminIdentity | null>(null);
// (#) True while the session check is still running (shows the "checking" state).
const checking = ref(true);

// (#) On load, ask who's signed in; kick out to /login if it's nobody.
onMounted(async () => {
  admin.value = await getAdminIdentity();
  checking.value = false;
  if (!admin.value) router.replace("/login");
});

// (#) Sign the admin out and send them back to the login page.
async function onSignOut() {
  await logoutAdmin();
  router.replace("/login");
}
</script>

<template>
  <div v-if="checking" class="admin-shell">
    <div></div>
    <main class="admin-main"><p class="admin-note">Checking admin session…</p></main>
  </div>

  <div v-else-if="admin" class="admin-shell">
    <aside class="admin-sidebar">
      <RouterLink to="/" class="brand" aria-label="Wise Workout home">
        <span class="brand-mark" aria-hidden="true"></span>
        <span class="brand-name">Wise <span>Workout</span></span>
      </RouterLink>

      <nav class="admin-nav">
        <RouterLink to="/admin">Overview</RouterLink>
        <RouterLink to="/admin/users">Users</RouterLink>
        <RouterLink to="/admin/applications">Expert applications</RouterLink>
        <RouterLink to="/admin/listings">Service listings</RouterLink>
        <RouterLink to="/admin/categories">Categories</RouterLink>
        <RouterLink to="/admin/pricing">Pricing</RouterLink>
        <RouterLink to="/admin/faq">FAQ</RouterLink>
        <RouterLink to="/admin/testimonials">Testimonials</RouterLink>
        <RouterLink to="/admin/feedback">Feedback</RouterLink>
        <RouterLink to="/admin/contact">Contact inbox</RouterLink>
      </nav>

      <div class="admin-signout">
        <div class="admin-note" style="margin-bottom: 8px">
          Signed in as {{ admin.first_name }} {{ admin.last_name }}
        </div>
        <button type="button" class="admin-btn" @click="onSignOut">Sign out</button>
      </div>
    </aside>

    <main class="admin-main">
      <RouterView />
    </main>
  </div>
</template>
