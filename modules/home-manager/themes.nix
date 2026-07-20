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
      # Palettes are generated from each wallpaper by
      # wallpapers/regenerate-palettes.sh and committed as base16 JSON
      # (base00-base0F, bare hex). No static theme is picked any more.
      paletteDir = ../../wallpapers/palettes;
      paletteNames = map (n: lib.removeSuffix ".json" n) (
        builtins.filter (n: lib.hasSuffix ".json" n) (builtins.attrNames (builtins.readDir paletteDir))
      );
      palettes = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = builtins.fromJSON (builtins.readFile (paletteDir + "/${name}.json"));
        }) paletteNames
      );

      # Default active wallpaper; the runtime picker overrides current/theme.name.
      activeWallpaper = "wood-dark";
      activePalette = palettes.${activeWallpaper};

      # A nix-colors-shaped colorScheme built from a wallpaper palette.
      mkColorScheme = name: palette: {
        slug = name;
        name = name;
        author = "wallust (wallpaper-derived)";
        inherit palette;
      };

      # Wallpaper images exposed at a runtime path, so the picker + theme-switch
      # can find them by slug (filename without extension).
      wallpaperImages = builtins.filter (
        n: lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n || lib.hasSuffix ".jpeg" n
      ) (builtins.attrNames (builtins.readDir ../../wallpapers));
      wallpaperFiles = builtins.listToAttrs (
        map (f: {
          name = ".local/share/lkasper-hyprland/wallpapers/${f}";
          value = {
            source = ../../wallpapers + "/${f}";
          };
        }) wallpaperImages
      );

      # Runtime wallpaper + theme switcher (invoked by the picker and a keybind).
      # Sets the wallpaper, repoints the active-theme pointer (AGS watches it and
      # recolours live), and recolours Hyprland borders from the new palette.
      theme-switch = pkgs.writeShellApplication {
        name = "theme-switch";
        runtimeInputs = [
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          name="''${1:-}"
          if [ -z "$name" ]; then
            echo "usage: theme-switch <wallpaper>" >&2
            exit 1
          fi
          share="$HOME/.local/share/lkasper-hyprland"
          wp=""
          for f in "$share/wallpapers/$name".*; do
            if [ -e "$f" ]; then wp="$f"; break; fi
          done
          if [ -z "$wp" ]; then
            echo "theme-switch: unknown wallpaper '$name'" >&2
            exit 1
          fi
          pal="$share/themes/$name/colors.json"

          # wallpaper (hyprpaper IPC)
          hyprctl hyprpaper preload "$wp" >/dev/null 2>&1 || true
          hyprctl hyprpaper wallpaper ",$wp" >/dev/null 2>&1 || true

          # active-theme pointer -> AGS recolours via its file monitor
          mkdir -p "$HOME/.config/lkasper-hyprland/current"
          printf '%s\n' "$name" > "$HOME/.config/lkasper-hyprland/current/theme.name"

          # Hyprland borders from the new palette (active = wallpaper accent)
          if [ -f "$pal" ]; then
            ab="$(jq -r '.accent // .base0D // empty' "$pal")"
            ib="$(jq -r '.base09 // empty' "$pal")"
            if [ -n "$ab" ]; then
              hyprctl keyword general:col.active_border "rgba(''${ab}ee)" >/dev/null 2>&1 || true
            fi
            if [ -n "$ib" ]; then
              hyprctl keyword general:col.inactive_border "rgba(''${ib}aa)" >/dev/null 2>&1 || true
            fi
          fi
        '';
      };

      runtimeThemeFiles = builtins.foldl' (
        acc: name:
        let
          palette = palettes.${name};
        in
        acc
        // {
          ".local/share/lkasper-hyprland/themes/${name}/colors.json".text = builtins.toJSON (
            palette
            // {
              background = "#${palette.base00}";
              foreground = "#${palette.base05}";
              # Wallpaper-derived accent (bare hex), decoupled from the fixed
              # ANSI base0D so the bar/borders visibly track the wallpaper.
              accent = palette.accent or palette.base0D;
              # Fully wallpaper-driven AGS UI: replace the ANSI-anchored accent
              # slots (identical across wallpapers) with the per-wallpaper accent
              # triple. Only colors.json (read by AGS) is remapped; the terminal
              # keeps faithful base16 via colorScheme, so red=red etc. in shells.
              base0A = palette.accent2 or palette.base0A;
              base0B = palette.accent3 or palette.base0B;
              base0C = palette.accent2 or palette.base0C;
              base0D = palette.accent or palette.base0D;
              base0E = palette.accent3 or palette.base0E;
              base0F = palette.accent or palette.base0F;
            }
          );
        }
      ) { } paletteNames;
    in
    {
      options."lkasper-hyprland" = (import ../../config.nix lib).lkasperHyprlandOptions;

      imports = [ inputs.nix-colors.homeManagerModules.default ];

      config = {
        colorScheme = mkColorScheme activeWallpaper activePalette;

        gtk = {
          enable = true;
          iconTheme = {
            name = "Gruvbox-Plus-Dark";
            package = pkgs.gruvbox-plus-icons;
          };
        };

        home.packages = [
          pkgs.libadwaita
          theme-switch
        ];

        home.file = {
          ".config/opencode/themes/opencode.json".text = ''
            {
              "$schema": "https://opencode.ai/theme.json",
              "theme": {
                "primary": "#${config.colorScheme.palette.base0D}",
                "secondary": "#${config.colorScheme.palette.base0E}",
                "accent": "#${config.colorScheme.palette.base0C}",
                "error": "#${config.colorScheme.palette.base08}",
                "warning": "#${config.colorScheme.palette.base09}",
                "success": "#${config.colorScheme.palette.base0B}",
                "info": "#${config.colorScheme.palette.base0D}",
                "text": "#${config.colorScheme.palette.base05}",
                "textMuted": "#${config.colorScheme.palette.base04}",
                "background": "#${config.colorScheme.palette.base00}",
                "backgroundPanel": "#${config.colorScheme.palette.base01}",
                "backgroundElement": "#${config.colorScheme.palette.base02}",
                "border": "#${config.colorScheme.palette.base03}",
                "borderActive": "#${config.colorScheme.palette.base0D}",
                "borderSubtle": "#${config.colorScheme.palette.base02}",
                "diffAdded": "#${config.colorScheme.palette.base0B}",
                "diffRemoved": "#${config.colorScheme.palette.base08}",
                "diffContext": "#${config.colorScheme.palette.base04}",
                "diffHunkHeader": "#${config.colorScheme.palette.base0D}",
                "diffHighlightAdded": "#${config.colorScheme.palette.base0B}",
                "diffHighlightRemoved": "#${config.colorScheme.palette.base08}",
                "diffAddedBg": "#${config.colorScheme.palette.base01}",
                "diffRemovedBg": "#${config.colorScheme.palette.base01}",
                "diffContextBg": "#${config.colorScheme.palette.base00}",
                "diffLineNumber": "#${config.colorScheme.palette.base03}",
                "diffAddedLineNumberBg": "#${config.colorScheme.palette.base01}",
                "diffRemovedLineNumberBg": "#${config.colorScheme.palette.base01}",
                "markdownText": "#${config.colorScheme.palette.base05}",
                "markdownHeading": "#${config.colorScheme.palette.base0D}",
                "markdownLink": "#${config.colorScheme.palette.base0E}",
                "markdownLinkText": "#${config.colorScheme.palette.base0C}",
                "markdownCode": "#${config.colorScheme.palette.base0B}",
                "markdownBlockQuote": "#${config.colorScheme.palette.base04}",
                "markdownEmph": "#${config.colorScheme.palette.base09}",
                "markdownStrong": "#${config.colorScheme.palette.base0A}",
                "markdownHorizontalRule": "#${config.colorScheme.palette.base03}",
                "markdownListItem": "#${config.colorScheme.palette.base0D}",
                "markdownListEnumeration": "#${config.colorScheme.palette.base0C}",
                "markdownImage": "#${config.colorScheme.palette.base0E}",
                "markdownImageText": "#${config.colorScheme.palette.base0C}",
                "markdownCodeBlock": "#${config.colorScheme.palette.base0B}",
                "syntaxComment": "#${config.colorScheme.palette.base03}",
                "syntaxKeyword": "#${config.colorScheme.palette.base0E}",
                "syntaxFunction": "#${config.colorScheme.palette.base0D}",
                "syntaxVariable": "#${config.colorScheme.palette.base08}",
                "syntaxString": "#${config.colorScheme.palette.base0B}",
                "syntaxNumber": "#${config.colorScheme.palette.base09}",
                "syntaxType": "#${config.colorScheme.palette.base0A}",
                "syntaxOperator": "#${config.colorScheme.palette.base05}",
                "syntaxPunctuation": "#${config.colorScheme.palette.base04}"
              }
            }
          '';
        }
        // runtimeThemeFiles
        // wallpaperFiles;

        home.activation.writeThemeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.config/lkasper-hyprland/current"

          # Writable default (not a read-only symlink) so theme-switch can
          # repoint it at runtime; AGS watches it and recolours live.
          if [ ! -f "$HOME/.config/lkasper-hyprland/current/theme.name" ]; then
            echo "wood-dark" > "$HOME/.config/lkasper-hyprland/current/theme.name"
          fi
          mkdir -p "$HOME/.config/hypr"
          mkdir -p "$HOME/.config/btop/themes"
          mkdir -p "$HOME/.config/ghostty/themes"

          if [ ! -f "$HOME/.config/hypr/theme.conf" ]; then
            cat > "$HOME/.config/hypr/theme.conf" << 'HYPREOF'
          general {
            col.active_border = rgba(${config.colorScheme.palette.accent or config.colorScheme.palette.base0D}aa)
            col.inactive_border = rgba(${config.colorScheme.palette.base09}aa)
          }

          group {
            col.border_active = rgba(${config.colorScheme.palette.accent or config.colorScheme.palette.base0D}aa)
            col.border_inactive = rgba(${config.colorScheme.palette.base09}aa)
          }
          HYPREOF
          fi

          if [ ! -f "$HOME/.config/btop/themes/lkh-runtime.theme" ]; then
            cat > "$HOME/.config/btop/themes/lkh-runtime.theme" << 'BTOPEOF'
          theme[main_fg]="${config.colorScheme.palette.base05}"
          theme[title]="${config.colorScheme.palette.base05}"
          theme[hi_fg]="${config.colorScheme.palette.base0D}"
          theme[selected_bg]="${config.colorScheme.palette.base01}"
          theme[selected_fg]="${config.colorScheme.palette.base05}"
          theme[inactive_fg]="${config.colorScheme.palette.base04}"
          theme[proc_misc]="${config.colorScheme.palette.base0D}"
          theme[cpu_box]="${config.colorScheme.palette.base0B}"
          theme[mem_box]="${config.colorScheme.palette.base09}"
          theme[net_box]="${config.colorScheme.palette.base0E}"
          theme[proc_box]="${config.colorScheme.palette.base0C}"
          theme[div_line]="${config.colorScheme.palette.base04}"
          theme[temp_start]="${config.colorScheme.palette.base0B}"
          theme[temp_mid]="${config.colorScheme.palette.base0A}"
          theme[temp_end]="${config.colorScheme.palette.base08}"
          theme[cpu_start]="${config.colorScheme.palette.base0B}"
          theme[cpu_mid]="${config.colorScheme.palette.base0A}"
          theme[cpu_end]="${config.colorScheme.palette.base08}"
          theme[free_start]="${config.colorScheme.palette.base0B}"
          theme[cached_start]="${config.colorScheme.palette.base0A}"
          theme[available_start]="${config.colorScheme.palette.base09}"
          theme[used_start]="${config.colorScheme.palette.base08}"
          theme[download_start]="${config.colorScheme.palette.base0E}"
          theme[download_mid]="${config.colorScheme.palette.base0D}"
          theme[download_end]="${config.colorScheme.palette.base0C}"
          theme[upload_start]="${config.colorScheme.palette.base0E}"
          theme[upload_mid]="${config.colorScheme.palette.base0D}"
          theme[upload_end]="${config.colorScheme.palette.base0C}"
          BTOPEOF
          fi

          if [ ! -f "$HOME/.config/ghostty/themes/lkh-runtime" ]; then
            cat > "$HOME/.config/ghostty/themes/lkh-runtime" << 'GHOSTTYEOF'
          background = #${config.colorScheme.palette.base00}
          foreground = #${config.colorScheme.palette.base05}
          selection-background = #${config.colorScheme.palette.base02}
          selection-foreground = #${config.colorScheme.palette.base00}
          palette = 0=#${config.colorScheme.palette.base00}
          palette = 1=#${config.colorScheme.palette.base08}
          palette = 2=#${config.colorScheme.palette.base0B}
          palette = 3=#${config.colorScheme.palette.base0A}
          palette = 4=#${config.colorScheme.palette.base0D}
          palette = 5=#${config.colorScheme.palette.base0E}
          palette = 6=#${config.colorScheme.palette.base0C}
          palette = 7=#${config.colorScheme.palette.base05}
          palette = 8=#${config.colorScheme.palette.base03}
          palette = 9=#${config.colorScheme.palette.base08}
          palette = 10=#${config.colorScheme.palette.base0B}
          palette = 11=#${config.colorScheme.palette.base0A}
          palette = 12=#${config.colorScheme.palette.base0D}
          palette = 13=#${config.colorScheme.palette.base0E}
          palette = 14=#${config.colorScheme.palette.base0C}
          palette = 15=#${config.colorScheme.palette.base07}
          palette = 16=#${config.colorScheme.palette.base09}
          palette = 17=#${config.colorScheme.palette.base0F}
          palette = 18=#${config.colorScheme.palette.base01}
          palette = 19=#${config.colorScheme.palette.base02}
          palette = 20=#${config.colorScheme.palette.base04}
          palette = 21=#${config.colorScheme.palette.base06}
          GHOSTTYEOF
          fi

          if [ ! -f "$HOME/.config/starship.toml" ]; then
            cat > "$HOME/.config/starship.toml" << 'STARSHIPEOF'
          add_newline = false
          format = "$directory$git_branch$git_status$character"

          [directory]
          style = "bold #${config.colorScheme.palette.base0D}"
          truncation_length = 4

          [git_branch]
          style = "bold #${config.colorScheme.palette.base05}"

          [git_status]
          style = "#${config.colorScheme.palette.base05}"

          [character]
          success_symbol = "[>](bold #${config.colorScheme.palette.base0D})"
          error_symbol = "[>](bold #${config.colorScheme.palette.base0D})"
          STARSHIPEOF
          fi
        '';
      };
    };
}
