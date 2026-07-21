---
# lkasper-hyprland-9ura
title: Wallpaper-driven dynamic theming for AGS
status: completed
type: feature
priority: normal
created_at: 2026-07-20T12:39:57Z
updated_at: 2026-07-21T11:24:23Z
---

The whole AGS shell (bar, overlays: launcher/soltty/shortcuts, notification center, all popups) derives every colour from the CURRENT wallpaper. Changing the wallpaper recolours the shell. No hardcoded hex anywhere. Supersedes the gruvbox vars and the static w- Wood Dark tokens from the bar redesign; overlaps de2q (colouring standard).

## Open questions (opsx:explore)
- Generator: matugen (Material You) vs pywal/wallust vs custom extraction
- Build-time (per switch) vs runtime (regenerate on wallpaper change; hyprpaper currently static)
- AGS consumption: generated SCSS tokens imported by style.scss + hot-reload on change
- Guardrails: contrast/legibility on any wallpaper, light/dark, semantic ok/warn/crit, fallback

## Tasks
- [x] Shape requirements via opsx:explore
- [x] Implement via opsx:apply



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


- [x] group 3 AGS runtime colour: style.scss colours -> GTK named colours via c()/ca() helpers (@baseNN + alpha()); ags/theme.ts injects @define-color from active colors.json at startup (App.start css) and re-applies on current/theme.name change (Gio monitor). Builds; compiled CSS uses @base refs; no static palette colours. 3.6 (live recolour) pairs with group 4 (switcher makes current writable).
- Note: style.scss + app.ts entangle bar-redesign + soltty + this theming (same files, all uncommitted) -> group 3 can't be committed cleanly alone.


- [x] group 4 switch: theme-switch <slug> (in themes.nix home.packages) sets wallpaper via hyprpaper IPC, writes current/theme.name (now mutable; AGS monitor recolours live), recolours Hyprland borders via hyprctl. Wallpaper images exposed at ~/.local/share/lkasper-hyprland/wallpapers/. shellcheck-clean; config evaluates.
- Limitation: terminals/btop read build-time colorScheme -> follow on rebuild, not on runtime switch (bar+overlays+borders+wallpaper switch live). 4.3 live-verify pairs with user test.
- Next: group 5 (picker overlay).


## Bug: "theme-switch doesn't recolour live" (root cause = generation, not runtime)
User reported no visible change on switch. Investigation (read astal App.apply_css/reset_css in the compiled bundle) confirmed the RUNTIME path is correct: reset_css removes tracked providers, apply_css adds a fresh one at PRIORITY_USER -> re-styles live. The 1.5s poll (theme.ts) fires applyTheme.
Real cause: every wallpaper's palette shared an IDENTICAL accent (base0D=3A7DCE) and near-black bg — `ansidark16` anchors ANSI slots to fixed hues, so the slot the UI themed on (base0D) never moved. Static accent hiding in a "dynamic" pipeline.
Fix (user chose "Decoupled accent"):
- regenerate-palettes.sh now also runs a non-ANSI `dark`/lch pass and picks the max-chroma colour as `accent` (bare hex) added to each palettes/<slug>.json. Per-wallpaper: wood-dark 37BDC0 teal, studio-ghibli F9AC5C orange, beach-light 2C8BB7 blue, planet-zoo FFD67F gold, beach-dark FF614B, princess-mononoke C88D6B.
- themes.nix: colors.json carries `accent` (bare, from palette.accent||base0D); hypr border defaults + theme-switch active-border use accent.
- ags/theme.ts: emits `@define-color accent`; ags/style.scss accent-role tokens ($accent,$w-accent,$w-accent-soft,$so-amber,$nixos-blue,inline ca(base0D)) -> `accent`. $blue/semantic slots stay base0D (faithful ANSI for terminal + status colours).
Verified: build green; compiled CSS refs @accent 30x; colors.json accents differ per wallpaper, base0D stays faithful blue. Awaiting live user confirmation.
- Supersedes the earlier 6.2 note about ANSI-faithful semantics: we KEEP ansidark16 for base16 (terminal faithful) and decouple the UI accent instead.


