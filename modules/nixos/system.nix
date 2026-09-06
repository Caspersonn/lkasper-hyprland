{ inputs, ... }:
{
  flake.nixosModules.lkh-system =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config."lkasper-hyprland";
      packages = import ../_packages.nix {
        inherit pkgs lib;
        exclude_packages = cfg.exclude_packages;
      };
    in
    {
      options."lkasper-hyprland" = (import ../../config.nix lib).lkasperHyprlandOptions;

      config = {
        nixpkgs.config.allowUnfree = true;

        # Initial login experience
        services.greetd = {
          enable = true;
          settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        };

        # Install packages
        environment.systemPackages = packages.systemPackages;
        programs.direnv.enable = true;
        programs.nautilus-open-any-terminal = {
          enable = true;
          terminal = "ghostty";
        };

        # For battery display ags
        services.upower = {
          enable = true;
        };

        #fonts.packages = with pkgs; [
        #  noto-fonts
        #  noto-fonts-color-emoji
        #  nerd-fonts.caskaydia-mono
        #  nerd-fonts.jetbrains-mono
        #];
      };
    };
}
