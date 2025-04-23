package main

import (
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"schej.it/server/db"
	"schej.it/server/logger"
	"schej.it/server/routes"
	"schej.it/server/services/gcloud"
	"schej.it/server/slackbot"
	"schej.it/server/utils"
	"schej.it/server/services/auth"

	swaggerfiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	_ "schej.it/server/docs"
)

// @title Gatherly API
// @version 1.0
// @description This is the API for Gatherly!

// @host localhost:3002/api

func main() {
	// Set release flag
	release := flag.Bool("release", false, "Whether this is the release version of the server")
	flag.Parse()
	if *release {
		os.Setenv("GIN_MODE", "release")
		gin.SetMode(gin.ReleaseMode)
	} else {
		os.Setenv("GIN_MODE", "debug")
	}

	// Init logfile
	logFile, err := os.OpenFile("logs.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	gin.DefaultWriter = io.MultiWriter(logFile, os.Stdout)

	// Init logger
	logger.Init(logFile)

	// Load .env variables
	loadDotEnv()

	// Init router
	router := gin.New()
	router.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		var statusColor, methodColor, resetColor string
		if param.IsOutputColor() {
			statusColor = param.StatusCodeColor()
			methodColor = param.MethodColor()
			resetColor = param.ResetColor()
		}

		if param.Latency > time.Minute {
			param.Latency = param.Latency.Truncate(time.Second)
		}
		return fmt.Sprintf("%v |%s %3d %s| %13v | %15s |%s %-7s %s %#v\n%s",
			param.TimeStamp.Format("2006/01/02 15:04:05"),
			statusColor, param.StatusCode, resetColor,
			param.Latency,
			param.ClientIP,
			methodColor, param.Method, resetColor,
			param.Path,
			param.ErrorMessage,
		)
	}))
	router.Use(gin.Recovery())

	// Cors
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"https://verdant-coyote-455921-h1.web.app", "http://localhost:8080", "http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Content-Type", "Content-Length", "Accept-Encoding", "X-CSRF-Token", "Authorization", "accept", "origin", "Cache-Control", "X-Requested-With", "Cookie"},
		ExposeHeaders:    []string{"Content-Length", "Content-Type", "Set-Cookie"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Init database
	closeConnection := db.Init()
	defer closeConnection()

	// Init google cloud stuff
	closeTasks := gcloud.InitTasks()
	defer closeTasks()

	// Initialize Firebase
	logger.StdOut.Printf("Initializing Firebase authentication...")
	if err := auth.InitFirebase(); err != nil {
		logger.StdErr.Printf("Warning: Failed to initialize Firebase: %v", err)
		logger.StdErr.Printf("Authentication with Firebase will not work!")
	} else {
		logger.StdOut.Printf("Firebase authentication initialized successfully")
	}

	// Session
	store := cookie.NewStore([]byte("secret"))
	
	// Determine if running in development mode
	isDevelopment := os.Getenv("GIN_MODE") != "release"
	
	// Configure session cookies based on environment
	sessionOptions := sessions.Options{
		Path:     "/",
		MaxAge:   86400 * 7, // 7 days
		HttpOnly: true,
	}
	
	// In development, use SameSiteLaxMode with insecure cookies
	if isDevelopment {
		sessionOptions.SameSite = http.SameSiteLaxMode
		sessionOptions.Secure = false
		// When using different ports, the domain must be explicitly set for cookies to work
		sessionOptions.Domain = "localhost"
	} else {
		// In production, use SameSiteNoneMode with secure cookies
		sessionOptions.SameSite = http.SameSiteNoneMode
		sessionOptions.Secure = true
	}
	
	store.Options(sessionOptions)
	router.Use(sessions.Sessions("session", store))

	// Init routes
	apiRouter := router.Group("/api")
	routes.InitAuth(apiRouter)
	routes.InitUser(apiRouter)
	routes.InitEvents(apiRouter)
	routes.InitUsers(apiRouter)
	routes.InitAnalytics(apiRouter)
	slackbot.InitSlackbot(apiRouter)

	// Add a base URL health check endpoint
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Server is running",
		})
	})

	// Check if running in Cloud Run
	if os.Getenv("K_SERVICE") != "" {
		// Skip trying to serve frontend files when running in Cloud Run
		log.Println("Running in Cloud Run, skipping frontend file serving")
	} else {
		// Only try to load frontend files when running locally
		err = filepath.WalkDir("../frontend/dist", func(path string, d fs.DirEntry, err error) error {
			if !d.IsDir() && d.Name() != "index.html" {
				split := splitPath(path)
				newPath := filepath.Join(split[3:]...)
				router.StaticFile(fmt.Sprintf("/%s", newPath), path)
			}
			return nil
		})
		if err != nil {
			log.Printf("Warning: failed to walk directories: %s", err)
		}

		router.LoadHTMLFiles("../frontend/dist/index.html")
		router.NoRoute(noRouteHandler())
	}

	// Init swagger documentation
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

	// Add a health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"message": "Server is healthy",
		})
	})

	// Print startup information
	port := os.Getenv("PORT")
	if port == "" {
		port = "3002"
		log.Printf("No PORT environment variable found, using default port %s", port)
	} else {
		log.Printf("Using PORT environment variable: %s", port)
	}

	// Run server
	log.Printf("Starting server on port %s", port)
	router.Run(fmt.Sprintf(":%s", port))
}

// Load .env variables
func loadDotEnv() {
	err := godotenv.Load(".env")

	if err != nil {
		log.Println("Warning: Error loading .env file, using environment variables")
	}
}

func noRouteHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		params := gin.H{}
		path := c.Request.URL.Path

		// Determine meta tags based off URL
		if match := regexp.MustCompile(`\/e\/(\w+)`).FindStringSubmatchIndex(path); match != nil {
			// /e/:eventId
			eventId := path[match[2]:match[3]]
			event := db.GetEventByEitherId(eventId)

			if event != nil {
				title := fmt.Sprintf("%s - Schej", event.Name)
				params = gin.H{
					"title":   title,
					"ogTitle": title,
				}

				if len(utils.Coalesce(event.When2meetHref)) > 0 {
					params["ogImage"] = "/img/when2meetOgImage2.png"
				}
			}
		}

		c.HTML(http.StatusOK, "index.html", params)
	}
}

func splitPath(path string) []string {
	dir, last := filepath.Split(path)
	if dir == "" {
		return []string{last}
	}
	return append(splitPath(filepath.Clean(dir)), last)
}
