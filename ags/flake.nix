{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      agsPkgs = inputs.ags.packages.${system};
      agsNixpkgs = inputs.ags.inputs.nixpkgs.legacyPackages.${system};

      astalLibs = with agsPkgs; [
        astal4
        io
        hyprland
        mpris
        battery
        network
        bluetooth
        wireplumber
        tray
      ];
    in {
      default = pkgs.stdenv.mkDerivation rec {
        pname = "lkasper-shell";
        version = "1.0";
        src = ./.;

        nativeBuildInputs = [
          agsPkgs.default
          agsNixpkgs.wrapGAppsHook4
          agsNixpkgs.gobject-introspection
        ];

        buildInputs = astalLibs
          ++ [ pkgs.gtk4 pkgs.gjs pkgs.glib pkgs.gnome-themes-extra ];

        installPhase = ''
          mkdir -p $out/bin
          ags bundle app.ts $out/bin/lkasper-shell
        '';
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.pnpm
          (inputs.ags.packages.${system}.default.override {
            extraPackages = [ ];
          })
        ];
      };
    });
  };
}
