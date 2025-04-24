<template>
  <div>
    <v-date-picker
      ref="datePicker"
      :pickerDate.sync="pickerDate"
      :value="value"
      @click:date="dateClick"
      @change="emitChange"
      readonly
      no-title
      multiple
      color="primary"
      :show-current="false"
      class="tw-w-full tw-rounded-md tw-border-0 tw-drop-shadow tw-overflow-x-auto"
      :min="minCalendarDate"
      full-width
      :scrollable="false"
    ></v-date-picker>
    <div class="tw-mt-2 tw-text-xs tw-text-very-dark-gray">
      {{ isMobile ? 'Tap to select dates' : 'Drag to select multiple dates' }}
    </div>
  </div>
</template>

<script>
export default {
  name: "DatePicker",

  props: {
    value: { type: Array, required: true },
    minCalendarDate: { type: String, default: "" },
  },

  data() {
    return {
      datePickerEl: null,
      dragging: false,
      dragState: "add",
      dragStates: { ADD: "add", REMOVE: "remove" },
      pickerDate: "",
      lastTouchedDate: null,
      isMobile: false
    }
  },

  methods: {
    // Click date handler (works on both mobile and desktop)
    dateClick(date) {
      console.log("Date clicked:", date);
      
      try {
        if (!date) return;
        
        // For mobile, simply toggle the date
        if (this.isMobile) {
          this.toggleDate(date);
          return;
        }
        
        // For desktop, start drag mode
        this.dragging = true;
        this.setDragState(date);
        this.toggleDate(date);
        
        // Add document-level mouse listeners
        document.addEventListener('mousemove', this.documentMouseMove);
        document.addEventListener('mouseup', this.documentMouseUp);
      } catch (err) {
        console.error("Error in date click:", err);
      }
    },
    
    // Document level event listeners for drag selection
    documentMouseMove(e) {
      if (!this.dragging || this.isMobile) return;
      
      try {
        // Get element under mouse
        const el = document.elementFromPoint(e.clientX, e.clientY);
        if (!el) return;
        
        // Find button content element
        const btnContent = el.closest('.v-btn__content');
        if (!btnContent) return;
        
        // Get date from button
        const day = btnContent.textContent.trim();
        if (!day || isNaN(parseInt(day))) return;
        
        // Format date and process it
        const dateStr = `${this.pickerDate}-${day.padStart(2, '0')}`;
        if (dateStr !== this.lastTouchedDate) {
          this.lastTouchedDate = dateStr;
          this.toggleDate(dateStr);
        }
      } catch (err) {
        console.error("Error in mouse move:", err);
      }
    },
    
    documentMouseUp() {
      if (this.isMobile) return;
      
      // Clean up
      this.dragging = false;
      this.lastTouchedDate = null;
      
      // Remove document listeners
      document.removeEventListener('mousemove', this.documentMouseMove);
      document.removeEventListener('mouseup', this.documentMouseUp);
    },
    
    // Change event handler
    emitChange(dates) {
      if (Array.isArray(dates)) {
        this.$emit("input", dates);
      }
    },
    
    // Helper methods
    setDragState(date) {
      if (!date) return;
      
      const set = new Set(this.value);
      if (set.has(date)) {
        this.dragState = this.dragStates.REMOVE;
      } else {
        this.dragState = this.dragStates.ADD;
      }
    },
    
    toggleDate(date) {
      if (!date) return;
      
      const set = new Set(this.value);
      
      if (this.dragging && !this.isMobile) {
        // In drag mode, use the drag state
        if (this.dragState === this.dragStates.ADD) {
          set.add(date);
        } else {
          set.delete(date);
        }
      } else {
        // In click mode, toggle the date
        if (set.has(date)) {
          set.delete(date);
        } else {
          set.add(date);
        }
      }
      
      this.$emit("input", [...set]);
    }
  },

  mounted() {
    // Set mobile flag
    this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    console.log("Device detected as:", this.isMobile ? "Mobile" : "Desktop");
    
    // Set reference to date picker element
    try {
      this.datePickerEl = this.$refs.datePicker.$el;
    } catch (err) {
      console.error("Error setting up DatePicker:", err);
    }
  },
  
  beforeDestroy() {
    // Clean up event listeners
    if (!this.isMobile) {
      document.removeEventListener('mousemove', this.documentMouseMove);
      document.removeEventListener('mouseup', this.documentMouseUp);
    }
  },

  watch: {
    pickerDate(newValue) {
      this.$emit('update:pickerDate', newValue);
    }
  }
}
</script>

<style scoped>
.datepicker-container {
  width: 100%;
}
</style>
