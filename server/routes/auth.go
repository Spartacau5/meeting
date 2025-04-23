/* The /auth group contains all the routes to sign in and sign out */
package routes

import (
	"context"
	"fmt"
	"net/http"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"schej.it/server/db"
	"schej.it/server/logger"
	"schej.it/server/middleware"
	"schej.it/server/models"
	"schej.it/server/services/auth"
	"schej.it/server/services/calendar"
	"schej.it/server/services/listmonk"
	"schej.it/server/services/microsoftgraph"
	"schej.it/server/slackbot"
	"schej.it/server/utils"
)

// SignInRequest represents the payload for the sign-in endpoint
type SignInRequest struct {
	Code           string              `json:"code" binding:"required"`
	Scope          string              `json:"scope" binding:"required"`
	CalendarType   models.CalendarType `json:"calendarType" binding:"required"`
	TimezoneOffset int                 `json:"timezoneOffset" binding:"required"`
	Origin         string              `json:"origin"`
}

// Add a new struct for Firebase sign-in request
// FirebaseSignInRequest represents the payload for the Firebase sign-in endpoint
type FirebaseSignInRequest struct {
	IdToken        string              `json:"idToken" binding:"required"`
	AccessToken    string              `json:"accessToken"` // Optional but useful for calendar access
	RefreshToken   string              `json:"refreshToken"` // Optional but useful for refresh
	CalendarType   models.CalendarType `json:"calendarType" binding:"required"`
	TimezoneOffset int                 `json:"timezoneOffset" binding:"required"`
}

func InitAuth(router *gin.RouterGroup) {
	authRouter := router.Group("/auth")

	authRouter.POST("/sign-in", signIn)
	authRouter.POST("/sign-in-mobile", signInMobile)
	authRouter.POST("/sign-in-firebase", signInFirebase)
	authRouter.POST("/sign-out", signOut)
	authRouter.GET("/status", middleware.AuthRequired(), getStatus)
}

// @Summary Sign in a user
// @Description Authenticates a user with Google Calendar
// @Tags auth
// @Accept json
// @Produce json
// @Param request body SignInRequest true "Sign-in request"
// @Success 200 {object} models.User
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/sign-in [post]
func signIn(c *gin.Context) {
	var req SignInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// If origin is not provided, get it from the request
	if req.Origin == "" {
		req.Origin = utils.GetOrigin(c)
	}

	// Get tokens from auth code
	tokens, err := auth.GetTokensFromAuthCode(req.Code, req.Scope, req.Origin, req.CalendarType)
	if err != nil {
		logger.StdErr.Printf("Failed to exchange auth code: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to authenticate with Google"})
		return
	}

	user := signInHelper(c, tokens, models.WEB, req.CalendarType, req.TimezoneOffset)

	c.JSON(http.StatusOK, user)
}

// @Summary Signs user in from mobile
// @Description Signs user in and sets the access token session variable
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body object{timezoneOffset=int,accessToken=string,scope=string,idToken=string,expiresIn=int,refreshToken=string,tokenOrigin=string,calendarType=string} true "Object containing the Google authorization code, calendar type, and the user's timezone offset"
// @Success 200
// @Router /auth/sign-in-mobile [post]
func signInMobile(c *gin.Context) {
	payload := struct {
		AccessToken    string                 `json:"accessToken" binding:"required"`
		Scope          string                 `json:"scope" binding:"required"`
		IdToken        string                 `json:"idToken" binding:"required"`
		ExpiresIn      int                    `json:"expiresIn" binding:"required"`
		RefreshToken   string                 `json:"refreshToken" binding:"required"`
		TokenOrigin    models.TokenOriginType `json:"tokenOrigin" binding:"required"`
		CalendarType   models.CalendarType    `json:"calendarType" binding:"required"`
		TimezoneOffset int                    `json:"timezoneOffset" binding:"required"`
	}{}
	if err := c.BindJSON(&payload); err != nil {
		return
	}

	signInHelper(
		c,
		auth.TokenResponse{
			AccessToken:  payload.AccessToken,
			IdToken:      payload.IdToken,
			ExpiresIn:    payload.ExpiresIn,
			RefreshToken: payload.RefreshToken,
			Scope:        payload.Scope,
		},
		payload.TokenOrigin,
		payload.CalendarType,
		payload.TimezoneOffset,
	)

	c.JSON(http.StatusOK, gin.H{})
}

