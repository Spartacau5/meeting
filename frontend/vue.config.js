const { defineConfig } = require("@vue/cli-service")
module.exports = defineConfig({
  transpileDependencies: ["vuetify"],
  publicPath: '/',
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
    historyApiFallback: true
  },
  pwa: {
    name: 'BetterMeet',
    themeColor: '#4DBA87',
    msTileColor: '#000000',
    appleMobileWebAppCapable: 'yes',
    appleMobileWebAppStatusBarStyle: 'black',
    workboxOptions: {
      skipWaiting: true,
      clientsClaim: true,
      // Don't precache dynamic pages like event pages
      exclude: [/\.map$/, /_redirects/, /e\/(.*)\.html/],
      // Define runtime caching rules for navigation
      runtimeCaching: [
        {
          // Cache API calls
          urlPattern: new RegExp('^https://.*\\.run\\.app/api/'),
          handler: 'NetworkFirst',
          options: {
            cacheName: 'api-cache',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 // 1 hour
            }
          }
        },
        {
          // Special handling for event page navigation
          urlPattern: new RegExp('/e/.*'),
          handler: 'NetworkFirst',
          options: {
            cacheName: 'event-pages',
            expiration: {
              maxEntries: 50,
              maxAgeSeconds: 60 * 60 * 24 // 24 hours
            }
          }
        },
        {
          // Cache static assets
          urlPattern: new RegExp('\\.(?:js|css|png|jpg|jpeg|svg|gif)$'),
          handler: 'CacheFirst',
          options: {
            cacheName: 'static-resources',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 * 24 * 7 // 7 days
            }
          }
        }
      ]
    }
  }
})
