## Context

The desktop currently launches applications through walker, an external launcher bound to `SUPER, SPACE`, autostarted as a gapplication-service, and reachable from the bar launcher button (`ags/windows/bar/index.tsx`). walker's theming is maintained outside this shell and does not match the gruvbox-themed AGS surfaces.

The keybind cheatsheet (`ags/windows/shortcuts/index.tsx`, shipped in the prior change) established a reusable layer-shell overlay pattern in this shell: an all-edge `OVERLAY` window with `Astal.Exclusivity.IGNORE`, `Astal.Keymode.EXCLUSIVE`, a dimmed backdrop, a centered card, `EventControllerKey` for `ESC`, a backdrop `GestureClick` to dismiss, `createState`-backed visibility, and an `ags request` toggle wired through `ags/app.ts`. This change reuses that shell for a launcher and adds the interactive parts the cheatsheet never needed: a text entry, live filtering, a moving selection, and process launch.

Constraint: the nested `ags/flake.nix` `astalLibs` list does not include `apps`, so `gi://AstalApps` does not resolve at bundle time today. It must be added.

## Goals / Non-Goals

**Goals:**
- A first-party AGS launcher that matches the gruvbox theming and lifecycle of the other overlays.
- App enumeration, fuzzy search, and launch via `AstalApps`.
- Full keyboard operation: type to filter, `Up`/`Down` to move selection, `Enter` to launch, `ESC` to dismiss.
- Make the AGS launcher the primary launcher (`SUPER, SPACE`, bar button) while keeping walker as a fallback bind.

**Non-Goals:**
- Non-app modes (calculator, run-command, emoji, clipboard). The window leaves structural room but implements none.
- Removing walker. walker stays installed and autostarted; this change only rebinds it.
- `uwsm app --` launch scoping. Plain `.launch()` for now; revisit only if xwayland scoping issues appear.
- Configurable options / `mkDefault`-style toggles for the launcher. Not user-facing config.

## Decisions

### D1: App source is AstalApps (add `apps` to astalLibs)
Use `AstalApps.Apps` with `.fuzzy_query(text)` for the result list and `Application.launch()` to run. This gives fuzzy matching, `.name`/`.icon_name`/`.description`, and frequency-aware ordering for free.
- **Requires** adding `apps` to the `astalLibs` list in `ags/flake.nix` so the GIR is present when `ags bundle` resolves `gi://AstalApps`.
- **Alternatives considered**: (B) parse `.desktop` files by hand — reimplements what AstalApps does, no icons/frequency; (C) shell out to walker — defeats the purpose. Rejected both.

### D2: Interactive state machine layered on the shortcuts shell
Reuse the shortcuts window structure verbatim for the overlay chrome. Add:
- A `Gtk.Entry` at the top holding typing focus while the overlay is open (focus grabbed via `GLib.idle_add` on open).
- `createState` for the query text and the selected app; results are a computed fuzzy query over the query text.
- **Selection is a stable app key (`app.get_entry()`), not a numeric index.** gnim `<For>` reuses row widgets across query changes (rows keyed by `app.get_entry()`), so a captured index goes stale and highlights the wrong row. `rowClasses` is a `createComputed([selectedKey], k => k === item.key ? [...,"selected"] : [...])`, and arrow navigation resolves the current key against the *fresh* results list (`results().findIndex(it => it.key === selectedKey())`) before stepping/clamping. Enter looks the app up by key (falling back to the first result). See `[[gnim-for-duplicate-keys]]`.
- An `EventControllerKey` on **the window** (not the entry) with `PropagationPhase.CAPTURE`, added via `$={(self) => self.add_controller(keys)}`. Capture phase intercepts `Up`/`Down`/`Return`/`KP_Enter`/`Escape` before the focused entry consumes them (the entry would otherwise fire `activate` on Return and move the text cursor on arrows), while ordinary typing still falls through to the entry.
- On open and on every keystroke: `selectFirst()` sets the selected key to the top result so there is always a visible highlight and Enter launches the top match. On close: hide window.
- **Alternatives considered**: a GTK `ListView` with a selection model — heavier and less consistent with the hand-rendered rows already used in shortcuts. Chose manual list + stable key for consistency and control.

