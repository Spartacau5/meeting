import posthog from "posthog-js"

export default {
  install(Vue, options) {
    // Only initialize PostHog if we have a valid API key
    const apiKey = process.env.VUE_APP_POSTHOG_API_KEY;
    
    if (apiKey && apiKey !== "phc_disabled" && apiKey !== "") {
      Vue.prototype.$posthog = posthog.init(apiKey, {
        api_host: "https://e.schej.it",
        capture_pageview: false,
        autocapture: {
          dom_event_allowlist: ["click"],
        },
      });
    } else {
      // Create a dummy posthog object to prevent errors when posthog is referenced
      Vue.prototype.$posthog = {
        capture: () => {},
        identify: () => {},
        isFeatureEnabled: () => false,
        getFeatureFlag: () => null,
        onFeatureFlags: (callback) => { callback(); },
        setPersonPropertiesForFlags: () => {},
      };
    }
  },
}
