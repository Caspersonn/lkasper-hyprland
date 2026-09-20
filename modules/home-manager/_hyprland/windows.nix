{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      {
        match.class = ".*";
        suppress_event = "maximize";
      }

      {
        match.class = "^(chromium)$";
        tile = true;
      }

      {
        match.class = "^(org.pulseaudio.pavucontrol|blueman|nwg-displays)$";
        float = true;
      }

      {
        match.class = "^(steam)$";
        float = true;
      }
      {
        match.class = "^(com.libretro.RetroArch)$";
        fullscreen = true;
      }

      {
        match.class = ".*";
        opacity = "0.97 0.9";
      }
      {
        match = {
          class = "^(chromium|google-chrome|google-chrome-unstable)$";
          title = ".*Youtube.*";
        };
        opacity = "1 1";
      }
      {
        match.class = "^(chromium|google-chrome|google-chrome-unstable)$";
        opacity = "1 0.97";
      }
      {
        match.initial_class = "^(chrome-.*-Default)$";
        opacity = "0.97 0.9";
      }
      {
        match.initial_class = "^(chrome-youtube.*-Default)$";
        opacity = "1 1";
      }
      {
        match.class = "^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$";
        opacity = "1 1";
      }
      {
        match.class = "^(com.libretro.RetroArch|steam)$";
        opacity = "1 1";
      }

      {
        match = {
          class = "^$";
          title = "^$";
          xwayland = true;
          float = true;
          fullscreen = false;
          pin = false;
        };
        no_focus = true;
      }

      {
        match.title = "(clipse)";
        float = true;
        size = [
          622
          652
        ];
        stay_focused = true;
      }

      {
        match.title = "(nmtui)";
        float = true;
        size = [
          622
          652
        ];
        stay_focused = true;
      }

      {
        match.class = "^(org.gnome.Nautilus)$";
        float = true;
        size = [
          992
          608
        ];
        stay_focused = true;
      }
    ];

    layer_rule = [
      {
        match.namespace = "wofi";
        blur = true;
      }
      {
        match.namespace = "bar";
        blur = true;
      }
    ];
  };
}
