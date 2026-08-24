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
  nvidiaEnv = [
    "NVD_BACKEND,direct"
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
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
    QT_STYLE_OVERRIDE = "adwaita";
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
      "GDK_SCALE,${toString cfg.scale}"
      "XCURSOR_SIZE,24"
      "HYPRCURSOR_SIZE,24"
      "XCURSOR_THEME,Adwaita"
      "HYPRCURSOR_THEME,Adwaita"
      "GDK_BACKEND,wayland"
      "QT_QPA_PLATFORM,wayland"
      "QT_STYLE_OVERRIDE,kvantum"
      "SDL_VIDEODRIVER,wayland"
      "MOZ_ENABLE_WAYLAND,1"
      "ELECTRON_OZONE_PLATFORM_HINT,wayland"
      "OZONE_PLATFORM,wayland"
      ''CHROMIUM_FLAGS,"--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4"''
      "XDG_DATA_DIRS,$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share"
      "EDITOR,nvim"
    ];

    xwayland = {
      force_zero_scaling = true;
    };

    ecosystem = {
      no_update_news = true;
    };
  };
}
