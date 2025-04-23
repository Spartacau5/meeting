<template>
  <div>
    <v-date-picker
      ref="datePicker"
      :pickerDate.sync="pickerDate"
      :value="value"
      @touchstart:date="touchstart"
      @mousedown:date="mousedown"
      @mouseover:date="mouseover"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
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
    <!-- <div class="tw-mt-2 tw-text-xs tw-text-very-dark-gray">
      Drag to select multiple dates
    </div> -->
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
    /** Start drag */
    mousedown(date) {
      if (this.isMobile) return // Skip if on mobile
      
      this.dragging = true
      this.setDragState(date)
      this.addRemoveDate(date)
    },
    
    touchstart(date) {
      // Prevent default to avoid potential browser handling
      event.preventDefault()
      
      console.log("Touch start on date:", date)
      
      // Store the date that was touched
      this.lastTouchedDate = date
      
      this.dragging = true
      this.setDragState(date)
      this.addRemoveDate(date)
    },

    /** Dragging */
    mouseover(date) {
      if (!this.dragging || this.isMobile) return

      this.addRemoveDate(date)
    },
    
    handleTouchMove(e) {
      if (!this.dragging) return
      
      // Prevent scroll and browser handling
      e.preventDefault()
      
      // Get the current touch position
      const touch = e.touches[0]
      
      // Find element under the touch point
      const target = document.elementFromPoint(
        touch.clientX,
        touch.clientY
      )
      
      console.log("Touch move, target:", target ? target.tagName : "none")
      
      // Process only v-btn elements that contain date numbers
      if (
        target && 
        this.datePickerEl.contains(target) &&
        (target.classList.contains("v-btn__content") || 
         target.closest(".v-btn__content"))
      ) {
        // Get the actual element with text content
        const btnContent = target.classList.contains("v-btn__content") ? 
                           target : target.closest(".v-btn__content")
        
        if (!btnContent) return
        
        // Get date num from target
        const dateNum = parseInt(btnContent.textContent.trim())
        if (!isNaN(dateNum)) {
          console.log("Processing touchmove for date:", dateNum)
          const dateNumString = `${dateNum}`
          const date = `${this.pickerDate}-${dateNumString.padStart(2, "0")}`
          
          // Only trigger if this is a different date than last processed
          if (date !== this.lastTouchedDate) {
            this.lastTouchedDate = date
            this.addRemoveDate(date)
          }
        }
      }
    },

    /** End drag */
    handleTouchEnd(e) {
      // Prevent default to avoid clicks or other actions
      e.preventDefault()
      
      console.log("Touch drag ended")
      this.dragging = false
      this.lastTouchedDate = null
    },
    
    mouseup(e) {
      if (!this.dragging || this.isMobile) return

      // Prevent month switching when tap and drag to left / right
      e.preventDefault()
      e.stopPropagation()

      this.dragging = false
    },

    /** Sets the drag state based on the date */
    setDragState(date) {
      const set = new Set(this.value)
      if (set.has(date)) {
        this.dragState = this.dragStates.REMOVE
      } else {
        this.dragState = this.dragStates.ADD
      }
    },
    
    addRemoveDate(date) {
      if (!date) return // Skip if date is null or undefined
      
      if (this.dragState === this.dragStates.ADD) {
        this.addDate(date)
      } else if (this.dragState === this.dragStates.REMOVE) {
        this.removeDate(date)
      }
    },
    
    addDate(date) {
      const set = new Set(this.value)
      set.add(date)
      this.$emit("input", [...set])
    },
    
    removeDate(date) {
      const set = new Set(this.value)
      set.delete(date)
      this.$emit("input", [...set])
    },
    
    // Detect mobile device
    checkIfMobile() {
      this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
      console.log("Device detected as:", this.isMobile ? "Mobile" : "Desktop")
    }
  },

  mounted() {
    this.checkIfMobile()
    this.datePickerEl = this.$refs.datePicker.$el
    
    // We now handle touchmove and touchend directly through v-date-picker events
    // But keep mouseup event for desktop
    this.datePickerEl.addEventListener("mouseup", this.mouseup)
  },

  beforeDestroy() {
    this.datePickerEl.removeEventListener("mouseup", this.mouseup)
  },

  watch: {
    pickerDate(newValue) {
      this.$emit('update:pickerDate', newValue);
    }
  },
}
</script>
