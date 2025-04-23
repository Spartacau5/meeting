import Vue from "vue"
import VueWorker from "vue-worker"
import App from "./App.vue"
import "./registerServiceWorker"
import router from "./router"
import store from "./store"
import vuetify from "./plugins/vuetify"
import posthogPlugin from "./plugins/posthog"
import VueGtm from "@gtm-support/vue2-gtm"
import VueMeta from "vue-meta"
import "./index.css"
import { auth } from "./firebase"
import { onAuthStateChanged } from "firebase/auth"

// Posthog
// if (process.env.NODE_ENV !== "development") {
Vue.use(posthogPlugin)
// }

// Google Analytics
Vue.use(VueGtm, {
  id: "GTM-M677X6V",
  vueRouter: router,
})

// Site Metadata
Vue.use(VueMeta)

// Workers
Vue.use(VueWorker)

// Register a global tooltip directive
Vue.directive('tooltip', {
  bind: function(el, binding) {
    // Simple tooltip implementation
    el.setAttribute('title', binding.value);
    el.style.position = 'relative';
    el.style.cursor = 'pointer';
  }
});

// Initialize Firebase Auth State Listener
onAuthStateChanged(auth, (user) => {
  if (user) {
    // User is signed in, but we'll rely on our backend for user data
    console.log("Firebase user signed in:", user.email)
    
    // If we don't have user data yet, fetch it from backend
    if (!store.state.authUser) {
      store.dispatch("refreshAuthUser").catch(err => {
        console.error("Failed to refresh user data:", err)
      })
    }
  } else {
    // User is signed out
    console.log("Firebase user signed out")
    
    // Clear user data if any exists
    if (store.state.authUser) {
      store.commit("setAuthUser", null)
    }
  }
})

Vue.config.productionTip = false

new Vue({
  router,
  store,
  vuetify,
  render: (h) => h(App),
}).$mount("#app")
