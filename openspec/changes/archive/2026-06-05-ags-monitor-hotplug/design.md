## Context

`ags/app.ts` builds the bar set inside `App.start({ main() })`. `main()` runs exactly once at process init and reads `App.get_monitors()` — a point-in-time array. Bars are therefore frozen to the displays present at launch:

```ts
main() {
    for (const monitor of App.get_monitors()) {
        Bar(monitor)
    }
}
```

`Bar` (`ags/windows/bar/index.tsx`) returns an Astal `<window>` with `application={App}`, hardcoded `name="bar"` and `namespace="bar"`. The shell is the `aylur/ags` gtk4 runtime (gnim), where `App` is the gnim-wrapped `Astal.Application` (a `GObject`). The window is bundled as `lkasper-shell` via `ags bundle app.ts`.

Two coupled problems:
1. No subscription to display changes → hot-plugged monitors get no bar until ags restarts; unplugged monitors leave orphaned bars.
2. Every bar shares `name="bar"`, so name-keyed lookups in the `App` window registry are ambiguous. `modules/home-manager/_hyprland/bindings.nix` binds `SUPER SHIFT, SPACE → ags toggle bar`, which targets a single window by name.

## Goals / Non-Goals

**Goals:**
- Create a bar for every monitor present at launch **and** for any monitor connected later.
- Destroy a monitor's bar when that monitor is disconnected, with no leaked or duplicate windows.
- Give each bar a window identity that is unique per monitor so it is individually addressable.
- Keep the `SUPER SHIFT, SPACE` bar-toggle working regardless of monitor count.

**Non-Goals:**
- No change to bar *contents* (widgets, layout, styling) — only lifecycle and window identity.
- No new Nix option surface; no change to the `lkasper-shell` package interface or build.
- No per-monitor *configuration* (different bars on different displays) — every monitor gets the same bar.
- No Hyprland-side monitor management changes.

## Decisions

### D1 — Event-driven lifecycle instead of one-time iteration
Replace the one-shot loop with a long-lived subscription that reacts to monitor add/remove for the life of the process. `main()` seeds bars for the current monitors, then keeps listening.

*Alternatives considered:* periodic polling of `get_monitors()` (rejected — wasteful, laggy, racy); restart ags on a Hyprland `monitoradded` event hook (rejected — pushes the fix outside the shell, drops all bars on every hotplug, visible flicker).

### D2 — Monitor event source: Gdk `ListModel` as primary, Astal signals if confirmed
Two candidate APIs:
- **(A) `Astal.Application` signals** — `App.connect("monitor-added"/"monitor-removed", (_, mon) => …)`, each carrying a `Gdk.Monitor`. Ergonomic and gives the monitor object directly.
- **(B) Gdk display `ListModel`** — `Gdk.Display.get_default().get_monitors()` returns a `Gio.ListModel`; connect to `items-changed(position, removed, added)` and diff against tracked monitors. GTK-native and version-stable.

**Decision (RESOLVED — verified against pinned ags 3.1.0):** approach **(A)** is impossible — the gnim `App` exposes **no** `monitor-added`/`monitor-removed` signals. Instead, `App`'s constructor already wires the Gdk monitor `ListModel`'s `items-changed` into a GObject `notify::monitors` property-notify signal. The implementation therefore subscribes to **`App.connect("notify::monitors", reconcile)`** and `reconcile()` diffs the current `App.get_monitors()` against the tracked bar map (add missing, destroy removed). This is approach (B) refined to use the wrapper's own notify rather than the raw `ListModel`. The spec is written against observable behavior so the choice does not change requirements.

*Alternative considered:* a gnim reactive `For`/binding over `App.monitors` in JSX — rejected as a larger structural rewrite of `app.ts` than this change warrants.

### D3 — Reactive `<For>` over `createBinding(App, "monitors")` (REVISED after runtime failure)
**Superseded approach (imperative reconcile):** track bars in a `Map<connector, window>`, subscribe to `notify::monitors`, and on each fire diff `get_monitors()` against the map — add missing, `destroy()` removed. **This failed at runtime on HDMI replug:** in GTK4 the window surface is already torn down when the output vanishes, so `win.destroy()` throws *before* the `map.delete(key)` runs, leaving a stale entry; the next add then sees the stale key and skips recreating the bar.

