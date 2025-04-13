<template>
  <div class="auth-loading">
    <p>Authenticating, please wait...</p>
  </div>
</template>

<script>
import { post } from "@/utils"

export default {
  name: "Auth",
  async mounted() {
    try {
      // Extract the code and state from the URL
      const urlParams = new URLSearchParams(window.location.search)
      const code = urlParams.get("code")
      const state = urlParams.get("state")

      if (!code) {
        throw new Error("Missing authorization code")
      }

      // Exchange the code for a token/session on your backend
      await post("/auth/google/callback", { code, state })

      // ✅ Success! Redirect to /home
      this.$router.replace({ name: "home" })
    } catch (error) {
      console.error("Authentication failed:", error)
      // ⛔ If anything goes wrong, redirect to landing page
      this.$router.replace({ name: "landing" })
    }
  }
}
</script>

<style scoped>
.auth-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100vh;
  font-size: 18px;
}
</style>
