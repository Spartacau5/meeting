import Vue from "vue"
import VueRouter from "vue-router"
import Landing from "@/views/Landing"
import { get } from "@/utils"

Vue.use(VueRouter)

const routes = [
  {
    path: "/",
    name: "landing",
    component: Landing,
  },
  {
    path: "/home",
    name: "home",
    component: () => import("@/views/Home.vue"),
    props: true,
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
  mode: "hash",
  base: process.env.BASE_URL,
  routes,
})

router.beforeEach(async (to, from, next) => {
  const authRoutes = ["home", "settings"]
  const noAuthRoutes = ["landing"]
  const publicRoutes = ["landing", "auth", "privacy-policy", "404"]

  try {
    await get("/auth/status") // means user is logged in

    // Don't redirect if already going to "home"
    if (noAuthRoutes.includes(to.name)) {
      if (to.name !== "home") {
        next({ name: "home" })
      } else {
        next()
      }
    } else {
      next()
    }
  } catch (err) {
    // Not authenticated

    // Allow public routes
    if (publicRoutes.includes(to.name)) {
      next()
    }
    // Redirect away from protected routes
    else if (authRoutes.includes(to.name)) {
      if (to.name !== "landing") {
        next({ name: "landing" })
      } else {
        next()
      }
    } else {
      next()
    }
  }
})


export default router
