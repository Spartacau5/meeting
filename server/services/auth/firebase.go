package auth

import (
	"context"
	"errors"
	"fmt"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
	"schej.it/server/logger"
)

var (
	firebaseApp *firebase.App
	authClient  *auth.Client
)

// InitFirebase initializes the Firebase app
func InitFirebase() error {
	// Use environment variable for project ID
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	if projectID == "" {
		projectID = "verdant-coyote-455921-h1" // Fallback to config from file
	}

	// Read Firebase service account file
	serviceAccountPath := "./verdant-coyote-455921-h1-firebase-adminsdk-fbsvc-1e8177287d.json"
	serviceAccountJSON, err := os.ReadFile(serviceAccountPath)
	if err != nil {
		// If file not found, try a few other locations
		alternatePaths := []string{
			"../verdant-coyote-455921-h1-firebase-adminsdk-fbsvc-1e8177287d.json",
			"/etc/secrets/firebase-service-account.json",
		}
		
		for _, path := range alternatePaths {
			serviceAccountJSON, err = os.ReadFile(path)
			if err == nil {
				break
			}
		}
		
		if err != nil {
			logger.StdErr.Printf("Warning: Could not read Firebase service account file: %v", err)
			logger.StdErr.Printf("Trying to use Application Default Credentials instead")
			serviceAccountJSON = []byte("{}")
		}
	}

	// Initialize Firebase app
	opt := option.WithCredentialsJSON(serviceAccountJSON)
	config := &firebase.Config{ProjectID: projectID}

	var initErr error
	firebaseApp, initErr = firebase.NewApp(context.Background(), config, opt)
	if initErr != nil {
		return fmt.Errorf("error initializing Firebase app: %v", initErr)
	}

	// Initialize Firebase auth client
	authClient, initErr = firebaseApp.Auth(context.Background())
	if initErr != nil {
		return fmt.Errorf("error initializing Firebase auth client: %v", initErr)
	}

	return nil
}

// VerifyFirebaseIDToken verifies the provided Firebase ID token and returns user info
func VerifyFirebaseIDToken(idToken string) (*auth.UserRecord, error) {
	if authClient == nil {
		return nil, errors.New("Firebase auth client not initialized")
	}

	// Verify ID token
	token, err := authClient.VerifyIDToken(context.Background(), idToken)
	if err != nil {
		return nil, fmt.Errorf("error verifying ID token: %v", err)
	}

	// Get user info using UID from token
	user, err := authClient.GetUser(context.Background(), token.UID)
	if err != nil {
		return nil, fmt.Errorf("error getting user info: %v", err)
	}

	return user, nil
}

// GetFirebaseUserInfo extracts basic user info from Firebase UserRecord
func GetFirebaseUserInfo(user *auth.UserRecord) UserInfo {
	info := UserInfo{
		ID:            user.UID,
		Email:         user.Email,
		VerifiedEmail: user.EmailVerified,
		Name:          user.DisplayName,
		Picture:       user.PhotoURL,
	}

	// Split name into first and last name if available
	if user.DisplayName != "" {
		nameParts := splitName(user.DisplayName)
		if len(nameParts) > 0 {
			info.GivenName = nameParts[0]
		}
		if len(nameParts) > 1 {
			info.FamilyName = nameParts[1]
		}
	}

	return info
}

// splitName splits a full name into first and last name
func splitName(fullName string) []string {
	var parts []string
	var current string
	for _, char := range fullName {
		if char == ' ' {
			if current != "" {
				parts = append(parts, current)
				current = ""
			}
		} else {
			current += string(char)
		}
	}
	if current != "" {
		parts = append(parts, current)
	}
	
	// If only one part, return it as first name and empty last name
	if len(parts) == 1 {
		return []string{parts[0], ""}
	}
	
	// If more than two parts, combine all but the first into the last name
	if len(parts) > 2 {
		lastName := parts[1]
		for i := 2; i < len(parts); i++ {
			lastName += " " + parts[i]
		}
		return []string{parts[0], lastName}
	}
	
	return parts
} 