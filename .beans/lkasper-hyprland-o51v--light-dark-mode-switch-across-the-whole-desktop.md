---
# lkasper-hyprland-o51v
title: Light/dark mode switch across the whole desktop
status: completed
type: feature
priority: high
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

One keybind flips the entire desktop between light and dark with no rebuild: wallpaper, AGS shell (bar + all overlays), Hyprland borders, terminals, btop, hyprlock, GTK apps, starship, opencode. Neovim follows the same palette through a documented runtime contract.

Wallpapers become pairs: every wallpaper needs a light and a dark sibling, declared in a nix file. Toggling mode swaps the image AND the palette. Scope for the first landing is the `beach` pair only; the other four wallpapers were moved to `wallpaper.ignored/` until siblings are found.

Overarching bean. Sub-beans: f0lk (activation guards), mkrd (dead theme.conf), pw1t (GTK pinned dark), 2m3q (pair registry), mpzy (light palette pipeline), 4qcy (runtime bundle), dr7u (AGS light mode), 9k58 (nvim contract).

## Explore findings (opsx:explore)
- Force-dark was a deliberate resolution of the archived wallpaper-driven-theming change, not an oversight. Light mode is a NEW axis, not a disabled feature.
- Only AGS + Hyprland borders follow theme-switch today; every other consumer is baked at build time.
- L1 spike REJECTED: wallust has no `ansilight16`, and `lchansi`+`light16` scrambles ANSI slots 5/7 (green lands at hue 212, blue at 150). `git diff` would render additions in blue.
- L2 spike VALIDATED: `lchansi`+`ansidark16` on the LIGHT image scores 0/7 off-hue (better than the dark baseline's 1/7). Split the shell (light16) from the hues (ansidark16) and merge; the darken clamp costs <=0.3 deg hue drift.

## Tasks
- [x] Shape requirements via opsx:explore
- [x] Implement via opsx:apply

## OpenSpec change
openspec/changes/light-dark-mode-switch/ (proposal.md, design.md, specs/{wallpaper-palette-generation,wallpaper-theme-switching,wallpaper-picker}, tasks.md)

## Implemented (opsx:apply)
OpenSpec change: openspec/changes/light-dark-mode-switch/ (proposal, design, 3 delta specs, tasks 47/49).
Two tasks left open: 5.5 (libadwaita follows the toggle) and 6.7 (light mode legibility) need a live desktop.

Keybind: SUPER SHIFT, W -> theme-toggle. SUPER, W still opens the picker (now pair-based).
Commands: theme-toggle | theme-switch <pair> | theme-apply <pair> <mode> | theme-state.

Verified by build + sandboxed HOME:
- both beach palettes regenerated; light is 0/7 ANSI slots off-hue, all accents >= 4.5:1, base00-07 monotonic and 8/8 distinct in BOTH modes (the dark ramp improved too - it had base02==base03 before).
- 24 bundle files render (12 per mode); nvim.lua keeps ANSI-faithful base0A=787A00 while colors.json carries the accent remap AA624B, so the editor contract is not polluted by the shell remap.
- toggle flips both directions, theme-switch preserves mode, `current` stays a symlink (no nesting), bad pair/mode rejected with a usage error.
- AGS bundle builds; all 8 tokenised sites compile to alpha(@hairline|@shade, ...) and zero hardcoded white/black rgba remain; light.scss is compiled in.
- unpaired-image assertion fires: added a stray png, eval failed naming it, removed it.

Correction found during implementation: hypr/theme.conf was NOT dead (see mkrd) - it is sourced last from configuration.nix extraConfig and was overriding looknfeel.nix.

Note: config.colorScheme is now set but consumed by nothing in either repo. Left in place as the nix-colors build-time default; a candidate for a later cleanup bean.

## Live-test round 2 (terminal + firefox not following)
Two more defects, both pre-existing rather than introduced:
- ghostty never re-themed because `gtk-single-instance` means new windows reuse the old config.
  Now driven by its `reload-config` D-Bus action. See 4qcy.
- GTK apps and Firefox could not follow because the XDG portal had NO `Settings` interface -
  home-manager's `xdg.portal` shadows the system portal dir, so `gtk.portal` was never visible.
  See xq4d. This also explains the original "portal is broken" comment; my dconf hypothesis in
  pw1t was wrong and is corrected there.

Still needs a relogin to finish: `GTK_THEME` and `ADW_DISABLE_PORTAL` are session-scoped, so
they linger in the running session until logout.

## Third-party GUI apps (slack, Aonsoku, teams-for-linux, firefox)
See bean v8re. Key scoping point: these follow POLARITY, not the palette - none accepts an
arbitrary base16 palette. All four consume the same portal signal, which is why xq4d was the
real blocker. Verified with `gdbus monitor` that every toggle emits
`org.freedesktop.appearance color-scheme` (1 = dark, 2 = light).

Firefox is fixed declaratively via policies.Preferences; teams-for-linux already defaults to
following; slack and Aonsoku each need a one-time in-app "follow the system" setting that no
config file can express.
