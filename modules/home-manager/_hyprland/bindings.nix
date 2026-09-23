{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config."lkasper-hyprland";

  inline = lib.generators.mkLuaInline;

  luaValue =
    v: if lib.isAttrs v && (v._type or "") == "lua-inline" then v.expr else builtins.toJSON v;

  dsp = expr: inline "hl.dsp.${expr}";
  execCmd = cmd: dsp "exec_cmd(${luaValue cmd})";

  mkBind =
    {
      keys,
      dispatcher,
      description ? null,
      opts ? { },
    }:
    let
      allOpts = opts // lib.optionalAttrs (description != null) { inherit description; };
    in
    {
      _args = [
        keys
        dispatcher
      ]
      ++ lib.optional (allOpts != { }) allOpts;
    };

  quickAppBinds = map (
    b:
    mkBind {
      inherit (b) keys;
      dispatcher = execCmd b.exec;
      description = b.description or null;
    }
  ) cfg.quick_app_bindings;

  digitKey = i: toString (lib.mod i 10);

  workspaceBinds = lib.concatMap (i: [
    (mkBind {
      keys = "SUPER + ${digitKey i}";
      dispatcher = dsp "focus({ workspace = ${toString i} })";
      description = "[Workspaces] Switch workspace";
    })
    (mkBind {
      keys = "SUPER + SHIFT + ${digitKey i}";
      dispatcher = dsp "window.move({ workspace = ${toString i} })";
      description = "[Workspaces] Move to workspace";
    })
  ]) (lib.range 1 10);

  mediaKeys = {
    locked = true;
    repeating = true;
  };
in
{
  wayland.windowManager.hyprland.settings = {
    bind =
      quickAppBinds
      ++ [
        (mkBind {
          keys = "SUPER + mouse_down";
          dispatcher = dsp ''focus({ workspace = "e+1" })'';
        })
        (mkBind {
          keys = "SUPER + mouse_up";
          dispatcher = dsp ''focus({ workspace = "e-1" })'';
        })

        (mkBind {
          keys = "SUPER + CTRL + SPACE";
          dispatcher = execCmd "walker";
          description = "[Launcher] Walker fallback";
        })
        (mkBind {
          keys = "SUPER + CTRL + V";
          dispatcher = execCmd "foot --title=clipse clipse";
          description = "[Launcher] Clipboard history";
        })
        (mkBind {
          keys = "SUPER + CTRL + N";
          dispatcher = execCmd "foot --title=nmtui nmtui";
          description = "[Launcher] Network manager";
        })

        (mkBind {
          keys = "SUPER + I";
          dispatcher = dsp "window.pin()";
          description = "[Windows] Pin window";
        })
        (mkBind {
          keys = "SUPER + Q";
          dispatcher = dsp "window.close()";
          description = "[Windows] Close window";
        })
        (mkBind {
          keys = "SUPER + Backspace";
          dispatcher = dsp "window.close()";
          description = "[Windows] Close window";
        })
        (mkBind {
          keys = "SUPER + V";
          dispatcher = dsp ''window.float({ action = "toggle" })'';
          description = "[Windows] Toggle floating";
        })
        (mkBind {
          keys = "SUPER + F";
          dispatcher = dsp ''window.fullscreen({ mode = "maximized" })'';
          description = "[Windows] Fullscreen";
        })
        (mkBind {
          keys = "SUPER + SHIFT + F";
          dispatcher = dsp ''window.fullscreen({ mode = "fullscreen" })'';
          description = "[Windows] Maximize";
        })

        (mkBind {
          keys = "SUPER + left";
          dispatcher = dsp ''focus({ direction = "left" })'';
          description = "[Focus] Focus left";
        })
        (mkBind {
          keys = "SUPER + right";
          dispatcher = dsp ''focus({ direction = "right" })'';
          description = "[Focus] Focus right";
        })
        (mkBind {
          keys = "SUPER + up";
          dispatcher = dsp ''focus({ direction = "up" })'';
          description = "[Focus] Focus up";
        })
        (mkBind {
          keys = "SUPER + down";
          dispatcher = dsp ''focus({ direction = "down" })'';
          description = "[Focus] Focus down";
        })

        (mkBind {
          keys = "SUPER + J";
          dispatcher = dsp ''layout("togglesplit")'';
          description = "[Tiling] Toggle split";
        })
        (mkBind {
          keys = "SUPER + P";
          dispatcher = dsp "window.pseudo()";
          description = "[Tiling] Pseudotile";
        })
        (mkBind {
          keys = "SUPER + minus";
          dispatcher = dsp "window.resize({ x = -100, y = 0, relative = true })";
          description = "[Tiling] Shrink width";
        })
        (mkBind {
          keys = "SUPER + equal";
          dispatcher = dsp "window.resize({ x = 100, y = 0, relative = true })";
          description = "[Tiling] Grow width";
        })
        (mkBind {
          keys = "SUPER + SHIFT + minus";
          dispatcher = dsp "window.resize({ x = 0, y = -100, relative = true })";
          description = "[Tiling] Shrink height";
        })
        (mkBind {
          keys = "SUPER + SHIFT + equal";
          dispatcher = dsp "window.resize({ x = 0, y = 100, relative = true })";
          description = "[Tiling] Grow height";
        })
        (mkBind {
          keys = "SUPER + SHIFT + left";
          dispatcher = dsp ''window.swap({ direction = "left" })'';
          description = "[Tiling] Swap left";
        })
        (mkBind {
          keys = "SUPER + SHIFT + right";
          dispatcher = dsp ''window.swap({ direction = "right" })'';
          description = "[Tiling] Swap right";
        })
        (mkBind {
          keys = "SUPER + SHIFT + up";
          dispatcher = dsp ''window.swap({ direction = "up" })'';
          description = "[Tiling] Swap up";
        })
        (mkBind {
          keys = "SUPER + SHIFT + down";
          dispatcher = dsp ''window.swap({ direction = "down" })'';
          description = "[Tiling] Swap down";
        })
      ]
      ++ workspaceBinds
      ++ [
        (mkBind {
          keys = "SUPER + comma";
          dispatcher = dsp ''focus({ workspace = "-1" })'';
          description = "[Workspaces] Previous workspace";
        })
        (mkBind {
          keys = "SUPER + period";
          dispatcher = dsp ''focus({ workspace = "+1" })'';
          description = "[Workspaces] Next workspace";
        })
        (mkBind {
          keys = "SUPER + S";
          dispatcher = dsp ''workspace.toggle_special("magic")'';
          description = "[Workspaces] Toggle scratchpad";
        })
        (mkBind {
          keys = "SUPER + SHIFT + S";
          dispatcher = dsp ''window.move({ workspace = "special:magic" })'';
          description = "[Workspaces] Move to scratchpad";
        })

        (mkBind {
          keys = "SUPER + ESCAPE";
          dispatcher = execCmd "hyprlock";
          description = "[Session] Lock screen";
        })
        (mkBind {
          keys = "SUPER + SHIFT + ESCAPE";
          dispatcher = dsp "exit()";
          description = "[Session] Exit Hyprland";
        })
        (mkBind {
          keys = "SUPER + CTRL + ESCAPE";
          dispatcher = execCmd "reboot";
          description = "[Session] Reboot";
        })
        (mkBind {
          keys = "SUPER + SHIFT + CTRL + ESCAPE";
          dispatcher = execCmd "hyprlock & disown && systemctl suspend";
          description = "[Session] Suspend";
        })

        (mkBind {
          keys = "SUPER + CTRL + S";
          dispatcher = execCmd "hyprshot -m region";
          description = "[Screenshots] Region";
        })
        (mkBind {
          keys = "SUPER + CTRL + W";
          dispatcher = execCmd "hyprshot -m window -m active";
          description = "[Screenshots] Active window";
        })
        (mkBind {
          keys = "CTRL + PRINT";
          dispatcher = execCmd "hyprshot -m output";
          description = "[Screenshots] Full output";
        })
        (mkBind {
          keys = "SUPER + PRINT";
          dispatcher = execCmd "hyprpicker -a";
          description = "[Screenshots] Color picker";
        })

        (mkBind {
          keys = "SUPER + mouse:272";
          dispatcher = dsp "window.drag()";
          opts.mouse = true;
        })
        (mkBind {
          keys = "SUPER + mouse:273";
          dispatcher = dsp "window.resize()";
          opts.mouse = true;
        })

        (mkBind {
          keys = "XF86AudioRaiseVolume";
          dispatcher = execCmd "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86AudioLowerVolume";
          dispatcher = execCmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86AudioMute";
          dispatcher = execCmd "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86AudioMicMute";
          dispatcher = execCmd "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86MonBrightnessUp";
          dispatcher = execCmd "brightnessctl -e4 -n2 set 5%+";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86MonBrightnessDown";
          dispatcher = execCmd "brightnessctl -e4 -n2 set 5%-";
          opts = mediaKeys;
        })

        (mkBind {
          keys = "SUPER + CTRL + SHIFT + W";
          dispatcher = execCmd "powerprofilesctl set power-saver & notify-send -u low 'Power Profile ' 'power-saver'";
          opts.dont_inhibit = true;
        })
        (mkBind {
          keys = "SUPER + CTRL + SHIFT + E";
          dispatcher = execCmd "powerprofilesctl set balanced & notify-send -u low 'Power Profile ' 'balanced'";
          opts.dont_inhibit = true;
        })
        (mkBind {
          keys = "SUPER + CTRL + SHIFT + R";
          dispatcher = execCmd "powerprofilesctl set performance & notify-send -u low 'Power Profile ' 'perfomance'";
          opts.dont_inhibit = true;
        })

        (mkBind {
          keys = "XF86AudioNext";
          dispatcher = execCmd "playerctl next";
          opts = mediaKeys;
        })
        (mkBind {
          keys = "XF86AudioPause";
          dispatcher = execCmd "playerctl play-pause";
          opts.dont_inhibit = true;
        })
        (mkBind {
          keys = "XF86AudioPlay";
          dispatcher = execCmd "playerctl play-pause";
          opts.dont_inhibit = true;
        })
        (mkBind {
          keys = "XF86AudioPrev";
          dispatcher = execCmd "playerctl previous";
          opts.dont_inhibit = true;
        })
      ];
  };
}