**Adopted approach (community-proven, matches `Neurarian/matshell`):** render bars with gnim's reactive `<For each={createBinding(App, "monitors")} cleanup={(win) => win.destroy()}>`. `For` diffs the `monitors` array (driven by `notify::monitors`), instantiates one `<window>` per monitor, and calls `cleanup` on removed entries — the framework owns the GTK4 create/destroy lifecycle, so the stale-entry class of bug cannot occur. The `For` lives in `ags/windows/bar/index.tsx` (a `.tsx` file); `app.ts` stays JSX-free and just calls the wrapper once in `main()`.

*Risk retired:* manual add↔remove identity matching (R1) is no longer our concern — `For` keys on the binding's array items.

### D4 — Unique `name`, shared `namespace`
Derive the window `name` per monitor from its connector, e.g. `bar-${gdkmonitor.connector}` ("DP-1", "HDMI-A-1"), falling back to a running index if `connector` is null. Keep `namespace="bar"` **shared** across all bars so Hyprland `layerrule`s and exclusivity continue to apply uniformly without per-monitor rules. `Bar` takes the resolved name as an argument so `app.ts` owns identity assignment.

*Alternative considered:* unique `namespace` too (rejected — would force per-monitor layer rules for no benefit).

### D5 — Toggle via a request handler, not a name lookup
`ags toggle bar` cannot target N differently-named windows. Register an application request handler (`App.start({ requestHandler })`) that toggles the visibility of **all** bars — found via `App.get_windows()` filtered by the per-monitor `name` prefix `bar` (no tracking map exists under the `For` approach in D3) — and change the keybind to invoke it (e.g. `ags request toggle-bars`). This is monitor-count-independent and keeps the single-keystroke UX.

*Alternative considered:* iterate and emit one `toggle` per known name from the keybind (rejected — the binding would need to know runtime monitor names).

## Risks / Trade-offs

- **R1 — Monitor object identity on removal.** The remove event must resolve to the same key used on add. → Key the map by the `Gdk.Monitor` object from the same source (approach A passes it directly; approach B reads it from the `ListModel`). If identity proves unstable across events, fall back to keying by `connector` string.
- **R2 — Duplicate add events / re-seeding.** A monitor could be reported both in the initial `get_monitors()` and a subsequent add event. → Guard creation: if the map already has the monitor, skip. Idempotent add.
- **R3 — `connector` may be null** on some backends. → Fall back to a monotonic index for the name; the map (keyed by monitor object) remains correct regardless.
- **R4 — Toggle keybind is BREAKING.** Anyone calling `ags toggle bar` directly will stop working. → Documented in the proposal; the keybind is updated in the same change so the user-facing behavior is preserved.
- **R5 — Wrapper API drift (D2-A).** If `monitor-added`/`monitor-removed` are not surfaced by the gnim `App`, approach A fails to compile. → Default to approach B, which has no such dependency; verify before coding.

## Migration Plan

1. Implement event-driven lifecycle + per-monitor naming in `ags/app.ts` and `ags/windows/bar/index.tsx`.
2. Add the toggle request handler and update `SUPER SHIFT, SPACE` in `modules/home-manager/_hyprland/bindings.nix`.
3. Rebuild the shell (`ags bundle`, via the flake `packages.default`) and `nixos-rebuild`/home-manager switch.
4. **Verify:** launch with one monitor, hot-plug a second (bar appears), unplug it (bar disappears, no orphan), and confirm `SUPER SHIFT, SPACE` toggles all bars.
5. **Rollback:** revert the three files and rebuild; no persistent state or migration to undo.

## Open Questions

- ~~**Does the pinned `aylur/ags` input expose `monitor-added`/`monitor-removed` on the gtk4 `App`?**~~ **RESOLVED:** No. ags 3.1.0 (`lib/gtk4/app.ts`) provides only `get_monitors()`/`monitors` plus a `notify::monitors` signal (constructor connects the display `ListModel` `items-changed` → `notify("monitors")`). Implementation uses `notify::monitors` + reconcile-by-diff. Bars are keyed by monitor `connector` (R1/R3) since repeated `get_monitors()` calls may not return identical JS wrapper identities.
- **Should the toggle hide all bars together, or per-focused-monitor?** Assumed all-together for parity with today's single-bar behavior; revisit if per-monitor toggling is wanted later.
