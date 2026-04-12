{ inputs, ... }:
{
  flake.homeManagerModules.lkh-hyprland =
    { config, pkgs, ... }:
    {
      imports = [ ./_hyprland/configuration.nix ];
      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
      services.hyprpolkitagent.enable = true;
    };
}