### D3: Layout — search on top, single vertical scrollable result column
Search entry on top, a vertical single-column list of rows below, each row = app icon + name. This mirrors walker's familiar layout (confirmed) and differs from the cheatsheet's 2-column balance.
- Results are **uncapped** and the list lives in a `<scrolledwindow>` (`hscrollbarPolicy=NEVER`, `vscrollbarPolicy=AUTOMATIC`, `maxContentHeight`, `propagateNaturalHeight`) so the user can scroll through every app. The selected row is scrolled into view via a `selectedKey.subscribe` that compares the row's allocation against the scrolledwindow's vadjustment, using a per-window `Map<key, Gtk.Widget>` of row widgets.
- **Hover also drives selection**: a `Gtk.EventControllerMotion` `enter` handler sets `selectedKey` to that row's key, so mouse and keyboard share one selection model and highlight the row actually under the cursor. Only `.selected` carries the highlight in SCSS (no separate `:hover` rule).
- The modal centers on both axes with `hexpand vexpand halign=CENTER valign=CENTER widthRequest=560`: the backdrop is a horizontal `Gtk.Box`, so the card must expand to claim the full allocation and then center a fixed-width card within it (a bare `halign` on the main axis is ignored and packs the card to the left).

### D4: walker coexistence via rebinding only
`SUPER, SPACE` → `ags request toggle-launcher` (labelled `[Launcher]` as a `bindd`). walker moves to `SUPER CTRL, SPACE` as a backup. `toggle-bars` is untouched on `SUPER SHIFT, SPACE`. walker's `walker.nix` and its `walker --gapplication-service` autostart stay so the backup bind works. The bar launcher button switches from exec-ing walker to `ags request toggle-launcher`.
- **Alternatives considered**: fully remove walker in this change — drags in `walker.nix`, `autostart.nix`, more risk, and no fallback if the AGS launcher regresses. Deferred to a later change.

### D5: Toggle lifecycle mirrors shortcuts / notification center
Export `initLauncher()` and `toggleLauncher()`; add a `toggle-launcher` branch to the `ags/app.ts` `requestHandler` and call `initLauncher()` in `main()`. Toggling flips the `createState` visibility and, on show, refreshes focus/selection.

### D6: Structural room for future modes (no implementation)
Keep the query→results pipeline behind a single function so a future change can branch on a mode prefix (e.g. `=` for calc) without restructuring the window. No mode logic is added now.

## Risks / Trade-offs

- [Arrow keys vs entry text cursor] → Resolved by putting the `EventControllerKey` on the window in `PropagationPhase.CAPTURE` so it claims `Up`/`Down`/`Return`/`KP_Enter`/`Escape` before the focused entry sees them, while typing still reaches the entry.
- [Backdrop click vs row click] → A `GestureClick` on the modal that `CLAIMED` the press cancels child row `<button>` clicks. Instead the backdrop's own `GestureClick` `pressed` handler hit-tests with `backdropBox.pick(x, y, Gtk.PickFlags.DEFAULT)` and an `isInside(picked, modalBox)` ancestor walk, closing only when the press lands outside the card — row buttons keep their clicks.
- [Stale selection index across query changes] → gnim `<For>` reuses row widgets keyed by `app.get_entry()`, so selection is tracked by that stable key, never a render-time index. See `[[gnim-for-duplicate-keys]]`.
- [`AstalApps` GIR missing at bundle time] → Adding `apps` to `astalLibs` is required; a local `ags bundle` may still succeed from the working dir while the nix build fails, so verify via the nix build path, and ensure the new file is `git add`-ed (dirty-tree nix builds omit untracked files).
- [walker still autostarted but demoted] → Slight resource overlap (walker daemon idle) accepted as the cost of a safe fallback; removal is a later change.
- [Launch without `uwsm app --`] → Some xwayland apps may not get proper systemd scoping. Accepted for v1; documented fallback is to add the prefix later.

## Migration Plan

1. Add `apps` to `astalLibs` in `ags/flake.nix`.
2. Add `ags/windows/launcher/index.tsx`; wire `ags/app.ts`; add SCSS; point the bar button at `toggle-launcher`.
3. Rebind in `bindings.nix` (`SUPER, SPACE` → launcher; walker → `SUPER CTRL, SPACE`).
4. `git add` the new file, `nix fmt`, rebuild, verify bundle resolves `gi://AstalApps`.
- **Rollback**: revert `bindings.nix` (walker back on `SUPER, SPACE`) and the bar button; the AGS launcher window is inert if unbound.

## Open Questions

None outstanding — AstalApps, keyboard nav, single-column layout, plain launch, walker backup on `SUPER CTRL, SPACE`, and out-of-scope modes are all confirmed.