// @Summary Sign in a user with Firebase
// @Description Authenticates a user with Firebase Auth
// @Tags auth
// @Accept json
// @Produce json
// @Param request body FirebaseSignInRequest true "Firebase sign-in request"
// @Success 200 {object} models.User
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/sign-in-firebase [post]
func signInFirebase(c *gin.Context) {
	var req FirebaseSignInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify the Firebase ID token
	firebaseUser, err := auth.VerifyFirebaseIDToken(req.IdToken)
	if err != nil {
		logger.StdErr.Printf("Failed to verify Firebase ID token: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Firebase ID token"})
		return
	}

	// Get user info from Firebase user record
	userInfo := auth.GetFirebaseUserInfo(firebaseUser)
	
	// Create tokens object to use with existing signInHelper
	tokens := auth.TokenResponse{
		IdToken:      req.IdToken,
		AccessToken:  req.AccessToken,
		RefreshToken: req.RefreshToken,
		// ExpiresIn is not directly available from Firebase token, use a reasonable default
		ExpiresIn: 3600, // 1 hour
	}
	
	// Use email address from verified Firebase user
	email := firebaseUser.Email
	
	// Get access token expire time
	accessTokenExpireDate := utils.GetAccessTokenExpireDate(tokens.ExpiresIn)

	// Construct calendar auth object (if tokens are provided)
	calendarAuth := models.OAuth2CalendarAuth{
		AccessToken:           tokens.AccessToken,
		AccessTokenExpireDate: primitive.NewDateTimeFromTime(accessTokenExpireDate),
		RefreshToken:          tokens.RefreshToken,
		Scope:                 "", // Firebase doesn't provide scope directly
	}

	primaryAccountKey := utils.GetCalendarAccountKey(email, req.CalendarType)

	// Create user object to create new user or update existing user
	userData := models.User{
		Email:     email,
		FirstName: userInfo.GivenName,
		LastName:  userInfo.FamilyName,
		Picture:   userInfo.Picture,

		PrimaryAccountKey: &primaryAccountKey,

		TimezoneOffset: req.TimezoneOffset,
		TokenOrigin:    models.WEB, // Assuming web origin
	}

	// Set up calendar account if tokens are provided
	if tokens.AccessToken != "" {
		calendarAccount := models.CalendarAccount{
			CalendarType:       req.CalendarType,
			OAuth2CalendarAuth: &calendarAuth,

			Email:   email,
			Picture: userInfo.Picture,
			Enabled: utils.TruePtr(),
		}
		calendarAccountKey := utils.GetCalendarAccountKey(email, req.CalendarType)

		// Check if user exists
		var userId primitive.ObjectID
		findResult := db.UsersCollection.FindOne(context.Background(), bson.M{"email": email})
		
		// Handle user creation or update similar to signInHelper
		if findResult.Err() == mongo.ErrNoDocuments {
			// User doesn't exist, create new
			userData.CalendarAccounts = map[string]models.CalendarAccount{
				calendarAccountKey: calendarAccount,
			}
			
			result, err := db.UsersCollection.InsertOne(context.Background(), userData)
			if err != nil {
				logger.StdErr.Printf("Failed to create user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
				return
			}
			
			userId = result.InsertedID.(primitive.ObjectID)
		} else {
			// User exists, update
			var user models.User
			if err := findResult.Decode(&user); err != nil {
				logger.StdErr.Printf("Failed to decode user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read user data"})
				return
			}
			
			userId = user.Id
			
			// If user has custom name, do not override
			if user.HasCustomName != nil && *user.HasCustomName {
				userData.FirstName = ""
				userData.LastName = ""
			}
			
			// Set calendar account
			userData.CalendarAccounts = user.CalendarAccounts
			userData.CalendarAccounts[calendarAccountKey] = calendarAccount
			
			// Update user
			_, err := db.UsersCollection.UpdateByID(context.Background(), userId, bson.M{"$set": userData})
			if err != nil {
				logger.StdErr.Printf("Failed to update user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
				return
			}
		}
		
		userData.Id = userId
	} else {
		// No calendar tokens, just authenticate the user
		var userId primitive.ObjectID
		findResult := db.UsersCollection.FindOne(context.Background(), bson.M{"email": email})
		
		if findResult.Err() == mongo.ErrNoDocuments {
			// Create a simple user without calendar accounts
			result, err := db.UsersCollection.InsertOne(context.Background(), userData)
			if err != nil {
				logger.StdErr.Printf("Failed to create user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
				return
			}
			
			userId = result.InsertedID.(primitive.ObjectID)
		} else {
			// User exists, update basic info
			var user models.User
			if err := findResult.Decode(&user); err != nil {
				logger.StdErr.Printf("Failed to decode user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read user data"})
				return
			}
			
			userId = user.Id
			
			// If user has custom name, do not override
			if user.HasCustomName != nil && *user.HasCustomName {
				userData.FirstName = ""
				userData.LastName = ""
			}
			
			// Keep existing calendar accounts
			userData.CalendarAccounts = user.CalendarAccounts
			
			// Update user
			_, err := db.UsersCollection.UpdateByID(context.Background(), userId, bson.M{"$set": userData})
			if err != nil {
				logger.StdErr.Printf("Failed to update user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
				return
			}
		}
		
		userData.Id = userId
	}

	// Set session variables
	session := sessions.Default(c)
	session.Set("userId", userData.Id.Hex())
	session.Save()

	c.JSON(http.StatusOK, userData)
}

// Helper function to sign user in with the given parameters from the google oauth route
func signInHelper(c *gin.Context, tokens auth.TokenResponse, tokenOrigin models.TokenOriginType, calendarType models.CalendarType, timezoneOffset int) models.User {
	// Get user info
	userInfo, err := auth.GetUserInfo(tokens.AccessToken)
	if err != nil {
		logger.StdErr.Printf("Failed to get user info: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get user info"})
		c.Abort()
		return models.User{}
	}

	// Get access token expire time
	accessTokenExpireDate := utils.GetAccessTokenExpireDate(tokens.ExpiresIn)

	// Construct calendar auth object
	calendarAuth := models.OAuth2CalendarAuth{
		AccessToken:           tokens.AccessToken,
		AccessTokenExpireDate: primitive.NewDateTimeFromTime(accessTokenExpireDate),
		RefreshToken:          tokens.RefreshToken,
		Scope:                 tokens.Scope,
	}

	var email, firstName, lastName, picture string
	if calendarType == models.GoogleCalendarType {
		// Get user info from JWT
		claims := utils.ParseJWT(tokens.IdToken)
		email, _ = claims.GetStr("email")
		firstName, _ = claims.GetStr("given_name")
		lastName, _ = claims.GetStr("family_name")
		picture, _ = claims.GetStr("picture")
	} else if calendarType == models.OutlookCalendarType {
		// Get user info from microsoft graph
		msUserInfo := microsoftgraph.GetUserInfo(nil, &calendarAuth)
		email = msUserInfo.Email
		firstName = msUserInfo.FirstName
		lastName = msUserInfo.LastName
		picture = ""
	} else {
		// Use the userInfo from GetUserInfo for other calendar types
		email = userInfo.Email
		firstName = userInfo.GivenName
		lastName = userInfo.FamilyName
		picture = userInfo.Picture
	}

	primaryAccountKey := utils.GetCalendarAccountKey(email, calendarType)

	// Create user object to create new user or update existing user
	userData := models.User{
		Email:     email,
		FirstName: firstName,
		LastName:  lastName,
		Picture:   picture,

		PrimaryAccountKey: &primaryAccountKey,

		TimezoneOffset: timezoneOffset,
		TokenOrigin:    tokenOrigin,
	}

	calendarAccount := models.CalendarAccount{
		CalendarType:       calendarType,
		OAuth2CalendarAuth: &calendarAuth,

		Email:   email,
		Picture: picture,
		Enabled: utils.TruePtr(), // Workaround to pass a boolean pointer
	}
	calendarAccountKey := utils.GetCalendarAccountKey(email, calendarType)

	var userId primitive.ObjectID
	findResult := db.UsersCollection.FindOne(context.Background(), bson.M{"email": email})
	// If user doesn't exist, create a new user
	if findResult.Err() == mongo.ErrNoDocuments {
		// Fetch subcalendars
		subCalendars, err := calendar.GetCalendarProvider(calendarAccount).GetCalendarList()
		if err == nil {
			calendarAccount.SubCalendars = &subCalendars
		}

		// Set calendar accounts
		userData.CalendarAccounts = map[string]models.CalendarAccount{
			calendarAccountKey: calendarAccount,
		}

		// Create user
		res, err := db.UsersCollection.InsertOne(context.Background(), userData)
		if err != nil {
			logger.StdErr.Panicln(err)
		}

		userId = res.InsertedID.(primitive.ObjectID)

		slackbot.SendTextMessage(fmt.Sprintf(":wave: %s %s (%s) has joined schej.it!", firstName, lastName, email))
	} else {
		var user models.User
		if err := findResult.Decode(&user); err != nil {
			logger.StdErr.Panicln(err)
		}
		userId = user.Id

		// If user has custom name, do not override first name and last name
		if user.HasCustomName != nil && *user.HasCustomName {
			userData.FirstName = ""
			userData.LastName = ""
		}

		// Set subcalendars map based on whether calendar account already exists
		if oldCalendarAccount, ok := user.CalendarAccounts[calendarAccountKey]; ok && oldCalendarAccount.SubCalendars != nil {
			calendarAccount.SubCalendars = oldCalendarAccount.SubCalendars
		} else {
			subCalendars, err := calendar.GetCalendarProvider(calendarAccount).GetCalendarList()
			if err == nil {
				calendarAccount.SubCalendars = &subCalendars
			}
		}

		// Set calendar account
		userData.CalendarAccounts = user.CalendarAccounts
		userData.CalendarAccounts[calendarAccountKey] = calendarAccount

		// Update user if exists
		_, err := db.UsersCollection.UpdateByID(
			context.Background(),
			userId,
			bson.M{"$set": userData},
		)
		if err != nil {
			logger.StdErr.Panicln(err)
		}
	}

	if exists, userId := listmonk.DoesUserExist(email); exists {
		listmonk.AddUserToListmonk(email, firstName, lastName, picture, userId)
	} else {
		listmonk.AddUserToListmonk(email, firstName, lastName, picture, nil)
	}

	// Set session variables
	session := sessions.Default(c)
	session.Set("userId", userId.Hex())
	session.Save()

	userData.Id = userId
	return userData
}

// @Summary Signs user out
// @Description Signs user out and deletes the session
// @Tags auth
// @Accept json
// @Produce json
// @Success 200
// @Router /auth/sign-out [post]
func signOut(c *gin.Context) {
	// Delete session
	session := sessions.Default(c)
	session.Delete("userId")
	session.Save()

	c.JSON(http.StatusOK, gin.H{})
}

// @Summary Gets whether the user is signed in or not
// @Description Returns a 401 error if user is not signed in, 200 if they are
// @Tags auth
// @Success 200
// @Failure 401 {object} responses.Error "Error object"
// @Router /auth/status [get]
func getStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{})
}