## Legibility + "everything dynamic" (user follow-ups)
1. Washed-out/dark text: wallust palette collapses base04≈base05≈06 (no dim) and base03 too dark. Fixed in style.scss by ramping dim/faint off the real fg: $w-dim=alpha(@base05,.75), $w-faint=alpha(@base05,.5); $subtext0=.72, $gray=.6. Legible hierarchy on every wallpaper, still wallpaper-driven.
2. "Are some colors static?" -> yes: base0A/0B/0C/0D/0E/0F were byte-identical across all wallpapers (ansidark16 ANSI-anchoring). User chose "Everything dynamic".
   Fix: generator now extracts accent + accent2 + accent3 (vivid, hue-diverse; hue-rotation fallback for near-monochrome wallpapers) via a python picker in regenerate-palettes.sh (needs wallust+python3+jq). themes.nix colors.json (AGS-only) overrides base0A..base0F with the triple (0A/0C=accent2, 0B/0E=accent3, 0D/0F=accent); colorScheme (terminal foot/btop/ghostty) keeps faithful base16 so red=red. No style.scss change (values flow through existing @base0A..0F).
   Result: zero static colours in AGS; terminal stays faithful. Tradeoff accepted: battery/warning/critical no longer guaranteed green/yellow/red.
   Verified: AGS colors.json base0B/0C/0D vivid per-wallpaper (wood-dark 438697/BE9294/37BDC0; ghibli 8A6356/DA7360/F9AC5C); palette base0B stays 2F8D5F for terminal. Builds green.


## Group 5 - wallpaper picker overlay (+ 4.3 verified)
- 4.3 live recolour verified by user (theme-switch recolours Hyprland + AGS instantly).
- ags/windows/wallpaper-picker/index.tsx: per-monitor Astal overlay (focused-monitor visibility), 3-col grid of wallpaper thumbnails (Gtk.Picture, COVER, overflow-clipped rounded), marks the active one ("current" chip). Arrow-key nav + click; Escape/backdrop closes without changing. Selection dispatches `theme-switch <slug>` via Hyprland IPC (session PATH, not the stripped shell PATH) and closes.
- app.ts: toggle-wallpaper-picker request handler + initWallpaperPicker in main.
- bindings.nix: SUPER, W -> ags request toggle-wallpaper-picker.
- style.scss: window.wallpaper-picker styles, all theme tokens (no static colours).
- Build green; bundle has the toggle, theme-switch dispatch, wp-tile, Picture.
- 5.5 pending user live-verify (open, lists wallpapers, select switches + recolours).


## Group 6 - guardrails
- 6.1 Fallback palette: ags/theme.ts has a built-in dark FALLBACK_PALETTE (base00-0F + accent); paletteFor() returns it when colors.json is missing/corrupt, so the shell is never unstyled and @baseNN/@accent always resolve. colorScheme build-time default stays wood-dark (always present).
- 6.2 Force-dark (resolved): generator ansidark16 -> always dark base00; UI authored dark-surface + light-text fg ramps; fallback is dark too. No light mode.
- 6.2 Contrast clamp (resolved): wallust check_contrast=true covers base00-0F fg/bg; the wallpaper-derived accent triple isn't covered by it, so regenerate-palettes.sh clamps each accent to HSV v>=0.55 (readable on the near-black bar). Threshold leaves current accents unchanged except studio-ghibli accent3 8A6356->8C6557 (~1%). design.md open questions resolved.
- Build green; FALLBACK_PALETTE in bundle; ghibli colors.json base0B=8C6557.
- Next: group 7 (opsx:verify + link change to this bean).


## Group 7 - verified (opsx:verify)
Implemented via OpenSpec change: openspec/changes/wallpaper-driven-theming (proposal/design/specs/tasks).
opsx:verify: 8/8 requirements implemented, all scenarios covered, follows design (Approach C, base16-native, whole-desktop, force-dark + contrast clamp). No critical issues. Tasks 28/28.
Optional follow-ups (non-blocking): (1) opsx:sync a note that base0A/base0B are remapped to accent2/accent3 in the AGS colors.json ("everything dynamic"); (2) pin wallust version in regenerate-palettes.sh for byte-deterministic regen.
Ready to archive the change + close this bean.
