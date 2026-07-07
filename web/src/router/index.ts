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
