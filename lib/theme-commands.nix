{
  pkgs,
  lib,
  lkh,
}:
let
  inherit (lkh)
    themeRoot
    stateDir
    defaultPair
    defaultMode
    ;
migrateCurrent = ''
  if [ -e "${stateDir}/current" ] && [ ! -L "${stateDir}/current" ]; then
    rm -f "${stateDir}/current/theme.name"
    rmdir "${stateDir}/current" 2>/dev/null || rm -rf "${stateDir}/current"
  fi
  rm -f "${stateDir}/current.new"
'';

theme-apply = pkgs.writeShellApplication {
  name = "theme-apply";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.glib
    pkgs.procps
    pkgs.tmux
    pkgs.fish
    pkgs.jq
  ];
  text = ''
    pair="''${1:-}"
    mode="''${2:-}"
    if [ -z "$pair" ] || [ -z "$mode" ]; then
      echo "usage: theme-apply <pair> <light|dark>" >&2
      exit 1
    fi
    if [ "$mode" != "light" ] && [ "$mode" != "dark" ]; then
      echo "theme-apply: mode must be light or dark, got '$mode'" >&2
      exit 1
    fi

    bundle="$HOME/${themeRoot}/$pair/$mode"
    if [ ! -d "$bundle" ]; then
      echo "theme-apply: no theme bundle at $bundle" >&2
      exit 1
    fi

    mkdir -p "${stateDir}"
    ${migrateCurrent}
    ln -sfn "$bundle" "${stateDir}/current.new"
    mv -Tf "${stateDir}/current.new" "${stateDir}/current"
    printf '%s %s\n' "$pair" "$mode" > "${stateDir}/state"

    if [ -f "$bundle/wallpaper.path" ]; then
      wallpaper="$(cat "$bundle/wallpaper.path")"
      hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 || true
      hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null 2>&1 || true
    fi

    hyprctl reload >/dev/null 2>&1 || true

    pkill -USR1 -x foot >/dev/null 2>&1 || true

    claude_settings="$HOME/.claude/settings.json"
    if [ -f "$claude_settings" ]; then
      if jq --arg t "$mode-ansi" '.theme = $t' "$claude_settings" > "$claude_settings.lkh-new" 2>/dev/null; then
        mv -f "$claude_settings.lkh-new" "$claude_settings"
      else
        rm -f "$claude_settings.lkh-new"
      fi
    fi

    if command -v fish >/dev/null 2>&1; then
      fish -c 'source "'"${stateDir}"'/current/fish.fish"' >/dev/null 2>&1 || true
    fi

    for tmux_dir in "''${TMUX_TMPDIR:-}" "/run/user/$(id -u)" /tmp; do
      [ -n "$tmux_dir" ] || continue
      tmux_sockets="$tmux_dir/tmux-$(id -u)"
      [ -d "$tmux_sockets" ] || continue
      for tmux_socket in "$tmux_sockets"/*; do
        [ -S "$tmux_socket" ] || continue
        tmux -S "$tmux_socket" source-file "${stateDir}/current/tmux.conf" >/dev/null 2>&1 || true
        tmux -S "$tmux_socket" refresh-client -S >/dev/null 2>&1 || true
      done
    done

    if gdbus call --session --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.ListNames 2>/dev/null |
        grep -q com.mitchellh.ghostty; then
      gdbus call --session --dest com.mitchellh.ghostty \
        --object-path /com/mitchellh/ghostty \
        --method org.gtk.Actions.Activate reload-config "[]" "{}" >/dev/null 2>&1 || true
    fi

    export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:''${XDG_DATA_DIRS:-}"
    if [ "$mode" = "light" ]; then
      gsettings set org.gnome.desktop.interface color-scheme prefer-light >/dev/null 2>&1 || true
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita >/dev/null 2>&1 || true
    else
      gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark >/dev/null 2>&1 || true
    fi

    ags request theme-reload >/dev/null 2>&1 || true
  '';
};

theme-state = pkgs.writeShellApplication {
  name = "theme-state";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    pair="${defaultPair}"
    mode="${defaultMode}"
    if [ -f "${stateDir}/state" ]; then
      read -r saved_pair saved_mode < "${stateDir}/state" || true
      if [ -n "''${saved_pair:-}" ] && [ -d "$HOME/${themeRoot}/$saved_pair" ]; then
        pair="$saved_pair"
      fi
      if [ "''${saved_mode:-}" = "light" ] || [ "''${saved_mode:-}" = "dark" ]; then
        mode="$saved_mode"
      fi
    fi
    printf '%s %s\n' "$pair" "$mode"
  '';
};

theme-toggle = pkgs.writeShellApplication {
  name = "theme-toggle";
  runtimeInputs = [
    pkgs.coreutils
    theme-apply
    theme-state
  ];
  text = ''
    read -r pair mode < <(theme-state)
    if [ "$mode" = "dark" ]; then
      theme-apply "$pair" light
    else
      theme-apply "$pair" dark
    fi
  '';
};

theme-switch = pkgs.writeShellApplication {
  name = "theme-switch";
  runtimeInputs = [
    pkgs.coreutils
    theme-apply
    theme-state
  ];
  text = ''
    target="''${1:-}"
    if [ -z "$target" ]; then
      echo "usage: theme-switch <pair>" >&2
      exit 1
    fi
    read -r _ mode < <(theme-state)
    theme-apply "$target" "$mode"
  '';
};
in
{
  inherit
    migrateCurrent
    theme-apply
    theme-state
    theme-toggle
    theme-switch
    ;

  all = [
    theme-apply
    theme-state
    theme-toggle
    theme-switch
  ];
}
