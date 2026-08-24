{ ... }:
{
  flake.homeManagerModules.lkh-hyprlock =
    { ... }:
    {
      programs.hyprlock = {
        enable = true;
        sourceFirst = true;
        settings = {
          source = [ "~/.config/lkasper-hyprland/current/hyprlock.conf" ];

          general = {
            disable_loading_bar = true;
            no_fade_in = false;
          };
          auth = {
            fingerprint.enabled = true;
          };
          background = {
            monitor = "";
            path = "screenshot";
            blur_passes = 1;
          };

          input-field = {
            monitor = "";
            size = "600, 100";
            position = "0, 0";
            halign = "center";
            valign = "center";

            inner_color = "$lkh_surface";
            outer_color = "$lkh_accent";
            outline_thickness = 4;

            font_family = "CaskaydiaMono Nerd Font";
            font_size = 32;
            font_color = "$lkh_foreground";

            placeholder_color = "$lkh_muted";
            placeholder_text = "  Enter Password 󰈷 ";
            check_color = "$lkh_ok";
            fail_text = "Wrong";

            rounding = 0;
            shadow_passes = 0;
            fade_on_empty = false;
          };

          label = {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';

            color = "$lkh_muted";
            font_size = 64;
            font_family = "CaskaydiaMono Nerd Font";
            position = "0, 120";
            halign = "center";
            valign = "center";
          };
        };
      };
    };
}
