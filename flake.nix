{
  description = "A simple Telegram bot to allow controlling a Home Assistant garage door";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flocken = {
      url = "github:mirkolenz/flocken/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    search = {
      url = "github:NuschtOS/search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flocken,
    search,
  }: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in rec {
      tg-ha-door = pkgs.buildGoModule {
        pname = "tg-ha-door";
        inherit version;
        src = ./.;
        vendorHash = "sha256-n3XbhzPd75DCW8KNRqb/wdp83iKUnf/1rQRNq5dRhbk=";
      };

      default = tg-ha-door;

      docker = pkgs.dockerTools.buildLayeredImage {
        name = "tg-ha-door";
        tag = "${version}";
        contents = with pkgs; [cacert tg-ha-door];
        config = {Entrypoint = ["tg-ha-door"];};
      };
    });

    legacyPackages = forAllSystems (system: {
      docker-manifest = flocken.legacyPackages.${system}.mkDockerManifest {
        github = {
          enable = true;
          token = "$GH_TOKEN";
        };
        inherit version;
        images = with self.packages; [
          x86_64-linux.docker
          aarch64-linux.docker
        ];
        autoTags = {
          major = false;
          majorMinor = false;
        };
      };

      options-search = search.packages.${system}.mkSearch {
        title = "tg-ha-door Options Search";
        modules = [self.nixosModules.default {_module.args = {pkgs = nixpkgsFor.${system};};}];
        urlPrefix = "https://github.com/peprolinbot/tg-ha-door/blob/main/";
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [go gopls gotools go-tools];
      };
    });

    nixosModules = rec {
      default = tg-ha-door;
      tg-ha-door = {
        lib,
        pkgs,
        config,
        ...
      }:
        with lib; let
          cfg = config.services.tg-ha-door;
        in {
          options.services.tg-ha-door = {
            enable = mkEnableOption "tg-ha-door";
            package = mkPackageOption self.packages.${pkgs.system} "tg-ha-door" {};
            settings = mkOption {
              description = ''
                Your tg-ha-door configuration. Will be set to the environment variables in [the README](https://github.com/peprolinbot/tg-ha-door/tree/main?tab=readme-ov-file#environment-variables) for definitions and values.
              '';
              example = lib.literalExpression ''
                {
                  TG_BOT_TOKEN = "4839574812:AAFD39kkdpWt3ywyRZergyOLMaJhac60qc";
                  TG_KEY_CHAT_ID = "123456";
                  TG_LOG_CHAT_ID = "654321";
                  HA_URL = "http://homeassistant.local:8123";
                  HA_AUTH_TOKEN = "eyJhbGciO...U";
                  HA_DOOR_ENTITY_ID = "cover.garage_door";
                  DOOR_OPEN_CLOSE_TIME = 60;
                }
              '';
              type = types.submodule {
                options = {
                  TG_BOT_TOKEN = mkOption {
                    description = ''
                      The token you obtained from @BotFather ([more info](https://core.telegram.org/bots/tutorial#obtain-your-bot-token))
                    '';
                    type = types.str;
                    example = "4839574812:AAFD39kkdpWt3ywyRZergyOLMaJhac60qc";
                  };
                  TG_KEY_CHAT_ID = mkOption {
                    description = ''
                      Id of the chat (channel probably) whose members should be allowed to use the bot (no one else can)
                    '';
                    type = types.str;
                    example = "123456";
                  };
                  TG_LOG_CHAT_ID = mkOption {
                    description = ''
                      Id of the channel where all the events will be logged (feature will be disabled if not set)
                    '';
                    type = types.str;
                    example = "654321";
                    default = "";
                  };
                  HA_URL = mkOption {
                    description = ''
                      URL of the Home Assistant instance to use
                    '';
                    type = types.str;
                    example = "http://homeassistant.local:8123";
                  };
                  HA_AUTH_TOKEN = mkOption {
                    description = ''
                      Token used to authenticate against the Home Assistant instance (Long-lived acces token is recommended)
                    '';
                    type = types.str;
                    example = "eyJhbGciO...U";
                  };
                  HA_DOOR_ENTITY_ID = mkOption {
                    description = ''
                      The door's (which must be of cover type) entity_id in Home Assistant
                    '';
                    type = types.str;
                    example = "cover.garage_door";
                  };
                  DOOR_OPEN_CLOSE_TIME = mkOption {
                    description = ''
                      The time (in seconds) to wait between the `Open` and `Close` commands when using the automatic `Open and Close` button
                    '';
                    type = types.ints.positive;
                    example = 60;
                    apply = toString;
                  };
                };
              };
            };
          };

          config = mkIf cfg.enable {
            systemd.services.tg-ha-door = {
              description = "A simple Telegram bot to allow controlling a Home Assistant garage door";
              documentation = ["https://github.com/peprolinbot/tg-ha-door"];
              wantedBy = ["multi-user.target"];
              after = ["network.target"];
              environment = cfg.settings;
              serviceConfig = {
                User = "tg-ha-door";
                Group = "tg-ha-door";
                DynamicUser = true;
                StateDirectory = "tg-ha-door";
                ExecStart = "${cfg.package}/bin/tg-ha-door'";
                Restart = "on-failure";
              };
            };
          };
        };
    };
  };
}
