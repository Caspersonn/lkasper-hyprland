{ inputs, ... }:
{
  flake.homeManagerModules.lkh-hyprshot =
    { config, pkgs, ... }:
    {
      programs.hyprshot = {
        enable = true;
        saveLocation = "$HOME/Pictures/Screenshots";
      };
    };
}
