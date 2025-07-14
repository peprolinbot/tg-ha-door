{
  description = "A simple Telegram bot to allow controlling a Home Assistant garage door";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";

  outputs = {
    self,
    nixpkgs,
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
        vendorHash = "sha256-OafU9iQpzYMQE3nra3OczdUGb8BLfavXXIDLKHn9MBw=";
      };

      docker = pkgs.dockerTools.buildLayeredImage {
        name = "tg-ha-door";
        tag = "v${version}";
        contents = with pkgs; [cacert tg-ha-door];
        config = {Entrypoint = ["tg-ha-door"];};
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
