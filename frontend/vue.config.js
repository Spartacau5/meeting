const { defineConfig } = require("@vue/cli-service")
module.exports = defineConfig({
  transpileDependencies: ["vuetify"],
  publicPath: './',
  // publicPath: "/dist",
  // pluginOptions: {
  devServer: {
    port: 8080,
  }
})
