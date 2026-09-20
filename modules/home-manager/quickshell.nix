{ lib, ... }:

{
  flake.homeManagerModules.lkh-quickshell =
    { pkgs, ... }:
    {
      programs.quickshell = {
        enable = true;

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

      home.sessionVariables = {
        QUICKSHELL_KDE_INTEGRATION = "1";
      };

      wayland.windowManager.hyprland.settings = {
        bind = [
          {
            _args = [
              "SUPER + SPACE"
              (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("qs ipc call launcher toggle")'')
              { description = "[Launcher] App launcher"; }
            ];
          }
          {
            _args = [
              "SUPER + D"
              (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("qs ipc call monitors toggle")'')
              { description = "[monitor] Show monitor configration"; }
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + SPACE"
              (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("qs ipc call bar toggle")'')
              { description = "[System] Toggle bars"; }
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + N"
              (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("qs ipc call notifications dnd_toggle")'')
              { description = "[System] Toggle do not disturb"; }
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + W"
              (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("theme-toggle")'')
              { description = "[System] Toggle light dark mode"; }
            ];
          }
        ];
      };
    };
}
