/* The /analytics group contains all the routes to track analytics */
package routes

import (
	"context"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"schej.it/server/db"
	"schej.it/server/logger"
	"schej.it/server/models"
	"schej.it/server/slackbot"
)

func InitAnalytics(router *gin.RouterGroup) {
	analyticsRouter := router.Group("/analytics")

	analyticsRouter.POST("/scanned-poster", scannedPoster)
	analyticsRouter.GET("/stats", getStats)
}

// Handler for GET /analytics/stats
func getStats(c *gin.Context) {
	userCount, err := db.UsersCollection.CountDocuments(context.Background(), bson.M{})
	if err != nil {
		logger.StdErr.Printf("Error counting users: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve user count"})
		return
	}

	eventCount, err := db.EventsCollection.CountDocuments(context.Background(), bson.M{})
	if err != nil {
		logger.StdErr.Printf("Error counting events: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve event count"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"userCount":  userCount,
		"eventCount": eventCount,
	})
}

// @Summary Notifies us when poster QR code has been scanned
// @Tags analytics
// @Accept json
// @Produce json
// @Param payload body object{url=string,location=models.Location} true "Object containing the location that poster was scanned from and the url that was scanned"
// @Success 200
// @Router /analytics/scanned-poster [post]
func scannedPoster(c *gin.Context) {
	payload := struct {
		Url      string           `json:"url" binding:"required"`
		Location *models.Location `json:"location"`
	}{}
	if err := c.BindJSON(&payload); err != nil {
		return
	}

	if payload.Location != nil {
		slackbot.SendTextMessage(
			fmt.Sprintf(":face_with_monocle: Poster was scanned :face_with_monocle:\n*Location:* %s, %s, %s\n*URL:* %s",
				payload.Location.City,
				payload.Location.State,
				payload.Location.CountryCode,
				payload.Url,
			),
		)
	} else {
		slackbot.SendTextMessage(
			fmt.Sprintf(":face_with_monocle: Poster was scanned :face_with_monocle:\n*URL:* %s", payload.Url),
		)
	}

	c.JSON(http.StatusOK, gin.H{})
}
