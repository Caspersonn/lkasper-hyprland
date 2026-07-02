## Why

Bean: `.beans/lkasper-hyprland-44ro--underline-workspace-grow-dynamicly-with-amount-app.md`

Each workspace cell in the bar draws a coloured underline, but its width is fixed (`.ws-underline { min-width: 14px }` in `ags/style.scss`) regardless of how many apps live on that workspace. A workspace with one window and a workspace with eight look identical, so the underline carries no "how full is this workspace" information. The underline should grow with the number of clients on the workspace so busier workspaces read as busier at a glance.

While wiring this up we also found the icon row and the underline disagreed about "how many apps": the underline counts client windows, but the icon row deduplicated by window class, so opening the same app twice widened the underline without adding an icon. Both should count client windows.

## What Changes

- Drive the workspace underline width from the workspace's client count instead of a fixed CSS width. In `ags/windows/bar/workspaces.tsx`, add a computed `widthRequest` for the `.ws-underline` box derived from `clients.length`: one 20px base unit per client window, clamped to 3 clients — i.e. `20 → 40 → 60` — so the underline never overflows the cell.
- Stop deduplicating the workspace icon row by window class. In `ags/windows/bar/workspaces.tsx`, the `appIcons` accessor now emits one icon per client window (in client order, still capped), so the icon row and the underline both reflect the client-window count.
- Remove the static `min-width: 14px` from `.ws-underline` in `ags/style.scss` (the width now comes from the widget's `widthRequest`); keep the height, radius, margin, and colour rules unchanged.
- No change to workspace visibility, focus/occupied/empty colouring, monitor-accent logic, or the number label — purely the underline's width and the icon-row counting.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `ags-bar`: the "Workspaces module (left island)" requirement changes — the workspace underline width SHALL scale with the number of client windows on the workspace (a base width, growing per client, up to a cap) instead of a fixed width, and the icon row SHALL show one icon per client window (not deduplicated per distinct app class) so it counts the same thing as the underline. Colour, height, and focus/occupied/empty behaviour are unchanged.

## Impact

- **Targets**: home-manager AGS shell sources under `ags/` (consumed by the home-manager ags integration). No NixOS modules or shared flake plumbing affected; no `homeManagerModules.*` option surface change.
- **Files**:
  - `ags/windows/bar/workspaces.tsx` — add a `clients`-derived `underlineWidth` computed accessor bound to the `.ws-underline` box's `widthRequest`, and drop the per-class dedup in the `appIcons` accessor.
  - `ags/style.scss` — drop `min-width: 14px` from `.ws-underline`.
- **Deps**: none. Uses the existing `AstalHyprland.Workspace` `clients` binding already read for icons and occupied state.
- **Verification**: `nix fmt`; `ags bundle` compiles; rebuild and confirm the underline lengthens as apps are added, clamps at the cap, and that opening the same app twice adds a second icon.
