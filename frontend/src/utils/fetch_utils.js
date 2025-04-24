import { serverURL, backendURL, errors } from "@/constants"

/* 
  Fetch utils
*/
export const get = (route) => {
  return fetchMethod("GET", route)
}

export const post = (route, body = {}) => {
  return fetchMethod("POST", route, body)
}

export const patch = (route, body = {}) => {
  return fetchMethod("PATCH", route, body)
}

export const put = (route, body = {}) => {
  return fetchMethod("PUT", route, body)
}

export const _delete = (route, body = {}) => {
  return fetchMethod("DELETE", route, body)
}

export const fetchMethod = (method, route, body = {}) => {
  /* Calls the given route with the give method and body */
  const params = {
    method,
    credentials: "include", // This is important for cookies/session
  }

  if (method !== "GET") {
    // Add params specific to POST/PATCH/DELETE
    params.headers = {
      "Content-Type": "application/json",
    }
    params.body = JSON.stringify(body)
  }

  // Detect if running on mobile
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  let timeoutPromise = null; // Declare outside the if block

  if (isMobile) {
    console.log(`[Mobile Device] Making API request: ${method} ${route}`);
    // Add longer timeout for mobile
    timeoutPromise = new Promise((_, reject) => // Assign inside the if block
      setTimeout(() => reject(new Error('Request timeout - mobile device')), 20000)
    );
    
    // Add detailed mobile debugging
    if (method === "POST" && route === "/events") {
      console.log("[Mobile Debug] Creating event with payload:", JSON.stringify(body));
    }
  }

  // Use the full backend URL in production to avoid using the storage domain
  let apiUrl;
  let adjustedRoute = route;
  
  if (process.env.NODE_ENV === "development") {
    apiUrl = serverURL;
  } else {
    // Use the backendURL from constants instead of hardcoding
    apiUrl = backendURL;
    
    // If the route already starts with /api, remove it to avoid duplication
    if (adjustedRoute.startsWith("/api")) {
      adjustedRoute = adjustedRoute.substring(4);
    }
  }

  const fullUrl = apiUrl + adjustedRoute;
  console.log(`[API ${method}] ${fullUrl}`);
  
  if (method !== "GET" && body) {
    console.log(`Request body:`, body);
  }
  
  const fetchPromise = fetch(fullUrl, params)
    .then(async (res) => {
      try {
        const text = await res.text()
        console.log(`[API Response] ${fullUrl} - Status: ${res.status} ${res.statusText}`);

        // Check for authentication issues (401)
        if (res.status === 401) {
          console.warn("[Auth Error] Unauthorized API request detected");
          // We could emit an event here or directly update Vuex store
        }

        // Parse JSON if text is not empty
        let returnValue
        if (text.length === 0) {
          returnValue = text
        } else {
          try {
            returnValue = JSON.parse(text)
          } catch (err) {
            console.error(`[API Parse Error] ${fullUrl} - Failed to parse response as JSON:`, text);
            throw { error: errors.JsonError }
          }
        }

        // Check if response was ok
        if (!res.ok) {
          console.error(`[API Error] ${fullUrl} - Server returned error:`, returnValue);
          throw returnValue
        }

        return returnValue
      } catch (err) {
        console.error(`[API Processing Error] ${fullUrl} - Error processing response:`, err);
        throw err;
      }
    })
    .catch(err => {
      if (err.name === 'TypeError' && err.message === 'Failed to fetch') {
        console.error(`[API Network Error] ${fullUrl} - Could not reach server. Network issue or CORS problem.`);
        // Additional troubleshooting info for mobile issues
        console.error(`User Agent: ${navigator.userAgent}`);
        console.error(`Is Online: ${navigator.onLine}`);
        
        // Special handling for mobile 
        if (isMobile) {
          console.error(`[Mobile Network Error] Additional context: 
            Screen Width: ${window.innerWidth}
            Screen Height: ${window.innerHeight}
            Pixel Ratio: ${window.devicePixelRatio}
            Orientation: ${window.orientation}
            Connection Type: ${navigator.connection ? navigator.connection.effectiveType : 'unknown'}
          `);
        }
      } else {
        console.error(`[API Error] ${fullUrl} -`, err);
      }
      throw err;
    });
    
  // Return the fetch promise with timeout for mobile devices
  return isMobile && timeoutPromise ? // Check if timeoutPromise exists
    Promise.race([fetchPromise, timeoutPromise]) :
    fetchPromise;
}
