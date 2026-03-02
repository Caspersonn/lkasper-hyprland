{ inputs, ... }: {
  flake.homeManagerModules.omarchy-themes = { config, lib, pkgs, ... }:
    let
      cfg = config.omarchy;
      themes = import ../_themes.nix;
      declarativeTheme = themes."tokyo-night";

      packages = import ../_packages.nix {
        inherit pkgs lib;
        exclude_packages = cfg.exclude_packages;
      };

      lightThemes = [
        "catppuccin-latte"
        "flexoki-light"
        "gruvbox-light"
        "rose-pine"
        "white"
      ];

      defaultWallpapers = {
        "catppuccin" = "catppuccin";
        "catppuccin-latte" = "catppuccin-latte";
        "ethereal" = "ethereal";
        "everforest" = "everforest";
        "flexoki-light" = "flexoki-light";
        "gruvbox" = "gruvbox";
        "gruvbox-light" = "gruvbox";
        "hackerman" = "hackerman";
        "kanagawa" = "kanagawa";
        "matte-black" = "matte-black";
        "miasma" = "miasma";
        "nord" = "nord";
        "osaka-jade" = "osaka-jade";
        "ristretto" = "ristretto";
        "rose-pine" = "rose-pine";
        "tokyo-night" = "tokyo-night";
        "vantablack" = "vantablack";
        "white" = "white";
      };

      fixedThemeNames =
        builtins.filter (name: builtins.hasAttr "base16-theme" themes.${name})
        (builtins.attrNames themes);

      runtimeThemes = builtins.listToAttrs (map (name:
        let
          palette = inputs.nix-colors.colorSchemes.${
              themes.${name}.base16-theme
            }.palette;
        in {
          name = name;
          value = { inherit palette; };
        }) fixedThemeNames);

      wallpaperFilesForTheme = themeName:
        let
          wallpaperDir = ../../config/themes/wallpapers/${themeName};
          entries = builtins.readDir wallpaperDir;
          fileNames = builtins.filter (n: entries.${n} == "regular")
            (builtins.attrNames entries);
        in builtins.listToAttrs (map (fileName: {
          name =
            ".local/share/omarchy/themes/${themeName}/backgrounds/${fileName}";
          value = {
            source = ../../config/themes/wallpapers/${themeName}/${fileName};
          };
        }) fileNames);

      runtimeThemeFiles = builtins.foldl' (acc: name:
        let
          theme = runtimeThemes.${name};
          palette = theme.palette;
          wallpaperDirName = if builtins.hasAttr name defaultWallpapers then
            defaultWallpapers.${name}
          else
            null;
          hasWallpaperDir = wallpaperDirName != null && builtins.pathExists
            ../../config/themes/wallpapers/${wallpaperDirName};
        in acc // {
          ".local/share/omarchy/themes/${name}/colors.toml".text = ''
            base00 = "${palette.base00}"
            base01 = "${palette.base01}"
            base02 = "${palette.base02}"
            base03 = "${palette.base03}"
            base04 = "${palette.base04}"
            base05 = "${palette.base05}"
            base06 = "${palette.base06}"
            base07 = "${palette.base07}"
            base08 = "${palette.base08}"
            base09 = "${palette.base09}"
            base0A = "${palette.base0A}"
            base0B = "${palette.base0B}"
            base0C = "${palette.base0C}"
            base0D = "${palette.base0D}"
            base0E = "${palette.base0E}"
            base0F = "${palette.base0F}"
            background = "#${palette.base00}"
            foreground = "#${palette.base05}"
            accent = "#${palette.base0D}"
          '';
        } // (if builtins.elem name lightThemes then {
          ".local/share/omarchy/themes/${name}/light.mode".text = "";
        } else
          { }) // (if hasWallpaperDir then
            wallpaperFilesForTheme wallpaperDirName
          else
            { })) { } fixedThemeNames;

      runtimeDefaultTheme = "tokyo-night";
    in {
      options.omarchy = (import ../../config.nix lib).omarchyOptions;

      imports = [ inputs.nix-colors.homeManagerModules.default ];

      config = {
        colorScheme =
          inputs.nix-colors.colorSchemes.${declarativeTheme.base16-theme};

        gtk = {
          enable = true;
          theme = {
            name = "Adwaita";
            package = pkgs.gnome-themes-extra;
          };
          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };
        };

        programs.neovim.enable = true;

        home.packages = packages.homePackages ++ [ pkgs.libadwaita ];

        home.sessionPath =
          [ "${config.home.homeDirectory}/.local/share/omarchy/bin" ];

        home.file = {
          ".local/share/omarchy/bin" = {
            source = ../../bin;
            recursive = true;
          };
          ".local/share/omarchy/default/themed/walker.css.tpl".text = ''
            @define-color selected-text {{ accent }};
            @define-color text {{ foreground }};
            @define-color base {{ background }};
            @define-color border {{ foreground }};
            @define-color foreground {{ foreground }};
            @define-color background {{ background }};
          '';
          ".local/share/omarchy/default/themed/waybar.css.tpl".text = ''
            @define-color background #{{ base00 }};
            * {
              color: #{{ base05 }};
            }

            window#waybar {
              background-color: #{{ base00 }};
            }
          '';
          ".local/share/omarchy/default/themed/wofi.css.tpl".text = ''
            window {
              background-color: #{{ base00 }};
            }

            #inner-box,
            #outer-box,
            #scroll,
            #input,
            #entry {
              background-color: #{{ base00 }};
            }

            #text {
              color: #{{ base06 }};
            }

            #entry:selected #text {
              color: #{{ base02 }};
            }
          '';
          ".local/share/omarchy/default/themed/mako.conf.tpl".text = ''
            background-color=#{{ base00 }}
            text-color=#{{ base05 }}
            border-color=#{{ base04 }}
            progress-color=#{{ base0D }}
          '';
          ".local/share/omarchy/default/themed/hyprland.conf.tpl".text = ''
            general {
              col.active_border = rgba({{ base0D }}aa)
              col.inactive_border = rgba({{ base09 }}aa)
            }

            group {
              col.border_active = rgba({{ base0D }}aa)
              col.border_inactive = rgba({{ base09 }}aa)
            }
          '';
          ".local/share/omarchy/default/themed/btop.theme.tpl".text = ''
            theme[main_fg]="{{ base05 }}"
            theme[title]="{{ base05 }}"
            theme[hi_fg]="{{ base0D }}"
            theme[selected_bg]="{{ base01 }}"
            theme[selected_fg]="{{ base05 }}"
            theme[inactive_fg]="{{ base04 }}"
            theme[proc_misc]="{{ base0D }}"
            theme[cpu_box]="{{ base0B }}"
            theme[mem_box]="{{ base09 }}"
            theme[net_box]="{{ base0E }}"
            theme[proc_box]="{{ base0C }}"
            theme[div_line]="{{ base04 }}"
            theme[temp_start]="{{ base0B }}"
            theme[temp_mid]="{{ base0A }}"
            theme[temp_end]="{{ base08 }}"
            theme[cpu_start]="{{ base0B }}"
            theme[cpu_mid]="{{ base0A }}"
            theme[cpu_end]="{{ base08 }}"
            theme[free_start]="{{ base0B }}"
            theme[cached_start]="{{ base0A }}"
            theme[available_start]="{{ base09 }}"
            theme[used_start]="{{ base08 }}"
            theme[download_start]="{{ base0E }}"
            theme[download_mid]="{{ base0D }}"
            theme[download_end]="{{ base0C }}"
            theme[upload_start]="{{ base0E }}"
            theme[upload_mid]="{{ base0D }}"
            theme[upload_end]="{{ base0C }}"
          '';
          ".local/share/omarchy/default/themed/ghostty.conf.tpl".text = ''
            background = #{{ base00 }}
            foreground = #{{ base05 }}
            selection-background = #{{ base02 }}
            selection-foreground = #{{ base00 }}
            palette = 0=#{{ base00 }}
            palette = 1=#{{ base08 }}
            palette = 2=#{{ base0B }}
            palette = 3=#{{ base0A }}
            palette = 4=#{{ base0D }}
            palette = 5=#{{ base0E }}
            palette = 6=#{{ base0C }}
            palette = 7=#{{ base05 }}
            palette = 8=#{{ base03 }}
            palette = 9=#{{ base08 }}
            palette = 10=#{{ base0B }}
            palette = 11=#{{ base0A }}
            palette = 12=#{{ base0D }}
            palette = 13=#{{ base0E }}
            palette = 14=#{{ base0C }}
            palette = 15=#{{ base07 }}
            palette = 16=#{{ base09 }}
            palette = 17=#{{ base0F }}
            palette = 18=#{{ base01 }}
            palette = 19=#{{ base02 }}
            palette = 20=#{{ base04 }}
            palette = 21=#{{ base06 }}
          '';
          ".local/share/omarchy/default/themed/opencode.json.tpl".text = ''
            {
              "$schema": "https://opencode.ai/theme.json",
              "theme": {
                "primary": "#{{ base0D }}",
                "secondary": "#{{ base0E }}",
                "accent": "#{{ base0C }}",
                "error": "#{{ base08 }}",
                "warning": "#{{ base09 }}",
                "success": "#{{ base0B }}",
                "info": "#{{ base0D }}",
                "text": "#{{ base05 }}",
                "textMuted": "#{{ base04 }}",
                "background": "#{{ base00 }}",
                "backgroundPanel": "#{{ base01 }}",
                "backgroundElement": "#{{ base02 }}",
                "border": "#{{ base03 }}",
                "borderActive": "#{{ base0D }}",
                "borderSubtle": "#{{ base02 }}",
                "diffAdded": "#{{ base0B }}",
                "diffRemoved": "#{{ base08 }}",
                "diffContext": "#{{ base04 }}",
                "diffHunkHeader": "#{{ base0D }}",
                "diffHighlightAdded": "#{{ base0B }}",
                "diffHighlightRemoved": "#{{ base08 }}",
                "diffAddedBg": "#{{ base01 }}",
                "diffRemovedBg": "#{{ base01 }}",
                "diffContextBg": "#{{ base00 }}",
                "diffLineNumber": "#{{ base03 }}",
                "diffAddedLineNumberBg": "#{{ base01 }}",
                "diffRemovedLineNumberBg": "#{{ base01 }}",
                "markdownText": "#{{ base05 }}",
                "markdownHeading": "#{{ base0D }}",
                "markdownLink": "#{{ base0E }}",
                "markdownLinkText": "#{{ base0C }}",
                "markdownCode": "#{{ base0B }}",
                "markdownBlockQuote": "#{{ base04 }}",
                "markdownEmph": "#{{ base09 }}",
                "markdownStrong": "#{{ base0A }}",
                "markdownHorizontalRule": "#{{ base03 }}",
                "markdownListItem": "#{{ base0D }}",
                "markdownListEnumeration": "#{{ base0C }}",
                "markdownImage": "#{{ base0E }}",
                "markdownImageText": "#{{ base0C }}",
                "markdownCodeBlock": "#{{ base0B }}",
                "syntaxComment": "#{{ base03 }}",
                "syntaxKeyword": "#{{ base0E }}",
                "syntaxFunction": "#{{ base0D }}",
                "syntaxVariable": "#{{ base08 }}",
                "syntaxString": "#{{ base0B }}",
                "syntaxNumber": "#{{ base09 }}",
                "syntaxType": "#{{ base0A }}",
                "syntaxOperator": "#{{ base05 }}",
                "syntaxPunctuation": "#{{ base04 }}"
              }
            }
          '';
          ".local/share/omarchy/default/themed/starship.toml.tpl".text = ''
            add_newline = false
            format = "$directory$git_branch$git_status$character"

            [directory]
            style = "bold {{ accent }}"
            truncation_length = 4

            [git_branch]
            style = "bold {{ foreground }}"

            [git_status]
            style = "{{ foreground }}"

            [character]
            success_symbol = "[>](bold {{ accent }})"
            error_symbol = "[>](bold {{ accent }})"
          '';
          ".local/share/omarchy/default/themed/tmux.conf.tpl".text = ''
            set-option -g status-style "fg={{ foreground }},bg={{ background }}"
            set-option -g message-style "fg={{ foreground }},bg={{ background }}"
            set-option -g message-command-style "fg={{ foreground }},bg={{ background }}"
            set-option -g pane-border-style "fg={{ background }}"
            set-option -g pane-active-border-style "fg={{ accent }}"
            set-option -g status-left-style "fg={{ accent }},bg={{ background }}"
            set-option -g status-right-style "fg={{ foreground }},bg={{ background }}"
            set-option -g window-status-current-style "fg={{ accent }},bg={{ background }}"
            set-option -g window-status-style "fg={{ foreground }},bg={{ background }}"
          '';
          ".config/omarchy/theme-default".text = ''
            ${runtimeDefaultTheme}
          '';
          ".config/omarchy/theme-list".text =
            lib.concatStringsSep "\n" fixedThemeNames + "\n";
          ".config/waybar/runtime.css".text = ''
            @define-color background #${config.colorScheme.palette.base00};
            * {
              color: #${config.colorScheme.palette.base05};
            }

            window#waybar {
              background-color: #${config.colorScheme.palette.base00};
            }
          '';
          ".config/wofi/runtime.css".text = ''
            window {
              background-color: #${config.colorScheme.palette.base00};
            }

            #inner-box,
            #outer-box,
            #scroll,
            #input,
            #entry {
              background-color: #${config.colorScheme.palette.base00};
            }

            #text {
              color: #${config.colorScheme.palette.base06};
            }

            #entry:selected #text {
              color: #${config.colorScheme.palette.base02};
            }
          '';
          ".config/mako/runtime.conf".text = ''
            background-color=#${config.colorScheme.palette.base00}
            text-color=#${config.colorScheme.palette.base05}
            border-color=#${config.colorScheme.palette.base04}
            progress-color=#${config.colorScheme.palette.base0D}
          '';
          ".config/hypr/theme.conf".text = ''
            general {
              col.active_border = rgba(${config.colorScheme.palette.base0D}aa)
              col.inactive_border = rgba(${config.colorScheme.palette.base09}aa)
            }

            group {
              col.border_active = rgba(${config.colorScheme.palette.base0D}aa)
              col.border_inactive = rgba(${config.colorScheme.palette.base09}aa)
            }
          '';
          ".config/btop/themes/omarchy-runtime.theme".text = ''
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
          '';
          ".config/ghostty/themes/omarchy-runtime".text = ''
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
          '';
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
          ".config/starship.toml".text = ''
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
          '';
        } // runtimeThemeFiles;
      };
    };
}
