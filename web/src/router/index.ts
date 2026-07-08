import { createRouter, createWebHistory } from "vue-router";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      name: "landing",
      component: () => import("@/boundary/ui/landing/LandingPage.vue"),
    },
    {
      path: "/login",
      name: "login",
      component: () => import("@/boundary/ui/auth/LoginPage.vue"),
    },
    {
      path: "/register",
      name: "register",
      component: () => import("@/boundary/ui/auth/RegisterPage.vue"),
    },
    {
      path: "/expert-application",
      name: "expert-application",
      component: () => import("@/boundary/ui/auth/ExpertApplicationPage.vue"),
    },
    {
      path: "/privacy",
      name: "privacy",
      component: () => import("@/boundary/ui/legal/PrivacyPage.vue"),
    },
    {
      path: "/terms",
      name: "terms",
      component: () => import("@/boundary/ui/legal/TermsPage.vue"),
    },
    {
      path: "/admin",
      component: () => import("@/boundary/ui/admin/AdminLayout.vue"),
      children: [
        { path: "", name: "admin-overview", component: () => import("@/boundary/ui/admin/OverviewPage.vue") },
        { path: "users", name: "admin-users", component: () => import("@/boundary/ui/admin/UsersPage.vue") },
        { path: "applications", name: "admin-applications", component: () => import("@/boundary/ui/admin/ApplicationsPage.vue") },
        { path: "listings", name: "admin-listings", component: () => import("@/boundary/ui/admin/ListingsPage.vue") },
        { path: "categories", name: "admin-categories", component: () => import("@/boundary/ui/admin/CategoriesPage.vue") },
        { path: "pricing", name: "admin-pricing", component: () => import("@/boundary/ui/admin/PricingPage.vue") },
        { path: "faq", name: "admin-faq", component: () => import("@/boundary/ui/admin/FaqPage.vue") },
        { path: "testimonials", name: "admin-testimonials", component: () => import("@/boundary/ui/admin/TestimonialsPage.vue") },
        { path: "feedback", name: "admin-feedback", component: () => import("@/boundary/ui/admin/FeedbackPage.vue") },
        { path: "contact", name: "admin-contact", component: () => import("@/boundary/ui/admin/ContactPage.vue") },
      ],
    },
    {
      path: "/:pathMatch(.*)*",
      redirect: "/",
    },
  ],
  scrollBehavior(to) {
    if (to.hash) return { el: to.hash, behavior: "smooth" };
    return { top: 0 };
  },
});

export default router;
