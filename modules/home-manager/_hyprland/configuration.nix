{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omarchy;
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
    #"$webapp" = lib.mkDefault "$browser --app";

    monitor = if cfg.monitors != [ ] then cfg.monitors else [ ",preferred,auto,1" ];
  };

  wayland.windowManager.hyprland.plugins = [
    pkgs.hyprlandPlugins.hyprsplit
    pkgs.hyprlandPlugins.hyprspace
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ~/.config/hypr/monitors.conf
    source = ~/.config/hypr/workspaces.conf
    source = ~/.config/hypr/theme.conf
  '';
}
