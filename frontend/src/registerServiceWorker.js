/* eslint-disable no-console */

import { register } from "register-service-worker"

if (process.env.NODE_ENV === "production") {
  register(`${process.env.BASE_URL}service-worker.js`, {
    ready() {
      console.log(
        "App is being served from cache by a service worker.\n" +
          "For more details, visit https://goo.gl/AFskqB"
      )
    },
    registered(registration) {
      console.log("Service worker has been registered.")
      
      // Immediately update service worker on registration to ensure freshest content
      registration.update();
      
      // Check for updates every 15 minutes
      setInterval(() => {
        registration.update();
        console.log("Checking for service worker updates");
      }, 15 * 60 * 1000);
    },
    cached() {
      console.log("Content has been cached for offline use.")
    },
    updatefound() {
      console.log("New content is downloading.")
    },
    updated(registration) {
      console.log("New content is available; please refresh.")
      
      // Create a flag in localStorage so the main app can check for updates
      localStorage.setItem('appUpdateAvailable', 'true');
      
      // Claim clients immediately for better navigation handling
      registration.active.postMessage({ type: 'SKIP_WAITING' });
      
      // Or show a notification to the user
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('App Update Available', {
          body: 'A new version is available. Refresh to update.'
        });
      }
    },
    offline() {
      console.log(
        "No internet connection found. App is running in offline mode."
      )
    },
    error(error) {
      console.error("Error during service worker registration:", error)
    },
  })
}

// Add event listener for service worker messages
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'RELOAD') {
      window.location.reload();
    }
  });
  
  // Add listener for service worker controlling change
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    // Only reload if we were expecting the service worker to take control
    if (localStorage.getItem('appUpdateAvailable') === 'true') {
      localStorage.removeItem('appUpdateAvailable');
      window.location.reload();
    }
  });
}
