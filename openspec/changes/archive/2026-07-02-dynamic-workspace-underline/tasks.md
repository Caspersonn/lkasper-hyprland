## 1. Drive underline width from client count

- [x] 1.1 In `ags/windows/bar/workspaces.tsx`, add an `underlineWidth` computed accessor over the existing `clients` binding: one base unit (`20`) per client window, clamped to 3 clients — i.e. `20 → 40 → 60`
- [x] 1.2 In `ags/windows/bar/workspaces.tsx`, bind `widthRequest={underlineWidth}` on the `.ws-underline` box
- [x] 1.3 In `ags/style.scss`, remove `min-width: 14px` from `.ws-underline` (keep height, margin, radius, colour)
- [x] 1.4 In `ags/windows/bar/workspaces.tsx`, remove the class-dedup `Set` from `appIcons` so the icon row shows one icon per client window (still capped at 3), matching the underline's window count

## 2. Verify

- [x] 2.1 Run `nix fmt`
- [x] 2.2 Rebuild and confirm: the underline lengthens as apps are added, stays at the base width for a single/empty-focused workspace, clamps at the 3-client cap, and opening the same app twice now adds a second icon (icons no longer deduped)
