import Vue from "vue"
import VueRouter from "vue-router"
import Landing from "@/views/Landing"
import RedirectComponent from "@/components/RedirectComponent"
import { auth } from "../firebase"
import { get } from "@/utils"

Vue.use(VueRouter)

const routes = [
  {
    path: "/",
    name: "landing",
    component: Landing,
  },
  {
    path: "/dashboard",
    name: "dashboard",
    component: () => import("@/views/Home.vue"),
    props: true,
  },
  {
    path: "/home",
    name: "home",
    component: RedirectComponent,
    props: { to: "dashboard" }
  },
  {
    path: "/settings",
    name: "settings",
    component: () => import("@/views/Settings.vue"),
  },
  {
    path: "/e/:eventId",
    name: "event",
    component: () => import("@/views/Event.vue"),
    props: true,
  },
  {
    path: "/e/:eventId/responded",
    name: "responded",
    component: () => import("@/views/Responded.vue"),
    props: true,
  },
  {
    path: "/g/:groupId",
    name: "group",
    component: () => import("@/views/Group.vue"),
    props: true,
  },
  {
    path: "/s/:signUpId",
    name: "signUp",
    component: () => import("@/views/SignUp.vue"),
    props: true,
  },
  {
    path: "/auth",
    name: "auth",
    component: () => import("@/views/Auth.vue"),
  },
  {
    path: "/privacy-policy",
    name: "privacy-policy",
    component: () => import("@/views/PrivacyPolicy.vue"),
  },
  {
    path: "*",
    name: "404",
    component: () => import("@/views/PageNotFound.vue"),
  },
]

const router = new VueRouter({
  mode: "history",
  base: process.env.BASE_URL,
  routes,
})

router.beforeEach(async (to, from, next) => {
  // Routes that require authentication
  const authRoutes = ["dashboard", "settings"];
  
  // Routes that are accessible without authentication
  const publicRoutes = ["landing", "auth", "privacy-policy", "404"];
  
  // Special routes that may be accessed both authenticated and non-authenticated
  // (event, group, signUp pages that can work in both modes)
  const hybridRoutes = ["event", "group", "signUp", "responded"];
  
  console.log(`Route navigation: ${from.name || 'initial'} -> ${to.name}, auth required: ${authRoutes.includes(to.name)}`);

  // Check if user is authenticated with Firebase
  const currentUser = auth.currentUser;
  const isFirebaseAuthenticated = !!currentUser;
  console.log(`Firebase auth state: ${isFirebaseAuthenticated ? 'authenticated' : 'not authenticated'}`);

  // For hybrid routes, we always allow access
  if (hybridRoutes.includes(to.name)) {
    console.log(`Allowing access to hybrid route: ${to.name}`);
    next();
    return;
  }

  // For public routes, we always allow access
  if (publicRoutes.includes(to.name)) {
    console.log(`Allowing access to public route: ${to.name}`);
    next();
    return;
  }

  // For auth routes, we need to verify authentication
  if (authRoutes.includes(to.name)) {
    // If Firebase says we're authenticated, we allow access
    if (isFirebaseAuthenticated) {
      console.log(`Firebase authenticated, allowing access to: ${to.name}`);
      next();
      return;
    }
    
    // Double-check with server as a fallback
    try {
      console.log('Checking auth status with backend');
      await get("/auth/status");
      console.log('Backend confirms authentication, allowing access');
      next();
    } catch (err) {
      console.error('Not authenticated with backend, redirecting to landing');
      next({ name: "landing" });
    }
    return;
  }

  // For any other route, allow by default
  console.log(`Route ${to.name} not explicitly categorized, allowing access`);
  next();
});

export default router
