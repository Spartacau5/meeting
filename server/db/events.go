package db

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AddGoogleMeetLinkToEvent adds a Google Meet link to an event
func AddGoogleMeetLinkToEvent(eventId string, meetLink string, startTime string, endTime string) error {
	objId, err := primitive.ObjectIDFromHex(eventId)
	if err != nil {
		return err
	}

	filter := bson.M{"_id": objId}
	update := bson.M{
		"$set": bson.M{
			"meetLink":        meetLink,
			"meetStartTime":   startTime,
			"meetEndTime":     endTime,
			"updatedAt":       time.Now(),
		},
	}

	_, err = EventsCollection.UpdateOne(context.Background(), filter, update)
	return err
} 