## Why

Bean: `.beans/lkasper-hyprland-p9k5--asg-v2-bar.md`

The current bar is three capsule "pills" carrying a handful of status modules. The ASG V2 design reimagines it as three free-floating rounded-rectangle "islands" (left/center/right) with a far richer surface: an app launcher, an active-window readout, in-bar media with a full player popover, geolocated weather, live system stats, a consolidated control center, a calendar, a notifications popover, and a power menu. This change rebuilds the bar 1:1 against that design while reusing the existing Astal widget wiring wherever possible.

## What Changes

- **BREAKING** Replace the three capsule pills with three rounded-rectangle islands (radius 14px, `$base-dark` translucent fill, 1px border, drop shadow, 1px internal dividers). GTK4 cannot do the design's `backdrop-filter: blur`; islands rely on opacity + border + shadow only.
- Adopt JetBrains Mono and full Nerd Font glyphs (`nf-*`) 1:1 in place of symbolic icon names.
- **Left island**: app launcher button (NixOS glyph) | workspaces | active-window widget (focused client glyph + ellipsized title).
- Rebuild workspaces in the V2 style: dynamic existing-only cells (not fixed 1..10), focused = monitor-tinted background + monitor-colored number + glowing underline, occupied = faint background + underline, empty = dim number. Keep the existing deterministic base16 monitor→accent hash (no hardcoded colors); drop the right-click screen picker.
- **Center island**: clock face (calendar glyph + time + divider + date) opening a calendar popover.
- **Right island**: media widget + weather + system stats (CPU/RAM/temp) + system tray + quick-controls cluster + notifications bell + power button.
- Add popovers (GTK4 `Gtk.Popover`, auto-dismiss, no full-screen overlay): calendar, media player, weather, control center, notifications, power menu.
- **BREAKING** Remove the slide-in `notification-center` window; the bell opens a notifications popover instead.
- **BREAKING** Remove the QuickSettings subsystem; its function moves into a control-center popover (Wi-Fi/Bluetooth/DND/Night-Light toggles, volume + brightness sliders, power-profile segmented control).
- Reuse existing tooling already wired into keybinds: `brightnessctl` (brightness) and `powerprofilesctl`/`services.power-profiles-daemon` (power profiles), `walker` (launcher). Add only the genuinely new dependencies: `hyprsunset` (night light) and the `jetbrains-mono` (Nerd Font) font; weather is fetched over HTTP.

## Capabilities

### New Capabilities
- `ags-active-window`: focused-client app glyph + ellipsized title widget in the left island.
- `ags-media`: in-bar media widget (art + title/artist + animated EQ) plus a media player popover with transport controls and progress.
- `ags-weather`: weather widget (icon + temp + city) plus a weather popover (current conditions + hourly forecast), via geolocation refreshed every 15 minutes.
- `ags-system-stats`: CPU/RAM/temperature cluster showing percentages with thin progress bars and a temperature readout.
- `ags-control-center`: control-center popover consolidating Wi-Fi/Bluetooth/DND/Night-Light toggles, volume + brightness sliders, and a power-profile segmented control. Supersedes the quick-settings subsystem.
- `ags-power-menu`: power-menu popover (Lock/Suspend/Log out/Reboot/Shut down).
- `ags-calendar`: calendar popover opened from the clock (large time, month navigation, day grid).

### Modified Capabilities
- `ags-bar`: reshape from three pills to three rounded-rectangle islands; new left-island launcher + active-window placement; V2 workspace styling; restructured clock face; right-island composition (media/weather/stats/tray/quick-controls/notifications/power); JetBrains Mono + Nerd Font glyphs.
- `notification-center`: convert the slide-in window into a bell-triggered popover.
- `quick-settings-panel`: **REMOVED** — superseded by `ags-control-center`, retiring the `quick-settings-*` widget capabilities along with it.

## Impact

- **Targets**: the ags shell sources under `ags/` (consumed by the home-manager ags integration), plus supporting system plumbing.
- **ags sources**: rewrite `ags/windows/bar/` (index, workspaces, clock, media, tray, network/wifi, bluetooth, volume, battery, notifications); add launcher, active-window, weather, system-stats, control-center, power-menu, calendar widgets/popovers; rewrite `ags/style.scss`; delete `ags/windows/QuickSettings/` and the slide-in `ags/windows/notifications/center.tsx` window.
- **Deps**: reuse already-wired `brightnessctl`, `powerprofilesctl` (power-profiles-daemon already enabled), and `walker` via `exec`; add only `hyprsunset` (night light) and the `jetbrains-mono` Nerd Font font. Weather is fetched over HTTP. No `ags/flake.nix` `astalLibs` change required.
- **Specs retired**: `quick-settings-panel`, `quick-settings-audio`, `quick-settings-bluetooth`, `quick-settings-brightness`, `quick-settings-dnd`, `quick-settings-network`, `quick-settings-night-light`, `quick-settings-quick-actions`, `quick-settings-widgets`.
