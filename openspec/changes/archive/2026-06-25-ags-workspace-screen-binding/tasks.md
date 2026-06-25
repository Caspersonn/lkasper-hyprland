## 1. Workspaces widget: numbers + states

- [x] 1.1 Rewrote `ags/windows/bar/workspaces.tsx`: always renders a fixed `WS_IDS = [1..10]` (10th labelled `0`) as `<button>`s; each reactively finds its Hyprland workspace via `createComputed(() => workspaces().find(w => w.id === id))`; left-click → `hyprctl dispatch workspace <id>` (switches/creates).
- [x] 1.2 State classes via `focusedWorkspace`: `active` (focused) / `occupied` (exists) / `empty` (non-existent, rendered dimmed via `.empty .ws-num`).
- [x] 1.3 Each cell shows the workspace's **representative app icon** (`ws.lastClient.class`, reactive on `clients`, hidden when none) before the number — the per-app icon folded in from the removed clients row; cells are roomy rectangles (`padding: 3px 12px`, rounded), active = subtle rounded background.

## 2. Monitor → base16 accent (no hardcoding)

- [x] 2.1 `accentIndex(name)` — pure deterministic hash `% ACCENT_POOL` (5); the TSX produces only an index, no colour literals.
- [x] 2.2 `ags/style.scss`: `.ws-accent-0…4 { background-color: <palette var> }` using existing base16 vars (`$green/$blue/$purple/$yellow/$red`); the accent class is applied to the centered underline bar.

## 3. Workspace → monitor + underline

- [x] 3.1 Bound monitor resolved directly from `AstalHyprland` — `ws.monitor.name` (the GIR confirms `Workspace.monitor` exists; no `hyprctl monitors -j` fallback needed).
- [x] 3.2 Short (~18px, ~2.5px) **centered** underline bar (`.ws-underline` box, accent `background-color`); its class is a `createComputed` that tracks the `workspaces` binding so it recolours after a move.

## 4. Screen picker (right-click)

- [x] 4.1 `Gtk.GestureClick` (`button={3}`) on each workspace opens a `<popover>` (captured via the `$` ref) parented to the button; left-click focus and right-click picker coexist.
- [x] 4.2 Picker rows come from `createBinding(hypr,"monitors")` (reactive) — symbolic icon (`computer-laptop-symbolic` for `eDP*`, else `video-display-symbolic`), `model`/`description`, `width×height @ refreshRate`, connector name. (AstalHyprland `Monitor` exposes all these directly, so no `hyprctl monitors -j`.)
- [x] 4.3 Selecting a row execs `hyprctl dispatch moveworkspacetomonitor <ws.id> <name>` then `popover.popdown()`.

## 5. Remove the clients widget

- [x] 5.1 Deleted `ags/windows/bar/clients.tsx`.
- [x] 5.2 Removed the `Clients` import and `<Clients />` from the left pill in `ags/windows/bar/index.tsx`.
- [x] 5.3 Removed `.workspace-dot` / `.client-button` / `.clients-separator` from `ags/style.scss`; added the workspace number / accent-pool / `.screen-picker` styling (base16 vars only).

## 6. Build & verify

- [x] 6.1 Build-check: built the pinned `ags` CLI and ran `ags bundle app.ts` — exit 0 (662 KB).
- [x] 6.2 Manual verification (user, after rebuild + shell restart): workspaces show as numbers with active/occupied states; each underline is coloured by its monitor (stable across restart); the app-icon row is gone; left-click focuses; right-click opens the screen picker with correct model/resolution/refresh/connector; selecting a display runs `moveworkspacetomonitor` and the underline recolours.
