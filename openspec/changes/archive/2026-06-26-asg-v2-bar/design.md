## Context

The bar is an Astal (gtk4) shell under `ags/`, bundled via `ags bundle app.ts` and wired through the home-manager ags integration. Today it renders three capsule pills per monitor over a transparent layer-shell window; status modules are thin wrappers over Astal libraries (Hyprland, Mpris, Wireplumber, Network, Bluetooth, Battery, Tray, Notifd). The ASG V2 design (a Claude-artifact HTML mockup with simulated state) specifies a much richer three-island bar with seven popovers. This change ports that design to real Astal widgets, reusing existing wiring per the user directive: "reuse as much as possible and keep styling 1:1 ratio on the new design, the backend does not matter, it should just work."

Constraints: base16-first theming (no hardcoded colors — derive from palette vars); AGENTS rules (no code comments, no markdown outside `openspec/`, no whitespace churn). The design's `backdrop-filter: blur` is not expressible in GTK4 CSS.

## Goals / Non-Goals

**Goals:**
- Reproduce the V2 layout and styling 1:1 within GTK4's capabilities.
- Reuse existing Astal widget wiring (workspaces, clock, media, volume, battery, bluetooth, network, tray, notifications) rather than rewriting backends.
- Add the missing data sources (weather, RAM/temp, brightness, power profiles, night light) with the least integration that "just works."
- Consolidate quick-settings into one control-center popover and convert the notification center to a popover.

**Non-Goals:**
- Real frosted-glass blur behind islands (GTK4 limitation).
- The mockup's `bg` wallpaper switcher (preview chrome only; real wallpaper is owned by `lib/selected-wallpaper.nix`).
- A class→glyph lookup table for app identity (keep the current themed-icon approach).
- Re-theming beyond the bar (OSD, lockscreen, etc. unchanged).

## Decisions

**Islands instead of pills, no blur.** Each island is a styled `box` (radius 14px, `$base-dark` translucent fill, 1px border, drop shadow, 1px internal dividers between sections). The layer-shell window stays fully transparent. We add one SCSS var `$base-dark` (#1d2021) since the islands are darker than `$base` (#282828); every other color in the mockup already maps 1:1 to existing base16 vars. *Alternative considered:* faux-blur by sampling the wallpaper — rejected as complex and brittle.

**Popovers via `Gtk.Popover`, no overlay.** All seven popovers (calendar, media, weather, control center, notifications, power) use `Gtk.Popover` parented to their trigger button, which auto-dismisses on outside click. The mockup's full-screen click-catcher and single-`open` state machine are dropped — GTK4 gives this for free. The screen-picker popover pattern already proven in the archived workspaces widget is the template.

**Glyphs vs app icons (reconciling B5/B6).** Static UI chrome (launcher, weather, stats, tray fallback, quick-controls, bell, power, transport, toggles) uses Nerd Font glyphs 1:1 with the design via JetBrains Mono Nerd Font labels. App-identity imagery (workspace representative icon, active-window icon, media art, tray items) keeps the current themed-icon approach (`Gtk.Image` from client class / mpris art / tray gicon) — no class→glyph table.

**Workspaces: dynamic V2 styling, keep the accent hash.** Render existing workspaces only (drop fixed 1..10 and the right-click screen picker). Reuse the deterministic base16 monitor→accent hash from the archived widget (no hardcoded monitor colors). Render that accent as the design shows: focused = monitor-tinted background + monitor-colored number + glowing underline (CSS `box-shadow`); occupied = faint background + dimmer underline; empty = dim number, no underline. Underline is a centered child (~62% width, 2px).

**New data sources (least-effort, reuse-first):**
- *Weather* — `wttr.in/?format=j1` (server-side IP geolocation, current + hourly in one JSON), fetched via `AstalIO`/GLib HTTP on a 15-minute `GLib` timeout. Map WWO weather codes to Nerd Font glyphs. *Alternative:* open-meteo + separate IP-geolocation call — more moving parts; kept as fallback if wttr.in proves unreliable.
- *System stats* — poll on a 2s `GLib` timeout: CPU from `/proc/stat` jiffy deltas, RAM from `/proc/meminfo`, temperature from `/sys/class/thermal/thermal_zone*/temp` (fallback `sensors`). Reuse the existing `cpu.tsx` polling pattern.
- *Brightness* — `brightnessctl get`/`set`/`max` via `exec` (already wired into keybinds; no Astal lib).
- *Power profiles* — `powerprofilesctl get`/`set` via `exec` (already wired into keybinds; power-profiles-daemon already enabled); map profiles power-saver/balanced/performance → Saver/Balanced/Turbo. No `AstalPowerProfiles` / `ags/flake.nix` change, consistent with the brightness approach.
- *Night light* — toggle `hyprsunset` via `exec` (new dependency).

**Control center replaces quick-settings.** New `ags/windows/bar/control-center.tsx` popover composes the existing audio/network/bluetooth/dnd/brightness/night-light logic (cannibalized from `QuickSettings/`), then `QuickSettings/` is deleted. The 2×2 toggle grid uses on=accent-tint / off=surface tile classes; volume + brightness sliders use `Gtk.Scale`; power profile is a 3-segment button group.

**Notifications popover replaces slide-in.** The bell opens a notifications `Gtk.Popover` (header + Clear-all, card list or "all caught up" empty state) reusing `AstalNotifd` wiring from the existing center; the slide-in `window.notification-center` is removed. Popup toasts (`notifications/popups.ts`) are untouched.

## Risks / Trade-offs

- **No real blur** → islands use opacity + border + shadow; accept a flatter look than the mockup. Documented as a non-goal.
- **wttr.in reliability / rate limits** → cache the last successful payload and render stale data on fetch failure; open-meteo fallback path kept in reserve.
- **Temperature sensor portability** (`thermal_zone` naming varies by machine) → best-effort per decision C9; hide the temp readout if no sensor resolves rather than erroring.
- **Large surface area in one change** → many widgets touched at once; mitigate by reusing existing wiring and structuring tasks per island/popover so progress is incremental and independently verifiable.
- **Glyph rendering depends on the font** → requires JetBrains Mono Nerd Font present; added as a dependency so glyphs don't fall back to tofu.

**Launcher and notification IPC.** The launcher button execs `walker` (matching the `SUPER, SPACE` keybind in `modules/home-manager/_hyprland/bindings.nix`). Existing `ags request` IPC keybinds must keep working after the rebuild: `toggle-notifications` (now opens/closes the notifications popover instead of the slide-in window), `toggle-dnd`, and `toggle-bars`.

## Open Questions

- None outstanding.
