#!/usr/bin/env bash
set -euo pipefail

CMD="${1:-start}"
STATE_DIR="${STATE_DIR:-/tmp/opencode/hypr-headless-vnc}"
RUNTIME_DIR="${RUNTIME_DIR:-/tmp/lhh}"
VNC_PORT="${VNC_PORT:-5902}"
NOVNC_PORT="${NOVNC_PORT:-6082}"
CONFIG_FILE="$STATE_DIR/hyprland.conf"
INSTANCE_FILE="$STATE_DIR/instance"
HYPRLAND_PID_FILE="$STATE_DIR/hyprland.pid"
WAYVNC_PID_FILE="$STATE_DIR/wayvnc.pid"
NOVNC_PID_FILE="$STATE_DIR/novnc.pid"

usage() {
    printf '%s\n' "usage: $0 [start|stop|status|screenshot]"
    printf '%s\n' "STATE_DIR=$STATE_DIR"
    printf '%s\n' "RUNTIME_DIR=$RUNTIME_DIR"
    printf '%s\n' "VNC_PORT=$VNC_PORT"
    printf '%s\n' "NOVNC_PORT=$NOVNC_PORT"
}

resolve_cmd() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if command -v "$cmd" >/dev/null 2>&1; then
        command -v "$cmd"
        return 0
    fi

    if command -v nix-shell >/dev/null 2>&1; then
        nix-shell -p "$pkg" --run "command -v $cmd"
        return 0
    fi

    printf '%s\n' "$cmd not found" >&2
    exit 1
}

