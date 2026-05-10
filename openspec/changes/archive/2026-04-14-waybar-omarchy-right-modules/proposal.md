## Why

The waybar right-side modules lack visual separation and are missing useful status indicators. The omarchy-dotfiles project has a clean pattern using CSS border-left separators between modules wrapped in a pill-shaped container, plus custom modules for fan speed, tmux sessions, and weather. Adopting this pattern improves readability and adds practical at-a-glance information.

## What Changes

- Wrap `modules-right` in a `group/right-cluster` with pill-shaped container styling
- Add CSS `border-left` separators between right-side modules
- Add three new custom waybar modules: `custom/fan` (universal via lm-sensors), `custom/tmux`, `custom/weather` (IP-based auto-location)
- Remove `power-profiles-daemon` module
- Update `cpu` module format to show usage percentage
- Replace GUI `on-click` handlers with TUI alternatives (`bluetuith` for bluetooth, `pulsemixer` for wireplumber)
- Add separator and container styling to `config/waybar/style.css`

## Capabilities

### New Capabilities
- `waybar-right-cluster`: Group wrapper, CSS pipe separators, and pill container for right-side modules
- `waybar-custom-modules`: Custom waybar modules for fan monitoring (lm-sensors), tmux session status, and weather display

### Modified Capabilities

## Impact

- **home-manager module**: `homeManagerModules.omarchy-waybar` -- no structural changes needed, already copies `config/waybar/` recursively. Script executability may need attention.
- **Config files**: `config/waybar/config.jsonc` (module list, module configs), `config/waybar/style.css` (new CSS rules)
- **New files**: `config/waybar/scripts/fan.sh`, `config/waybar/scripts/tmux-brief.sh`, `config/waybar/scripts/weather-brief.sh`
- **Dependencies**: `lm-sensors` (for fan script), `bluetuith` and `pulsemixer` (TUI replacements for GUI apps), `python3` and `curl` (for weather script)
