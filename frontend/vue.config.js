const { defineConfig } = require("@vue/cli-service")
module.exports = defineConfig({
  transpileDependencies: ["vuetify"],
  publicPath: './',
  // publicPath: "/dist",
  // pluginOptions: {
  devServer: {
    port: 8080,
    host: 'localhost',
    allowedHosts: 'all',
    client: {
      webSocketURL: 'ws://localhost:8080/ws',
    },
    headers: {
      'Access-Control-Allow-Origin': '*',
    },
  },
  pwa: {
    name: 'BetterMeet',
    themeColor: '#4DBA87',
    msTileColor: '#000000',
    appleMobileWebAppCapable: 'yes',
    appleMobileWebAppStatusBarStyle: 'black',
    workboxOptions: {
      skipWaiting: true
    }
  }
})
