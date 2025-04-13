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
        <div class="tw-flex tw-flex-col md:tw-flex-row tw-justify-between tw-items-stretch tw-gap-8 tw-mt-4">
          
          <!-- Left panel: Create event card -->
          <div class="tw-w-full md:tw-w-3/5 tw-flex tw-items-center">
            <div class="tw-bg-white tw-rounded-xl tw-shadow-md tw-p-8 tw-h-auto tw-w-full tw-border tw-border-gray-100">
              <div class="tw-flex tw-flex-col tw-items-center tw-text-center">
                <div class="tw-mb-4 tw-w-16 tw-h-16 tw-rounded-full tw-bg-green/10 tw-flex tw-items-center tw-justify-center">
                  <v-icon color="green" size="32">mdi-calendar-plus</v-icon>
                </div>
                
                <h2 class="tw-text-2xl tw-font-medium tw-mb-3">Create an event</h2>
                
                <p class="tw-text-gray-600 tw-mb-6 tw-max-w-md">
                  Schedule a meeting by finding the best time for everyone to meet. Create polls, sync with your calendar, and invite participants easily.
                </p>
                
                <v-btn 
                  color="success"
                  class="tw-bg-green tw-text-white tw-w-full tw-py-6"
                  elevation="2"
                  x-large
                  @click="newDialog = true"
                >
                  <span class="tw-text-base">Create New Event</span>
                </v-btn>
              </div>
            </div>
          </div>

          <!-- Right panel: Join event card -->
          <div class="tw-w-full md:tw-w-2/5 tw-flex tw-items-center">
            <div class="tw-bg-white tw-rounded-xl tw-shadow-md tw-p-8 tw-h-auto tw-w-full tw-border tw-border-gray-100">
              <div class="tw-flex tw-flex-col tw-items-center tw-text-center">
                <div class="tw-mb-4 tw-w-16 tw-h-16 tw-rounded-full tw-bg-blue/10 tw-flex tw-items-center tw-justify-center">
                  <v-icon color="primary" size="32">mdi-login-variant</v-icon>
                </div>
                
                <h2 class="tw-text-2xl tw-font-medium tw-mb-3">Join an event</h2>
                
                <p class="tw-text-gray-600 tw-mb-6 tw-max-w-xs">
                  Enter the 4-letter code to join and add your availability to an existing event.
                </p>
                
                <div class="tw-flex tw-flex-col tw-w-full tw-space-y-4">
                  <v-text-field
                    v-model="eventCode"
                    label="Event Code"
                    placeholder="Enter 4-letter code"
                    outlined
                    hide-details
                    class="tw-mb-4"
                    :class="{ 'error--text': codeError }"
                    @keyup.enter="joinEvent"
                    :error-messages="codeError ? 'Please enter a valid event code' : ''"
                  ></v-text-field>
                  
                  <v-btn 
                    color="primary"
                    class="tw-bg-blue tw-text-white tw-w-full tw-py-6"
                    :loading="joining"
                    elevation="2"
                    x-large
                    @click="joinEvent"
                  >
                    <span class="tw-text-base">Join Event</span>
                  </v-btn>
                </div>
              </div>
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
    SignInGoogleBtn,
    NewEvent,
    NewDialog,
    Logo,
  },

  data: () => ({
    signInDialog: false,
    newDialog: false,
    eventCode: '',
    codeError: false,
    joining: false,
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
    async joinEvent() {
      // Reset error state
      this.codeError = false;
      
      // Validate code format (4 letters/numbers)
      if (!this.eventCode || this.eventCode.trim().length === 0) {
        this.codeError = true;
        return;
      }
      
      const code = this.eventCode.trim().toUpperCase();
      
      this.joining = true;
      
      try {
        // Navigate to the event page with the code
        this.$router.push({ path: `/e/${code}` });
      } catch (error) {
        console.error('Error joining event:', error);
        this.codeError = true;
      } finally {
        this.joining = false;
      }
    }
  }
}
</script>
