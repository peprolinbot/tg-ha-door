{
  description = "A simple Telegram bot to allow controlling a Home Assistant garage door";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flocken = {
      url = "github:mirkolenz/flocken/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flocken,
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
    });
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [go gopls gotools go-tools];
      };
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.tg-ha-door);
  };
}
