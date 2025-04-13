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
    <div class="tw-bg-gradient-to-b tw-from-white tw-to-green/5 tw-py-12 tw-relative tw-overflow-hidden">
      <!-- Background wave illustration -->
      <div class="tw-absolute tw-bottom-0 tw-left-0 tw-w-full tw-pointer-events-none tw-opacity-40">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 320" preserveAspectRatio="none" class="tw-w-full">
          <path fill="#3B82F6" fill-opacity="0.15" d="M0,224L48,224C96,224,192,224,288,202.7C384,181,480,139,576,149.3C672,160,768,224,864,229.3C960,235,1056,181,1152,154.7C1248,128,1344,128,1392,128L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z" class="wave wave-1"></path>
          <path fill="#10B981" fill-opacity="0.1" d="M0,288L48,266.7C96,245,192,203,288,181.3C384,160,480,160,576,165.3C672,171,768,181,864,192C960,203,1056,213,1152,218.7C1248,224,1344,224,1392,224L1440,224L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z" class="wave wave-2"></path>
        </svg>
      </div>
      
      <div class="tw-max-w-6xl tw-mx-auto tw-px-4 tw-relative">
        <!-- Hero section tagline -->
        <div class="tw-text-center tw-mb-10">
          <h1 class="tw-text-3xl md:tw-text-4xl tw-font-bold tw-mb-3 tw-text-gray-800">Find the perfect meeting time, effortlessly</h1>
          <p class="tw-text-lg tw-text-gray-600 tw-max-w-2xl tw-mx-auto">Schedule meetings without the back-and-forth emails. Create an event, share the link, and see when everyone is available.</p>
        </div>
        
        <div class="tw-flex tw-flex-col md:tw-flex-row tw-justify-between tw-items-stretch tw-gap-4">
          
          <!-- Left panel: Create event card -->
          <div class="tw-w-full md:tw-w-1/2 tw-flex tw-items-center">
            <div class="tw-bg-white tw-rounded-xl tw-shadow-md tw-p-6 tw-h-full tw-w-full tw-border tw-border-gray-100 tw-flex tw-flex-col tw-justify-between">
              <div class="tw-flex tw-flex-col tw-items-center tw-text-center">
                <div class="tw-mb-3 tw-w-12 tw-h-12 tw-rounded-full tw-bg-green/10 tw-flex tw-items-center tw-justify-center">
                  <v-icon color="green" size="24">mdi-calendar-plus</v-icon>
                </div>
                
                <h2 class="tw-text-xl tw-font-medium tw-mb-2">Create an event</h2>
                
                <p class="tw-text-gray-600 tw-mb-4 tw-max-w-md tw-text-sm">
                  Schedule a meeting by finding the best time for everyone to meet. Create polls, sync with your calendar, and invite participants easily.
                </p>
              </div>
              
              <v-btn 
                color="success"
                class="tw-bg-green tw-text-white tw-w-full"
                elevation="2"
                @click="newDialog = true"
              >
                <span class="tw-text-base">Create New Event</span>
              </v-btn>
            </div>
          </div>

          <!-- Right panel: Join event card -->
          <div class="tw-w-full md:tw-w-1/2 tw-flex tw-items-center">
            <div class="tw-bg-white tw-rounded-xl tw-shadow-md tw-p-6 tw-h-full tw-w-full tw-border tw-border-gray-100 tw-flex tw-flex-col tw-justify-between">
              <div class="tw-flex tw-flex-col tw-items-center tw-text-center">
                <div class="tw-mb-3 tw-w-12 tw-h-12 tw-rounded-full tw-bg-blue/10 tw-flex tw-items-center tw-justify-center">
                  <v-icon color="primary" size="24">mdi-login-variant</v-icon>
                </div>
                
                <h2 class="tw-text-xl tw-font-medium tw-mb-2">Join an event</h2>
                
                <p class="tw-text-gray-600 tw-mb-4 tw-max-w-md tw-text-sm">
                  Enter the 4-letter code to join and add your availability to an existing event.
                </p>
              </div>
              
              <div class="tw-flex tw-flex-col tw-w-full tw-space-y-2">
                <v-text-field
                  v-model="eventCode"
                  label="Event Code"
                  placeholder="Enter 4-letter code"
                  outlined
                  dense
                  hide-details
                  class="tw-mb-2"
                  :class="{ 'error--text': codeError }"
                  @keyup.enter="joinEvent"
                  :error-messages="codeError ? 'Please enter a valid event code' : ''"
                ></v-text-field>
                
                <v-btn 
                  color="primary"
                  class="tw-bg-blue tw-text-white tw-w-full"
                  :loading="joining"
                  elevation="2"
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

    <!-- Modern footer with improved layout -->
    <footer class="tw-bg-white tw-py-4 tw-border-t tw-border-gray-200">
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

.wave {
  transform-origin: bottom;
  animation-timing-function: ease-in-out;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}

.wave-1 {
  animation-name: wave-animation-1;
  animation-duration: 8s;
}

.wave-2 {
  animation-name: wave-animation-2;
  animation-duration: 12s;
}

@keyframes wave-animation-1 {
  0% {
    transform: translateX(-5px) scale(1.01);
  }
  100% {
    transform: translateX(5px) scale(1);
  }
}

@keyframes wave-animation-2 {
  0% {
    transform: translateX(5px) scale(1.02);
  }
  100% {
    transform: translateX(-5px) scale(1);
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
