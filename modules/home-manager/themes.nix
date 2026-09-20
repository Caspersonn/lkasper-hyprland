{ inputs, ... }:
{
  flake.homeManagerModules.lkh-themes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lkh = import ../../lib/themes.nix { inherit lib inputs; };

      inherit (lkh)
        wallpaperRoot
        pairs
        pairNames
        modes
        dataRoot
        themeRoot
        stateDir
        claimed
        paletteOf
        defaultPair
        defaultMode
        themeFiles
        ;

      inherit (lkh.validation)
        unpaired
        duplicated
        missingImages
        missingPalettes
        malformed
        ;

      bundleFiles = lib.listToAttrs (
        lib.concatMap (
          pair:
          lib.concatMap (
            mode:
            lib.mapAttrsToList (name: content: {
              name = "${themeRoot}/${pair}/${mode}/${name}";
              value = {
                text = content;
              };
            }) (themeFiles pair mode)
          ) modes
        ) pairNames
      );

      wallpaperFiles = lib.listToAttrs (
        map (image: {
          name = "${dataRoot}/wallpapers/${image}";
          value = {
            source = wallpaperRoot + "/${image}";
          };
        }) claimed
      );

      pairsIndex = {
        "${dataRoot}/pairs.json".text = builtins.toJSON pairs;
      };

      themeCommands = import ../../lib/theme-commands.nix { inherit pkgs lib lkh; };

      inherit (themeCommands)
        migrateCurrent
        theme-apply
        theme-state
        theme-toggle
        theme-switch
        ;
    in
    {
      options."lkasper-hyprland" = (import ../../config.nix lib).lkasperHyprlandOptions;

      imports = [ inputs.nix-colors.homeManagerModules.default ];

      config = {
        assertions = [
          {
            assertion = malformed == [ ];
            message = "lkh-themes: wallpaper pairs must declare exactly a light and a dark member; malformed: ${toString malformed}";
          }
          {
            assertion = unpaired == [ ];
            message = "lkh-themes: wallpaper images are not a member of any pair in wallpapers/pairs.nix: ${toString unpaired}";
          }
          {
            assertion = duplicated == [ ];
            message = "lkh-themes: wallpaper images are claimed by more than one pair role: ${toString duplicated}";
          }
          {
            assertion = missingImages == [ ];
            message = "lkh-themes: wallpapers/pairs.nix references images that do not exist: ${toString missingImages}";
          }
          {
            assertion = missingPalettes == [ ];
            message = "lkh-themes: no committed palette for: ${toString missingPalettes} (run wallpapers/regenerate-palettes.sh)";
          }
        ];

        colorScheme = {
          slug = "${defaultPair}-${defaultMode}";
          name = "${defaultPair} ${defaultMode}";
          author = "wallust (wallpaper-derived)";
          palette = paletteOf pairs.${defaultPair}.${defaultMode};
        };

        gtk = {
          enable = true;
          iconTheme = {
            name = "Gruvbox-Plus-Dark";
            package = pkgs.gruvbox-plus-icons;
          };
        };

        home.packages = [
          pkgs.libadwaita
          theme-apply
          theme-state
          theme-toggle
          theme-switch
        ];

        home.file = bundleFiles // wallpaperFiles // pairsIndex;

        home.activation.lkhThemeCurrent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "${stateDir}"
          run mkdir -p "$HOME/.config/btop/themes"
          run mkdir -p "$HOME/.config/ghostty/themes"
          run mkdir -p "$HOME/.config/gtk-3.0"
          run mkdir -p "$HOME/.config/gtk-4.0"
          run mkdir -p "$HOME/.config/opencode/themes"
          run mkdir -p "$HOME/.config/clipse"

          run rm -f "$HOME/.config/hypr/theme.conf"

          if command -v systemctl >/dev/null 2>&1; then
            run systemctl --user unset-environment GTK_THEME ADW_DISABLE_PORTAL || true
          fi

          ${migrateCurrent}

          if [ ! -L "${stateDir}/current" ] || [ ! -d "${stateDir}/current" ]; then
            run ln -sfn "$HOME/${themeRoot}/${defaultPair}/${defaultMode}" "${stateDir}/current"
          fi

          if [ ! -f "${stateDir}/state" ]; then
            run printf '%s %s\n' "${defaultPair}" "${defaultMode}" > "${stateDir}/state"
          fi

          run ln -sfn "${stateDir}/current/btop.theme" "$HOME/.config/btop/themes/lkh-runtime.theme"
          run ln -sfn "${stateDir}/current/ghostty" "$HOME/.config/ghostty/themes/lkh-runtime"
          run ln -sfn "${stateDir}/current/starship.toml" "$HOME/.config/starship.toml"
          run ln -sfn "${stateDir}/current/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
          run ln -sfn "${stateDir}/current/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
          run ln -sfn "${stateDir}/current/opencode.json" "$HOME/.config/opencode/themes/opencode.json"
          run ln -sfn "${stateDir}/current/clipse-theme.json" "$HOME/.config/clipse/custom_theme.json"
        '';
      };
    };
}
