## 1. Verify monitor-event API (resolves design D2)

- [x] 1.1 Inspect the pinned `aylur/ags` input (via `ags/flake.lock` / the gtk4 `App` typings) to confirm whether `App.connect("monitor-added"|"monitor-removed", cb)` is exposed on the gnim `App`.
- [x] 1.2 Record the outcome in `design.md` Open Questions: if signals exist, use approach A (Astal signals); otherwise use approach B (`Gdk.Display.get_default().get_monitors()` `items-changed`). → No signals; ags 3.1.0 exposes `notify::monitors`.

## 2. Per-monitor bar identity (`ags/windows/bar/index.tsx`)

- [x] 2.1 Change `Bar(gdkmonitor)` to also accept a resolved window name, e.g. `Bar(gdkmonitor: Gdk.Monitor, name: string)`.
- [x] 2.2 Set the window `name={name}` (unique per monitor) and keep `namespace="bar"` shared, per design D4.
- [x] 2.3 Ensure `Bar` returns the window handle so the caller can `destroy()` it on monitor removal.

## 3. Event-driven lifecycle (`ags/app.ts`)

- [x] 3.1 Add a name resolver: derive `bar-${gdkmonitor.connector}`, falling back to a monotonic index when `connector` is null (spec: connector-unavailable scenario).
- [x] 3.2 Introduce a `Map<Gdk.Monitor, window>` to track live bars.
- [x] 3.3 In `main()`, seed bars for each monitor in `App.get_monitors()`, storing each in the map (replaces the bare `for` loop).
- [x] 3.4 Add an idempotent `addBar(monitor)` helper that skips creation if the monitor is already tracked (spec: add-is-idempotent).
- [x] 3.5 Subscribe to monitor-added events (approach chosen in task 1.2) and call `addBar`.
- [x] 3.6 Subscribe to monitor-removed events; look up the bar, `destroy()` it, and delete the map entry (spec: monitor-disconnected).

## 4. Toggle handler + keybind (design D5)

- [x] 4.1 Add a request handler in `App.start({ requestHandler })` that toggles `visible` on every bar in the tracking map (e.g. request name `toggle-bars`).
- [x] 4.2 Update `modules/home-manager/_hyprland/bindings.nix` `SUPER SHIFT, SPACE` from `ags toggle bar` to invoke the new request (e.g. `ags request toggle-bars`).

## 5. Build & verify

- [x] 5.1 Type/bundle the shell in the ags devshell: `nix develop ./ags -c ags bundle ags/app.ts /tmp/lkasper-shell` (or `nix build ./ags`).
- [x] 5.2 `nix fmt` the changed Nix files and run `nix flake check`.
- [x] 5.3 Manual verification: launch with one monitor, hot-plug a second (bar appears), unplug it (bar disappears, no orphan), and confirm `SUPER SHIFT, SPACE` toggles all bars. → CONFIRMED WORKING by user after the fix below. First imperative `notify::monitors` reconcile FAILED on replug (stale map entry: GTK4 destroys the surface on unplug, so `win.destroy()` threw before the map delete, blocking recreation). **Fix applied:** switched to gnim reactive `<For each={createBinding(App,"monitors")} cleanup={win=>win.destroy()}>` (pattern from `Neurarian/matshell`). Rebuilds clean. **Awaiting user replug re-test.**
