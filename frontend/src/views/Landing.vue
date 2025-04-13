<template>
  <div>
    <!-- Modern header with subtle shadow -->
    <header class="tw-bg-white tw-py-4 tw-px-4 tw-border-b tw-border-gray-100 tw-shadow-sm">
      <div class="tw-max-w-6xl tw-mx-auto tw-flex tw-items-center tw-justify-between">
        <Logo type="schej" />
        <div class="tw-flex tw-items-center tw-gap-4">
          <v-btn text href="https://forms.gle/7iKpHRr1Adn7SWSS6" target="_blank" class="tw-text-gray-600 hover:tw-text-blue">Give Feedback</v-btn>
          <v-btn 
            outlined 
            @click="signIn" 
            class="tw-border-blue tw-text-blue hover:tw-bg-blue hover:tw-text-white tw-transition-colors"
          >
            Sign in
          </v-btn>
        </div>
      </div>
    </header>

    <!-- Enhanced main content with gradient background -->
    <div class="tw-min-h-screen tw-bg-gradient-to-b tw-from-white tw-to-green/5">
      <div class="tw-max-w-6xl tw-mx-auto tw-px-4 tw-py-8">
        <!-- Improved title section with animation -->
        <div class="tw-text-center tw-mb-12">
          <h1 class="tw-text-3xl md:tw-text-4xl tw-font-bold tw-mb-4">
            <span class="tw-bg-gradient-to-r tw-from-[#0088FF] tw-to-[#0055FF] tw-bg-clip-text tw-text-transparent hover:tw-scale-105 tw-transition-transform tw-inline-block">
              Meetings made easier
            </span>
          </h1>
          <p class="tw-text-gray-600 tw-text-lg tw-max-w-2xl tw-mx-auto tw-leading-relaxed">
            It's like a better When2Meet!
          </p>
        </div>

        <!-- Main container with enhanced card design -->
        <div class="tw-flex tw-flex-col md:tw-flex-row tw-justify-center tw-items-start tw-gap-16">
          <!-- Left panel: Calendar with modern card design -->
          <div class="tw-w-full md:tw-w-[42%] tw-mt-0">
            <div v-if="isPhone" class="tw-text-center tw-mb-2">
              <v-img
                alt="Gatherly character"
                src="@/assets/schejie/wave.png"
                :height="45"
                contain
                class="tw-mx-auto"
              />
            </div>
            <div>
              <LandingPageCalendar />
            </div>
          </div>

          <!-- Right panel: Event creation form with matching design -->
          <div class="tw-w-full md:tw-w-[42%] tw-mt-0">
            <div>
              <NewEvent
                :dialog="false"
                :allow-notifications="false"
                @signIn="signIn"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modern footer with improved layout -->
    <footer class="tw-bg-white tw-py-8 tw-border-t tw-border-gray-200">
      <div class="tw-max-w-6xl tw-mx-auto tw-px-4">
        <div class="tw-grid tw-grid-cols-1 tw-gap-8 md:tw-grid-cols-3">
          <div>
            <Logo type="schej" class="tw-mb-4" />
            <p class="tw-text-gray-600">
              Finding a time to meet, made simple.
            </p>
          </div>
          
          <div>
            <h3 class="tw-font-semibold tw-mb-4 tw-text-gray-800">Quick Links</h3>
            <div class="tw-space-y-2">
              <a href="#" @click.prevent="signIn" class="tw-block tw-text-gray-600 hover:tw-text-blue tw-transition-colors">
                Sign In
              </a>
              <a href="https://forms.gle/7iKpHRr1Adn7SWSS6" target="_blank" class="tw-block tw-text-gray-600 hover:tw-text-blue tw-transition-colors">
                Give Feedback
              </a>
            </div>
          </div>
          
          <div>
            <h3 class="tw-font-semibold tw-mb-4 tw-text-gray-800">Get Started</h3>
            <v-btn
              color="primary"
              class="tw-rounded-lg tw-bg-blue tw-text-white hover:tw-bg-[#0055FF] tw-transition-colors"
              @click="newDialog = true"
              elevation="2"
            >
              Create Event
            </v-btn>
          </div>
        </div>
        
        <div class="tw-mt-8 tw-pt-6 tw-border-t tw-border-gray-200 tw-text-center tw-text-sm tw-text-gray-600">
          © 2025 Arpit Ahluwalia. All rights reserved.
        </div>
      </div>
    </footer>

    <!-- Enhanced dialogs -->
    <v-dialog v-model="signInDialog" max-width="400">
      <v-card class="tw-rounded-xl">
        <v-card-title class="tw-text-xl tw-font-semibold">Sign in</v-card-title>
        <v-card-text class="tw-flex tw-flex-col tw-items-center tw-py-6">
          <SignInGoogleBtn class="tw-mb-6" @click="signInGoogle" />
          <div class="tw-text-center tw-text-sm tw-text-gray-600">
            By continuing, you agree to our
            <router-link class="tw-text-green hover:tw-text-darkest-green tw-transition-colors" :to="{ name: 'privacy-policy' }">
              privacy policy
            </router-link>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <NewDialog
      v-model="newDialog"
      :allow-notifications="false"
      no-tabs
      @signIn="signIn"
    />
  </div>
</template>

<style scoped>
@media screen and (min-width: 375px) and (max-width: 640px) {
  #header {
    font-size: 1.875rem !important; /* 30px */
    line-height: 2.25rem !important; /* 36px */
  }
}
</style>

<script>
import LandingPageCalendar from "@/components/landing/LandingPageCalendar.vue"
import { isPhone, signInGoogle } from "@/utils"
import SignInGoogleBtn from "@/components/SignInGoogleBtn.vue"
import NewEvent from "@/components/NewEvent.vue"
import NewDialog from "@/components/NewDialog.vue"
import Logo from "@/components/Logo.vue"

export default {
  name: "Landing",

  metaInfo: {
    title: "Gatherly - Finding a time to meet, made simple",
    meta: [
      {
        vmid: "description",
        name: "description",
        content:
          "Gatherly helps you quickly find the best time for your group to meet. It's like When2meet with Google Calendar integration!",
      },
      {
        property: "og:title",
        content: "Gatherly - Finding a time to meet, made simple",
      },
      {
        property: "og:site_name",
        content: "Gatherly",
      },
      {
        property: "og:type",
        content: "website",
      },
      {
        property: "og:url",
        content: "https://gatherly.app",
      },
      {
        property: "og:image",
        content: "https://gatherly.app/img/ogImage.png",
      },
      {
        property: "og:description",
        content:
          "Gatherly helps you quickly find the best time for your group to meet. It's like When2meet with Google Calendar integration!",
      },
    ],
  },

  components: {
    LandingPageCalendar,
    SignInGoogleBtn,
    NewEvent,
    NewDialog,
    Logo,
  },

  data: () => ({
    signInDialog: false,
    newDialog: false,
  }),

  computed: {
    isPhone() {
      return isPhone(this.$vuetify)
    },
  },

  methods: {
    signInGoogle() {
      signInGoogle({ state: null, selectAccount: true })
    },
    signIn() {
      this.signInDialog = true
    },
    redirectToPrivacyPolicy() {
      this.$router.push({ name: 'privacy-policy' })
    },
  }
}
</script>
