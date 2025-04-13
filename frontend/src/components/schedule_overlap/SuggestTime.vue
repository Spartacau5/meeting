<template>
  <div>
    <v-card>
      <v-card-title class="tw-flex">
        <div>Suggested Meeting Times</div>
        <v-spacer />
        <v-btn icon @click="closeDialog">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-card-title>

      <v-card-text class="tw-pb-8">
        <div v-if="loading" class="tw-flex tw-justify-center tw-py-8">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>
        <div v-else>
          <div v-if="suggestions.length === 0" class="tw-text-center tw-py-4">
            <div class="tw-text-lg tw-mb-2">No perfect overlaps found</div>
            <div class="tw-text-sm tw-text-gray-600">
              Try adjusting availability or consider splitting into smaller groups
            </div>
          </div>
          <div v-else>
            <div v-for="(suggestion, index) in suggestions" :key="index" class="tw-mb-4">
              <v-card outlined class="tw-p-4">
                <div class="tw-flex tw-justify-between tw-items-center">
                  <div>
                    <div class="tw-font-medium">{{ suggestion.time }}</div>
                    <div class="tw-text-sm tw-text-gray-600">{{ suggestion.details }}</div>
                  </div>
                  <v-btn small color="primary" @click="selectTime(suggestion)">
                    Select
                  </v-btn>
                </div>
              </v-card>
            </div>
          </div>
        </div>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
