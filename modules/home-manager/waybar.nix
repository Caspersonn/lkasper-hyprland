{ inputs, ... }: {
  flake.homeManagerModules.omarchy-waybar = { config, pkgs, ... }:
    let
      palette = config.colorScheme.palette;
      convert = inputs.nix-colors.lib.conversions.hexToRGBString;
      backgroundRgb = "rgb(${convert ", " palette.base00})";
      foregroundRgb = "rgb(${convert ", " palette.base05})";
    in {
      home.packages = with pkgs; [
        bluetuith
        pulsemixer
        lm_sensors
        python3
        curl
        jq
        tmux
      ];

      home.file = {
        ".config/waybar/config.jsonc" = {
          source = ../../config/waybar/config.jsonc;
        };
        ".config/waybar/style.css" = {
          source = ../../config/waybar/style.css;
        };
        ".config/waybar/scripts/fan.sh" = {
          source = ../../config/waybar/scripts/fan.sh;
          executable = true;
        };
        ".config/waybar/scripts/weather-brief.sh" = {
          source = ../../config/waybar/scripts/weather-brief.sh;
          executable = true;
        };
        ".config/waybar/theme.css" = {
          text = ''
            @define-color background ${backgroundRgb};
            @define-color foreground ${foregroundRgb};
            * {
              color: ${foregroundRgb};
            }

            window#waybar {
              background-color: transparent;
            }

            @import url("file://${config.home.homeDirectory}/.config/waybar/runtime.css");
          '';
        };
      };

      programs.waybar = { enable = true; };
    };
}
