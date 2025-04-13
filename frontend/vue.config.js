const { defineConfig } = require("@vue/cli-service")
module.exports = defineConfig({
  transpileDependencies: ["vuetify"],
  // publicPath: "/dist",
  // pluginOptions: {
  //   webpackBundleAnalyzer: {
  //     openAnalyzer: false,
  //   },
  // },
  devServer: {
    port: 8080,
    allowedHosts: "all"
  }
})
