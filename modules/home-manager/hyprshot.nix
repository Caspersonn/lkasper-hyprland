{ inputs, ... }:
{
  flake.homeManagerModules.omarchy-hyprshot =
    { config, pkgs, ... }:
    {
      programs.hyprshot = {
        enable = true;
        saveLocation = "$HOME/Pictures/Screenshots";
      };
    };
}
