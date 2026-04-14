## Context

The waybar right-side modules in `config/waybar/config.jsonc` are a flat list with no visual grouping. The style in `config/waybar/style.css` applies uniform `margin-right: 13px` spacing with transparent backgrounds. The omarchy-dotfiles project demonstrates a more polished pattern: modules wrapped in a `group/right-cluster` with a pill-shaped container and CSS border-left separators.

The nix module `modules/home-manager/waybar.nix` copies `config/waybar/` recursively to `~/.config/waybar/` and generates `theme.css` with `@foreground` and `@background` color variables from the nix-colors palette. This means CSS can use `alpha(@foreground, ...)` and `alpha(@background, ...)` for theme-aware styling.

## Goals / Non-Goals

**Goals:**
- Adopt the omarchy `group/right-cluster` wrapper pattern with pill-shaped container styling
- Add CSS `border-left` separators between right-side modules
- Add custom modules for fan speed (lm-sensors), tmux sessions, and weather
- Replace GUI click handlers (blueberry, pavucontrol) with TUI alternatives (bluetuith, pulsemixer)
- Show CPU usage percentage in the format string
- Remove power-profiles-daemon module

**Non-Goals:**
- Changing left-side modules or center clock
- Modifying the workspace styling
- Changing the waybar.nix module structure (it already copies config/ recursively)
- Supporting ThinkPad-specific fan hardware paths

## Decisions

### 1. Use `group/right-cluster` for module wrapping

Wrap all right-side modules in `group/right-cluster` so the container can be styled as a single pill-shaped unit. The top-level `modules-right` becomes `["group/right-cluster"]`.

**Alternative**: Keep flat `modules-right` and style individual modules. Rejected because the container background/border needs to span all modules as one visual unit.

### 2. Fan monitoring via lm-sensors (universal)

Use `sensors` command (from lm-sensors) to read fan RPM. This works across all hardware with kernel hwmon support, not just ThinkPad.

The script outputs JSON for waybar's `return-type: json` format. If no fan is detected or sensors is unavailable, it outputs empty text (waybar hides empty custom modules with `hide-empty-text: true`).

**Alternative**: ThinkPad-specific `/proc/acpi/ibm/fan`. Rejected because this system is not ThinkPad-only.

### 3. Weather defaults to IP-based auto-location

The weather script uses `wttr.in` with `auto` location by default (IP-based geolocation). Users can override via `WAYBAR_WEATHER_LOCATION` environment variable.

**Alternative**: Hardcoded location. Rejected because the config should work on any network without modification.

### 4. TUI replacements for on-click handlers

- bluetooth: `bluetuith` (replaces `blueberry`)
- wireplumber: `pulsemixer` (replaces `pavucontrol`)
- Both launched in the terminal emulator via `ghostty -e <cmd>`, consistent with the existing cpu on-click pattern

**Alternative**: Keep GUI apps. Rejected per user preference for TUI-based tools.

### 5. Keep wireplumber module (not switch to pulseaudio)

The current config uses the `wireplumber` waybar module. The omarchy config uses `pulseaudio`. Staying with `wireplumber` since that's the native PipeWire controller already in use.

### 6. Script installation via recursive copy

Scripts go in `config/waybar/scripts/`. The existing `home.file.".config/waybar/".recursive = true` in `waybar.nix` already copies everything. However, scripts need to be executable -- the nix module must set `executable = true` on the scripts directory or individual files, OR the scripts can be installed as nix packages.

Decision: Add the scripts directory to `home.file` with `executable = true` as a separate entry, overriding the recursive copy for that path. This keeps scripts in `config/waybar/scripts/` while ensuring they're executable after deployment.

### 7. Package dependencies in waybar.nix

New packages (`lm_sensors`, `bluetuith`, `pulsemixer`, `python3`, `curl`, `tmux`, `jq`) need to be available. Add them to `home.packages` in `waybar.nix` guarded by `omarchy.exclude_packages` where appropriate.

### 8. Module order

Follow omarchy order: tray, bluetooth, network, wireplumber, cpu, custom/fan, custom/tmux, custom/weather, battery. The battery stays last (rightmost) as the anchor.

## Risks / Trade-offs

- **[lm-sensors not detecting fans]** -> Script outputs empty text; module hides itself via `hide-empty-text: true`. Desktop systems without fans simply won't show the module.
- **[wttr.in rate limiting or downtime]** -> Weather module shows stale data (900s interval). Not critical information; acceptable degradation.
- **[bluetuith/pulsemixer not installed]** -> On-click handlers fail silently. Mitigated by installing both as home.packages.
- **[Scripts not executable after nix build]** -> Modules fail to run. Mitigated by explicit `executable = true` on the scripts home.file entry.
