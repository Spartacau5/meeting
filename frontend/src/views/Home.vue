<template>
  <div>
    <!-- Modern header with subtle shadow - same as Landing page -->
    <header class="tw-bg-gradient-to-r tw-from-blue-50 tw-to-green-50 tw-py-5 tw-px-4 tw-border-b tw-border-gray-200 tw-shadow-md">
      <div class="tw-max-w-6xl tw-mx-auto tw-flex tw-items-center tw-justify-between">
        <router-link to="/">
          <Logo type="schej" />
        </router-link>
        <div class="tw-flex tw-items-center tw-gap-4">
          <v-btn text href="https://forms.gle/7iKpHRr1Adn7SWSS6" target="_blank" class="tw-text-gray-700 hover:tw-text-blue tw-font-medium">Give Feedback</v-btn>
          <v-btn 
            outlined 
            @click="signOut" 
            class="tw-border-blue tw-text-blue hover:tw-bg-blue hover:tw-text-white tw-transition-colors tw-shadow-sm"
          >
            Sign out
          </v-btn>
        </div>
      </div>
    </header>

    <!-- Main content with improved styling -->
    <div class="tw-bg-gradient-to-br tw-from-blue-50 tw-via-purple-50 tw-to-green-50 tw-min-h-screen tw-pt-8 tw-pb-12">
      <div class="tw-mx-auto tw-max-w-6xl tw-space-y-8 tw-px-4">
        <div
          v-if="loading && !eventsNotEmpty"
          class="tw-flex tw-h-[calc(100vh-10rem)] tw-w-full tw-items-center tw-justify-center"
        >
          <v-progress-circular
            indeterminate
            color="primary"
            :size="36"
            :width="3"
          ></v-progress-circular>
        </div>
        
        <template v-if="groupsEnabled">
          <v-fade-transition>
            <div
              class="tw-rounded-xl tw-bg-white tw-shadow-md tw-border tw-border-gray-100 tw-p-6"
              v-if="!loading || eventsNotEmpty"
            >
              <EventType
                :eventType="availabilityGroups"
                emptyText="You are not part of any availability groups!"
              />
            </div>
          </v-fade-transition>
        </template>
        
        <v-fade-transition>
          <div
            class="tw-rounded-xl tw-bg-white tw-shadow-md tw-border tw-border-gray-100 tw-p-6"
            v-if="!loading || eventsNotEmpty"
          >
            <div class="tw-grid tw-gap-4 sm:tw-gap-8">
              <EventType
                v-for="(eventType, t) in events"
                :key="t"
                :eventType="eventType"
              ></EventType>
            </div>
          </div>
        </v-fade-transition>

        <!-- Add Stats Section Here -->
        <div class="tw-mt-8 tw-mb-8 tw-text-center tw-text-gray-600">
          <div v-if="isLoadingStats" class="tw-text-sm tw-italic">
            Loading stats...
          </div>
          <div v-else-if="statsError" class="tw-text-sm tw-text-red-400">
            Could not load stats.
          </div>
          <div v-else class="tw-flex tw-justify-center tw-gap-x-8 tw-text-sm">
            <div class="tw-flex tw-items-center tw-gap-2">
              <v-icon color="blue" small>mdi-account-group</v-icon>
              <span>{{ formattedUserCount }} users</span>
            </div>
            <div class="tw-flex tw-items-center tw-gap-2">
              <v-icon color="green" small>mdi-calendar-multiple</v-icon>
              <span>{{ formattedEventCount }} events created</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- FAB -->
    <BottomFab v-if="isPhone" id="create-event-btn" @click="createNew" color="primary" class="tw-bg-blue">
      <v-icon>mdi-plus</v-icon>
    </BottomFab>
  </div>
</template>

<script>
import EventType from "@/components/EventType.vue"
import BottomFab from "@/components/BottomFab.vue"
import CreateSpeedDial from "@/components/CreateSpeedDial.vue"
import Logo from "@/components/Logo.vue"
import { mapState, mapActions } from "vuex"
import { eventTypes } from "@/constants"
import { isPhone } from "@/utils"
import { get } from "@/utils/fetch_utils" // Import the get helper

export default {
  name: "Dashboard",

  metaInfo: {
    title: "Dashboard - Schej",
  },

  components: {
    EventType,
    BottomFab,
    CreateSpeedDial,
    Logo,
  },

  props: {
    contactsPayload: {
      type: Object,
      default: () => ({}),
    },
    openNewGroup: { type: Boolean, default: false },
  },

  data: () => ({
    loading: true,
    userCount: 0,
    eventCount: 0,
    isLoadingStats: true,
    statsError: false,
  }),

  mounted() {
    this.fetchStats() // Fetch stats when component mounts
    
    // If coming from enabling contacts, show the dialog. Checks if contactsPayload is not an Observer.
    this.$emit("setNewDialogOptions", {
      show: Object.keys(this.contactsPayload).length > 0 || this.openNewGroup,
      contactsPayload: this.contactsPayload,
      openNewGroup: this.openNewGroup,
    })
  },

  computed: {
    ...mapState(["createdEvents", "joinedEvents", "authUser", "groupsEnabled"]),
    events() {
      return [
        {
          header: "Events I created",
          events: this.createdEventsNonGroup,
        },
        {
          header: "Events I joined",
          events: this.joinedEventsNonGroup,
        },
      ]
    },
    createdEventsNonGroup() {
      return this.createdEvents.filter((e) => e.type !== eventTypes.GROUP)
    },
    joinedEventsNonGroup() {
      return this.joinedEvents.filter((e) => e.type !== eventTypes.GROUP)
    },
    availabilityGroups() {
      return {
        header: "Availability groups",
        events: this.createdEvents
          .filter((e) => e.type === eventTypes.GROUP)
          .concat(this.joinedEvents.filter((e) => e.type === eventTypes.GROUP))
          .sort((e1, e2) => (this.userRespondedToEvent(e1) ? 1 : -1)),
      }
    },
    eventsNotEmpty() {
      return this.createdEvents.length > 0 || this.joinedEvents.length > 0
    },
    isPhone() {
      return isPhone(this.$vuetify)
    },
    formattedUserCount() {
      return this.userCount.toLocaleString()
    },
    formattedEventCount() {
      return this.eventCount.toLocaleString()
    },
  },

  methods: {
    ...mapActions(["getEvents", "signOut"]),
    userRespondedToEvent(event) {
      return this.authUser._id in event.responses
    },
    createNew() {
      this.$emit("setNewDialogOptions", {
        show: true,
        contactsPayload: {},
        openNewGroup: false,
      })
    },
    async fetchStats() {
      this.isLoadingStats = true
      this.statsError = false
      try {
        const stats = await get("/analytics/stats") // Use the correct endpoint
        this.userCount = stats.userCount
        this.eventCount = stats.eventCount
      } catch (error) {
        console.error("Error fetching stats:", error)
        this.statsError = true
      } finally {
        this.isLoadingStats = false
      }
    },
  },

  created() {
    this.getEvents().then(() => {
      this.loading = false
    })
  },
}
</script>
