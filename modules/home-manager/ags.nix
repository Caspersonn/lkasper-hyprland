{ inputs, ... }: {
  flake.homeManagerModules.lkh-ags = { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
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

      lkasper-shell = pkgs.stdenv.mkDerivation {
        pname = "lkasper-shell";
        version = "1.0";
        src = ../../ags;

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
    in { home.packages = [ lkasper-shell ]; };
}
