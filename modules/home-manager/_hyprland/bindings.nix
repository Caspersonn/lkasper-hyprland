{ config, pkgs, ... }:
let
  cfg = config."lkasper-hyprland";
in
{
  wayland.windowManager.hyprland.settings = {
    # Plain binds: app launchers (from config) plus mouse-scroll workspace
    # switching. These carry no description and are intentionally hidden from
    # the keybind cheatsheet overlay.
    bind = cfg.quick_app_bindings ++ [
      #"SUPER, I, exec, [workspace 1 silent;] ghostty"
      #"SUPER, I, exec, [workspace 2 silent;] firefox"

      # Scroll through existing workspaces with mainMod + scroll
      "SUPER, mouse_down, workspace, e+1"
      "SUPER, mouse_up, workspace, e-1"
    ];

    # Described binds: surfaced in the keybind cheatsheet overlay (SUPER, slash).
    # Format: MODS, KEY, [Group] Label, DISPATCHER, ARGS
    # The description carries no commas; the leading [Group] tag drives grouping.
    bindd = [
      # Launcher
      "SUPER, SPACE, [Launcher] App launcher, exec, ags request toggle-launcher"
      "SUPER CTRL, SPACE, [Launcher] Walker fallback, exec, walker"
      "CTRL SUPER, V, [Launcher] Clipboard history, exec, foot --title=clipse clipse"
      "CTRL SUPER, N, [Launcher] Network manager, exec, foot --title=nmtui nmtui"

      # System
      "SUPER, slash, [System] Keyboard shortcuts, exec, ags request toggle-shortcuts"
      "SUPER SHIFT, SPACE, [System] Toggle bars, exec, ags request toggle-bars"
      "SUPER, N, [System] Notification center, exec, ags request toggle-notifications"
      "SUPER SHIFT, N, [System] Toggle do not disturb, exec, ags request toggle-dnd"
      "SUPER, T, [System] Soltty time tracker, exec, ags request toggle-soltty"
      "SUPER, W, [System] Wallpaper picker, exec, ags request toggle-wallpaper-picker"

      # Windows
      "SUPER, I, [Windows] Pin window, exec, hyprctl dispatch pin"
      "SUPER, Q, [Windows] Close window, killactive,"
      "SUPER, Backspace, [Windows] Close window, killactive,"
      "SUPER, V, [Windows] Toggle floating, togglefloating,"
      "SUPER, F, [Windows] Fullscreen, fullscreen, 1"
      "SUPER SHIFT, F, [Windows] Maximize, fullscreen, 0"

      # Focus
      "SUPER, left, [Focus] Focus left, movefocus, l"
      "SUPER, right, [Focus] Focus right, movefocus, r"
      "SUPER, up, [Focus] Focus up, movefocus, u"
      "SUPER, down, [Focus] Focus down, movefocus, d"

      # Tiling
      "SUPER, J, [Tiling] Toggle split, layoutmsg, togglesplit"
      "SUPER, P, [Tiling] Pseudotile, pseudo,"
      "SUPER, minus, [Tiling] Shrink width, resizeactive, -100 0"
      "SUPER, equal, [Tiling] Grow width, resizeactive, 100 0"
      "SUPER SHIFT, minus, [Tiling] Shrink height, resizeactive, 0 -100"
      "SUPER SHIFT, equal, [Tiling] Grow height, resizeactive, 0 100"
      "SUPER SHIFT, left, [Tiling] Swap left, swapwindow, l"
      "SUPER SHIFT, right, [Tiling] Swap right, swapwindow, r"
      "SUPER SHIFT, up, [Tiling] Swap up, swapwindow, u"
      "SUPER SHIFT, down, [Tiling] Swap down, swapwindow, d"

      # Workspaces (SUPER + digit binds collapse into a range row in the overlay)
      "SUPER, 1, [Workspaces] Switch workspace, workspace, 1"
      "SUPER, 2, [Workspaces] Switch workspace, workspace, 2"
      "SUPER, 3, [Workspaces] Switch workspace, workspace, 3"
      "SUPER, 4, [Workspaces] Switch workspace, workspace, 4"
      "SUPER, 5, [Workspaces] Switch workspace, workspace, 5"
      "SUPER, 6, [Workspaces] Switch workspace, workspace, 6"
      "SUPER, 7, [Workspaces] Switch workspace, workspace, 7"
      "SUPER, 8, [Workspaces] Switch workspace, workspace, 8"
      "SUPER, 9, [Workspaces] Switch workspace, workspace, 9"
      "SUPER, 0, [Workspaces] Switch workspace, workspace, 10"
      "SUPER, comma, [Workspaces] Previous workspace, workspace, -1"
      "SUPER, period, [Workspaces] Next workspace, workspace, +1"
      "SUPER SHIFT, 1, [Workspaces] Move to workspace, movetoworkspace, 1"
      "SUPER SHIFT, 2, [Workspaces] Move to workspace, movetoworkspace, 2"
      "SUPER SHIFT, 3, [Workspaces] Move to workspace, movetoworkspace, 3"
      "SUPER SHIFT, 4, [Workspaces] Move to workspace, movetoworkspace, 4"
      "SUPER SHIFT, 5, [Workspaces] Move to workspace, movetoworkspace, 5"
      "SUPER SHIFT, 6, [Workspaces] Move to workspace, movetoworkspace, 6"
      "SUPER SHIFT, 7, [Workspaces] Move to workspace, movetoworkspace, 7"
      "SUPER SHIFT, 8, [Workspaces] Move to workspace, movetoworkspace, 8"
      "SUPER SHIFT, 9, [Workspaces] Move to workspace, movetoworkspace, 9"
      "SUPER SHIFT, 0, [Workspaces] Move to workspace, movetoworkspace, 10"
      "SUPER, S, [Workspaces] Toggle scratchpad, togglespecialworkspace, magic"
      "SUPER SHIFT, S, [Workspaces] Move to scratchpad, movetoworkspace, special:magic"

      # Session
      "SUPER, ESCAPE, [Session] Lock screen, exec, hyprlock"
      "SUPER SHIFT, ESCAPE, [Session] Exit Hyprland, exit,"
      "SUPER CTRL, ESCAPE, [Session] Reboot, exec, reboot"
      "SUPER SHIFT CTRL, ESCAPE, [Session] Suspend, exec, hyprlock & disown && systemctl suspend"

      # Screenshots
      "SUPER CTRL, S, [Screenshots] Region, exec, hyprshot -m region"
      "SUPER CTRL, W, [Screenshots] Active window, exec, hyprshot -m window -m active"
      "CTRL, PRINT, [Screenshots] Full output, exec, hyprshot -m output"
      "SUPER, PRINT, [Screenshots] Color picker, exec, hyprpicker -a"
    ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    bindel = [
      # Laptop multimedia keys for volume and LCD brightness
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
      ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
    ];

    bindl = [
      # Requires playerctl
      # Each media key pings AGS with its action so the OSD shows the matching
      # icon (play/pause/next/prev). Keyboard-only on purpose: MPRIS cannot tell
      # a user skip from a track auto-advance, so we never trigger reactively.
      ", XF86AudioNext, exec, playerctl next && ags request osd-media next"
      ", XF86AudioPause, exec, playerctl play-pause && ags request osd-media playpause"
      ", XF86AudioPlay, exec, playerctl play-pause && ags request osd-media playpause"
      ", XF86AudioPrev, exec, playerctl previous && ags request osd-media prev"
    ];

    bindp = [
      # Powerprofileselecter
      "SUPER+Ctrl+Shift, W, exec, powerprofilesctl set power-saver & notify-send -u low 'Power Profile 🚀' 'power-saver'"
      "SUPER+Ctrl+Shift, E, exec, powerprofilesctl set balanced & notify-send -u low 'Power Profile 🚀' 'balanced'"
      "SUPER+Ctrl+Shift, R, exec, powerprofilesctl set performance & notify-send -u low 'Power Profile 🚀' 'perfomance'"
    ];
  };
}
