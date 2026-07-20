{ inputs, ... }:

{
  flake.homeManagerModules.lkh-ags =
    { pkgs, ... }:

    let
      system = pkgs.stdenv.hostPlatform.system;
      agsPkgs = inputs.ags.packages.${system};
      solttyPkg = inputs.soltty.packages.${system}.soltty;

      astalLibs = with agsPkgs; [
        astal4
        io
        apps
        notifd
        hyprland
        mpris
        battery
        network
        bluetooth
        wireplumber
        tray
      ];

      runtimeLibs = astalLibs ++ [
        pkgs.gtk4
        pkgs.glib
        pkgs.graphene
        pkgs.cairo
        pkgs.pango
        pkgs.gdk-pixbuf
        pkgs.librsvg
        pkgs.harfbuzz
        pkgs.gobject-introspection

        pkgs.networkmanager
      ];

      allOutputs = pkg: map (outputName: pkg.${outputName}) (pkg.outputs or [ "out" ]);

      typelibOutputs = pkgs.lib.concatMap allOutputs runtimeLibs;

      typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" typelibOutputs;

      libraryPath = pkgs.lib.makeLibraryPath runtimeLibs;

      dataPath = pkgs.lib.makeSearchPath "share" typelibOutputs;

      lkasper-shell = pkgs.stdenvNoCC.mkDerivation {
        pname = "lkasper-shell";
        version = "1.0";
        src = ../../ags;

        nativeBuildInputs = [
          agsPkgs.default
          pkgs.makeWrapper
          pkgs.glib
        ];

        buildInputs = runtimeLibs ++ [
          pkgs.gjs
        ];

        installPhase = ''
  runHook preInstall

  mkdir -p $out/bin
  mkdir -p $out/share/glib-2.0/schemas

  ags bundle \
  app.ts \
  $out/bin/.lkasper-shell-unwrapped

  # Collect all GSettings schema XML files from runtime dependencies.
  # nixpkgs installs schemas under share/gsettings-schemas/<name>/glib-2.0/schemas
  # (via the glib setup hook), not the plain share/glib-2.0/schemas layout, so
  # scan both. Missing globs stay literal and fail the -d test harmlessly.
  for dependency in ${pkgs.lib.escapeShellArgs typelibOutputs}; do
    for schemaDir in \
      "$dependency"/share/gsettings-schemas/*/glib-2.0/schemas \
      "$dependency"/share/glib-2.0/schemas; do

      if [ -d "$schemaDir" ]; then
        for schema in "$schemaDir"/*.gschema.xml; do
          if [ -e "$schema" ]; then
            ln -sf "$schema" \
            "$out/share/glib-2.0/schemas/$(basename "$schema")"
          fi
        done
      fi
    done
  done

  # Compile the collected schemas into one deterministic schema database.
  glib-compile-schemas $out/share/glib-2.0/schemas

  makeWrapper \
  $out/bin/.lkasper-shell-unwrapped \
  $out/bin/lkasper-shell \
  --prefix GI_TYPELIB_PATH : "${typelibPath}" \
  --prefix LD_LIBRARY_PATH : "${libraryPath}" \
  --prefix XDG_DATA_DIRS : "$out/share:${dataPath}" \
  --set GSETTINGS_SCHEMA_DIR "$out/share/gsettings-schemas/$name/glib-2.0/schemas" \
  --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
  --set SOLTTY_BIN "${solttyPkg}/bin/soltty"

  runHook postInstall
        '';
      };
    in
    {
      home.packages = [
        lkasper-shell
        agsPkgs.default
        solttyPkg
        pkgs.brightnessctl
        pkgs.hyprsunset
      ];

      systemd.user.services.lkasper-shell = {
        Unit = {
          Description = "LKasper AGS shell";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          StartLimitIntervalSec = 30;
          StartLimitBurst = 3;
        };

        Service = {
          Type = "simple";
          ExecStart = "${lkasper-shell}/bin/lkasper-shell";
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install.WantedBy = [
          "graphical-session.target"
        ];
      };
    };
}
