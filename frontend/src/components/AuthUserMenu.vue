<!-- Displays auth user's avatar, which displays a menu when clicked -->
<template>
  <v-menu v-if="authUser" offset-y left>
    <template v-slot:activator="{ on }">
      <v-btn id="user-menu-btn" icon :width="size" :height="size" v-on="on">
        <v-avatar :size="size">
          <UserAvatarContent :user="authUser" :size="size" />
        </v-avatar>
      </v-btn>
    </template>
    <v-list class="py-0" :dense="isPhone">
      <v-list-item>
        <v-list-item-title>
          <strong>{{ `${authUser.firstName} ${authUser.lastName}` }}</strong>
        </v-list-item-title>
      </v-list-item>
      <v-list-item
        v-if="showFeedbackBtn"
        id="feedback-btn"
        href="https://forms.gle/9AgRy4PQfWfVuBnw8"
        target="_blank"
      >
        <v-list-item-title class="tw-flex tw-items-center tw-gap-1">
          <v-icon class="tw-mr-1" small color="black">mdi-message</v-icon>
          Give feedback
        </v-list-item-title>
      </v-list-item>
      <v-list-item id="settings-btn" @click="goToSettings">
        <v-list-item-title class="tw-flex tw-items-center tw-gap-1">
          <v-icon class="tw-mr-1" small color="black">mdi-cog</v-icon>
          Settings
        </v-list-item-title>
      </v-list-item>
      <v-divider></v-divider>
      <v-list-item id="sign-out-btn" @click="signOut">
        <v-list-item-title class="red--text tw-flex tw-items-center tw-gap-1">
          <v-icon class="tw-mr-1" small color="red">mdi-logout</v-icon>
          Sign Out
        </v-list-item-title>
      </v-list-item>
    </v-list>
  </v-menu>
</template>

<script>
import UserAvatarContent from "@/components/UserAvatarContent"
import { mapState, mapMutations, mapActions } from "vuex"
import { isPhone } from "@/utils"

export default {
  name: "AuthUserMenu",

  components: {
    UserAvatarContent,
  },

  computed: {
    ...mapState(["authUser"]),
    isPhone() {
      return isPhone(this.$vuetify)
    },
    size() {
      return this.isPhone ? 32 : 42
    },
    showFeedbackBtn() {
      return !(!this.isPhone || this.$route.name === "home")
    },
  },

  methods: {
    ...mapMutations(["setAuthUser"]),
    ...mapActions(["signOut"]),
    
    async signOut() {
      try {
        await this.signOut()
        this.$posthog?.reset()
        this.$router.push({ name: "landing" })
      } catch (error) {
        console.error("Sign out failed:", error)
      }
    },
    
    goToSettings() {
      this.$router.replace({ name: "settings" })
    },
  },
}
</script>
