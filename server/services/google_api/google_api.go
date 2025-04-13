package google_api

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"
	"schej.it/server/logger"
)

// GetCalendarService returns a Google Calendar service for a user with the given refresh token
func GetCalendarService(refreshToken string) (*calendar.Service, error) {
	if refreshToken == "" {
		return nil, fmt.Errorf("no refresh token provided")
	}

	// Get credentials from environment variables
	clientID := os.Getenv("CLIENT_ID")
	clientSecret := os.Getenv("CLIENT_SECRET")

	// Create OAuth2 config
	config := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		Endpoint:     google.Endpoint,
		Scopes:       []string{calendar.CalendarEventsScope},
	}

	// Create token from refresh token
	token := &oauth2.Token{
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		Expiry:       time.Now().Add(-time.Hour), // Force refresh
	}

	// Get token source with automatic refreshing
	tokenSource := config.TokenSource(context.Background(), token)

	// Create the Calendar service
	srv, err := calendar.NewService(context.Background(), option.WithTokenSource(tokenSource))
	if err != nil {
		logger.StdErr.Printf("Unable to create Calendar service: %v", err)
		return nil, err
	}

	return srv, nil
}

// RefreshGoogleAccessToken refreshes an access token using a refresh token
func RefreshGoogleAccessToken(refreshToken string) (string, error) {
	// Get credentials from environment variables
	clientID := os.Getenv("CLIENT_ID")
	clientSecret := os.Getenv("CLIENT_SECRET")

	// Create request to refresh token
	reqURL := "https://oauth2.googleapis.com/token"
	reqBody := fmt.Sprintf(
		"client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token",
		clientID, clientSecret, refreshToken,
	)

	// Make POST request
	req, err := http.NewRequest("POST", reqURL, strings.NewReader(reqBody))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	// Read response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	// Parse response
	var tokenResp struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
		TokenType   string `json:"token_type"`
		Error       string `json:"error"`
	}
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return "", err
	}

	// Check for error
	if tokenResp.Error != "" {
		return "", fmt.Errorf("error refreshing token: %s", tokenResp.Error)
	}

	return tokenResp.AccessToken, nil
} 