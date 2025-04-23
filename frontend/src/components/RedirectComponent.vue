<template>
  <div class="tw-flex tw-justify-center tw-items-center tw-h-screen">
    <p>Redirecting...</p>
  </div>
</template>

<script>
export default {
  name: "RedirectComponent",
  props: {
    to: {
      type: String,
      required: true
    }
  },
  created() {
    this.$router.push({ name: this.to });
  }
}
</script> 