package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	log.Printf("Starting server on port %s", port)
	
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received request: %s %s", r.Method, r.URL.Path)
		fmt.Fprintf(w, "BetterMeet Server is running! Try accessing the API at /api")
	})
	
	http.HandleFunc("/api", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received API request: %s %s", r.Method, r.URL.Path)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, "{\"status\":\"ok\",\"message\":\"BetterMeet API is running!\"}")
	})
	
	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}
