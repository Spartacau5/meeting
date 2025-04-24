<template>
  <v-card
    :flat="dialog"
    :class="{ 'tw-py-4': !dialog, 'tw-flex-1': dialog }"
    class="tw-relative tw-flex tw-flex-col tw-overflow-visible tw-rounded-lg tw-transition-all tw-w-full tw-mx-auto"
    style="max-width: 100%;"
  >
    <v-card-title class="tw-mb-2 tw-flex tw-gap-2 tw-px-4 sm:tw-px-8" v-if="dialog">
      <div>
        <div class="tw-mb-1">
          {{ edit ? "Edit event" : "New event" }}
        </div>
        <div
          v-if="dialog && showHelp"
          class="tw-text-xs tw-font-normal tw-italic tw-text-dark-gray"
        >
          Ideal for one-time / recurring meetings
        </div>
      </div>
      <v-spacer />
      <template v-if="dialog">
        <v-btn v-if="showHelp" icon @click="helpDialog = true">
          <v-icon>mdi-information-outline</v-icon>
        </v-btn>
        <v-btn v-else @click="$emit('input', false)" icon>
          <v-icon>mdi-close</v-icon>
        </v-btn>
        <HelpDialog v-model="helpDialog">
          <template v-slot:header>Events</template>
          <div class="tw-mb-4">
            Use events to collect people's availabilities and compare them
            across certain days.
          </div>
        </HelpDialog>
      </template>
    </v-card-title>
    <v-card-text
      ref="cardText"
      class="tw-relative tw-flex-1 tw-overflow-visible tw-px-4 tw-py-1 sm:tw-px-8"
    >
      <AlertText v-if="edit && event?.ownerId == 0" class="tw-mb-4">
        Anybody can edit this event because it was created while not signed in
      </AlertText>
      <v-form
        ref="form"
        v-model="formValid"
        lazy-validation
        class="tw-flex tw-flex-col tw-gap-y-6"
        :disabled="loading"
      >
        <v-text-field
          ref="name-field"
          v-model="name"
          placeholder="Name your event..."
          hide-details="auto"
          solo
          @keyup.enter="blurNameField"
          :rules="nameRules"
          required
        />

        <SlideToggle
          v-if="daysOnlyEnabled && !edit"
          class="tw-w-full"
          v-model="daysOnly"
          :options="daysOnlyOptions"
        />

        <div>
          <v-expand-transition>
            <div v-if="!daysOnly">
              <div class="tw-mb-2 tw-text-lg tw-text-black">
                What times might work?
              </div>
              <div
                class="tw-mb-6 tw-flex tw-items-baseline tw-justify-center tw-space-x-2"
              >
                <v-select
                  :value="startTime"
                  @input="(t) => (startTime = t.time)"
                  menu-props="auto"
                  :items="times"
                  return-object
                  hide-details
                  solo
                  item-text="text"
                >
                  <template v-slot:selection="{ item }">
                    {{ item.text }}
                  </template>
                </v-select>
                <div>to</div>
                <v-select
                  :value="endTime"
                  @input="(t) => (endTime = t.time)"
                  menu-props="auto"
                  :items="times"
                  return-object
                  hide-details
                  solo
                  item-text="text"
                >
                  <template v-slot:selection="{ item }">
                    {{ item.text }}
                  </template>
                </v-select>
              </div>
            </div>
          </v-expand-transition>

          <div class="tw-mb-2 tw-text-lg tw-text-black">
            What
            {{ selectedDateOption === dateOptions.SPECIFIC ? "dates" : "days" }}
            might work?
          </div>
          <v-select
            v-if="!edit && !daysOnly"
            v-model="selectedDateOption"
            :items="Object.values(dateOptions)"
            solo
            hide-details
            class="tw-mb-4"
          />

          <v-expand-transition>
            <div v-if="selectedDateOption === dateOptions.SPECIFIC || daysOnly">
              <div class="tw-mb-2 tw-text-xs tw-text-dark-gray">
                {{ isMobile ? 'Tap to select dates' : 'Drag to select multiple dates' }}
              </div>
              <v-input
                v-model="selectedDays"
                hide-details="auto"
                :rules="selectedDaysRules"
                key="date-picker"
              >
                <DatePicker
                  v-model="selectedDays"
                  :minCalendarDate="minCalendarDate"
                  @update:pickerDate="updatePickerDate"
                />
              </v-input>
            </div>
            <div v-else-if="selectedDateOption === dateOptions.DOW">
              <v-input
                v-model="selectedDaysOfWeek"
                hide-details="auto"
                :rules="selectedDaysRules"
                key="days-of-week"
                class="tw-w-full tw-overflow-x-auto"
              >
                <v-btn-toggle
                  v-model="selectedDaysOfWeek"
                  multiple
                  solo
                  color="primary"
                  class="tw-flex tw-flex-wrap tw-justify-center"
                >
                  <v-btn depressed> Mon </v-btn>
                  <v-btn depressed> Tue </v-btn>
                  <v-btn depressed> Wed </v-btn>
                  <v-btn depressed> Thu </v-btn>
                  <v-btn depressed> Fri </v-btn>
                  <v-btn depressed> Sat </v-btn>
                  <v-btn depressed> Sun </v-btn>
                </v-btn-toggle>
              </v-input>
            </div>
          </v-expand-transition>
        </div>

        <v-checkbox
          v-if="allowNotifications && !guestEvent"
          v-model="notificationsEnabled"
          hide-details
          class="tw-mt-2"
        >
          <template v-slot:label>
            <span class="tw-text-sm tw-text-very-dark-gray"
              >Email me each time someone joins my event</span
            >
          </template>
        </v-checkbox>

        <div class="tw-flex tw-flex-col tw-gap-2">
          <ExpandableSection
            v-if="authUser && !guestEvent"
            label="Email reminders"
            v-model="showEmailReminders"
            :auto-scroll="dialog"
          >
            <div class="tw-flex tw-flex-col tw-gap-5 tw-pt-2">
              <EmailInput
                v-show="authUser"
                ref="emailInput"
                @requestContactsAccess="requestContactsAccess"
                labelColor="tw-text-very-dark-gray"
                :addedEmails="addedEmails"
                @update:emails="(newEmails) => (emails = newEmails)"
              >
                <template v-slot:header>
                  <div class="tw-flex tw-gap-1">
                    <div class="tw-text-very-dark-gray">
                      Remind people to fill out the event
                    </div>

                    <v-tooltip
                      top
                      content-class="tw-bg-very-dark-gray tw-shadow-lg tw-opacity-100 tw-py-4"
                    >
                      <template v-slot:activator="{ on, attrs }">
                        <v-icon small v-bind="attrs" v-on="on"
                          >mdi-information-outline
                        </v-icon>
                      </template>
                      <div>
                        Reminder emails will be sent the day of event
                        creation,<br />one day after, and three days after. You
                        will also receive <br />an email when everybody has
                        filled out the event.
                      </div>
                    </v-tooltip>
                  </div>
                </template>
              </EmailInput>
            </div>
          </ExpandableSection>

          <ExpandableSection
            v-model="showAdvancedOptions"
            label="Advanced options"
            :auto-scroll="dialog"
          >
            <div class="tw-flex tw-flex-col tw-gap-5 tw-pt-2">
              <v-checkbox
                v-model="collectEmails"
                messages="Adds emails to Google Calendar invite"
              >
                <template v-slot:label>
                  <span class="tw-text-sm tw-text-black">
                    Require respondents' email addresses
                  </span>
                </template>
                <template v-slot:message="{ key, message }">
                  <div
                    class="-tw-mt-1 tw-ml-[32px] tw-text-xs tw-text-dark-gray"
                  >
                    {{ message }}
                  </div>
                </template>
              </v-checkbox>
              <v-checkbox
                v-if="authUser && !guestEvent"
                v-model="blindAvailabilityEnabled"
                messages="Only show responses to event creator"
              >
                <template v-slot:label>
                  <span class="tw-text-sm tw-text-black">
                    Hide responses from respondents
                  </span>
                </template>
                <template v-slot:message="{ key, message }">
                  <div
                    class="-tw-mt-1 tw-ml-[32px] tw-text-xs tw-text-dark-gray"
                  >
                    {{ message }}
                  </div>
                </template>
              </v-checkbox>
              <v-checkbox
                v-else-if="!guestEvent"
                disabled
                messages="Only show responses to event creator. "
                off-icon="mdi-checkbox-blank-off-outline"
              >
                <template v-slot:label>
                  <span class="tw-text-sm"
                    >Hide responses from respondents</span
                  >
                </template>
                <template v-slot:message="{ key, message }">
                  <div
                    class="tw-pointer-events-auto -tw-mt-1 tw-ml-[32px] tw-text-xs tw-text-dark-gray"
                  >
                    {{ message }}
                    <span class="tw-font-medium tw-text-very-dark-gray"
                      ><a @click="$emit('signIn')">Sign in</a>
                      to use this feature
                    </span>
                  </div>
                </template>
              </v-checkbox>
              <v-checkbox
                v-if="authUser && !guestEvent"
                v-model="sendEmailAfterXResponsesEnabled"
                hide-details
              >
                <template v-slot:label>
                  <div
                    :class="!sendEmailAfterXResponsesEnabled && 'tw-opacity-50'"
                    class="tw-flex tw-items-center tw-gap-x-2 tw-text-sm tw-text-very-dark-gray"
                  >
                    <div>Email me after</div>
                    <v-text-field
                      v-model="sendEmailAfterXResponses"
                      @click="
                        (e) => {
                          e.preventDefault()
                          e.stopPropagation()
                        }
                      "
                      :disabled="!sendEmailAfterXResponsesEnabled"
                      dense
                      class="email-me-after-text-field -tw-mt-[2px] tw-w-10"
                      menu-props="auto"
                      hide-details
                      type="number"
                      min="1"
                    ></v-text-field>
                    <div>responses</div>
                  </div>
                </template>
              </v-checkbox>
              <TimezoneSelector v-model="timezone" label="Timezone" />
            </div>
          </ExpandableSection>
        </div>
      </v-form>
    </v-card-text>
    <v-card-actions class="tw-relative tw-px-4 sm:tw-px-8">
      <div class="tw-relative tw-w-full">
        <v-btn
          :disabled="!formValid"
          block
          :loading="loading"
          color="primary"
          class="tw-mt-4 tw-bg-blue"
          @click="submit"
        >
          {{ edit ? "Save edits" : "Create event" }}
        </v-btn>
        <div
          :class="formValid ? 'tw-invisible' : 'tw-visible'"
          class="tw-mt-1 tw-text-xs tw-text-red"
        >
          Please fix form errors before continuing
        </div>
      </div>
    </v-card-actions>

    <OverflowGradient
      v-if="hasMounted"
      :scrollContainer="$refs.cardText"
      class="tw-bottom-[90px]"
    />
  </v-card>
