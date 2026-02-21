{ inputs, ... }: {
  flake.nixosModules.omarchy-hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable = true;
      package =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        pkgs.xdg-desktop-portal-hyprland; # Use stable nixpkgs version to fix Qt version mismatch
    };

    # Configure XDG desktop portals for proper GTK dark mode support
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # Provides Settings portal for GTK apps
      ];
      config = {
        common = { default = [ "gtk" ]; };
        hyprland = { default = [ "hyprland" "gtk" ]; };
      };
    };
  };
}