host_wayland_socket() {
    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        printf '%s\n' "WAYLAND_DISPLAY is not set" >&2
        exit 1
    fi

    case "$WAYLAND_DISPLAY" in
        /*) printf '%s\n' "$WAYLAND_DISPLAY" ;;
        *) printf '%s/%s\n' "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}" "$WAYLAND_DISPLAY" ;;
    esac
}

check_port_free() {
    python3 - "$1" <<'PY'
import socket
import sys

port = int(sys.argv[1])
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("127.0.0.1", port))
except OSError as e:
    print(f"127.0.0.1:{port} is not available: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    s.close()
PY
}

safe_runtime_reset() {
    case "$RUNTIME_DIR" in
        /tmp/*) rm -rf "$RUNTIME_DIR" ;;
        *) printf '%s\n' "RUNTIME_DIR must be under /tmp" >&2; exit 1 ;;
    esac

    mkdir -p "$RUNTIME_DIR"
    chmod 700 "$RUNTIME_DIR"
}

write_config() {
    mkdir -p "$STATE_DIR"
    cat >"$CONFIG_FILE" <<'HYPRCONF'
monitor = ,preferred,auto,1

general {
    gaps_in = 0
    gaps_out = 0
    border_size = 0
}

decoration {
    rounding = 0
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}
HYPRCONF
}

instances_json() {
    local out

    out="$(env XDG_RUNTIME_DIR="$RUNTIME_DIR" hyprctl instances -j 2>/dev/null || true)"
    printf '%s' "$out" | python3 -c '
import json
import sys

try:
    data = json.loads(sys.stdin.read())
except Exception:
    data = []
if not isinstance(data, list):
    data = []
print(json.dumps(data))
'
}

first_instance_field() {
    python3 -c '
import json
import sys

field = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    data = []
if data:
    print(data[0].get(field, ""))
' "$1"
}

wait_for_instance() {
    local deadline=$((SECONDS + 20))
    local sig

    while [ "$SECONDS" -lt "$deadline" ]; do
        sig="$(instances_json | first_instance_field instance)"
        if [ -n "$sig" ]; then
            printf '%s\n' "$sig" >"$INSTANCE_FILE"
            instances_json | first_instance_field pid >"$HYPRLAND_PID_FILE"
            printf '%s\n' "$sig"
            return 0
        fi
        sleep 0.5
    done

    printf '%s\n' "nested Hyprland did not start" >&2
    [ -f "$STATE_DIR/hyprland.log" ] && tail -80 "$STATE_DIR/hyprland.log" >&2
    exit 1
}

instance() {
    local live

    live="$(instances_json | first_instance_field instance)"
    if [ -n "$live" ]; then
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$live" >"$INSTANCE_FILE"
        printf '%s\n' "$live"
        return 0
    fi

    rm -f "$INSTANCE_FILE"
}

nested_wayland_display() {
    instances_json | first_instance_field wl_socket
}

nested_hyprctl() {
    local sig
    sig="$(instance)"
    if [ -z "$sig" ]; then
        printf '%s\n' "nested instance not found" >&2
        exit 1
    fi
    env XDG_RUNTIME_DIR="$RUNTIME_DIR" hyprctl -i "$sig" "$@"
}

monitor_names() {
    nested_hyprctl monitors -j | python3 -c '
import json
import re
import sys

pattern = re.compile(sys.argv[1])
for monitor in json.load(sys.stdin):
    name = monitor.get("name", "")
    if pattern.search(name):
        print(name)
' "$1"
}

wait_for_monitor() {
    local name="$1"
    local deadline=$((SECONDS + 10))

    while [ "$SECONDS" -lt "$deadline" ]; do
        if monitor_names "^${name}$" | grep -qx "$name"; then
            return 0
        fi
        sleep 0.5
    done

    printf '%s\n' "$name did not appear" >&2
    nested_hyprctl monitors
    exit 1
}

kill_pid_file() {
    local pid_file="$1"
    local pid

    [ -s "$pid_file" ] || return 0
    pid="$(tr -d '\n' <"$pid_file")"

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill "$pid" 2>/dev/null || true
    fi

    rm -f "$pid_file"
}

start_hyprland() {
    local hyprland_bin
    local host_wl

    hyprland_bin="${HYPRLAND_BIN:-$(resolve_cmd Hyprland hyprland)}"
    host_wl="$(host_wayland_socket)"

    safe_runtime_reset
    write_config

    env XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        WAYLAND_DISPLAY="$host_wl" \
        HYPRLAND_NO_RT=1 \
        HYPRLAND_NO_CRASHREPORTER=1 \
        HYPRLAND_NO_SD_NOTIFY=1 \
        HYPRLAND_NO_SD_VARS=1 \
        setsid -f "$hyprland_bin" -c "$CONFIG_FILE" >"$STATE_DIR/hyprland.log" 2>&1

    wait_for_instance >/dev/null
}

make_headless_only() {
    local wayland_output

    nested_hyprctl output create headless >/dev/null
    wait_for_monitor HEADLESS-1

    while read -r wayland_output; do
        [ -n "$wayland_output" ] || continue
        nested_hyprctl output remove "$wayland_output" >/dev/null
    done < <(monitor_names '^WAYLAND-')
}

start_wayvnc() {
    local wayvnc_bin
    local wl

    check_port_free "$VNC_PORT"
    wayvnc_bin="$(resolve_cmd wayvnc wayvnc)"
    wl="$(nested_wayland_display)"

    env XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        WAYLAND_DISPLAY="$wl" \
        HYPRLAND_INSTANCE_SIGNATURE="$(instance)" \
        "$wayvnc_bin" 127.0.0.1 "$VNC_PORT" >"$STATE_DIR/wayvnc.log" 2>&1 &
    printf '%s\n' "$!" >"$WAYVNC_PID_FILE"
}

start_novnc() {
    local novnc_bin

    check_port_free "$NOVNC_PORT"
    novnc_bin="$(resolve_cmd novnc novnc)"

    "$novnc_bin" --vnc "localhost:$VNC_PORT" --listen "localhost:$NOVNC_PORT" >"$STATE_DIR/novnc.log" 2>&1 &
    printf '%s\n' "$!" >"$NOVNC_PID_FILE"
}

start() {
    if [ -n "$(instance)" ]; then
        printf '%s\n' "nested Hyprland already appears to be running in $RUNTIME_DIR" >&2
        exit 1
    fi

    check_port_free "$VNC_PORT"
    check_port_free "$NOVNC_PORT"
    start_hyprland
    make_headless_only
    start_wayvnc
    start_novnc

    printf '%s\n' "nested Hyprland: $(instance)"
    printf '%s\n' "VNC: 127.0.0.1:$VNC_PORT"
    printf '%s\n' "noVNC: http://localhost:$NOVNC_PORT/vnc.html?host=localhost&port=$NOVNC_PORT"
}

stop() {
    local sig

    kill_pid_file "$NOVNC_PID_FILE"
    pkill -TERM -f "localhost:${NOVNC_PORT} localhost:${VNC_PORT}" 2>/dev/null || true
    kill_pid_file "$WAYVNC_PID_FILE"
    pkill -TERM -f "wayvnc 127.0.0.1 ${VNC_PORT}" 2>/dev/null || true

    sig="$(instance)"
    if [ -n "$sig" ]; then
        env XDG_RUNTIME_DIR="$RUNTIME_DIR" hyprctl -i "$sig" dispatch exit >/dev/null 2>&1 || true
    fi

    kill_pid_file "$HYPRLAND_PID_FILE"
    rm -f "$INSTANCE_FILE"
}

status() {
    printf '%s\n' "STATE_DIR=$STATE_DIR"
    printf '%s\n' "RUNTIME_DIR=$RUNTIME_DIR"
    printf '%s\n' "VNC_PORT=$VNC_PORT"
    printf '%s\n' "NOVNC_PORT=$NOVNC_PORT"
    printf '%s\n' "instances:"
    instances_json
    if [ -n "$(instance)" ]; then
        printf '%s\n' "monitors:"
        nested_hyprctl monitors
    fi
}

screenshot() {
    local grim_bin
    local out="${2:-$STATE_DIR/headless.png}"
    local wl

    mkdir -p "$(dirname "$out")"
    grim_bin="$(resolve_cmd grim grim)"
    wl="$(nested_wayland_display)"

    env XDG_RUNTIME_DIR="$RUNTIME_DIR" WAYLAND_DISPLAY="$wl" "$grim_bin" -o HEADLESS-1 "$out"
    printf '%s\n' "$out"
}

case "$CMD" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    screenshot) screenshot "$@" ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 1 ;;
esac
