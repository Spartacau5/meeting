<template>
  <SlideToggle
    :value="value"
    @input="(e) => $emit('input', e)"
    :options="options"
  />
</template>

<script>
import { availabilityTypes } from "@/constants"
import SlideToggle from "@/components/SlideToggle.vue"

export default {
  name: "AvailabilityTypeToggle",

  props: {
    value: { type: String, required: true },
  },

  components: { SlideToggle },

  data() {
    return {
      options: [
        {
          text: "Available",
          activeClass: "tw-text-blue tw-bg-blue/5",
          borderClass: "tw-border-blue",
          borderStyle: { boxShadow: "0px 2px 8px 0px #3B82F640" },
          value: availabilityTypes.AVAILABLE,
        },
        {
          text: "If needed",
          activeClass: "tw-text-dark-yellow tw-bg-yellow/5",
          borderClass: "tw-border-orange",
          borderStyle: { boxShadow: "0px 2px 8px 0px #FEDB9340" },
          value: availabilityTypes.IF_NEEDED,
        },
      ],
    }
  },
}
</script>
