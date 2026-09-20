{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  cfg = config."lkasper-hyprland";
  hasNvidiaDrivers =
    osConfig != null && builtins.elem "nvidia" (osConfig.services.xserver.videoDrivers or [ ]);
  mkEnv = name: value: {
    _args = [
      name
      value
    ];
  };
  nvidiaEnv = [
    (mkEnv "NVD_BACKEND" "direct")
    (mkEnv "LIBVA_DRIVER_NAME" "nvidia")
    (mkEnv "__GLX_VENDOR_LIBRARY_NAME" "nvidia")
  ];
in
{
  home.sessionVariables = {
    GDK_SCALE = toString cfg.scale;
    XCURSOR_SIZE = "24";
    HYPRCURSOR_SIZE = "24";
    XCURSOR_THEME = "Adwaita";
    HYPRCURSOR_THEME = "Adwaita";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
    CHROMIUM_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4";
    EDITOR = "nvim";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share";
  };

  systemd.user.sessionVariables = config.home.sessionVariables;

  wayland.windowManager.hyprland.settings = {
    env = (lib.optionals hasNvidiaDrivers nvidiaEnv) ++ [
      (mkEnv "GDK_SCALE" (toString cfg.scale))
      (mkEnv "XCURSOR_SIZE" "24")
      (mkEnv "HYPRCURSOR_SIZE" "24")
      (mkEnv "XCURSOR_THEME" "Adwaita")
      (mkEnv "HYPRCURSOR_THEME" "Adwaita")
      (mkEnv "GDK_BACKEND" "wayland")
      (mkEnv "QT_QPA_PLATFORM" "wayland")
      (mkEnv "QT_QPA_PLATFORMTHEME" "gtk3")
      (mkEnv "SDL_VIDEODRIVER" "wayland")
      (mkEnv "MOZ_ENABLE_WAYLAND" "1")
      (mkEnv "ELECTRON_OZONE_PLATFORM_HINT" "wayland")
      (mkEnv "OZONE_PLATFORM" "wayland")
      (mkEnv "CHROMIUM_FLAGS" "--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4")
      (mkEnv "EDITOR" "nvim")
    ];

    config = {
      xwayland = {
        force_zero_scaling = true;
      };

      ecosystem = {
        no_update_news = true;
      };
    };
  };
}
