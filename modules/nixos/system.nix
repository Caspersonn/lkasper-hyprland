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

        security.rtkit.enable = true;
        services.pulseaudio.enable = false;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
          jack.enable = true;
        };

        # Initial login experience
        services.greetd = {
          enable = true;
          settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        };

        # Install packages
        environment.systemPackages = packages.systemPackages;
        programs.direnv.enable = true;

        # Networking
        services.resolved.enable = true;
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;
        networking = {
          networkmanager.enable = true;
        };

        # For battery display ags
        services.upower = {
          enable = true;
        };

        # For mpris cached spotify covers ags
        services.gvfs.enable = true;

        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-color-emoji
          nerd-fonts.caskaydia-mono
        ];
      };
    };
}
