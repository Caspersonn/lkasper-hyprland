{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.settings = {
    on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd("sleep 1 && lkasper-shell")
            hl.exec_cmd("hyprsunset")
            hl.exec_cmd("systemctl --user start hyprpolkitagent")
            hl.exec_cmd("wl-clip-persist --clipboard regular & clipse -listen")
            hl.exec_cmd("elephant")
            hl.exec_cmd("walker --gapplication-service")
          end'')
      ];
    };
  };
}
