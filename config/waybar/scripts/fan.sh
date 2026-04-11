#!/usr/bin/env bash
set -euo pipefail

get_fan_data() {
  local fans=()

  for f in /sys/class/hwmon/hwmon*/fan*_input; do
    [[ -r "$f" ]] || continue
    local rpm
    rpm="$(cat "$f" 2>/dev/null)" || continue
    local label_file="${f%_input}_label"
    local label
    if [[ -r "$label_file" ]]; then
      label="$(cat "$label_file" 2>/dev/null)" || label="${f##*/}"
    else
      label="${f##*/}"
    fi
    fans+=("${label}:${rpm}")
  done

  if [[ ${#fans[@]} -eq 0 ]] && [[ -r /proc/acpi/ibm/fan ]]; then
    local rpm
    rpm="$(awk '/^speed:/ {print $2}' /proc/acpi/ibm/fan 2>/dev/null)" || true
    if [[ -n "$rpm" ]]; then
      fans+=("fan:${rpm}")
    fi
  fi

  if [[ ${#fans[@]} -eq 0 ]] && command -v sensors >/dev/null 2>&1; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^(fan[0-9]*|Fan)[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]*RPM ]]; then
        fans+=("${BASH_REMATCH[1]}:${BASH_REMATCH[2]}")
      fi
    done < <(sensors 2>/dev/null || true)
  fi

  printf '%s\n' "${fans[@]}"
}

if [[ "${1:-}" == "--check" ]]; then
  data="$(get_fan_data)"
  [[ -n "$data" ]] && exit 0 || exit 1
fi

data="$(get_fan_data)"

if [[ -z "$data" ]]; then
  printf '{"text":"","tooltip":"","class":"off"}\n'
  exit 0
fi

python3 - "$data" <<'PY'
import json, sys

icon = "\U000f0210"
entries = [line.split(":", 1) for line in sys.argv[1].strip().splitlines() if ":" in line]
fans = [(name, int(rpm)) for name, rpm in entries]

active = [(name, rpm) for name, rpm in fans if rpm > 0]

if not active:
    print(json.dumps({"text": "", "tooltip": "", "class": "off"}, ensure_ascii=False))
    raise SystemExit(0)

max_rpm = max(rpm for _, rpm in active)

def compact_rpm(n):
    if n >= 1000:
        return f"{n/1000:.1f}k"
    return str(n)

text = f"{icon} {compact_rpm(max_rpm)}"
cls = "normal"
if max_rpm >= 5000:
    cls = "warning"

lines = []
for name, rpm in fans:
    lines.append(f"{name}: {rpm} RPM")
tooltip = "Fan speeds\n" + "\n".join(lines)

print(json.dumps({"text": text, "tooltip": tooltip, "class": cls}, ensure_ascii=False))
PY
