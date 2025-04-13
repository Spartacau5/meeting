package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"schej.it/server/db"
	"schej.it/server/logger"
	"schej.it/server/models"
	"schej.it/server/utils"
)

// UserInfo represents information about a user from an OAuth provider
type UserInfo struct {
	ID            string `json:"id"`
	Email         string `json:"email"`
	VerifiedEmail bool   `json:"verified_email"`
	Name          string `json:"name"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Picture       string `json:"picture"`
	Locale        string `json:"locale"`
}

// Returns access, refresh, and id tokens from the auth code
func GetTokensFromAuthCode(code string, scope string, origin string, calendarType models.CalendarType) (TokenResponse, error) {
	clientId, clientSecret := getCredentialsFromCalendarType(calendarType)
	tokenEndpoint := getTokenEndpointFromCalendarType(calendarType)

	// If scope is empty, use a default scope for Google OAuth
	if scope == "" && calendarType == models.GoogleCalendarType {
		scope = "openid email profile"
	}

	// Call Google oauth token endpoint
	redirectUri := fmt.Sprintf("%s/auth", origin)
	values := url.Values{
		"client_id":     {clientId},
		"client_secret": {clientSecret},
		"code":          {code},
		"redirect_uri":  {redirectUri},
		"grant_type":    {"authorization_code"},
	}
	
	// Only add scope if it's not empty
	if scope != "" {
		values.Add("scope", scope)
	}

	logger.StdOut.Printf("Making token exchange request to %s with redirect_uri=%s", tokenEndpoint, redirectUri)
	
	resp, err := http.PostForm(
		tokenEndpoint,
		values,
	)
	if err != nil {
		logger.StdErr.Printf("Failed to make token exchange request: %v", err)
		return TokenResponse{}, fmt.Errorf("failed to make token exchange request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body for logging
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		logger.StdErr.Printf("Failed to read response body: %v", err)
		return TokenResponse{}, fmt.Errorf("failed to read response body: %w", err)
	}

	// Check response status
	if resp.StatusCode != http.StatusOK {
		logger.StdErr.Printf("Token exchange failed with status %d: %s", resp.StatusCode, string(body))
		return TokenResponse{}, fmt.Errorf("token exchange failed with status %d", resp.StatusCode)
	}

	var res TokenResponse
	if err := json.Unmarshal(body, &res); err != nil {
		logger.StdErr.Printf("Failed to parse token response: %v", err)
		return TokenResponse{}, fmt.Errorf("failed to parse token response: %w", err)
	}

	if len(res.Error) > 0 {
		logger.StdErr.Printf("Token exchange returned error: %s", res.Error)
		return TokenResponse{}, fmt.Errorf("token exchange error: %s", res.Error)
	}

	logger.StdOut.Printf("Successfully exchanged code for tokens")
	return res, nil
}

func RefreshAccessToken(accountAuth *models.OAuth2CalendarAuth, calendarType models.CalendarType) AccessTokenResponse {
	clientId, clientSecret := getCredentialsFromCalendarType(calendarType)
	tokenEndpoint := getTokenEndpointFromCalendarType(calendarType)
	values := url.Values{
		"client_id":     {clientId},
		"client_secret": {clientSecret},
		"refresh_token": {accountAuth.RefreshToken},
		"scope":         {accountAuth.Scope},
		"grant_type":    {"refresh_token"},
	}

	resp, err := http.PostForm(
		tokenEndpoint,
		values,
	)
	if err != nil {
		logger.StdErr.Panicln(err)
	}
	defer resp.Body.Close()

	var res AccessTokenResponse
	json.NewDecoder(resp.Body).Decode(&res)

	return res
}

type RefreshAccessTokenData struct {
	TokenResponse AccessTokenResponse
	Email         string
	CalendarType  models.CalendarType
	Error         *interface{}
}

func RefreshAccessTokenAsync(email string, accountAuth *models.OAuth2CalendarAuth, calendarType models.CalendarType, c chan RefreshAccessTokenData) {
	// Recover from panics
	defer func() {
		if err := recover(); err != nil {
			c <- RefreshAccessTokenData{Error: &err}
		}
	}()

	tokenResponse := RefreshAccessToken(accountAuth, calendarType)

	c <- RefreshAccessTokenData{tokenResponse, email, calendarType, nil}
}

// If access token has expired, get a new token for the primary account as well as all other calendar accounts, update the user object, and save it to the database
// `accounts` specifies for which accounts to refresh access tokens. If `accounts` is nil or empty, then update tokens for all accounts
func RefreshUserTokenIfNecessary(u *models.User, accounts models.Set[string]) {
	refreshTokenChan := make(chan RefreshAccessTokenData)
	numAccountsToUpdate := 0

	// If `accounts` is nil, then update tokens for all accounts
	updateAllAccounts := len(accounts) == 0

	// Refresh calendar account access tokens if necessary
	for accountKey, account := range u.CalendarAccounts {
		if account.OAuth2CalendarAuth != nil { // Only refresh access tokens for OAuth2 calendar accounts
			accountAuth := account.OAuth2CalendarAuth

			if _, ok := accounts[accountKey]; ok || updateAllAccounts {
				if time.Now().After(accountAuth.AccessTokenExpireDate.Time()) && len(accountAuth.RefreshToken) > 0 {
					go RefreshAccessTokenAsync(account.Email, accountAuth, account.CalendarType, refreshTokenChan)
					numAccountsToUpdate++
				}
			}
		}
	}

	// Update access tokens as responses are received
	for i := 0; i < numAccountsToUpdate; i++ {
		res := <-refreshTokenChan

		if res.Error != nil {
			continue
		}

		accessTokenExpireDate := utils.GetAccessTokenExpireDate(res.TokenResponse.ExpiresIn)

		calendarAccountKey := utils.GetCalendarAccountKey(res.Email, res.CalendarType)
		if calendarAccount, ok := u.CalendarAccounts[calendarAccountKey]; ok {
			calendarAccount.OAuth2CalendarAuth.AccessToken = res.TokenResponse.AccessToken
			calendarAccount.OAuth2CalendarAuth.AccessTokenExpireDate = primitive.NewDateTimeFromTime(accessTokenExpireDate)
			u.CalendarAccounts[calendarAccountKey] = calendarAccount
		}
	}

	// Update user object if accounts were updated
	if numAccountsToUpdate > 0 {
		db.UsersCollection.FindOneAndUpdate(
			context.Background(),
			bson.M{"_id": u.Id},
			bson.M{"$set": u},
		)
	}
}

func getCredentialsFromCalendarType(calendarType models.CalendarType) (string, string) {
	if calendarType == models.GoogleCalendarType {
		return os.Getenv("CLIENT_ID"), os.Getenv("CLIENT_SECRET")
	} else if calendarType == models.OutlookCalendarType {
		return os.Getenv("MICROSOFT_CLIENT_ID"), os.Getenv("MICROSOFT_CLIENT_SECRET")
	}

	return "", ""
}

func getTokenEndpointFromCalendarType(calendarType models.CalendarType) string {
	if calendarType == models.GoogleCalendarType {
		return "https://oauth2.googleapis.com/token"
	} else if calendarType == models.OutlookCalendarType {
		return "https://login.microsoftonline.com/common/oauth2/v2.0/token"
	}

	return ""
}

func GetUserInfo(accessToken string) (UserInfo, error) {
	req, err := http.NewRequest("GET", "https://www.googleapis.com/oauth2/v2/userinfo", nil)
	if err != nil {
		logger.StdErr.Printf("Error creating request to get user info: %v\n", err)
		return UserInfo{}, fmt.Errorf("failed to get user info: %w", err)
	}

	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", accessToken))
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		logger.StdErr.Printf("Error getting user info: %v\n", err)
		return UserInfo{}, fmt.Errorf("failed to get user info: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		logger.StdErr.Printf("User info request failed with status %d\n", resp.StatusCode)
		return UserInfo{}, fmt.Errorf("user info request failed with status %d", resp.StatusCode)
	}

	var userInfo UserInfo
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		logger.StdErr.Printf("Error decoding user info response: %v\n", err)
		return UserInfo{}, fmt.Errorf("failed to decode user info response: %w", err)
	}

	return userInfo, nil
}
