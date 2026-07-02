{
  pkgs,
  lib,
  exclude_packages ? [ ],
}:
let
  # Essential Hyprland packages - cannot be excluded
  hyprlandPackages = with pkgs; [
    hyprpicker
    hyprsunset
    brightnessctl
    pamixer
    playerctl
    gnome-themes-extra
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    pavucontrol
    adwaita-icon-theme
    gruvbox-plus-icons
    hicolor-icon-theme
  ];

in
{
  systemPackages = hyprlandPackages;
}
