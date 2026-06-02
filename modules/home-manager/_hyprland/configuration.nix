{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config."lkasper-hyprland";
in
{
  imports = [
    ./autostart.nix
    ./bindings.nix
    ./envs.nix
    ./input.nix
    ./looknfeel.nix
    ./windows.nix
  ];
  wayland.windowManager.hyprland.settings = {
    # Default applications
    "$terminal" = lib.mkDefault "ghostty";
    "$fileManager" = lib.mkDefault "nautilus --new-window";
    "$browser" = lib.mkDefault "firefox";
    "$music" = lib.mkDefault "spotify";
    "$passwordManager" = lib.mkDefault "bitwarden";
    "$messenger" = lib.mkDefault "signal-desktop";

    monitor = if cfg.monitors != [ ] then cfg.monitors else [ ",preferred,auto,1" ];
  };

  # Remove start-hyprland error
  wayland.windowManager.hyprland.settings.misc.disable_watchdog_warning = true;

  wayland.windowManager.hyprland.plugins = [
    pkgs.hyprlandPlugins.hyprsplit
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ~/.config/hypr/monitors.conf
    source = ~/.config/hypr/workspaces.conf
    source = ~/.config/hypr/theme.conf
  '';
}
