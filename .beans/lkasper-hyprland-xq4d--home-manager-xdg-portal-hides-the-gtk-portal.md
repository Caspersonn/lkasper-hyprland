---
# lkasper-hyprland-xq4d
title: home-manager xdg.portal hides the gtk portal (no Settings, no FileChooser)
status: completed
type: bug
priority: high
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

The XDG desktop portal has been half-broken for a long time. `org.freedesktop.portal.Settings`
did not exist at all, and neither did `FileChooser`, `Print` or `Account` - only the 13
interfaces that need no backend plus hyprland's ScreenCast.

## Root cause
home-manager's `xdg.portal` module is enabled (pulled in by the HM hyprland module, with
`extraPortals = [xdg-desktop-portal-hyprland]`, `configPackages = [hyprland]`). It sets

    NIX_XDG_DESKTOP_PORTAL_DIR = ~/.nix-profile/share/xdg-desktop-portal/portals

which OVERRIDES the NixOS system value

    NIX_XDG_DESKTOP_PORTAL_DIR = /run/current-system/sw/share/xdg-desktop-portal/portals

The system directory holds `gtk.portal` AND `hyprland.portal`. The user-profile directory held
only `hyprland.portal`. So the NixOS-level `xdg.portal.extraPortals = [xdg-desktop-portal-gtk]`
in modules/nixos/hyprland.nix was correct and completely ineffective - the frontend could never
see the file.

Frontend log with G_MESSAGES_DEBUG=all, which names it exactly:

    Found 'hyprland' in configuration for default
    Found 'gtk' in configuration for default
    Requested gtk.portal is unrecognized
    Requested backend hyprland.portal does not support org.freedesktop.impl.portal.Settings. Skipping...

Note the config itself was fine: /etc/xdg/xdg-desktop-portal/hyprland-portals.conf says
`default=hyprland;gtk`. Starting xdg-desktop-portal-gtk.service by hand did NOT help, because
the problem is the missing .portal definition, not the missing backend process.

## Proof
    systemctl --user set-environment NIX_XDG_DESKTOP_PORTAL_DIR=/run/current-system/sw/share/xdg-desktop-portal/portals
    systemctl --user restart xdg-desktop-portal.service
    -> Settings.ReadOne(org.freedesktop.appearance, color-scheme) = uint32 2   (prefer-light)
    -> Settings, FileChooser, Print, Account all appear

## Fix
Add `xdg-desktop-portal-gtk` to the HOME-MANAGER `xdg.portal.extraPortals` (in
modules/home-manager/hyprland.nix), so the user-profile portal directory contains gtk.portal.
Verified: the new home-manager profile ships both gtk.portal and hyprland.portal, and gtk.portal
declares org.freedesktop.impl.portal.Settings.

Not just a theming bug - this also restores the GTK file chooser, print and account portals for
Firefox, Electron apps and anything else going through the portal.

Rolls up under o51v; supersedes the dconf hypothesis in pw1t.
