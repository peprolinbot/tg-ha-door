package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"

	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
	"github.com/go-telegram/ui/keyboard/reply"

	"github.com/peprolinbot/tg-ha-door/door"
)

var keyChatId string
var logChatId string

var doorReplyKeyboard *reply.ReplyKeyboard

var doorMenuStrings = struct {
	OpenAndClose,
	Open,
	Close,
	State string
}{
	OpenAndClose: "Abrir y cerrar (" + door.DoorOpenCloseTimeStr + "s)",
	Open:         "Abrir",
	Close:        "Cerrar",
	State:        "Estado",
}

func initDoorReplyKeyboard(b *bot.Bot) {
	doorReplyKeyboard = reply.New(
		reply.WithPrefix("main_menu"),
	).
		Button(doorMenuStrings.OpenAndClose, b, bot.MatchTypeExact, onDoorReplyKeyboardSelect).
		Row().
		Button(doorMenuStrings.Open, b, bot.MatchTypeExact, onDoorReplyKeyboardSelect).
		Button(doorMenuStrings.Close, b, bot.MatchTypeExact, onDoorReplyKeyboardSelect).
		Row().
		Button(doorMenuStrings.State, b, bot.MatchTypeExact, onDoorReplyKeyboardSelect)
}

func onDoorReplyKeyboardSelect(ctx context.Context, b *bot.Bot, update *models.Update) {
	var answer string

	switch update.Message.Text {
	case doorMenuStrings.OpenAndClose:
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID:    update.Message.Chat.ID,
			Text:      fmt.Sprintf("Abriendo puerta\\.\\.\\. \\(Se cerrará en %ds\\)", door.DoorOpenCloseTimeInt),
			ParseMode: models.ParseModeMarkdown,
		})
		door.OpenAndClose()
		answer = "Cerrando puerta\\.\\.\\."
	case doorMenuStrings.Open:
		door.Open()
		answer = "Abriendo puerta\\.\\.\\."
	case doorMenuStrings.Close:
		door.Close()
		answer = "Cerrando puerta\\.\\.\\."
	case doorMenuStrings.State:
		state, _ := door.State()

		answer = fmt.Sprintf("El estado de la puerta es *%s*", state)
	}

	b.SendMessage(ctx, &bot.SendMessageParams{
		ChatID:    update.Message.Chat.ID,
		Text:      answer,
		ParseMode: models.ParseModeMarkdown,
	})
}

func sendmenuHandler(ctx context.Context, b *bot.Bot, update *models.Update) {
	b.SendMessage(ctx, &bot.SendMessageParams{
		ChatID:      update.Message.Chat.ID,
		Text:        "El menú ha sido actualizado",
		ReplyMarkup: doorReplyKeyboard,
	})
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	var exists bool
	keyChatId, exists = os.LookupEnv("TG_KEY_CHAT_ID")
	if !exists {
		slog.Error("Please set the TG_KEY_CHAT_ID env var")
		os.Exit(1)
	}
	logChatId, exists = os.LookupEnv("TG_LOG_CHAT_ID")
	if !exists {
		slog.Error("Please set the TG_LOG_CHAT_ID env var")
		os.Exit(1)
	}

	opts := []bot.Option{
		bot.WithMiddlewares(requireAuth),
		bot.WithDefaultHandler(sendmenuHandler),
		bot.WithMessageTextHandler("/sendmenu", bot.MatchTypeExact, sendmenuHandler),
	}

	b, err := bot.New(os.Getenv("TG_BOT_TOKEN"), opts...)
	if nil != err {
		slog.Error("Error connecting to Telegram (make sure to set TG_BOT_TOKEN and other TG_* env vars):", "error", err)
		os.Exit(1)
	}

	initDoorReplyKeyboard(b)

	slog.Info("The Bot is ready to rock!")
	b.Start(ctx)

	slog.Info("Bye!")
}

func requireAuth(next bot.HandlerFunc) bot.HandlerFunc {
	return func(ctx context.Context, b *bot.Bot, update *models.Update) {

		if update.Message != nil {
			_, err := b.GetChatMember(ctx, &bot.GetChatMemberParams{
				ChatID: keyChatId,
				UserID: update.Message.From.ID,
			})

			authorized := err == nil

			if authorized {
				slog.Info("Authorized message:", "chatId", update.Message.From.ID, "text", update.Message.Text)
				next(ctx, b, update)
			} else {
				slog.Warn("Unathorized message:", "chatId", update.Message.From.ID, "text", update.Message.Text)
			}
		}
	}
}
