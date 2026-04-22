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
      cfg = config."lkasper-hyprland";
      themes = import ../_themes.nix;
      declarativeTheme = themes."tokyo-night";

      packages = import ../_packages.nix {
        inherit pkgs lib;
        exclude_packages = cfg.exclude_packages;
      };

      fixedThemeNames = builtins.filter (name: builtins.hasAttr "base16-theme" themes.${name}) (
        builtins.attrNames themes
      );

      runtimeThemes = builtins.listToAttrs (
        map (
          name:
          let
            palette = inputs.nix-colors.colorSchemes.${themes.${name}.base16-theme}.palette;
          in
          {
            name = name;
            value = { inherit palette; };
          }
        ) fixedThemeNames
      );

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

      wallpaperFilesForTheme =
        themeName:
        let
          wallpaperDir = ../../config/themes/wallpapers/${themeName};
          entries = builtins.readDir wallpaperDir;
          fileNames = builtins.filter (n: entries.${n} == "regular") (builtins.attrNames entries);
        in
        builtins.listToAttrs (
          map (fileName: {
            name = ".local/share/lkasper-hyprland/themes/${themeName}/backgrounds/${fileName}";
            value = {
              source = ../../config/themes/wallpapers/${themeName}/${fileName};
            };
          }) fileNames
        );

      runtimeThemeFiles = builtins.foldl' (
        acc: name:
        let
          theme = runtimeThemes.${name};
          palette = theme.palette;
          wallpaperDirName =
            if builtins.hasAttr name defaultWallpapers then defaultWallpapers.${name} else null;
          hasWallpaperDir =
            wallpaperDirName != null && builtins.pathExists ../../config/themes/wallpapers/${wallpaperDirName};
        in
        acc
        // {
          ".local/share/lkasper-hyprland/themes/${name}/colors.json".text = builtins.toJSON {
            inherit (palette)
              base00
              base01
              base02
              base03
              base04
              base05
              base06
              base07
              base08
              base09
              base0A
              base0B
              base0C
              base0D
              base0E
              base0F
              ;
            background = "#${palette.base00}";
            foreground = "#${palette.base05}";
            accent = "#${palette.base0D}";
          };
        }
        // (if hasWallpaperDir then wallpaperFilesForTheme wallpaperDirName else { })
      ) { } fixedThemeNames;
    in
    {
      options."lkasper-hyprland" = (import ../../config.nix lib).lkasperHyprlandOptions;

      imports = [ inputs.nix-colors.homeManagerModules.default ];

      config = {
        colorScheme = inputs.nix-colors.colorSchemes.${declarativeTheme.base16-theme};

        gtk = {
          enable = true;
          iconTheme = {
            name = "Gruvbox-Plus-Dark";
            package = pkgs.gruvbox-plus-icons;
          };
        };

        home.packages = packages.homePackages ++ [ pkgs.libadwaita ];

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
        // runtimeThemeFiles;

        home.activation.writeThemeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.config/lkasper-hyprland/current"
          mkdir -p "$HOME/.config/hypr"
          mkdir -p "$HOME/.config/btop/themes"
          mkdir -p "$HOME/.config/ghostty/themes"

          if [ ! -f "$HOME/.config/hypr/theme.conf" ]; then
            cat > "$HOME/.config/hypr/theme.conf" << 'HYPREOF'
          general {
            col.active_border = rgba(${config.colorScheme.palette.base0D}aa)
            col.inactive_border = rgba(${config.colorScheme.palette.base09}aa)
          }

          group {
            col.border_active = rgba(${config.colorScheme.palette.base0D}aa)
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
