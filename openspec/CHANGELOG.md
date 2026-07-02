# OpenSpec Changelog

## 2026-07-02

- **Dynamic workspace underline** — Underline width scales with app count
  - Drove the `.ws-underline` width from the workspace client count in `ags/windows/bar/workspaces.tsx` (20px per client window, clamped to 3 → `20/40/60`) and removed the static `min-width` from `ags/style.scss`.
  - Made the cell icon row count client windows (dropped the class-dedup and keyed `<For>` by client `address`), so icons and underline agree on the count.
  - Updated the `ags-bar` "Workspaces module" spec.
  - See [proposal](changes/archive/2026-07-02-dynamic-workspace-underline/proposal.md).

## 2026-07-01

- **Float bar popovers** — Popovers float below the bar with no shadow
  - Added `margin-top` (10px) to the shared `.popover-wrap > contents` rule in `ags/style.scss`, so all six bar popovers float a measured gap below the bar; kept `box-shadow: none`.
  - Added the `ags-bar` "Popover float gap" requirement.
  - See [proposal](changes/archive/2026-07-01-float-bar-popovers/proposal.md).

- **Flatten bar islands** — Solid island fill, drop shadow removed
  - Changed `$island-fill` to a solid `$base-dark` (no translucency) and dropped the island `box-shadow` in `ags/style.scss`.
  - Updated the `ags-bar` "Island styling" spec to require an opaque fill and no drop shadow.
  - See [proposal](changes/archive/2026-07-01-flatten-bar-islands/proposal.md).

## 2026-06-26

- **ASG V2 bar archived** — Synced specs and archived the bar rebuild
  - Replaced the old pill bar specs with the three-island ASG V2 bar model.
  - Added main specs for active window, calendar, control center, media, power menu, system stats, and weather.
  - See [proposal](changes/archive/2026-06-26-asg-v2-bar/proposal.md).
