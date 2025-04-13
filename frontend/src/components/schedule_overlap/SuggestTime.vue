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
            <div class="tw-text-lg tw-mb-2">No suitable times found</div>
            <div class="tw-text-sm tw-text-gray-600">
              Try adjusting availability or consider splitting into smaller groups
            </div>
          </div>
          <div v-else>
            <div v-for="(suggestion, index) in suggestions" :key="index" class="tw-mb-4">
              <v-card outlined class="tw-p-4" :class="{'tw-border-green-500': suggestion.isPerfect}">
                <div class="tw-flex tw-justify-between tw-items-start">
                  <div>
                    <div class="tw-font-medium tw-text-lg">{{ suggestion.time }}</div>
                    <div class="tw-text-sm tw-text-gray-600 tw-mb-2">{{ suggestion.details }}</div>
                    <div v-if="suggestion.compromises.length > 0" class="tw-text-xs tw-text-gray-500">
                      <div v-for="(compromise, i) in suggestion.compromises" :key="i" class="tw-mb-1">
                        <v-icon x-small class="tw-mr-1">mdi-account-alert</v-icon>
                        {{ compromise }}
                      </div>
                    </div>
                  </div>
                  <v-btn small :color="suggestion.isPerfect ? 'success' : 'primary'" @click="selectTime(suggestion)">
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
    },
    respondents: {
      type: Array,
      default: () => []
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
    },
    
    // Get a map of user IDs to names
    userNameMap() {
      const map = {};
      this.respondents.forEach(respondent => {
        map[respondent._id] = respondent.name;
      });
      return map;
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
        // Get all times with their availability counts and details
        const timeAvailability = new Map()
        const totalRespondents = Object.keys(this.responses).length
        const respondentsList = Object.keys(this.responses)
        
        if (totalRespondents === 0) {
          this.loading = false
          return;
        }
        
        // Track availability patterns for each respondent
        const respondentAvailability = {};
        respondentsList.forEach(id => {
          respondentAvailability[id] = {
            availableTimes: [],
            preferredHours: new Set(),
            dayPatterns: {}
          };
        });
        
        // First collect all availability data
        for (const [time, people] of this.responsesFormatted) {
          const timestamp = parseInt(time);
          const date = new Date(timestamp);
          const peopleIds = Array.from(people);
          const dayOfWeek = date.getDay();
          const hour = date.getHours();
          
          // Record this time for each available person
          peopleIds.forEach(id => {
            if (respondentAvailability[id]) {
              // Add to available times
              respondentAvailability[id].availableTimes.push(timestamp);
              
              // Add to preferred hours
              respondentAvailability[id].preferredHours.add(hour);
              
              // Track day patterns
              if (!respondentAvailability[id].dayPatterns[dayOfWeek]) {
                respondentAvailability[id].dayPatterns[dayOfWeek] = 0;
              }
              respondentAvailability[id].dayPatterns[dayOfWeek]++;
            }
          });
          
          timeAvailability.set(time, {
            count: peopleIds.length,
            people: peopleIds,
            timestamp: time,
            date: date,
            hour: hour,
            dayOfWeek: dayOfWeek
          });
        }
        
        // Find the maximum number of people available in any timeslot
        const maxAvailability = Math.max(...Array.from(timeAvailability.values()).map(data => data.count));
        
        // Check if perfect overlap exists (all respondents available)
        const perfectOverlaps = Array.from(timeAvailability.entries())
          .filter(([_, data]) => data.count === totalRespondents)
          .map(([time, data]) => ({time, data}));
          
        // Calculate scores for each time slot
        const timeScores = [];
        for (const [time, data] of timeAvailability.entries()) {
          // Skip this calculation if we have perfect overlaps and this isn't one
          if (perfectOverlaps.length > 0 && data.count < totalRespondents) {
            continue;
          }
          
          const date = data.date;
          const hour = data.hour;
          const peopleIds = data.people;
          const dayOfWeek = data.dayOfWeek;
          
          // Base information about the time slot
          const isWorkingHours = hour >= 9 && hour <= 17;
          const isLunchTime = hour >= 12 && hour <= 13;
          const isEarlyMorning = hour < 9;
          const isLateEvening = hour > 17;
          
          // Calculate a score for this time slot (higher is better)
          let score = data.count * 100; // Base score based on number of people available
          
          // Adjust score based on time of day
          if (isWorkingHours) score += 20;
          if (isLunchTime) score -= 10;
          if (isEarlyMorning) score -= 30;
          if (isLateEvening) score -= 15;
          
          // Calculate compromise info for people not available
          const unavailablePeople = respondentsList.filter(id => !peopleIds.includes(id));
          const compromises = [];
          
          // For unavailable people, analyze why they can't make it and what adjustment they need
          for (const id of unavailablePeople) {
            const userAvailability = respondentAvailability[id];
            
            if (!userAvailability || userAvailability.availableTimes.length === 0) {
              compromises.push(`${this.getUserName(id)} has no availability`);
              continue;
            }
            
            // Find the closest available time for this person
            const closestTime = this.findClosestAvailableTime(date.getTime(), userAvailability.availableTimes);
            const timeDiff = Math.abs(closestTime - date.getTime());
            const hoursDiff = Math.round(timeDiff / (1000 * 60 * 60));
            
            // Check if this person is generally available on this day
            const hasDayAvailability = userAvailability.dayPatterns[dayOfWeek] && 
                                      userAvailability.dayPatterns[dayOfWeek] > 0;
                                      
            // Check if this person is generally available at similar hours
            const nearbyHours = [hour-1, hour, hour+1].filter(h => h >= 0 && h <= 23);
            const hasNearbyHourAvailability = nearbyHours.some(h => userAvailability.preferredHours.has(h));
            
            if (hoursDiff <= 1) {
              // Very close time
              compromises.push(`${this.getUserName(id)} could adjust by ${hoursDiff} hour`);
              // Smaller penalty for short adjustments
              score -= 5;
            } else if (hasNearbyHourAvailability) {
              // Can fit if they adjust their schedule slightly
              compromises.push(`${this.getUserName(id)} has availability at similar hours`);
              score -= 15;
            } else if (hasDayAvailability) {
              // Available this day but at different hours
              compromises.push(`${this.getUserName(id)} is available this day at different times`);
              score -= 25;
            } else {
              // Not available this day at all
              compromises.push(`${this.getUserName(id)} not available on this day`);
              score -= 40;
            }
          }
          
          timeScores.push({
            time: time,
            score: score,
            peopleAvailable: data.count,
            peopleIds: peopleIds,
            hour: hour,
            date: date,
            compromises: compromises,
            isPerfect: data.count === totalRespondents
          });
        }
        
        // Sort by score (descending)
        timeScores.sort((a, b) => b.score - a.score);
        
        // Take top 3 suggestions
        const topSuggestions = timeScores.slice(0, 3);
        
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
            details: this.generateDetails(suggestion.peopleAvailable, totalRespondents, suggestion.hour, suggestion.isPerfect),
            people: suggestion.peopleIds,
            count: suggestion.peopleAvailable,
            timestamp: suggestion.time,
            compromises: suggestion.compromises,
            isPerfect: suggestion.isPerfect
          }
        });

      } catch (error) {
        console.error('Error generating suggestions:', error);
      }

      this.loading = false;
    },
    
    generateDetails(availableCount, totalCount, hour, isPerfect) {
      const percentage = Math.round((availableCount / totalCount) * 100);
      let timeQuality = '';
      
      if (hour >= 9 && hour <= 17) {
        timeQuality = 'during work hours';
      } else if (hour < 9) {
        timeQuality = 'early morning';
      } else {
        timeQuality = 'evening';
      }

      if (isPerfect) {
        return `Perfect match! Everyone is available ${timeQuality}`;
      } else if (percentage >= 75) {
        return `${availableCount}/${totalCount} participants available ${timeQuality}`;
      } else if (percentage >= 50) {
        return `Majority (${availableCount}/${totalCount}) can attend ${timeQuality}`;
      } else {
        return `${availableCount}/${totalCount} participants available ${timeQuality}`;
      }
    },
    
    findClosestAvailableTime(targetTime, availableTimes) {
      if (availableTimes.length === 0) return null;
      
      return availableTimes.reduce((closest, time) => {
        const currentDiff = Math.abs(time - targetTime);
        const closestDiff = Math.abs(closest - targetTime);
        return currentDiff < closestDiff ? time : closest;
      }, availableTimes[0]);
    },
    
    getUserName(userId) {
      return this.userNameMap[userId] || `Guest ${userId.substring(0, 4)}`;
    },

    selectTime(suggestion) {
      if (suggestion.timestamp) {
        this.$emit('select-time', suggestion.timestamp);
        this.$emit('close');
      }
    }
  }
}
</script>