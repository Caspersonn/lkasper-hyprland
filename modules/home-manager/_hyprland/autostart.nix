{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # "hypridle & mako & waybar & fcitx5"
      # "swaybg -i ~/.config/omarchy/current/background -m fill"
      "hyprsunset"
      "systemctl --user start hyprpolkitagent"
      "wl-clip-persist --clipboard regular & clipse -listen"
      "sh -lc '~/.local/share/omarchy/bin/omarchy-theme-set \"$(~/.local/share/omarchy/bin/omarchy-theme-current)\"'"
    ];

    exec = [ "pkill -SIGUSR2 waybar || waybar" ];
  };
}
