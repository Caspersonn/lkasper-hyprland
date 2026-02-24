{ pkgs, lib, exclude_packages ? [ ], }:
let
  hyprlandPackages = with pkgs; [
    hyprshot
    hyprpicker
    hyprsunset
    brightnessctl
    pamixer
    playerctl
    gnome-themes-extra
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    pavucontrol
  ];

  systemPackages = with pkgs; [
    git
    vim
    libnotify
    nautilus
    alejandra
    blueberry
    clipse
    fzf
    zoxide
    ripgrep
    eza
    fd
    curl
    unzip
    wget
    gnumake
  ];

  discretionaryPackages = with pkgs;
    [
      # TUIs
      lazygit
      lazydocker
      btop
      powertop
      fastfetch

      # GUIs
      chromium
      obsidian
      vlc
      signal-desktop

      # Development tools
      github-desktop
      gh

      # Containers
      docker-compose
      ffmpeg
    ]
    ++ lib.optionals (pkgs.system == "x86_64-linux") [ typora dropbox spotify ];

  filteredDiscretionaryPackages = lib.lists.subtractLists exclude_packages discretionaryPackages; allSystemPackages = hyprlandPackages ++ systemPackages ++ filteredDiscretionaryPackages;
in {
  systemPackages = allSystemPackages;

  homePackages = with pkgs;
    [
      xdg-desktop-portal-gtk
    ];
}
