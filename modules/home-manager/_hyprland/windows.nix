{ config, pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "suppressevent maximize, class:.*"

      "tile, class:^(chromium)$"

      "float, class:^(org.pulseaudio.pavucontrol|blueberry.py|nwg-displays)$"

      "float, class:^(steam)$"
      "fullscreen, class:^(com.libretro.RetroArch)$"

      "opacity 0.97 0.9, class:.*"
      "opacity 1 1, class:^(chromium|google-chrome|google-chrome-unstable)$, title:.*Youtube.*"
      "opacity 1 0.97, class:^(chromium|google-chrome|google-chrome-unstable)$"
      "opacity 0.97 0.9, initialClass:^(chrome-.*-Default)$"
      "opacity 1 1, initialClass:^(chrome-youtube.*-Default)$"
      "opacity 1 1, class:^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$"
      "opacity 1 1, class:^(com.libretro.RetroArch|steam)$"

      "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"

      "float, title:(clipse)"
      "size 622 652, title:(clipse)"
      "stayfocused, title:(clipse)"
    ];

    layerrule = [ "blur on, namespace:wofi" ];
  };
}
