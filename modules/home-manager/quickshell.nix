{ ... }:

{
  flake.homeManagerModules.lkh-quickshell =
    { pkgs, ... }:
    {
      programs.quickshell = {
        enable = true;

        # We use ~/.config/quickshell directly.
        activeConfig = null;

        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };
      };

      xdg.configFile."quickshell" = {
        source = ../../quickshell;
        recursive = true;
      };

      home.packages = with pkgs; [
        brightnessctl
      ];

      services.awww.enable = true;
    };
}
