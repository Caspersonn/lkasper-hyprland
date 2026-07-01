## Why

Bean: `.beans/lkasper-hyprland-e2nd--popover-floating-under-bar.md`

The bar's popovers (calendar, media, weather, control center, notifications, power) are created with `set_has_arrow(false)`, so they anchor **flush** against the bottom edge of their trigger button — they read as glued to the bar rather than as distinct surfaces. We want them to float a small, measured distance below the bar so each popover reads as its own card.

## What Changes

- Introduce a consistent vertical **gap** between the bar and every popover so they float below it.
- Apply the gap once via the shared `.popover-wrap` CSS class in `ags/style.scss` (all six popovers already add this class), keeping the "one lever, all popovers" pattern established by `flatten-bar-islands`.
- **No drop shadow** on the floated popovers — they stay visually consistent with the now-flat islands; the gap alone communicates separation.
- The gap distance is empirical ("measured and tested" per the bean); start at a small value (~10px) and tune against the 42px islands.

## Targeting

- **Home-manager modules only.** Change is scoped to the AGS shell sources under `ags/` (consumed by `homeManagerModules.omarchy-hyprland`). No NixOS module, no `omarchy.*` option surface, no shared flake plumbing.
- Impacted file: `ags/style.scss` (`.popover-wrap > contents` rule).

## Impact

- Affected spec: `ags-bar` (new "Popover float gap" requirement).
- Affected code: `ags/style.scss`.
- No change to popover contents, triggers, or dismissal behavior.
