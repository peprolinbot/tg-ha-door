package door

import (
	"log/slog"
	"os"
	"strconv"
	"time"

	ga "saml.dev/gome-assistant"
)

// Configuration variables
var doorEntityId = os.Getenv("HA_DOOR_ENTITY_ID")

// All are public in case we want to write about them
var DoorOpenCloseTimeStr = os.Getenv("DOOR_OPEN_CLOSE_TIME")
var DoorOpenCloseTimeInt int
var DoorOpenCloseTime time.Duration

var app *ga.App

func init() {
	var err error

	DoorOpenCloseTimeInt, err = strconv.Atoi(DoorOpenCloseTimeStr)
	if err != nil {
		slog.Error("Error converting DOOR_OPEN_CLOSE_TIME to int:", err)
		return
	}
	DoorOpenCloseTime = time.Duration(DoorOpenCloseTimeInt)

	app, err = ga.NewApp(ga.NewAppRequest{
		URL:         os.Getenv("HA_URL"),
		HAAuthToken: os.Getenv("HA_AUTH_TOKEN"),
	})

	if err != nil {
		slog.Error("Error connecting to HASS:", "error", err)
		os.Exit(1)
	}
}

func Open() error {
	slog.Info("Opening the door...")
	err := app.GetService().Cover.Open(doorEntityId)

	if err != nil {
		slog.Warn("Error while opening the door:", "error", err)
	}

	return err
}

func Close() error {
	slog.Info("Closing the door...")
	err := app.GetService().Cover.Close(doorEntityId)

	if err != nil {
		slog.Warn("Error while closing the door:", "error", err)
	}

	return err
}

func OpenAndClose() error {
	err := Open()

	if err != nil {
		return err
	}

	time.Sleep(DoorOpenCloseTime * time.Second)

	err = Close()

	return err
}

func State() (string, error) {
	slog.Debug("Getting door state...")

	state, err := app.GetState().Get(doorEntityId)

	if err != nil {
		slog.Warn("Error while getting the door state:", "error", err)
	} else {
		slog.Info("Got door state:", "state", state.State)
	}

	return state.State, err
}
