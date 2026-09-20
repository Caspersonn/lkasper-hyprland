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
    terminal = lib.mkDefault { _var = "ghostty"; };
    fileManager = lib.mkDefault { _var = "nautilus --new-window"; };
    browser = lib.mkDefault { _var = "firefox"; };
    music = lib.mkDefault { _var = "Aonsoku"; };
    passwordManager = lib.mkDefault { _var = "bitwarden"; };
    messenger = lib.mkDefault { _var = "signal-desktop"; };

    monitor =
      if cfg.monitors != [ ] then
        cfg.monitors
      else
        [
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = "auto";
          }
        ];

    config.misc.disable_watchdog_warning = true;
  };

  wayland.windowManager.hyprland.plugins = [
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    pcall(require, "monitors")
    pcall(require, "workspaces")

    local themeConfig = os.getenv("HOME") .. "/.config/lkasper-hyprland/current/hypr.lua"
    local themeChunk = loadfile(themeConfig)
    if themeChunk then
      pcall(themeChunk)
    end
  '';
}
