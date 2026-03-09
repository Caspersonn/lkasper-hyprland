{ config, pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "suppress_event maximize, match:class .*"

      "tile on, match:class ^(chromium)$"

      "float on, match:class ^(org.pulseaudio.pavucontrol|blueberry.py|nwg-displays)$"

      "float on, match:class ^(steam)$"
      "fullscreen on, match:class ^(com.libretro.RetroArch)$"

      "opacity 0.97 0.9, match:class .*"
      "opacity 1 1, match:class ^(chromium|google-chrome|google-chrome-unstable)$, match:title .*Youtube.*"
      "opacity 1 0.97, match:class ^(chromium|google-chrome|google-chrome-unstable)$"
      "opacity 0.97 0.9, match:initial_class ^(chrome-.*-Default)$"
      "opacity 1 1, match:initial_class ^(chrome-youtube.*-Default)$"
      "opacity 1 1, match:class ^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$"
      "opacity 1 1, match:class ^(com.libretro.RetroArch|steam)$"

      "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0"

      "float on, match:title (clipse)"
      "size 622 652, match:title (clipse)"
      "stay_focused on, match:title (clipse)"
    ];

    layerrule = [ "blur on, match:namespace wofi" ];
  };
}
