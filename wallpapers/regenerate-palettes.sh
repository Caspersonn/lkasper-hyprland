#!/usr/bin/env bash
# Regenerate a committed base16 palette (base00-base0F) for every static
# wallpaper in this directory, using wallust. Palettes are written to
# palettes/<slug>.json with bare hex (no leading '#') to match nix-colors.
#
# Per wallpaper we extract:
#   * base00-base0F           - faithful ANSI colours ("ansidark16"), so
#                               terminals and btop stay legible (red=red, ...).
#                               The base16 consumers (foot/btop/ghostty) use
#                               these via the nix colorScheme.
#   * accent / accent2 / accent3 - the most vivid, hue-diverse colours in the
#                               image (from a non-ANSI "dark" run). The AGS UI
#                               is fully driven by these: the primary accent
#                               plus two secondaries replace the ANSI-anchored
#                               (otherwise identical across wallpapers) slots in
#                               the AGS-only colors.json, so nothing in the shell
#                               is a static colour. A hue-rotation fallback
#                               guarantees three distinct colours even for a
#                               near-monochrome wallpaper.
#
# Run it with wallust + python3 + jq available, e.g.:
#   nix shell nixpkgs#wallust nixpkgs#python3 nixpkgs#jq \
#     --command ./wallpapers/regenerate-palettes.sh
#
# Add a wallpaper: drop a .png/.jpg here, run this, commit the new palette.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out_dir="$here/palettes"
mkdir -p "$out_dir"

cfg="$(mktemp -d)"
mkdir -p "$cfg/wallust/templates" "$cfg/cache"
cp "$here/base16-template.json" "$cfg/wallust/templates/base16.json"
# Vivid candidate colours to pick the three accents from.
printf '%s' '["{{color1}}","{{color2}}","{{color3}}","{{color4}}","{{color5}}","{{color6}}","{{color7}}","{{color9}}","{{color10}}","{{color11}}","{{color12}}","{{color13}}","{{color14}}"]' \
  > "$cfg/wallust/templates/accents.json"

# Pick 3 vivid, hue-diverse accents from wallust's candidate list on stdin.
cat > "$cfg/pick.py" <<'PY'
import sys, colorsys, json
def rgb(h):
    h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))
def hsv(h):
    r,g,b=[x/255 for x in rgb(h)]; return colorsys.rgb_to_hsv(r,g,b)
def chroma(h):
    r,g,b=rgb(h); return max(r,g,b)-min(r,g,b)
def hexof(hh,s,v):
    r,g,b=colorsys.hsv_to_rgb(hh%1.0,s,v); return "%02X%02X%02X"%(round(r*255),round(g*255),round(b*255))
def hue_deg(h): return hsv(h)[0]*360
def far(a,b,th=40):
    d=abs(a-b)%360; d=min(d,360-d); return d>=th
def lift(c):                                    # floor brightness: dark UI clamp
    h,s,v=hsv('#'+c); return hexof(h,s,max(v,0.55))
cands=[c.lstrip('#') for c in json.load(sys.stdin) if c]
viv=[c for c in cands if chroma(c)>=40 and max(rgb(c))>=55]
viv.sort(key=lambda c:-chroma(c))
picks=[]
for c in viv:                                   # most vivid, hue-diverse first
    if all(far(hue_deg(c),hue_deg(p)) for p in picks):
        picks.append(c)
    if len(picks)==3: break
for c in viv:                                   # relax hue-diversity if short
    if len(picks)>=3: break
    if c not in picks: picks.append(c)
if picks:                                       # rotate primary hue to fill 3
    ph,ps,pv=hsv('#'+picks[0]); ps=max(ps,0.55); pv=min(max(pv,0.55),0.92)
    while len(picks)<3:
        picks.append(hexof(ph+(1.0/3)*len(picks), ps, pv))
else:
    picks=['888888','888888','888888']
print(json.dumps([lift(c) for c in picks[:3]]))
PY

shopt -s nullglob
for img in "$here"/*.png "$here"/*.jpg "$here"/*.jpeg; do
  slug="$(basename "${img%.*}")"

  # 1. faithful base16 (ANSI-anchored) for the terminal
  cat > "$cfg/wallust/wallust.toml" <<TOML
backend = "fastresize"
color_space = "lchansi"
palette = "ansidark16"
check_contrast = true
[templates]
base16 = { template = 'base16.json', target = '$out_dir/$slug.raw.json' }
TOML
  XDG_CONFIG_HOME="$cfg" XDG_CACHE_HOME="$cfg/cache" wallust run "$img" -q -s

  # 2. accents = vivid hue-diverse colours from a non-ANSI "dark" run
  cat > "$cfg/wallust/wallust.toml" <<TOML
backend = "fastresize"
color_space = "lch"
palette = "dark"
check_contrast = true
[templates]
accents = { template = 'accents.json', target = '$cfg/accents.json' }
TOML
  XDG_CONFIG_HOME="$cfg" XDG_CACHE_HOME="$cfg/cache" wallust run "$img" -q -s
  read -r a1 a2 a3 < <(python3 "$cfg/pick.py" < "$cfg/accents.json" | jq -r '@tsv')

  # strip '#' from base16, splice in the bare-hex accents
  sed 's/#//g' "$out_dir/$slug.raw.json" \
    | jq --arg a "$a1" --arg b "$a2" --arg c "$a3" \
        '. + {accent: $a, accent2: $b, accent3: $c}' > "$out_dir/$slug.json"
  rm -f "$out_dir/$slug.raw.json"
  echo "generated palettes/$slug.json (accents #$a1 / #$a2 / #$a3)"
done

rm -rf "$cfg"
