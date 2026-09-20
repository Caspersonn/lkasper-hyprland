{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.settings = {
    config.input = lib.mkDefault {
      kb_layout = "us";
      kb_options = "";

      follow_mouse = 1;

      sensitivity = 0;

      touchpad = {
        natural_scroll = true;
        scroll_factor = 0.5;
      };
    };
  };
}
