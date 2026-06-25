## Why

The bar's left section is currently two unrelated widgets: workspace **dots**
(`ags/windows/bar/workspaces.tsx`) and a flat row of **unique app icons**
(`ags/windows/bar/clients.tsx`) that has no relationship to the workspaces. On a
multi-monitor setup there's no indication of *which monitor* a workspace lives
on, and no quick way to move a workspace between displays.

This change replaces both with a single **monitor-aware workspaces widget**
(the "Workspace → screen binding" concept): workspaces render as numbers, each
underlined in the base16 accent of the monitor it's bound to, and a right-click
opens a screen picker to reassign a workspace to another display. The app-icon
row is dropped.

This change targets the **home-manager** side: the AGS shell source (`ags/`,
built by `homeManagerModules.lkh-ags` into `lkasper-shell`).

Tracking bean: [lkasper-hyprland-afp0](../../../.beans/lkasper-hyprland-afp0--workspacescreen-binding-bar-widget.md)

## What Changes

- Rewrite `ags/windows/bar/workspaces.tsx`: always render workspaces **1–10**
  (10th labelled `0`), each a roomy rectangular cell showing its
  **representative app icon** (its last-focused client) + its **number**
  (replacing the dots), with a short (~50% width) **centered underline coloured
  by the monitor it's bound to**; active/occupied normal, empty (non-existent)
  rendered dimmed. Left-click switches to (and creates) the workspace.
- **Monitor → accent colour** comes from the **base16 palette** via a
  deterministic hash of the monitor name into a fixed base16 accent pool (e.g.
  `base0B/0D/0E/0C/09/08`) — stable across reloads, no hardcoded hex.
- Add a **screen picker**: right-click a workspace opens a popover listing each
  connected display with a symbolic device icon (laptop for `eDP*`, monitor
  otherwise), model, resolution, refresh rate, and connector. Selecting a row
  runs `hyprctl dispatch moveworkspacetomonitor <id> <NAME>`. Display specs are
  read from `hyprctl monitors -j`.
- **Delete `ags/windows/bar/clients.tsx`** and remove `<Clients />` from the bar
  (`ags/windows/bar/index.tsx`); the standalone app-icon row is gone — the
  per-app icon is folded into each workspace cell instead.
- Add the needed styling to `ags/style.scss` (underline, number states, picker
  rows) using base16 variables only.

## Capabilities

### New Capabilities
<!-- None — this builds on the existing ags-bar capability. -->

### Modified Capabilities
- `ags-bar`: the **Workspaces module** requirement changes from dots to
  monitor-bound numbers with a coloured underline and a right-click screen
  picker; a new requirement covers the workspace→monitor accent mapping and the
  screen picker behaviour. The (code-only, never-specified) clients row is
  removed.

## Impact

- **AGS shell (`ags/`)**, rebuilt by `homeManagerModules.lkh-ags`:
  - `ags/windows/bar/workspaces.tsx` — rewritten (numbers + monitor underline +
    right-click screen picker).
  - `ags/windows/bar/clients.tsx` — **deleted**.
  - `ags/windows/bar/index.tsx` — drop the `<Clients />` import and usage from
    the left pill.
  - `ags/style.scss` — workspace number/underline/active states + screen-picker
    popover styling (base16 only).
- **Data sources:** `AstalHyprland` for reactive workspaces/monitors and
  `workspace → monitor`; `hyprctl monitors -j` for the picker's detailed specs
  (model / mode / connector); `hyprctl dispatch moveworkspacetomonitor` for the
  move action (the bar already execs `hyprctl`).
- **Dependencies:** no new packages.
- **Behavioural:** the running-app icon row disappears from the bar; workspaces
  gain monitor-colour underlines and a right-click move-to-monitor picker.
