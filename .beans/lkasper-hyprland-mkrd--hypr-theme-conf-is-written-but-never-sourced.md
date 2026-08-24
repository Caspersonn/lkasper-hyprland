---
# lkasper-hyprland-mkrd
title: hypr/theme.conf silently overrides looknfeel border colours
status: completed
type: bug
priority: low
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

`themes.nix` activation writes `~/.config/hypr/theme.conf` with `general{}` and `group{}` border colours, guarded by `if [ ! -f ]` so it is written exactly once (see f0lk). `modules/home-manager/_hyprland/looknfeel.nix:20-21` ALSO sets `col.active_border` / `col.inactive_border` from `config.colorScheme`.

Two sources for one value, and theme.conf wins: `_hyprland/configuration.nix:39` sources it from `extraConfig`, which home-manager appends at the END of hyprland.conf (verified at line 238 of the generated config, vs. `general {` at line 175). So Hyprland's border colours come from a file written once at first activation and never refreshed, silently overriding the declarative value in looknfeel.nix.

Correction to an earlier reading of this: theme.conf is NOT dead. It is sourced, it is last, and it wins. That makes it worse than dead, not harmless.

Fix: drop the static border colours from `looknfeel.nix`, repoint the `extraConfig` source at the generated `current/hypr.conf`, and remove the stale `theme.conf` in activation. One source, last-wins, refreshed on every switch.

Rolls up under o51v.

## Fixed (opsx:apply)
Repointed configuration.nix extraConfig from ~/.config/hypr/theme.conf at ~/.config/lkasper-hyprland/current/hypr.conf, dropped the static col.active_border/col.inactive_border from looknfeel.nix, and activation removes the stale theme.conf. Verified in the generated hyprland.conf: exactly one border source, no static colours, and the bundle's hypr.conf differs between modes (FF614B dark vs 287DA5 light).
