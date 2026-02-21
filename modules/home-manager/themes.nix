{ inputs, ... }: {
  flake.homeManagerModules.omarchy-themes = { config, lib, pkgs, ... }:
    let
      cfg = config.omarchy;
      themes = import ../_themes.nix;

      isGenerated = cfg.theme == "generated_light" || cfg.theme
        == "generated_dark";
      isLight = cfg.theme == "generated_light" || cfg.theme == "gruvbox-light";

      wallpaper_path = cfg.theme_overrides.wallpaper_path;

      selectedTheme = if isGenerated || !builtins.hasAttr cfg.theme themes then
        null
      else
        themes.${cfg.theme};

      generatedColorScheme = (inputs.nix-colors.lib.contrib {
        inherit pkgs;
      }).colorSchemeFromPicture {
        path = wallpaper_path;
        variant = if cfg.theme == "generated_light" then "light" else "dark";
      };

      packages = import ../_packages.nix {
        inherit pkgs lib;
        exclude_packages = cfg.exclude_packages;
      };
    in {
      options.omarchy = (import ../../config.nix lib).omarchyOptions;

      imports = [ inputs.nix-colors.homeManagerModules.default ];

      config = {
        colorScheme = if isGenerated then
          generatedColorScheme
        else
          inputs.nix-colors.colorSchemes.${selectedTheme.base16-theme};

        gtk = {
          enable = true;
          theme = {
            name = if isLight then "Adwaita" else "Adwaita:dark";
            package = pkgs.gnome-themes-extra;
          };
        };

        programs.neovim.enable = true;

        home.packages = packages.homePackages;

        home.file = {
          ".local/share/omarchy/bin" = {
            source = ../../bin;
            recursive = true;
          };
          ".config/Kvantum/kvantum.kvconfig" = {
            text = ''
              [General]
              theme=${if isLight then "KvGnome" else "KvGnomeDark"}
            '';
          };
        };
      };
    };
}
