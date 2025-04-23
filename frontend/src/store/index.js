import Vue from "vue"
import Vuex from "vuex"
import { auth } from "../firebase"
import { 
  signInWithPopup, 
  GoogleAuthProvider, 
  signOut as firebaseSignOut,
  onAuthStateChanged
} from "firebase/auth"
import { get, post } from "@/utils"

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    error: "",
    info: "",

    authUser: null,

    createdEvents: [],
    joinedEvents: [],

    // Feature flags
    groupsEnabled: true,
    signUpFormEnabled: false,
    daysOnlyEnabled: false,
    overlayAvailabilitiesEnabled: false,
  },
  getters: {},
  mutations: {
    setError(state, error) {
      state.error = error
    },
    setInfo(state, info) {
      state.info = info
    },

    setAuthUser(state, authUser) {
      state.authUser = authUser
    },

    setCreatedEvents(state, createdEvents) {
      state.createdEvents = createdEvents
    },
    setJoinedEvents(state, joinedEvents) {
      state.joinedEvents = joinedEvents
    },

    setGroupsEnabled(state, enabled) {
      state.groupsEnabled = enabled
    },
    setSignUpFormEnabled(state, enabled) {
      state.signUpFormEnabled = enabled
    },
    setDaysOnlyEnabled(state, enabled) {
      state.daysOnlyEnabled = enabled
    },
    setOverlayAvailabilitiesEnabled(state, enabled) {
      state.overlayAvailabilitiesEnabled = enabled
    },
  },
  actions: {
    // Error & info
    showError({ commit }, error) {
      commit("setError", "")
      setTimeout(() => commit("setError", error), 0)
    },
    showInfo({ commit }, info) {
      commit("setInfo", "")
      setTimeout(() => commit("setInfo", info), 0)
    },

    async refreshAuthUser({ commit }) {
      try {
        console.log("Fetching user profile from backend");
        const authUser = await get("/user/profile");
        
        if (authUser) {
          console.log("User profile fetched successfully:", authUser.email);
          commit("setAuthUser", authUser);
          
          // If using Posthog, identify the user
          if (window.posthog) {
            window.posthog.identify(authUser._id, {
              email: authUser.email,
              firstName: authUser.firstName,
              lastName: authUser.lastName,
            });
          }
          
          return authUser;
        } else {
          console.warn("Backend returned empty user profile");
          commit("setAuthUser", null);
          return null;
        }
      } catch (error) {
        console.error("Failed to fetch user profile:", error);
        commit("setAuthUser", null);
        throw error;
      }
    },

    // Firebase Auth
    async signInWithGoogle({ commit, dispatch }) {
      try {
        const provider = new GoogleAuthProvider()
        // Add scopes for calendar access
        provider.addScope("https://www.googleapis.com/auth/calendar.calendarlist.readonly")
        provider.addScope("https://www.googleapis.com/auth/calendar.events.readonly")
        
        const result = await signInWithPopup(auth, provider)
        
        // Get the tokens from the result
        const credential = GoogleAuthProvider.credentialFromResult(result)
        const accessToken = credential.accessToken
        const user = result.user
        
        // Get the ID token 
        const idToken = await user.getIdToken()
        
        // Send token to your backend to create or update user
        try {
          const timezoneOffset = new Date().getTimezoneOffset()
          await post("/auth/sign-in-firebase", {
            idToken: idToken,
            accessToken: accessToken, // May be null/undefined if not requested
            refreshToken: "", // Firebase Web SDK doesn't expose refresh tokens directly
            calendarType: "google",
            timezoneOffset: -timezoneOffset
          })
          
          // Refresh user data from server
          await dispatch("refreshAuthUser")
        } catch (error) {
          console.error("Backend auth error:", error)
          dispatch("showError", "Failed to authenticate with server")
          throw error
        }
        
        return user
      } catch (error) {
        console.error("Firebase auth error:", error)
        dispatch("showError", "Authentication failed")
        throw error
      }
    },
    
    async signOut({ commit }) {
      try {
        // Sign out from Firebase
        await firebaseSignOut(auth)
        
        // Sign out from backend
        await post("/auth/sign-out")
        
        // Clear user data
        commit("setAuthUser", null)
        commit("setCreatedEvents", [])
        commit("setJoinedEvents", [])
      } catch (error) {
        console.error("Sign out error:", error)
        throw error
      }
    },

    // Events
    getEvents({ commit, dispatch }) {
      if (this.state.authUser) {
        return get("/user/events")
          .then((data) => {
            commit("setCreatedEvents", data.events)
            commit("setJoinedEvents", data.joinedEvents)
          })
          .catch((err) => {
            dispatch("showError", "There was a problem fetching events!")
          })
      } else {
        return null
      }
    },
  },
  modules: {},
})
