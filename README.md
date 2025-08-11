<div align="center">

<img src="./logo.png" alt="Logo" width="150"/>

<br>

![GitHub License](https://img.shields.io/github/license/peprolinbot/tg-ha-door?style=for-the-badge&color=orange) ![GitHub go.mod Go version](https://img.shields.io/github/go-mod/go-version/peprolinbot/tg-ha-door?style=for-the-badge) [![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/peprolinbot/tg-ha-door/docker.yaml?style=for-the-badge&label=Docker%20Build)

</div>

# tg-ha-door

A simple Telegram bot written in [Go] with [go-telegram] to allow multiple people (e.g. your family) controlling a [Home Assistant] garage door.

## 🔧 Deploy it

### 🐳 Docker (Recommended)

This is quick, easy and simple. Just run these command replacing the variables as appropiate:

```bash
docker run -d --name tg-ha-door \
    -e TG_BOT_TOKEN=4839574812:AAFD39kkdpWt3ywyRZergyOLMaJhac60qc \
    -e TG_KEY_CHAT_ID=123456 \
    -e TG_LOG_CHAT_ID=654321 \
    -e HA_URL=http://homeassistant.local:8123 \
    -e HA_AUTH_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJOZXZlciBnb25uYSBnaXZlIHlvdSB1cCIsImlhdCI6MTIzNDU2NzgsImV4cCI6ODc2NTQzMjEsImhlbGxvIjoiR29vZCB0cnkifQ.VMlDF1fNNGkChoDc7vUgtazEq4xjSBcnj0sDr4Y5_-U \
    -e HA_DOOR_ENTITY_ID=cover.garage_door \
    -e DOOR_OPEN_CLOSE_TIME=60 \
    ghcr.io/peprolinbot/tg-ha-door
```

### ❄️ Nix package

If you use [NixOS] or have [Nix] installed, you can easily use the flake in this repo, which includes a package `tg-ha-door` (the default one) and a NixOS module. Be sure to set all the required environment variables. You can, for example, do:

```bash
nix run github:peprolinbot/tg-ha-door
```

### Environment Variables

| Name             | Description                                                                                                                                                                                                                           | Required? |
|-----------|-----------------------------------------------------------------------------------------------------------------------|----------|
| `TG_BOT_TOKEN` | The token you obtained from @BotFather ([more info](https://core.telegram.org/bots/tutorial#obtain-your-bot-token))         | Yes             |
| `TG_KEY_CHAT_ID` | Id of the chat (channel probably) whose members should be allowed to use the bot (no one else can)                                                       | Yes             |
| `TG_LOG_CHAT_ID` | Id of the channel where all the events will be logged       (feature will be disabled if not set)                                                               | No                |
| `HA_URL`  |  URL of the Home Assistant instance to use, e.g. `http://homeassistant.local:8123`                                                                                                 | Yes             |
| `HA_AUTH_TOKEN`  |  Token used to authenticate against the Home Assistant instance (Long-lived acces token is recommended)                                        | Yes              |
| `HA_DOOR_ENTITY_ID`  |  The door's (which must be of cover type) entity_id in Home Assistant, e.g. `cover.garage_door`                                                 | Yes              |
| `DOOR_OPEN_CLOSE_TIME`  |  The time (in seconds) to wait between the Open and Close commands when using the automatic Open and Close button                              | Yes              |

_**Tip💡:**_ You can use a [Home Assistant cover template](https://www.home-assistant.io/integrations/template/#cover) if your door isn't shown as a cover

#### Build the image

You will need [Nix] installed with flakes support

```bash
git clone https://github.com/peprolinbot/tg-ha-door
cd tg-ha-door
nix build .#docker # This will build for the current architecture
docker load < ./result
docker images # You should see the loaded image
```

## 💪🏻 Development

You will need [Nix] installed with flakes support, and the included `devShell` will take care of the rest

```bash
git clone https://github.com/peprolinbot/tg-ha-door
cd tg-ha-door
nix develop
go run . # For example
```

[Go]:https://go.dev/
[go-telegram]:https://github.com/go-telegram
[Home Assistant]: https://www.home-assistant.io
[Nix]: https://nixos.org/download/#download-nix
[NixOS]: https://nixos.org/download/#download-nix
