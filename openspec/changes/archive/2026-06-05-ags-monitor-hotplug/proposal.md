## Why

The ags shell builds one bar per monitor in `App.start({ main() })`, but `main()` runs only once at startup and reads a one-time `App.get_monitors()` snapshot. Monitors connected after Hyprland/ags start get no bar until ags is restarted, and disconnected monitors leave their bars orphaned. The bar lifecycle needs to be event-driven so displays are handled as they come and go.

## What Changes

- Subscribe to monitor add/remove events for the lifetime of the ags process instead of iterating monitors once at startup.
- Create a bar when a monitor is added (including the initial set present at launch) and destroy the corresponding bar when its monitor is removed.
- Track bars per-monitor so the right window can be torn down on removal (no leaked or duplicate bars).
- Give each bar a unique window `name`/`namespace` per monitor, since multiple identically named windows collide in the `App` window registry and break name-based lookups such as the `ags toggle bar` keybind. **BREAKING** for any consumer assuming a single window literally named `bar`.

## Capabilities

### New Capabilities
- `ags-bar-monitors`: Lifecycle of the top bar across displays — initial population, hot-plug add, unplug teardown, and per-monitor window identity.

### Modified Capabilities
<!-- None — openspec/specs/ contains no existing capabilities. -->

## Impact

- `ags/app.ts` — replace the one-time `for` loop in `main()` with event-based monitor subscription and per-monitor bar tracking.
- `ags/windows/bar/index.tsx` — accept/derive a unique `name`/`namespace` per monitor; expose a handle the app can destroy on removal.
- `modules/home-manager/_hyprland/bindings.nix` — `SUPER SHIFT, SPACE → ags toggle bar` depends on the window name; behavior must be reconciled with per-monitor names.
- Affected output: `packages.default` (`lkasper-shell`, built via `ags bundle app.ts`); no Nix option surface changes.
