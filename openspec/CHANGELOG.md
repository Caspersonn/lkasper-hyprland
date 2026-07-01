# OpenSpec Changelog

## 2026-07-01

- **Flatten bar islands** — Solid island fill, drop shadow removed
  - Changed `$island-fill` to a solid `$base-dark` (no translucency) and dropped the island `box-shadow` in `ags/style.scss`.
  - Updated the `ags-bar` "Island styling" spec to require an opaque fill and no drop shadow.
  - See [proposal](changes/archive/2026-07-01-flatten-bar-islands/proposal.md).

## 2026-06-26

- **ASG V2 bar archived** — Synced specs and archived the bar rebuild
  - Replaced the old pill bar specs with the three-island ASG V2 bar model.
  - Added main specs for active window, calendar, control center, media, power menu, system stats, and weather.
  - See [proposal](changes/archive/2026-06-26-asg-v2-bar/proposal.md).
