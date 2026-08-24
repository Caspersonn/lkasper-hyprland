#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out_dir="$here/palettes"
tool="$here/palette-tool.py"
mkdir -p "$out_dir"

for binary in wallust python3 jq nix; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "regenerate-palettes: missing $binary" >&2
    echo "try: nix shell nixpkgs#wallust nixpkgs#python3 nixpkgs#jq --command $0" >&2
    exit 1
  fi
done

cfg="$(mktemp -d)"
trap 'rm -rf "$cfg"' EXIT
mkdir -p "$cfg/wallust/templates" "$cfg/cache"
cp "$here/base16-template.json" "$cfg/wallust/templates/base16.json"
printf '%s' '["{{color1}}","{{color2}}","{{color3}}","{{color4}}","{{color5}}","{{color6}}","{{color7}}","{{color9}}","{{color10}}","{{color11}}","{{color12}}","{{color13}}","{{color14}}"]' \
  > "$cfg/wallust/templates/accents.json"

wallust_run() {
  local space="$1" palette="$2" template="$3" target="$4" image="$5"
  cat > "$cfg/wallust/wallust.toml" <<TOML
backend = "fastresize"
color_space = "$space"
palette = "$palette"
check_contrast = true
[templates]
out = { template = '$template', target = '$target' }
TOML
  XDG_CONFIG_HOME="$cfg" XDG_CACHE_HOME="$cfg/cache" wallust run "$image" -q -s -w
}

pairs_json="$(nix eval --impure --json --expr "import $here/pairs.nix")"

echo "$pairs_json" | jq -r 'to_entries[] | .key as $pair | .value | to_entries[] | "\($pair)\t\(.key)\t\(.value)"' |
  while IFS=$'\t' read -r pair mode image; do
    if [ "$mode" != "light" ] && [ "$mode" != "dark" ]; then
      echo "regenerate-palettes: pair '$pair' has unknown role '$mode'" >&2
      exit 1
    fi
    if [ ! -f "$here/$image" ]; then
      echo "regenerate-palettes: pair '$pair' role '$mode' references missing image '$image'" >&2
      exit 1
    fi

    slug="$(basename "${image%.*}")"

    wallust_run lchansi ansidark16 base16.json "$cfg/$slug.ansi.json" "$here/$image"
    wallust_run lch dark accents.json "$cfg/$slug.accents.json" "$here/$image"

    shell_json="$cfg/$slug.ansi.json"
    if [ "$mode" = "light" ]; then
      wallust_run lch light16 base16.json "$cfg/$slug.shell.json" "$here/$image"
      shell_json="$cfg/$slug.shell.json"
    fi

    python3 "$tool" \
      "$mode" \
      "$shell_json" \
      "$cfg/$slug.ansi.json" \
      "$cfg/$slug.accents.json" \
      "$out_dir/$slug.json"
  done
