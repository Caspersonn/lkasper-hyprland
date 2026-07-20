#!/usr/bin/env bash
# Regenerate a committed base16 palette (base00–base0F) for every static
# wallpaper in this directory, using wallust. Palettes are written to
# palettes/<slug>.json with bare hex (no leading '#') to match nix-colors.
#
# Run it with wallust available, e.g.:
#   nix shell nixpkgs#wallust --command ./wallpapers/regenerate-palettes.sh
#
# Add a wallpaper: drop a .png/.jpg here, run this, commit the new palette.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out_dir="$here/palettes"
mkdir -p "$out_dir"

cfg="$(mktemp -d)"
mkdir -p "$cfg/wallust/templates" "$cfg/cache"
cp "$here/base16-template.json" "$cfg/wallust/templates/base16.json"

shopt -s nullglob
for img in "$here"/*.png "$here"/*.jpg "$here"/*.jpeg; do
  slug="$(basename "${img%.*}")"
  cat > "$cfg/wallust/wallust.toml" <<TOML
backend = "fastresize"
color_space = "lchansi"
palette = "ansidark16"
check_contrast = true
[templates]
base16 = { template = 'base16.json', target = '$out_dir/$slug.raw.json' }
TOML
  XDG_CONFIG_HOME="$cfg" XDG_CACHE_HOME="$cfg/cache" wallust run "$img" -q -s
  # strip '#' so values are bare hex (nix-colors palette format)
  sed 's/#//g' "$out_dir/$slug.raw.json" > "$out_dir/$slug.json"
  rm -f "$out_dir/$slug.raw.json"
  echo "generated palettes/$slug.json"
done

rm -rf "$cfg"
