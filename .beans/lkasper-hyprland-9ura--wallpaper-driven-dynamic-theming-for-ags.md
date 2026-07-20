---
# lkasper-hyprland-9ura
title: Wallpaper-driven dynamic theming for AGS
status: in-progress
type: feature
priority: normal
created_at: 2026-07-20T12:39:57Z
updated_at: 2026-07-20T14:06:14Z
---

The whole AGS shell (bar, overlays: launcher/soltty/shortcuts, notification center, all popups) derives every colour from the CURRENT wallpaper. Changing the wallpaper recolours the shell. No hardcoded hex anywhere. Supersedes the gruvbox vars and the static w- Wood Dark tokens from the bar redesign; overlaps de2q (colouring standard).

## Open questions (opsx:explore)
- Generator: matugen (Material You) vs pywal/wallust vs custom extraction
- Build-time (per switch) vs runtime (regenerate on wallpaper change; hyprpaper currently static)
- AGS consumption: generated SCSS tokens imported by style.scss + hot-reload on change
- Guardrails: contrast/legibility on any wallpaper, light/dark, semantic ok/warn/crit, fallback

## Tasks
- [x] Shape requirements via opsx:explore
- [ ] Implement via opsx:apply



## OpenSpec change
openspec/changes/wallpaper-driven-theming/ (proposal.md, design.md, specs/{wallpaper-palette-generation,wallpaper-theme-switching,wallpaper-picker}, tasks.md).
Decisions: approach C (committed per-wallpaper base16 via wallust) - whole-desktop - wallpaper-derived semantics - AGS recolours live at runtime - wallpaper picker overlay. Subsumes de2q for AGS.



## Progress (opsx:apply)
- [x] group 0 wallpapers in-repo (static, slugified) + hyprpaper repointed
- [x] group 1 wallust base16 generator committed; palettes/*.json for 6 wallpapers (16 slots, bare hex)
- Note: lchansi+dark16 scrambles hue→slot (base08 not red etc.); use palette 'darkansi' for ANSI-faithful semantics — tuning in guardrail spike 6.2.
- Next: group 2 (nix pipeline: colorScheme from active wallpaper, whole-desktop), group 3 (AGS runtime recolor spike).


- [x] group 2 nix pipeline: themes.nix reads committed wallpaper palettes; colorScheme = active wallpaper (wood-dark) so whole desktop derives from it; runtime themes/<name>/colors.json emitted; config evaluates. (fixed hyprpaper path->string)
- Next: group 3 (AGS runtime recolor spike), 4-6 (switch/picker/guardrails) — need live desktop.
