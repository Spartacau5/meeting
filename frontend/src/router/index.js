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
  const authRoutes = ["dashboard", "settings"]
  const publicRoutes = ["landing", "auth", "privacy-policy", "404"]

  // Check if user is authenticated with Firebase
  const currentUser = auth.currentUser

  if (currentUser) {
    // User is authenticated - allow access to any route
    next()
  } else {
    // User is not authenticated
    try {
      // Double-check with server (for cases where Firebase auth might be out of sync)
      await get("/auth/status")
      
      // If successful, user is authenticated on backend but not in Firebase
      // Allow access to any route
      next()
    } catch (err) {
      // Not authenticated on backend either
      
      // Allow public routes
      if (publicRoutes.includes(to.name)) {
        next()
      }
      // Redirect away from protected routes
      else if (authRoutes.includes(to.name)) {
        next({ name: "landing" })
      } else {
        next()
      }
    }
  }
})

export default router