</template>

<style>
.email-me-after-text-field input {
  padding: 0px !important;
}
</style>

<script>
import { eventTypes, dayIndexToDayString, authTypes } from "@/constants"
import {
  post,
  put,
  timeNumToTimeString,
  dateToTimeNum,
  getISODateString,
  isPhone,
  signInGoogle,
  getDateWithTimezone,
  getTimeOptions,
} from "@/utils"
import { mapActions, mapState } from "vuex"
import TimezoneSelector from "./schedule_overlap/TimezoneSelector.vue"
import HelpDialog from "./HelpDialog.vue"
import EmailInput from "./event/EmailInput.vue"
import DatePicker from "@/components/DatePicker.vue"
import SlideToggle from "./SlideToggle.vue"
import AlertText from "@/components/AlertText.vue"
import OverflowGradient from "@/components/OverflowGradient.vue"
import { guestUserId } from "@/constants"
import moment from "moment"

import dayjs from "dayjs"
import utcPlugin from "dayjs/plugin/utc"
import timezonePlugin from "dayjs/plugin/timezone"
import ExpandableSection from "./ExpandableSection.vue"
dayjs.extend(utcPlugin)
dayjs.extend(timezonePlugin)

export default {
  name: "NewEvent",

  emits: ["input"],

  props: {
    event: { type: Object },
    edit: { type: Boolean, default: false },
    dialog: { type: Boolean, default: true },
    allowNotifications: { type: Boolean, default: true },
    contactsPayload: { type: Object, default: () => ({}) },
    showHelp: { type: Boolean, default: false },
  },

  components: {
    TimezoneSelector,
    HelpDialog,
    EmailInput,
    DatePicker,
    SlideToggle,
    ExpandableSection,
    AlertText,
    OverflowGradient,
  },

  data: () => ({
    formValid: true,
    name: "",
    startTime: 9,
    endTime: 17,
    loading: false,
    selectedDays: [],
    selectedDaysOfWeek: [],
    startOnMonday: true,
    notificationsEnabled: false,
    pickerDate: "",

    daysOnly: false,
    daysOnlyOptions: Object.freeze([
      { text: "Dates and times", value: false },
      { text: "Dates only", value: true },
    ]),

    // Date options
    dateOptions: Object.freeze({
      SPECIFIC: "Specific dates",
      DOW: "Days of the week",
    }),
    selectedDateOption: "Specific dates",

    // Email reminders
    showEmailReminders: false,
    emails: [], // For email reminders

    // Advanced options
    showAdvancedOptions: false,
    collectEmails: false,
    blindAvailabilityEnabled: false,
    timezone: {},
    sendEmailAfterXResponsesEnabled: false,
    sendEmailAfterXResponses: 3,

    helpDialog: false,

    // Unsaved changes
    initialEventData: {},

    hasMounted: false,

    dayIndexToDayString: [
      "2018-06-17", // Sunday
      "2018-06-18", // Monday
      "2018-06-19", // Tuesday
      "2018-06-20", // Wednesday
      "2018-06-21", // Thursday
      "2018-06-22", // Friday
      "2018-06-23", // Saturday
      "2018-06-24", // Sunday (for Monday-based week)
    ],
  }),

  mounted() {
    if (Object.keys(this.contactsPayload).length > 0) {
      this.toggleEmailReminders(true)

      /** Get previously filled out data after enabling contacts  */
      this.name = this.contactsPayload.name
      this.startTime = this.contactsPayload.startTime
      this.endTime = this.contactsPayload.endTime
      this.daysOnly = this.contactsPayload.daysOnly
      this.selectedDateOption = this.contactsPayload.selectedDateOption
      this.selectedDaysOfWeek = this.contactsPayload.selectedDaysOfWeek
      this.selectedDays = this.contactsPayload.selectedDays
      this.notificationsEnabled = this.contactsPayload.notificationsEnabled
      this.timezone = this.contactsPayload.timezone

      this.$refs.form.resetValidation()
    }

    this.$nextTick(() => {
      this.hasMounted = true
    })
  },

  computed: {
    ...mapState(["authUser", "daysOnlyEnabled"]),
    nameRules() {
      return [(v) => !!v || "Event name is required"]
    },
    selectedDaysRules() {
      return [
        (selectedDays) =>
          selectedDays.length > 0 || "Please select at least one day",
      ]
    },
    addedEmails() {
      if (Object.keys(this.contactsPayload).length > 0)
        return this.contactsPayload.emails
      return this.event && this.event.remindees
        ? this.event.remindees.map((r) => r.email)
        : []
    },
    times() {
      return getTimeOptions()
    },
    minCalendarDate() {
      if (this.edit) {
        return ""
      }

      let today = new Date()
      let dd = String(today.getDate()).padStart(2, "0")
      let mm = String(today.getMonth() + 1).padStart(2, "0")
      let yyyy = today.getFullYear()

      return yyyy + "-" + mm + "-" + dd
    },
    isPhone() {
      return isPhone(this.$vuetify)
    },
    isMobile() {
      return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    },
    guestEvent() {
      return this.event && this.event.ownerId == guestUserId
    },
  },

  methods: {
    ...mapActions(["showError"]),
    blurNameField() {
      this.$refs["name-field"].blur()
    },
    reset() {
      this.name = ""
      this.startTime = 9
      this.endTime = 17
      this.selectedDays = []
      this.selectedDaysOfWeek = []
      this.notificationsEnabled = false
      this.daysOnly = false
      this.selectedDateOption = "Specific dates"
      this.emails = []
      this.showAdvancedOptions = false
      this.blindAvailabilityEnabled = false
      this.sendEmailAfterXResponsesEnabled = false
      this.sendEmailAfterXResponses = 3
      this.collectEmails = false

      this.$refs.form.resetValidation()
    },
    submit() {
      if (!this.$refs.form.validate()) return
      
      // Detect if this is a mobile device
      const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
      
      // Set loading state
      this.loading = true
      let duration = this.endTime - this.startTime
      // Fix duration calculation if it wraps around midnight
      if (duration <= 0) duration += 24
      
      console.log("Start time:", this.startTime, "End time:", this.endTime, "Duration:", duration)
      console.log("Device type:", isMobile ? "Mobile" : "Desktop");
      
      let type
      let dates = []
      let formattedDates = []

      try {
        if (this.selectedDateOption === this.dateOptions.SPECIFIC) {
          type = this.daysOnly ? eventTypes.SPECIFIC_DATES : eventTypes.SPECIFIC_DATES
          // Deep copy selectedDays and ensure it's not empty
          const dateStrings = [...this.selectedDays]
          console.log("Selected date strings:", dateStrings);
          
          if (dateStrings.length === 0) {
            throw new Error("No dates selected. Please select at least one date.");
          }

          // More robust date processing for all devices
          for (let dateString of dateStrings) {
            try {
              console.log("Processing date string:", dateString);
              
              // Make sure we have a valid string
              if (!dateString || typeof dateString !== 'string') {
                console.error("Invalid date string:", dateString);
                continue;
              }
              
              // Normalize the dateString format if needed
              let normalizedDateString = dateString.trim();
              
              // Method 1: Parse ISO formatted date (YYYY-MM-DD)
              try {
                // Ensure format is YYYY-MM-DD
                if (/^\d{4}-\d{2}-\d{2}$/.test(normalizedDateString)) {
                  const [year, month, day] = normalizedDateString.split('-').map(Number);
                  
                  // Validate the components
                  if (!year || !month || !day || isNaN(year) || isNaN(month) || isNaN(day)) {
                    console.log("Invalid date components, trying alternative approach");
                    throw new Error("Invalid date components");
                  }
                  
                  // Create a date object (month is 0-indexed in JS)
                  const date = new Date(year, month - 1, day);
                  
                  // Set the time component
                  date.setHours(Math.floor(this.startTime), 0, 0, 0);
                  
                  // Validate the date
                  if (isNaN(date.getTime())) {
                    console.log("Invalid date created, trying alternative approach");
                    throw new Error("Invalid date object");
                  }
                  
                  // Success - add to dates array
                  const isoDate = date.toISOString();
                  dates.push(isoDate);
                  formattedDates.push(normalizedDateString);
                  console.log("Successfully processed date:", normalizedDateString, "→", isoDate);
                  continue; // Skip to next date
                } else {
                  throw new Error("Date string not in YYYY-MM-DD format");
                }
              } catch (parseErr) {
                console.log("Error with method 1:", parseErr);
                // Continue to next method
              }
              
              // Method 2: Handle potential shortened format with current month/year
              try {
                // If it's just a day number, add current month and year
                if (/^\d{1,2}$/.test(normalizedDateString)) {
                  const currentDate = new Date();
                  const year = currentDate.getFullYear();
                  const month = currentDate.getMonth() + 1; // JS months are 0-indexed
                  const day = parseInt(normalizedDateString);
                  
                  normalizedDateString = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
                  
                  const date = new Date(year, month - 1, day);
                  date.setHours(Math.floor(this.startTime), 0, 0, 0);
                  
                  if (isNaN(date.getTime())) {
                    throw new Error("Invalid date from short format");
                  }
                  
                  const isoDate = date.toISOString();
                  dates.push(isoDate);
                  formattedDates.push(normalizedDateString);
                  console.log("Method 2 success with short format:", normalizedDateString, "→", isoDate);
                  continue;
                } else {
                  throw new Error("Not a short day format");
                }
              } catch (shortFormatErr) {
                console.log("Error with method 2:", shortFormatErr);
              }
              
              // Method 3: Try with pickerDate prefix
              try {
                // If previous methods failed, try with pickerDate prefix
                if (this.pickerDate && typeof this.pickerDate === 'string') {
                  // pickerDate should be in format YYYY-MM
                  const prefix = this.pickerDate;
                  
                  // If dateString is just a day number
                  if (/^\d{1,2}$/.test(normalizedDateString)) {
                    const day = parseInt(normalizedDateString).toString().padStart(2, '0');
                    const fullDateString = `${prefix}-${day}`;
                    
                    const date = new Date(fullDateString);
                    date.setHours(Math.floor(this.startTime), 0, 0, 0);
                    
                    if (isNaN(date.getTime())) {
                      throw new Error("Invalid date from pickerDate format");
                    }
                    
                    const isoDate = date.toISOString();
                    dates.push(isoDate);
                    formattedDates.push(fullDateString);
                    console.log("Method 3 success with pickerDate:", fullDateString, "→", isoDate);
                    continue;
                  }
                }
                throw new Error("No valid pickerDate available");
              } catch (pickerDateErr) {
                console.log("Error with method 3:", pickerDateErr);
              }
              
              // Method 4: Last resort, direct Date object creation
              try {
                // Try to create date directly 
                const date = new Date(normalizedDateString);
                
                // Set hours explicitly
                date.setHours(Math.floor(this.startTime), 0, 0, 0);
                
                // Validate the date
                if (isNaN(date.getTime())) {
                  console.log("Method 4 failed, invalid date");
                  throw new Error("Invalid date from direct creation");
                }
                
                // Success - add to dates array
                const isoDate = date.toISOString();
                dates.push(isoDate);
                formattedDates.push(normalizedDateString);
                console.log("Method 4 success, processed date:", normalizedDateString, "→", isoDate);
                continue; // Skip to next date
              } catch (directErr) {
                console.log("Error with method 4:", directErr);
              }
              
              // If we get here, all methods failed
              console.error("All date parsing methods failed for:", normalizedDateString);
            } catch (dateErr) {
              console.error("Error processing date:", dateString, dateErr);
            }
          }
        } else {
          type = eventTypes.DOW
          
          // More robust day of week processing
          for (let dayIndex of this.selectedDaysOfWeek) {
            try {
              // Use day of week to get a reference date string
              const dayRefDate = this.dayIndexToDayString[dayIndex];
              
              // If no reference date is available, create one
              if (!dayRefDate) {
                console.log("No reference date for day index:", dayIndex);
                // Create a date for next occurrence of this day of week
                const today = new Date();
                const dayDiff = (dayIndex - today.getDay() + 7) % 7;
                const targetDate = new Date(today);
                targetDate.setDate(today.getDate() + dayDiff);
                targetDate.setHours(Math.floor(this.startTime), 0, 0, 0);
                
                const isoDate = targetDate.toISOString();
                dates.push(isoDate);
                console.log("Created dynamic reference for day of week:", dayIndex, "→", isoDate);
                continue;
              }
              
              // Parse the date components
              const [year, month, day] = dayRefDate.split('-').map(Number);
              
              // Create date object and set time
              const date = new Date(year, month - 1, day);
              date.setHours(Math.floor(this.startTime), 0, 0, 0);
              
              // Validate the date
              if (isNaN(date.getTime())) {
                console.error("Invalid day of week date:", date);
                continue;
              }
              
              // Success - add to dates array
              const isoDate = date.toISOString();
              dates.push(isoDate);
              formattedDates.push(dayRefDate);
              console.log("Successfully processed day of week:", dayIndex, "→", isoDate);
            } catch (dateErr) {
              console.error("Error processing day of week:", dayIndex, dateErr);
            }
          }
        }

        // Make sure we have at least one valid date
        if (dates.length === 0) {
          console.error("No valid dates could be processed. Original selections:", 
            this.selectedDateOption === this.dateOptions.SPECIFIC ? this.selectedDays : this.selectedDaysOfWeek);
          
          // Log more details for debugging
          if (this.selectedDateOption === this.dateOptions.SPECIFIC) {
            console.log("Date format issue: Selected days were:", this.selectedDays);
          } else {
            console.log("Day of week issue: Selected days of week were:", this.selectedDaysOfWeek);
          }
          
          throw new Error("No valid dates could be processed");
        }

        console.log("Dates being sent:", dates)
        console.log("Event type:", type)
      } catch (err) {
        console.error("Error in date processing:", err);
        this.showError("There was a problem with the date selection. Please try again.");
        this.loading = false;
        return;
      }

      const payload = {
        name: this.name,
        duration,
        dates,
        type,
        daysOnly: this.daysOnly,
        notificationsEnabled: this.notificationsEnabled,
        blindAvailabilityEnabled: this.blindAvailabilityEnabled,
        remindees: this.emails,
        sendEmailAfterXResponses: this.sendEmailAfterXResponsesEnabled
          ? parseInt(this.sendEmailAfterXResponses)
          : null,
        startOnMonday: this.startOnMonday,
        collectEmails: this.collectEmails,
      }
      
      console.log("Payload being sent:", JSON.stringify(payload))
      
      const posthogPayload = {
        eventName: this.name,
        eventDuration: duration,
        eventDates: JSON.stringify(formattedDates),
        eventNotificationsEnabled: this.notificationsEnabled,
        eventBlindAvailabilityEnabled: this.blindAvailabilityEnabled,
        eventDaysOnly: this.daysOnly,
        eventRemindees: this.emails,
        eventType: type,
        eventSendEmailAfterXResponses: this.sendEmailAfterXResponsesEnabled
          ? parseInt(this.sendEmailAfterXResponses)
          : -1,
        eventCollectEmails: this.collectEmails,
        eventStartOnMonday: this.startOnMonday,
      }

      if (!this.edit) {
        // Prepare a failsafe URL in case both router and direct navigation fail
        const failsafeUrl = `${window.location.origin}/e/`;
        let navigationComplete = false;
        
        // Set a safety timeout to ensure loading state clears even if navigation fails
        const safetyTimeout = setTimeout(() => {
          if (!navigationComplete) {
            console.warn('Safety timeout triggered - navigation did not complete');
            this.loading = false;
            this.$emit("input", false);
            // Show a message to the user with a clickable link as backup
            const eventIdToUse = window.sessionStorage.getItem('lastCreatedEventId');
            const dashboardMessage = this.authUser ? " or check your dashboard." : ".";
            if (eventIdToUse) {
              const failsafeBaseUrl = `${window.location.origin}/e/`;
              const message = `<div>Your event was created, but there was a problem navigating to it. 
                <a href="${failsafeBaseUrl}${eventIdToUse}" style="text-decoration: underline; color: white; font-weight: bold;">
                  Click here to open your event
                </a>${dashboardMessage}</div>`;
              this.$store.dispatch('showInfo', { message, html: true, timeout: 10000 });
            } else {
              const fallbackMessage = `Your event was created, but there was a problem navigating to it.${dashboardMessage} Please try refreshing.`;
              this.showError(fallbackMessage);
            }
          }
        }, 15000); // 15 second safety timeout for mobile
        
        // Create new event on backend
        post("/events", payload)
          .then(({ eventId, shortId }) => {
            const eventIdToUse = shortId ?? eventId;
            
            // Store in session storage for recovery if navigation fails
            try {
              window.sessionStorage.setItem('lastCreatedEventId', eventIdToUse);
              console.log("Stored event ID in session storage:", eventIdToUse);
            } catch (storageErr) {
              console.error("Failed to store event ID in session storage:", storageErr);
            }
            
            // Log success for debugging
            console.log(`Event created successfully with ID: ${eventIdToUse}`);
            
            // Capture analytics before navigation
            posthogPayload.eventId = eventId;
            this.$posthog?.capture("Event created", posthogPayload);

            // Reset the form *before* navigation starts to avoid race conditions
            this.$emit("input", false);
            this.reset();
            
            // Set a flag to prevent double-navigation attempts
            if (navigationComplete) return;
            navigationComplete = true;
            
            // Clear the safety timeout since navigation succeeded (theoretically)
            clearTimeout(safetyTimeout);
            
            // IMPORTANT: Only reset loading state AFTER navigation attempt
            const completeNavigation = () => {
              // Ensure loading is always turned off eventually, even if nav hangs
              setTimeout(() => {
                if (this.loading) {
                  console.log("Resetting loading state after navigation attempt.");
                  this.loading = false;
                }
              }, 500); // Reset loading after 500ms
            };

            // Unified navigation logic using Vue Router for all devices
            console.log("Using router navigation for all devices");
            this.$router.push({
              name: "event",
              params: {
                eventId: eventIdToUse,
                initialTimezone: this.timezone,
              },
            }).then(() => {
              console.log("Router push successful");
              completeNavigation();
            }).catch(err => {
              console.error("Router navigation failed:", err);
              // Fallback to direct URL change if router fails (might still hit server issue)
              try {
                const eventIdToUse = window.sessionStorage.getItem('lastCreatedEventId');
                if (eventIdToUse) {
                  const failsafeUrl = `${window.location.origin}/e/${eventIdToUse}`;
                  console.warn("Router failed, attempting direct navigation:", failsafeUrl);
                  window.location.href = `/e/${eventIdToUse}`; 
                } else {
                  throw new Error("No event ID found in session storage for fallback navigation");
                }
              } catch (directNavErr) {
                console.error("Direct navigation fallback also failed:", directNavErr);
                // Show error if everything fails
                const dashboardMessage = this.authUser ? " Please check your dashboard or refresh." : " Please try refreshing.";
                this.showError(`Event created, but failed to navigate automatically.${dashboardMessage}`);
              }
              completeNavigation();
            });
          })
          .catch((err) => {
            console.error("Error creating event:", err);
            if (err.message && err.message.includes("NetworkError")) {
              this.showError("Network error. Please check your connection and try again.");
            } else {
              this.showError(
                "There was a problem creating that event! Please try again later."
              );
            }
            this.loading = false;
          });
      } else {
        // Edit event on backend
        if (this.event) {
          put(`/events/${this.event._id}`, payload)
            .then(() => {
              posthogPayload.eventId = this.event._id
              this.$posthog?.capture("Event edited", posthogPayload)

              // this.$emit("input", false)
              // this.reset()
              window.location.reload()
            })
            .catch((err) => {
              this.showError(
                "There was a problem editing this event! Please try again later."
              )
            })
            .finally(() => {
              this.loading = false
            })
        }
      }
    },

    toggleEmailReminders(delayed = false) {
      if (delayed) {
        setTimeout(
          () => (this.showEmailReminders = !this.showEmailReminders),
          300
        )
      } else {
        this.showEmailReminders = !this.showEmailReminders
      }
    },

    /** Redirects user to oauth page requesting access to the user's contacts */
    requestContactsAccess({ emails }) {
      const payload = {
        emails,
        name: this.name,
        startTime: this.startTime,
        endTime: this.endTime,
        daysOnly: this.daysOnly,
        selectedDays: this.selectedDays,
        selectedDaysOfWeek: this.selectedDaysOfWeek,
        selectedDateOption: this.selectedDateOption,
        notificationsEnabled: this.notificationsEnabled,
        timezone: this.timezone,
      }
      signInGoogle({
        state: {
          type: authTypes.EVENT_CONTACTS,
          eventId: this.event ? this.event.shortId ?? this.event._id : "",
          openNewGroup: false,
          payload,
        },
        requestContactsPermission: true,
      })
    },
    /** Update state based on the contactsPayload after granting contacts access */
    contactsAccessGranted({ curScheduledEvent, ...data }) {
      this.curScheduledEvent = curScheduledEvent
      this.$refs.confirmDetailsDialog?.setData(data)
      this.confirmDetailsDialog = true
    },

    /** Populates the form fields based on this.event */
    updateFieldsFromEvent() {
      if (this.event) {
        this.name = this.event.name

        // Set start time, accounting for the timezone
        this.startTime = Math.floor(
          dateToTimeNum(getDateWithTimezone(this.event.dates[0]), true)
        )
        this.startTime %= 24

        this.endTime = (this.startTime + this.event.duration) % 24
        this.notificationsEnabled = this.event.notificationsEnabled
        this.blindAvailabilityEnabled = this.event.blindAvailabilityEnabled
        this.daysOnly = this.event.daysOnly

        if (
          this.event.sendEmailAfterXResponses !== null &&
          this.event.sendEmailAfterXResponses > 0
        ) {
          this.sendEmailAfterXResponsesEnabled = true
          this.sendEmailAfterXResponses = this.event.sendEmailAfterXResponses
        }

        if (this.event.daysOnly) {
          this.selectedDateOption = this.dateOptions.SPECIFIC
          const selectedDays = []
          for (let date of this.event.dates) {
            selectedDays.push(getISODateString(date, true))
          }
          this.selectedDays = selectedDays
        } else {
          if (this.event.type === eventTypes.SPECIFIC_DATES) {
            this.selectedDateOption = this.dateOptions.SPECIFIC
            const selectedDays = []
            for (let date of this.event.dates) {
              date = getDateWithTimezone(date)

              selectedDays.push(getISODateString(date, true))
            }
            this.selectedDays = selectedDays
          } else if (this.event.type === eventTypes.DOW) {
            this.selectedDateOption = this.dateOptions.DOW
            const selectedDaysOfWeek = []
            for (let date of this.event.dates) {
              date = getDateWithTimezone(date)

              if (this.event.startOnMonday && date.getUTCDay() === 0) {
                selectedDaysOfWeek.push(7)
              } else {
                selectedDaysOfWeek.push(date.getUTCDay())
              }
            }
            this.selectedDaysOfWeek = selectedDaysOfWeek
            if (this.event.startOnMonday) {
              this.startOnMonday = true
            }
          }
        }
      }
    },
    resetToEventData() {
      this.updateFieldsFromEvent()
      this.$refs.emailInput.reset()
    },
    setInitialEventData() {
      this.initialEventData = {
        name: this.name,
        startTime: this.startTime,
        endTime: this.endTime,
        daysOnly: this.daysOnly,
        selectedDays: this.selectedDays,
        selectedDaysOfWeek: this.selectedDaysOfWeek,
        selectedDateOption: this.selectedDateOption,
        notificationsEnabled: this.notificationsEnabled,
        emails: [...this.emails],
        blindAvailabilityEnabled: this.blindAvailabilityEnabled,
        sendEmailAfterXResponsesEnabled: this.sendEmailAfterXResponsesEnabled,
        sendEmailAfterXResponses: this.sendEmailAfterXResponses,
      }
    },
    hasEventBeenEdited() {
      return (
        this.name !== this.initialEventData.name ||
        this.startTime !== this.initialEventData.startTime ||
        this.endTime !== this.initialEventData.endTime ||
        this.selectedDateOption !== this.initialEventData.selectedDateOption ||
        JSON.stringify(this.selectedDays) !==
          JSON.stringify(this.initialEventData.selectedDays) ||
        JSON.stringify(this.selectedDaysOfWeek) !==
          JSON.stringify(this.initialEventData.selectedDaysOfWeek) ||
        this.daysOnly !== this.initialEventData.daysOnly ||
        this.notificationsEnabled !==
          this.initialEventData.notificationsEnabled ||
        JSON.stringify(this.emails) !==
          JSON.stringify(this.initialEventData.emails) ||
        this.blindAvailabilityEnabled !==
          this.initialEventData.blindAvailabilityEnabled ||
        this.sendEmailAfterXResponsesEnabled !==
          this.initialEventData.sendEmailAfterXResponsesEnabled ||
        this.sendEmailAfterXResponses !==
          this.initialEventData.sendEmailAfterXResponses
      )
    },
    getFullDate(dateString) {
      try {
        // Parse the date components safely
        const [year, month, day] = dateString.split('-').map(Number);
        
        // Create a date object (month is 0-indexed in JS)
        const date = new Date(year, month - 1, day);
        
        // Set the start time
        date.setHours(Math.floor(this.startTime), 0, 0, 0);
        
        // Check if date is valid
        if (isNaN(date.getTime())) {
          console.error('Invalid date created in getFullDate:', dateString);
          throw new Error('Invalid date');
        }
        
        return date.toISOString();
      } catch (err) {
        console.error('Error in getFullDate:', err);
        // Fallback to old method
        return `${dateString} ${Math.floor(this.startTime)}:00:00`;
      }
    },
    
    timeNumToTimeString(timeNum) {
      // Convert time number (e.g., 14) to time string (e.g., "14:00")
      return `${Math.floor(timeNum)}:00:00`
    },
    updatePickerDate(newPickerDate) {
      this.pickerDate = newPickerDate;
    },
  },

  watch: {
    event: {
      immediate: true,
      handler() {
        this.updateFieldsFromEvent()
        this.setInitialEventData()
      },
    },
    selectedDateOption() {
      // Reset the other date / day selection when date option is changed
      if (this.selectedDateOption === this.dateOptions.SPECIFIC) {
        this.selectedDaysOfWeek = []
      } else if (this.selectedDateOption === this.dateOptions.DOW) {
        this.selectedDays = []
      }
    },
  },
}
</script>
