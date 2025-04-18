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
    credentials: "include",
  }

  if (method !== "GET") {
    // Add params specific to POST/PATCH/DELETE
    params.headers = {
      "Content-Type": "application/json",
    }
    params.body = JSON.stringify(body)
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

  console.log("Making request to:", apiUrl + adjustedRoute);
  if (method !== "GET") {
    console.log("Request body:", params.body);
  }
  
  return fetch(apiUrl + adjustedRoute, params)
    .then(async (res) => {
      const text = await res.text()
      console.log(`Response status: ${res.status} ${res.statusText}`);

      // Parse JSON if text is not empty
      let returnValue
      if (text.length === 0) {
        returnValue = text
        console.log("Empty response received");
      } else {
        try {
          returnValue = JSON.parse(text)
          console.log("Response data:", returnValue);
        } catch (err) {
          console.error("Failed to parse response as JSON:", text);
          throw { error: errors.JsonError }
        }
      }

      // Check if response was ok
      if (!res.ok) {
        console.error("Response error:", returnValue);
        throw returnValue
      }

      return returnValue
    })
    .then((data) => {
      return data
    })
    .catch(err => {
      console.error("Fetch error:", err);
      throw err;
    })
}
