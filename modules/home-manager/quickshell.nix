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

      #services.awww.enable = true;

      home.sessionVariables = {
        QUICKSHELL_KDE_INTEGRATION = "1";
      };

      wayland.windowManager.hyprland.settings = {
        bindd = [
          # Launcher
          "SUPER, SPACE, [Launcher] App launcher, exec, qs ipc call launcher toggle"

          # System
          # "SUPER, slash, [System] Keyboard shortcuts, exec, ags request toggle-shortcuts" Needs to be build
          "SUPER SHIFT, SPACE, [System] Toggle bars, exec, qs ipc call bar toggle"
          # "SUPER, N, [System] Notification center, exec, ags request toggle-notifications" Is not there yet
          "SUPER SHIFT, N, [System] Toggle do not disturb, exec, qs ipc call notifications dnd_toggle"
          # "SUPER, T, [System] Soltty time tracker, exec, ags request toggle-soltty" Is not there yet
          # "SUPER, W, [System] Wallpaper picker, exec, ags request toggle-wallpaper-picker" Not there yet
          "SUPER SHIFT, W, [System] Toggle light dark mode, exec, theme-toggle"
        ];

        #bindl = [
        #  ", XF86AudioNext, exec, playerctl next && ags request osd-media next"
        #  ", XF86AudioPause, exec, playerctl play-pause && ags request osd-media playpause"
        #  ", XF86AudioPlay, exec, playerctl play-pause && ags request osd-media playpause"
        #  ", XF86AudioPrev, exec, playerctl previous && ags request osd-media prev"
        #];
      };
    };
}
