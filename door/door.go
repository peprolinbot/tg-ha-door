package door

import (
	"log/slog"
	"os"
	"strconv"
	"time"

	homeassistant "github.com/mutablelogic/go-client/pkg/homeassistant"
)

// All are public in case we want to write about them
var DoorOpenCloseTimeStr string
var DoorOpenCloseTimeInt int
var DoorOpenCloseTime time.Duration

var doorEntityId string

var haClient *homeassistant.Client

func init() {
	var err error

	DoorOpenCloseTimeStr = os.Getenv("DOOR_OPEN_CLOSE_TIME")
	DoorOpenCloseTimeInt, err = strconv.Atoi(DoorOpenCloseTimeStr)
	if err != nil {
		slog.Error("Error converting DOOR_OPEN_CLOSE_TIME to int:", err)
		os.Exit(1)
	}
	DoorOpenCloseTime = time.Duration(DoorOpenCloseTimeInt)

	var exists bool
	doorEntityId, exists = os.LookupEnv("HA_DOOR_ENTITY_ID")
	if !exists {
		slog.Error("Please set the HA_DOOR_ENTITY_ID env var")
		os.Exit(1)
	}

	haClient, err = homeassistant.New(os.Getenv("HA_URL")+"/api", os.Getenv("HA_AUTH_TOKEN"))

	if err != nil {
		slog.Error("Error connecting to HASS (make sure to set HA_URL and HA_AUTH_TOKEN):", "error", err)
		os.Exit(1)
	}
}

func Open() error {
	slog.Info("Opening the door...")
	_, err := haClient.Call("open_cover", doorEntityId)

	if err != nil {
		slog.Warn("Error while opening the door:", "error", err)
	}

	return err
}

func Close() error {
	slog.Info("Closing the door...")
	_, err := haClient.Call("close_cover", doorEntityId)

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

	if state, err := haClient.State(doorEntityId); err != nil {
		slog.Warn("Error while getting the door state:", "error", err)
		return "error", err
	} else {
		slog.Info("Got door state:", "state", state.State)
		return state.State, err
	}
}
