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
      wallpaperRoot = ../../wallpapers;
      paletteDir = wallpaperRoot + "/palettes";
      pairs = import (wallpaperRoot + "/pairs.nix");

      dataRoot = ".local/share/lkasper-hyprland";
      themeRoot = "${dataRoot}/themes";
      stateDir = "$HOME/.config/lkasper-hyprland";

      modes = [
        "light"
        "dark"
      ];
      pairNames = builtins.attrNames pairs;

      imageNames = builtins.filter (
        n: lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n || lib.hasSuffix ".jpeg" n
      ) (builtins.attrNames (builtins.readDir wallpaperRoot));

      claimed = lib.concatMap (pair: builtins.attrValues pairs.${pair}) pairNames;
      unpaired = builtins.filter (image: !(builtins.elem image claimed)) imageNames;
      duplicated = builtins.filter (image: lib.count (c: c == image) claimed > 1) (lib.unique claimed);
      missingImages = builtins.filter (image: !(builtins.elem image imageNames)) claimed;
      malformed = builtins.filter (
        pair:
        builtins.attrNames pairs.${pair} != [
          "dark"
          "light"
        ]
      ) pairNames;

      slugOf = image: lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" image));

      paletteOf = image: builtins.fromJSON (builtins.readFile (paletteDir + "/${slugOf image}.json"));

      missingPalettes = builtins.filter (
        image: !(builtins.pathExists (paletteDir + "/${slugOf image}.json"))
      ) claimed;

      defaultPair = if builtins.elem "beach" pairNames then "beach" else builtins.head pairNames;
      defaultMode = "dark";

      hexToRgb = inputs.nix-colors.lib.conversions.hexToRGBString ", ";

      retrobox = {
        dark = {
          bg = "1c1c1c";
          fg = "ebdbb2";
          surface = "303030";
          selection = "2a405a";
          comment = "928374";
          accent = "d79921";
          info = "83a598";
          ansi = [
            "1c1c1c"
            "cc241d"
            "98971a"
            "d79921"
            "458588"
            "b16286"
            "689d6a"
            "a89984"
            "928374"
            "fb5944"
            "b8bb26"
            "fabd2f"
            "83a598"
            "d3869b"
            "8ec07c"
            "ebdbb2"
          ];
        };
        light = {
          bg = "fbf1c7";
          fg = "3c3836";
          surface = "e5d4b1";
          selection = "b0d0d0";
          comment = "928374";
          accent = "b57614";
          info = "076678";
          ansi = [
            "3c3836"
            "cc241d"
            "98971a"
            "d79921"
            "458588"
            "b16286"
            "689d6a"
            "7c6f64"
            "928374"
            "9d0006"
            "79740e"
            "b57614"
            "076678"
            "8f3f71"
            "427b58"
            "fbf1c7"
          ];
        };
      };

      base16Slots = map (c: "base0${c}") (lib.stringToCharacters "0123456789ABCDEF");

      accentPalette =
        palette:
        palette
        // {
          base0A = palette.accent2;
          base0B = palette.accent3;
          base0C = palette.accent2;
          base0D = palette.accent;
          base0E = palette.accent3;
          base0F = palette.accent;
        };

      themeFiles =
        pair: mode:
        let
          image = pairs.${pair}.${mode};
          palette = paletteOf image;
          shell = accentPalette palette;
          accent = palette.accent;
          rb = retrobox.${mode};
          rbAnsi = i: builtins.elemAt rb.ansi i;
          wallpaper = wallpaperRoot + "/${image}";
        in
        {
          "colors.json" = builtins.toJSON (
            shell
            // {
              inherit mode;
              background = "#${shell.base00}";
              foreground = "#${shell.base05}";
              accent = accent;
              hairline = if mode == "light" then shell.base05 else shell.base07;
              shade = if mode == "light" then shell.base03 else "000000";
            }
          );

          "colors-ansi.json" = builtins.toJSON (palette // { inherit mode; });

          "nvim.lua" = ''
            return {
              mode = "${mode}",
              colorscheme = "retrobox",
              background = "${mode}",
              wallpaper_background = "#${palette.base00}",
              palette = {
            ${lib.concatMapStringsSep "\n" (slot: "    ${slot} = \"#${palette.${slot}}\",") base16Slots}
              },
            }
          '';

          "wallpaper.path" = "${wallpaper}\n";

          "foot.ini" = ''
            [colors]
            background=${rb.bg}
            foreground=${rb.fg}
            selection-background=${rb.selection}
            selection-foreground=${rb.fg}
            ${lib.concatStringsSep "\n" (lib.genList (i: "regular${toString i}=${rbAnsi i}") 8)}
            ${lib.concatStringsSep "\n" (lib.genList (i: "bright${toString i}=${rbAnsi (i + 8)}") 8)}
          '';

          "ghostty" = ''
            background = #${rb.bg}
            foreground = #${rb.fg}
            selection-background = #${rb.selection}
            selection-foreground = #${rb.fg}
            ${lib.concatStringsSep "\n" (lib.genList (i: "palette = ${toString i}=#${rbAnsi i}") 16)}
          '';

          "clipse-theme.json" = builtins.toJSON {
            useCustomTheme = true;
            TitleFore = "#${rb.bg}";
            TitleBack = "#${rb.fg}";
            TitleInfo = "#${rbAnsi 12}";
            NormalTitle = "#${rb.fg}";
            DimmedTitle = "#${rb.comment}";
            SelectedTitle = "#${rbAnsi 11}";
            NormalDesc = "#${rb.comment}";
            DimmedDesc = "#${rb.comment}";
            SelectedDesc = "#${rbAnsi 11}";
            StatusMsg = "#${rbAnsi 10}";
            PinIndicatorColor = "#${rbAnsi 11}";
            SelectedBorder = "#${rb.accent}";
            SelectedDescBorder = "#${rb.accent}";
            FilteredMatch = "#${rbAnsi 10}";
            FilterPrompt = "#${rbAnsi 10}";
            FilterInfo = "#${rbAnsi 12}";
            FilterText = "#${rb.fg}";
            FilterCursor = "#${rb.accent}";
            HelpKey = "#${rbAnsi 12}";
            HelpDesc = "#${rb.comment}";
            PageActiveDot = "#${rb.accent}";
            PageInactiveDot = "#${rb.comment}";
            DividerDot = "#${rb.comment}";
            PreviewedText = "#${rb.fg}";
            PreviewBorder = "#${rb.comment}";
          };

          "fish.fish" = ''
            set -U fish_color_normal ${rb.fg}
            set -U fish_color_command ${rbAnsi 10}
            set -U fish_color_keyword ${rbAnsi 9}
            set -U fish_color_quote ${rbAnsi 10}
            set -U fish_color_redirection ${rbAnsi 14}
            set -U fish_color_end ${rbAnsi 11}
            set -U fish_color_error ${rbAnsi 9}
            set -U fish_color_param ${rb.fg}
            set -U fish_color_option ${rbAnsi 14}
            set -U fish_color_comment ${rb.comment}
            set -U fish_color_operator ${rbAnsi 14}
            set -U fish_color_escape ${rbAnsi 11}
            set -U fish_color_autosuggestion ${rb.comment}
            set -U fish_color_cwd ${rbAnsi 11}
            set -U fish_color_user ${rbAnsi 14}
            set -U fish_color_host ${rbAnsi 12}
            set -U fish_color_valid_path --underline
            set -U fish_color_selection ${rb.fg} --background=${rb.selection}
            set -U fish_color_search_match --background=${rb.selection}
            set -U fish_pager_color_prefix ${rb.accent} --bold
            set -U fish_pager_color_completion ${rb.fg}
            set -U fish_pager_color_description ${rb.comment}
            set -U fish_pager_color_progress ${rb.comment}
            set -U fish_pager_color_selected_background --background=${rb.selection}
            set -U lkh_fg ${rb.fg}
            set -U lkh_dim ${rb.comment}
            set -U lkh_red ${rbAnsi 9}
            set -U lkh_green ${rbAnsi 10}
            set -U lkh_yellow ${rbAnsi 11}
            set -U lkh_blue ${rbAnsi 12}
            set -U lkh_magenta ${rbAnsi 13}
            set -U lkh_cyan ${rbAnsi 14}
          '';

          "tmux.conf" = ''
            set -g status-style "fg=#${rb.fg},bg=#${rb.surface}"
            set -g status-left-style "fg=#${rb.accent},bold"
            set -g status-right-style "fg=#${rb.comment}"
            set -g window-status-style "fg=#${rb.comment}"
            set -g window-status-current-style "fg=#${rb.bg},bg=#${rb.accent},bold"
            set -g window-status-activity-style "fg=#${rbAnsi 3}"
            set -g pane-border-style "fg=#${rb.comment}"
            set -g pane-active-border-style "fg=#${rb.info}"
            set -g message-style "fg=#${rb.bg},bg=#${rb.accent}"
            set -g message-command-style "fg=#${rb.fg},bg=#${rb.surface}"
            set -g mode-style "fg=#${rb.fg},bg=#${rb.selection}"
            set -g clock-mode-colour "#${rb.info}"
            set -g copy-mode-match-style "fg=#${rb.bg},bg=#${rb.info}"
            set -g copy-mode-current-match-style "fg=#${rb.bg},bg=#${rb.accent}"
          '';

          "btop.theme" = ''
            theme[main_bg]="#${rb.bg}"
            theme[main_fg]="#${rb.fg}"
            theme[title]="#${rb.fg}"
            theme[hi_fg]="#${rbAnsi 11}"
            theme[selected_bg]="#${rb.selection}"
            theme[selected_fg]="#${rb.fg}"
            theme[inactive_fg]="#${rb.comment}"
            theme[graph_text]="#${rb.comment}"
            theme[meter_bg]="#${rb.surface}"
            theme[proc_misc]="#${rbAnsi 12}"
            theme[cpu_box]="#${rbAnsi 10}"
            theme[mem_box]="#${rbAnsi 11}"
            theme[net_box]="#${rbAnsi 13}"
            theme[proc_box]="#${rbAnsi 12}"
            theme[div_line]="#${rb.comment}"
            theme[temp_start]="#${rbAnsi 10}"
            theme[temp_mid]="#${rbAnsi 11}"
            theme[temp_end]="#${rbAnsi 9}"
            theme[cpu_start]="#${rbAnsi 10}"
            theme[cpu_mid]="#${rbAnsi 11}"
            theme[cpu_end]="#${rbAnsi 9}"
            theme[free_start]="#${rbAnsi 10}"
            theme[cached_start]="#${rbAnsi 14}"
            theme[available_start]="#${rbAnsi 11}"
            theme[used_start]="#${rbAnsi 9}"
            theme[download_start]="#${rbAnsi 14}"
            theme[download_mid]="#${rbAnsi 12}"
            theme[download_end]="#${rbAnsi 13}"
            theme[upload_start]="#${rbAnsi 14}"
            theme[upload_mid]="#${rbAnsi 12}"
            theme[upload_end]="#${rbAnsi 13}"
          '';

          "starship.toml" = ''
            add_newline = false
            format = "$directory$git_branch$git_status$character"

            [directory]
            style = "bold #${accent}"
            truncation_length = 4

            [git_branch]
            style = "bold #${palette.base05}"

            [git_status]
            style = "#${palette.base05}"

            [character]
            success_symbol = "[>](bold #${accent})"
            error_symbol = "[>](bold #${palette.base08})"
          '';

          "hypr.conf" = ''
            general {
              col.active_border = rgba(${accent}ee)
              col.inactive_border = rgba(${palette.base03}aa)
            }

            group {
              col.border_active = rgba(${accent}ee)
              col.border_inactive = rgba(${palette.base03}aa)
            }
          '';

          "hyprlock.conf" = ''
            $lkh_surface = rgb(${hexToRgb palette.base02})
            $lkh_foreground = rgb(${hexToRgb palette.base05})
            $lkh_muted = rgb(${hexToRgb palette.base04})
            $lkh_accent = rgb(${hexToRgb accent})
            $lkh_ok = rgb(${hexToRgb palette.base0B})
          '';

          "gtk.css" = ''
            @define-color accent_color #${accent};
            @define-color accent_bg_color #${accent};
            @define-color accent_fg_color #${palette.base00};
            @define-color theme_bg_color #${palette.base00};
            @define-color theme_fg_color #${palette.base05};
            @define-color theme_base_color #${palette.base00};
            @define-color theme_text_color #${palette.base05};
          '';

          "opencode.json" = builtins.toJSON {
            "$schema" = "https://opencode.ai/theme.json";
            theme = {
              primary = "#${palette.base0D}";
              secondary = "#${palette.base0E}";
              accent = "#${accent}";
              error = "#${palette.base08}";
              warning = "#${palette.base09}";
              success = "#${palette.base0B}";
              info = "#${palette.base0D}";
              text = "#${palette.base05}";
              textMuted = "#${palette.base04}";
              background = "#${palette.base00}";
              backgroundPanel = "#${palette.base01}";
              backgroundElement = "#${palette.base02}";
              border = "#${palette.base03}";
              borderActive = "#${accent}";
              borderSubtle = "#${palette.base02}";
              diffAdded = "#${palette.base0B}";
              diffRemoved = "#${palette.base08}";
              diffContext = "#${palette.base04}";
              diffHunkHeader = "#${palette.base0D}";
              diffHighlightAdded = "#${palette.base0B}";
              diffHighlightRemoved = "#${palette.base08}";
              diffAddedBg = "#${palette.base01}";
              diffRemovedBg = "#${palette.base01}";
              diffContextBg = "#${palette.base00}";
              diffLineNumber = "#${palette.base03}";
              diffAddedLineNumberBg = "#${palette.base01}";
              diffRemovedLineNumberBg = "#${palette.base01}";
              markdownText = "#${palette.base05}";
              markdownHeading = "#${palette.base0D}";
              markdownLink = "#${palette.base0E}";
              markdownLinkText = "#${palette.base0C}";
              markdownCode = "#${palette.base0B}";
              markdownBlockQuote = "#${palette.base04}";
              markdownEmph = "#${palette.base09}";
              markdownStrong = "#${palette.base0A}";
              markdownHorizontalRule = "#${palette.base03}";
              markdownListItem = "#${palette.base0D}";
              markdownListEnumeration = "#${palette.base0C}";
              markdownImage = "#${palette.base0E}";
              markdownImageText = "#${palette.base0C}";
              markdownCodeBlock = "#${palette.base0B}";
              syntaxComment = "#${palette.base03}";
              syntaxKeyword = "#${palette.base0E}";
              syntaxFunction = "#${palette.base0D}";
              syntaxVariable = "#${palette.base08}";
              syntaxString = "#${palette.base0B}";
              syntaxNumber = "#${palette.base09}";
              syntaxType = "#${palette.base0A}";
              syntaxOperator = "#${palette.base05}";
              syntaxPunctuation = "#${palette.base04}";
            };
          };
        };

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

      migrateCurrent = ''
        if [ -e "${stateDir}/current" ] && [ ! -L "${stateDir}/current" ]; then
          rm -f "${stateDir}/current/theme.name"
          rmdir "${stateDir}/current" 2>/dev/null || rm -rf "${stateDir}/current"
        fi
        rm -f "${stateDir}/current.new"
      '';

      theme-apply = pkgs.writeShellApplication {
        name = "theme-apply";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.glib
          pkgs.procps
          pkgs.tmux
          pkgs.fish
          pkgs.jq
        ];
        text = ''
          pair="''${1:-}"
          mode="''${2:-}"
          if [ -z "$pair" ] || [ -z "$mode" ]; then
            echo "usage: theme-apply <pair> <light|dark>" >&2
            exit 1
          fi
          if [ "$mode" != "light" ] && [ "$mode" != "dark" ]; then
            echo "theme-apply: mode must be light or dark, got '$mode'" >&2
            exit 1
          fi

          bundle="$HOME/${themeRoot}/$pair/$mode"
          if [ ! -d "$bundle" ]; then
            echo "theme-apply: no theme bundle at $bundle" >&2
            exit 1
          fi

          mkdir -p "${stateDir}"
          ${migrateCurrent}
          ln -sfn "$bundle" "${stateDir}/current.new"
          mv -Tf "${stateDir}/current.new" "${stateDir}/current"
          printf '%s %s\n' "$pair" "$mode" > "${stateDir}/state"

          if [ -f "$bundle/wallpaper.path" ]; then
            wallpaper="$(cat "$bundle/wallpaper.path")"
            hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 || true
            hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null 2>&1 || true
          fi

          hyprctl reload >/dev/null 2>&1 || true

          pkill -USR1 -x foot >/dev/null 2>&1 || true

          claude_settings="$HOME/.claude/settings.json"
          if [ -f "$claude_settings" ]; then
            if jq --arg t "$mode-ansi" '.theme = $t' "$claude_settings" > "$claude_settings.lkh-new" 2>/dev/null; then
              mv -f "$claude_settings.lkh-new" "$claude_settings"
            else
              rm -f "$claude_settings.lkh-new"
            fi
          fi

          if command -v fish >/dev/null 2>&1; then
            fish -c 'source "'"${stateDir}"'/current/fish.fish"' >/dev/null 2>&1 || true
          fi

          for tmux_dir in "''${TMUX_TMPDIR:-}" "/run/user/$(id -u)" /tmp; do
            [ -n "$tmux_dir" ] || continue
            tmux_sockets="$tmux_dir/tmux-$(id -u)"
            [ -d "$tmux_sockets" ] || continue
            for tmux_socket in "$tmux_sockets"/*; do
              [ -S "$tmux_socket" ] || continue
              tmux -S "$tmux_socket" source-file "${stateDir}/current/tmux.conf" >/dev/null 2>&1 || true
              tmux -S "$tmux_socket" refresh-client -S >/dev/null 2>&1 || true
            done
          done

          if gdbus call --session --dest org.freedesktop.DBus \
              --object-path /org/freedesktop/DBus \
              --method org.freedesktop.DBus.ListNames 2>/dev/null |
              grep -q com.mitchellh.ghostty; then
            gdbus call --session --dest com.mitchellh.ghostty \
              --object-path /com/mitchellh/ghostty \
              --method org.gtk.Actions.Activate reload-config "[]" "{}" >/dev/null 2>&1 || true
          fi

          export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:''${XDG_DATA_DIRS:-}"
          if [ "$mode" = "light" ]; then
            gsettings set org.gnome.desktop.interface color-scheme prefer-light >/dev/null 2>&1 || true
            gsettings set org.gnome.desktop.interface gtk-theme Adwaita >/dev/null 2>&1 || true
          else
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
            gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark >/dev/null 2>&1 || true
          fi

          ags request theme-reload >/dev/null 2>&1 || true
        '';
      };

      theme-state = pkgs.writeShellApplication {
        name = "theme-state";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          pair="${defaultPair}"
          mode="${defaultMode}"
          if [ -f "${stateDir}/state" ]; then
            read -r saved_pair saved_mode < "${stateDir}/state" || true
            if [ -n "''${saved_pair:-}" ] && [ -d "$HOME/${themeRoot}/$saved_pair" ]; then
              pair="$saved_pair"
            fi
            if [ "''${saved_mode:-}" = "light" ] || [ "''${saved_mode:-}" = "dark" ]; then
              mode="$saved_mode"
            fi
          fi
          printf '%s %s\n' "$pair" "$mode"
        '';
      };

      theme-toggle = pkgs.writeShellApplication {
        name = "theme-toggle";
        runtimeInputs = [
          pkgs.coreutils
          theme-apply
          theme-state
        ];
        text = ''
          read -r pair mode < <(theme-state)
          if [ "$mode" = "dark" ]; then
            theme-apply "$pair" light
          else
            theme-apply "$pair" dark
          fi
        '';
      };

      theme-switch = pkgs.writeShellApplication {
        name = "theme-switch";
        runtimeInputs = [
          pkgs.coreutils
          theme-apply
          theme-state
        ];
        text = ''
          target="''${1:-}"
          if [ -z "$target" ]; then
            echo "usage: theme-switch <pair>" >&2
            exit 1
          fi
          read -r _ mode < <(theme-state)
          theme-apply "$target" "$mode"
        '';
      };
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
