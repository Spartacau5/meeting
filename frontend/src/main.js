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
onAuthStateChanged(auth, async (user) => {
  console.log("Firebase auth state changed:", user ? "Signed in" : "Signed out");
  
  if (user) {
    // User is signed in with Firebase, verify with backend
    try {
      const authUser = await store.dispatch("refreshAuthUser");
      console.log("Backend auth successful:", authUser ? authUser.email : "No user data");
    } catch (err) {
      console.error("Backend auth failed despite Firebase auth:", err);
      // If backend doesn't recognize the user, clear store state
      store.commit("setAuthUser", null);
    }
  } else {
    // User is signed out of Firebase
    console.log("Firebase user signed out, clearing auth state");
    
    // Clear user data if any exists
    store.commit("setAuthUser", null);
    // Also clear events data
    store.commit("setCreatedEvents", []);
    store.commit("setJoinedEvents", []);
  }
});

Vue.config.productionTip = false

new Vue({
  router,
  store,
  vuetify,
  render: (h) => h(App),
}).$mount("#app")
