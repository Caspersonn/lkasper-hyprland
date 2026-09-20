{ inputs, ... }:
{
  flake.homeManagerModules.lkh-hyprland =
    { config, pkgs, ... }:
    {
      imports = [ ./_hyprland/configuration.nix ];
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
      services.hyprpolkitagent.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };
}
