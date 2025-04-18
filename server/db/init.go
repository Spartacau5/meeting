package db

import (
	"context"
	"fmt"
	"os"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"schej.it/server/logger"
)

var Client *mongo.Client
var Db *mongo.Database
var EventsCollection *mongo.Collection
var UsersCollection *mongo.Collection
var DailyUserLogCollection *mongo.Collection
var FriendRequestsCollection *mongo.Collection
var SubmissionsCollection *mongo.Collection

func Init() func() {
	// Get MongoDB connection string from environment variable or use default
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		fmt.Println("MONGODB_URI environment variable not set, using default connection string")
		mongoURI = "mongodb://localhost:27017"
	} else {
		fmt.Println("Using MongoDB URI from environment variable")
	}
	
	fmt.Println("Connecting to MongoDB...")
	
	// Set client options
	clientOptions := options.Client().ApplyURI(mongoURI)
	
	// Connect to MongoDB
	client, err := mongo.Connect(context.TODO(), clientOptions)
	
	if err != nil {
		fmt.Println("Failed to connect to MongoDB:", err)
		logger.StdErr.Fatalln(err)
	}
	
	// Check the connection
	err = client.Ping(context.TODO(), nil)
	
	if err != nil {
		fmt.Println("Failed to ping MongoDB:", err)
		logger.StdErr.Fatalln(err)
	}
	
	fmt.Println("Connected to MongoDB!")
	
	// Global database
	Db = client.Database("gatherly")
	EventsCollection = Db.Collection("events")
	UsersCollection = Db.Collection("users")
	DailyUserLogCollection = Db.Collection("dailyuserlogs")
	FriendRequestsCollection = Db.Collection("friendrequests")
	SubmissionsCollection = Db.Collection("submissions")

	// Set up a ping every 30 seconds to prevent the connection from timing out

	// Return a function to close the connection
	return func() {
		client.Disconnect(context.TODO())
	}
}
