## Context

The bar's left pill today holds two unrelated widgets:
- `ags/windows/bar/workspaces.tsx` — workspace **dots** (active = wide filled, occupied = outline), driven by `createBinding(hypr, "workspaces")` + `focusedWorkspace`, click → `ws.focus()`.
- `ags/windows/bar/clients.tsx` — a flat row of **unique app icons** across all clients, `hyprctl`-execs to focus.

`AstalHyprland` exposes workspaces, monitors, and clients reactively, and the bar already `exec`s `hyprctl` (in `clients.tsx`). The shell is base16-themed via SCSS variables in `ags/style.scss` (`$blue/$green/$yellow/$red/$purple` etc. — the gruvbox palette). The user runs multiple monitors (the bar/OSD/notifications all do per-monitor work).

This change implements the "Workspace → screen binding" design: workspaces become monitor-aware numbers with a coloured underline, plus a right-click screen picker. The app-icon row is dropped.

## Goals / Non-Goals

**Goals:**
- Render workspaces as **numbers** with a ~2.5px underline in the **base16 accent of the bound monitor**, preserving active/occupied/focused states; left-click focuses.
- Monitor→colour mapping derived from the base16 palette (no hardcoded hex), stable across reloads.
- Right-click → **screen picker** popover (symbolic device icon, model, resolution, refresh, connector) → `moveworkspacetomonitor`.
- Delete `clients.tsx` and remove it from the bar.

**Non-Goals:**
- Real device photos (symbolic laptop/monitor icons only — deferrable later).
- Folding window/app indicators into the widget (clients dropped, not merged).
- An explicit per-monitor colour config map (deterministic hash only for now).

## Decisions

### D1: Workspaces render as numbers, dynamic set, states preserved

Keep the existing dynamic model — render the workspaces that exist (`id > 0`, sorted), not a fixed 1–10 — but render each as its **numeric id** (label) instead of a dot. Preserve **active** (focused, via `focusedWorkspace`) and **occupied** (exists) states as CSS classes. Left-click still calls `ws.focus()`.

- *Alternative — fixed 1–10 grid with empty slots:* rejected; diverges from current behaviour and the empty slots have no monitor to bind to.

### D2: Resolve workspace → monitor reactively

Each workspace's bound monitor comes from `AstalHyprland` (`workspace.monitor` — a `Monitor`, falling back to mapping via `hyprctl monitors -j` if the property is unavailable). The widget rebuilds reactively on `createBinding(hypr, "workspaces")` and monitor changes, so moving a workspace between monitors updates its underline live.

### D3: Monitor → base16 accent via deterministic hash (no hardcoding)

The underline colour is chosen by hashing the **monitor name** into a fixed pool of existing base16 SCSS accents (`$green/$blue/$purple/$yellow/$red`). The TSX computes only an **index** (`hash(name) % poolSize`) and applies a class `ws-accent-<i>`; `style.scss` maps each `ws-accent-<i>` to a palette variable's `border-bottom-color`. So no colour literal ever appears in the TSX, and a monitor keeps the same slot across reloads (the hash is pure).

- *Alternative — inject `config.colorScheme.palette` hex into the TSX:* rejected; that's hardcoding hex into code. Keeping colours in SCSS (palette vars) and only an index in TSX is cleaner and base16-faithful.
- Collision note: with more monitors than pool slots, two monitors may share a colour. Accepted (rare); an explicit override map is a future option.

### D4: Right-click screen picker

A `Gtk.GestureClick` (button 3) on each workspace opens a `Gtk.Popover` parented to that workspace. On open, the picker reads `hyprctl monitors -j` (exec + `JSON.parse`) for fresh specs and renders one row per monitor: a symbolic icon (`computer-laptop-symbolic` when the connector matches `eDP*`, else `video-display-symbolic`), the `description` (model), `WxH@refresh`, and the connector name. Selecting a row execs `hyprctl dispatch moveworkspacetomonitor <ws.id> <name>` and closes the popover. Left-click (focus) and right-click (picker) coexist on the same widget.

- *Alternative — AstalHyprland Monitor objects for specs:* used for reactivity, but the detailed model/mode/connector come from `hyprctl monitors -j` (per the design) since it reliably exposes all fields.

### D5: Remove the clients widget

Delete `ags/windows/bar/clients.tsx`, drop its import and `<Clients />` from the left pill in `ags/windows/bar/index.tsx`, and remove the now-unused `.client-button` / `.client-icon` / `.clients-separator` styling from `ags/style.scss`. The `ags-bar` spec's split-pill layout already lists only "Workspaces" for the left pill, so this realigns code with spec.

## Risks / Trade-offs

- **`workspace.monitor` availability** → if `AstalHyprland`'s `Workspace` doesn't expose the bound monitor directly, derive it from `hyprctl monitors -j` (each monitor lists its workspaces) or `monitorID`. Either way the data exists.
- **Popover in a layer-shell bar** → popovers work in the bar (QuickSettings uses one); right-click via `GestureClick` + `popover.popup()`.
- **Spec freshness** → the picker execs `hyprctl monitors -j` on open, so specs are current each time.
- **Colour collisions** beyond the pool size → accepted; override map deferred.
- **Reactivity on move** → `moveworkspacetomonitor` fires Hyprland events that update `hypr.workspaces`, so underlines refresh; verify on the live session.

## Migration Plan

Additive within the AGS shell: rewrite `workspaces.tsx`, delete `clients.tsx`, edit `index.tsx` + `style.scss`. Rebuild via home-manager + restart the shell. Rollback: restore the two widgets and the `<Clients />` usage.

## Open Questions

- Real device photos matched on model string — deferred (icons first).
- Optional explicit monitor→slot config map — deferred (hash is sufficient for stability).
