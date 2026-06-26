#!/usr/bin/env bash
set -euo pipefail

NS="${1:-bar}"
OUT="${2:-/tmp/ags-shot.png}"
PAD="${3:-6}"

GRIM="$(ls /nix/store/*-grim-*/bin/grim 2>/dev/null | head -1)"
[ -z "$GRIM" ] && { echo "grim not found in nix store" >&2; exit 1; }

read -r x y w h < <(hyprctl layers -j | python3 -c "
import json,sys
d=json.load(sys.stdin)
for mon in d.values():
    for lvl in mon['levels'].values():
        for s in lvl:
            if s.get('namespace')=='$NS':
                print(s['x'],s['y'],s['w'],s['h']); sys.exit()
")
[ -z "${x:-}" ] && { echo "layer namespace '$NS' not found" >&2; exit 1; }

"$GRIM" -g "$((x-PAD)),$((y-PAD)) $((w+2*PAD))x$((h+2*PAD))" -s 2 "$OUT"
echo "$OUT"
