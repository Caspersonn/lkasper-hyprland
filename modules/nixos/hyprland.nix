{ inputs, ... }:
{
  flake.nixosModules.lkh-hyprland =
    { pkgs, ... }:
    {

      nix.settings = {
        substituters = ["https://hyprland.cachix.org"];
        trusted-substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };

      programs.hyprland =  let
        hyprpkgs = inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}";
      in {
        enable = true;
        package = hyprpkgs.hyprland;
        portalPackage = hyprpkgs.xdg-desktop-portal-hyprland; # Use stable nixpkgs version to fix Qt version mismatch
      };

      # Configure XDG desktop portals for proper GTK dark mode support
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk # Provides Settings portal for GTK apps
        ];
        config = {
          common = {
            default = [ "gtk" ];
          };
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
          };
        };
      };
    };
}