export default {
  name: 'SuggestTime',
  
  props: {
    event: {
      type: Object,
      required: true
    },
    responses: {
      type: Object,
      required: true
    },
    responsesFormatted: {
      type: Map,
      required: true
    }
  },

  data() {
    return {
      loading: false,
      suggestions: []
    }
  },

  computed: {
    hasResponses() {
      return Object.keys(this.responses).length > 0
    }
  },

  watch: {
    dialog(val) {
      if (val) {
        this.generateSuggestions()
      }
    }
  },

  created() {
    this.generateSuggestions()
  },

  methods: {
    closeDialog() {
      this.$emit('close')
    },

    async generateSuggestions() {
      this.loading = true
      this.suggestions = []

      try {
        console.log("Starting suggestion generation")
        console.log("Responses:", this.responses)
        console.log("ResponsesFormatted:", this.responsesFormatted)
        
        // Get all times with their availability counts and details
        const timeAvailability = new Map()
        const totalRespondents = Object.keys(this.responses).length
        const respondentsList = Object.keys(this.responses)
        
        console.log("Total respondents:", totalRespondents)
        
        // Track how many total times each respondent is available
        const respondentAvailabilityCount = {}
        respondentsList.forEach(id => {
          respondentAvailabilityCount[id] = 0
        })
        
        // First collect all availability data
        for (const [time, people] of this.responsesFormatted) {
          const peopleIds = Array.from(people)
          
          // Count how many times each person is available
          peopleIds.forEach(id => {
            if (respondentAvailabilityCount[id] !== undefined) {
              respondentAvailabilityCount[id]++
            }
          })
          
          timeAvailability.set(time, {
            count: people.size,
            people: peopleIds,
            timestamp: time
          })
        }
        
        console.log("Respondent availability counts:", respondentAvailabilityCount)
        console.log("Time availability data:", Array.from(timeAvailability.entries()))
        
        // Calculate scores for each time slot
        const timeScores = []
        for (const [time, data] of timeAvailability.entries()) {
          const date = new Date(parseInt(time))
          const hour = date.getHours()
          const peopleIds = data.people
          
          // Base information about the time slot
          const isWorkingHours = hour >= 9 && hour <= 17
          const isLunchTime = hour >= 12 && hour <= 13
          const isEarlyMorning = hour < 9
          const isLateEvening = hour > 17
          const percentAvailable = data.count / totalRespondents

          // Calculate a "sacrifice score" - lower is better
          // This represents how much people would have to adjust their schedules
          let sacrificeScore = 0
          
          // For each unavailable person, calculate their sacrifice based on how
          // many other times they're available
          const unavailablePeople = respondentsList.filter(id => !peopleIds.includes(id))
          
          for (const id of unavailablePeople) {
            // If this person has many other available times, it's a smaller sacrifice
            const availabilityCount = respondentAvailabilityCount[id] || 0
            if (availabilityCount === 0) {
              // If they're not available at any time, high sacrifice
              sacrificeScore += 20
            } else {
              // Otherwise, sacrifice is inversely proportional to their availability
              sacrificeScore += 10 / Math.sqrt(availabilityCount)
            }
          }
          
          // Time-of-day adjustments (still prefer reasonable hours)
          if (!isWorkingHours) sacrificeScore += 5
          if (isLunchTime) sacrificeScore += 3
          if (isEarlyMorning) sacrificeScore += 8
          if (isLateEvening) sacrificeScore += 6
          
          timeScores.push({
            time: time,
            sacrificeScore: sacrificeScore,
            peopleAvailable: data.count,
            peopleIds: peopleIds,
            hour: hour,
            date: date
          })
        }
        
        console.log("Time scores before sorting:", timeScores)
        
        // Sort by sacrifice score (ascending - lower is better)
        timeScores.sort((a, b) => a.sacrificeScore - b.sacrificeScore)
        
        console.log("Time scores after sorting:", timeScores)
        
        // Take top 5 suggestions
        const topSuggestions = timeScores.slice(0, 5)
        
        // Format suggestions
        this.suggestions = topSuggestions.map(suggestion => {
          return {
            time: suggestion.date.toLocaleString('en-US', {
              weekday: 'long',
              month: 'long',
              day: 'numeric',
              hour: 'numeric',
              minute: 'numeric'
            }),
            details: this.generateDetails(suggestion.peopleAvailable, totalRespondents, suggestion.hour, suggestion.sacrificeScore),
            people: suggestion.peopleIds,
            count: suggestion.peopleAvailable,
            timestamp: suggestion.time
          }
        })
        
        console.log("Final suggestions:", this.suggestions)

      } catch (error) {
        console.error('Error generating suggestions:', error)
      }

      this.loading = false
    },
    
    generateDetails(availableCount, totalCount, hour, sacrificeScore) {
      const percentage = Math.round((availableCount / totalCount) * 100)
      let timeQuality = ''
      
      if (hour >= 9 && hour <= 17) {
        timeQuality = 'during work hours'
      } else if (hour < 9) {
        timeQuality = 'early morning'
      } else {
        timeQuality = 'evening'
      }

      if (availableCount === totalCount) {
        return `Perfect match! Everyone is available (${timeQuality})`
      } else if (availableCount === 0) {
        return `No one is currently available, but this time requires minimal adjustments (${timeQuality})`
      } else if (percentage >= 75) {
        return `${availableCount}/${totalCount} people available, minimal adjustment needed (${timeQuality})`
      } else if (percentage >= 50) {
        return `${availableCount}/${totalCount} people available, some adjustment needed (${timeQuality})`
      } else if (percentage >= 25) {
        return `${availableCount}/${totalCount} people available, significant adjustment needed (${timeQuality})`
      } else {
        return `Only ${availableCount}/${totalCount} people available, but better than alternatives (${timeQuality})`
      }
    },

    suggestSplitGroups(timeAvailability) {
      // Find times where at least half the group is available
      const possibleTimes = Array.from(timeAvailability.entries())
        .filter(([_, data]) => data.count >= Object.keys(this.responses).length / 2)
        
      if (possibleTimes.length >= 2) {
        const group1Time = new Date(parseInt(possibleTimes[0][0]))
        const group2Time = new Date(parseInt(possibleTimes[1][0]))
        
        return `Consider splitting into 2 groups:\nGroup 1: ${group1Time.toLocaleString('en-US', {
          weekday: 'long',
          hour: 'numeric',
          minute: 'numeric'
        })}\nGroup 2: ${group2Time.toLocaleString('en-US', {
          weekday: 'long',
          hour: 'numeric',
          minute: 'numeric'
        })}`
      }
      
      return null
    },

    selectTime(suggestion) {
      if (suggestion.timestamp) {
        this.$emit('select-time', suggestion.timestamp)
        this.$emit('close')
      }
    }
  }
}
</script>