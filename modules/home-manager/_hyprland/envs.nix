{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  cfg = config.omarchy;
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
    QT_STYLE_OVERRIDE = "kvantum";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
    CHROMIUM_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4";
    XCOMPOSEFILE = "~/.XCompose";
    EDITOR = "nvim";
    OMARCHY_PATH = "${config.home.homeDirectory}/.local/share/omarchy";
    # Disable libadwaita portal for dark mode - portal is broken, use direct GTK settings instead
    ADW_DISABLE_PORTAL = "1";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share";
  };

  # Import environment variables into systemd user environment
  # This is needed for apps launched via .desktop files (e.g., from wofi)
  systemd.user.sessionVariables = config.home.sessionVariables;

  wayland.windowManager.hyprland.settings = {
    # Environment variables — mirrors home.sessionVariables so Hyprland
    # child processes also see them before the session vars are sourced
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
      "XCOMPOSEFILE,~/.XCompose"
      "EDITOR,nvim"
      "OMARCHY_PATH,${config.home.homeDirectory}/.local/share/omarchy"
      "PATH,$PATH:${config.home.homeDirectory}/.local/share/omarchy/bin"
      "ADW_DISABLE_PORTAL,1"
    ];

    xwayland = {
      force_zero_scaling = true;
    };

    # Don't show update on first launch
    ecosystem = {
      no_update_news = true;
    };
  };
}
