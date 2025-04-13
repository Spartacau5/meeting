<template>
  <v-img
    :alt="alt"
    class="shrink tw-cursor-pointer hover-effect"
    contain
    :src="src"
    transition="scale-transition"
    :width="width"
  />
</template>

<script>
import { isPhone } from "@/utils"

export default {
  name: "Logo",

  props: {
    type: {
      type: String,
      default: "gatherly",
      validator: function(value) {
        return ["gatherly", "betterwhen2meet", "aprilfools", "schej"].includes(value)
      }
    },
  },

  computed: {
    isPhone() {
      return isPhone(this.$vuetify)
    },
    alt() {
      if (this.type === "betterwhen2meet") {
        return "Betterwhen2meet Logo"
      }
      return this.type === "schej" ? "Schej Logo" : "Gatherly Logo"
    },
    src() {
      switch (this.type) {
        case "gatherly":
        case "schej":
          return require("@/assets/logo.png")
        case "betterwhen2meet":
          return require("@/assets/april_fools_logo.png")
        case "aprilfools":
          return require("@/assets/april_fools_logo.png")
      }
    },
    width() {
      switch (this.type) {
        case "gatherly":
        case "schej":
          return this.isPhone ? 85 : 110
        case "betterwhen2meet":
          return this.isPhone ? 200 : 300
        case "aprilfools":
          return this.isPhone ? 200 : 300
      }
    },
  },
}
</script>

<style scoped>
.hover-effect {
  transition: transform 0.2s ease-in-out;
}
.hover-effect:hover {
  transform: scale(1.05);
}
</style>
