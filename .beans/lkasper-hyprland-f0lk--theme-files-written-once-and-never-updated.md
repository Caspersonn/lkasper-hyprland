---
# lkasper-hyprland-f0lk
title: Theme files written once and never updated (activation if-not-exists guards)
status: completed
type: bug
priority: high
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

`modules/home-manager/themes.nix` writes four theme files in `home.activation.writeThemeDefaults`, each guarded by `if [ ! -f ... ]`:

- `~/.config/hypr/theme.conf`
- `~/.config/btop/themes/lkh-runtime.theme`
- `~/.config/ghostty/themes/lkh-runtime`
- `~/.config/starship.toml`

They are therefore written exactly once, on the first activation that finds them absent, and never refreshed. Changing `activeWallpaper` and rebuilding silently does nothing to them, and `theme-switch` never rewrites them either. The infra was designed for runtime switching but these four are stuck at whatever the first-ever activation produced.

Fix: the theme bundle becomes a nix-generated store path per (pair, mode) and the app config paths become symlinks into `~/.config/lkasper-hyprland/current/`, so there is nothing to guard — content is always current and switching is one relink.

Rolls up under o51v.

## Fixed (opsx:apply)
All four guards removed. themes.nix now generates the full config bundle per (pair, mode) in the nix store and each app config path is a symlink into ~/.config/lkasper-hyprland/current/, so there is nothing to guard - content is always current and switching is one relink. Verified: activation package builds, all 24 bundle files render, toggle updates every consumer.
