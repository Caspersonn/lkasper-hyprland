{ inputs, ... }:
{
  flake.homeManagerModules.omarchy-waybar = { config, pkgs, ... }:
    let
      palette = config.colorScheme.palette;
      convert = inputs.nix-colors.lib.conversions.hexToRGBString;
      backgroundRgb = "rgb(${convert ", " palette.base00})";
      foregroundRgb = "rgb(${convert ", " palette.base05})";
    in
      {
      home.file = {
        ".config/waybar/" = {
          source = ../../config/waybar;
          recursive = true;
        };
        ".config/waybar/theme.css" = {
          text = ''
            @define-color background ${backgroundRgb};
            @define-color foreground ${foregroundRgb};
            * {
              color: ${foregroundRgb};
            }

            window#waybar {
              background-color: ${backgroundRgb};
            }

            @import url("file://${config.home.homeDirectory}/.config/waybar/runtime.css");
          '';
        };
      };

      programs.waybar = {
        enable = true;
      };
    };
}
