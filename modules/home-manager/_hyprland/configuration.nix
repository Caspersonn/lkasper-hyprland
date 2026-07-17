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
    # yazi 26.x hardcodes its window title to "Yazi: <dir>" with no config to
    # change it, so foot owns the title instead: --title sets it and
    # locked-title (per-instance via -o) stops yazi overriding it at runtime.
    # The Hyprland float rule in windows.nix matches this "yazi" title.
    "$fileManager" = lib.mkDefault "foot -o main.locked-title=yes --title=yazi yazi";
    "$browser" = lib.mkDefault "firefox";
    "$music" = lib.mkDefault "Aonsoku";
    "$passwordManager" = lib.mkDefault "bitwarden";
    "$messenger" = lib.mkDefault "signal-desktop";

    monitor = if cfg.monitors != [ ] then cfg.monitors else [ ",preferred,auto,1" ];
  };

  # Remove start-hyprland error
  wayland.windowManager.hyprland.settings.misc.disable_watchdog_warning = true;

  wayland.windowManager.hyprland.plugins = [
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ~/.config/hypr/monitors.conf
    source = ~/.config/hypr/workspaces.conf
    source = ~/.config/hypr/theme.conf
  '';
}
