---
# lkasper-hyprland-pw1t
title: GTK apps hard-pinned to dark by session env vars
status: completed
type: bug
priority: high
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

`modules/home-manager/_hyprland/envs.nix` sets, in both `home.sessionVariables` and the Hyprland `env` block:

    ADW_DISABLE_PORTAL = "1";   # comment claims "portal is broken"
    GTK_THEME = "Adwaita-dark";

`GTK_THEME` overrides gsettings for GTK3 and GTK4 alike, for the whole session. No light mode can reach nautilus or any libadwaita app while it is set, and it cannot change without a re-login.

Fix: remove both env vars and let `theme-apply` set `color-scheme` / `gtk-theme` via gsettings.

## The dconf hypothesis was WRONG (corrected after live diagnosis)
I first guessed the portal was broken because `programs.dconf.enable` was missing on
personal-casper / technative-casper. Measured on the live machine, dconf works fine -
`gsettings get org.gnome.desktop.interface color-scheme` returned `prefer-light` and it
persisted. The portal comment was accurate but the cause is unrelated. See bean `xq4d` for the
real root cause: home-manager's `xdg.portal` shadows the system portal directory, so
`gtk.portal` was never visible and the `Settings` interface did not exist at all.

Because the Settings portal genuinely was absent, `ADW_DISABLE_PORTAL=1` was a CORRECT
workaround by the original author, not a mistake. With `xq4d` fixed the portal works properly,
so removing it is right - but the ordering matters: remove the env vars AND fix the portal, or
libadwaita has nothing to read.

Rolls up under o51v.

## Fixed (opsx:apply)
Removed GTK_THEME and ADW_DISABLE_PORTAL from home.sessionVariables and from the Hyprland env block; enabled programs.dconf in modules/nixos/hyprland.nix; theme-apply sets color-scheme and gtk-theme via gsettings and the bundle ships gtk.css symlinked for GTK3 and GTK4. Verified the generated hyprland.conf carries neither variable. The dconf hypothesis is still unconfirmed on hardware - task 5.5 (libadwaita app follows the toggle live) needs a live desktop.
