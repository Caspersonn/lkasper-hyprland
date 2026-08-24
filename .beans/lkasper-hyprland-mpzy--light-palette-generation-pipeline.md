---
# lkasper-hyprland-mpzy
title: Light palette generation pipeline (wallust)
status: completed
type: task
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

`regenerate-palettes.sh` hardcodes `palette = "ansidark16"`, so every palette is dark — `beach-light.json` has `base00 = 000C00`. Light mode needs a real light pipeline.

## Spike results (measured on beach-light.png, ANSI slots >45 deg off canonical hue)

    lchansi + ansidark16  on beach-dark.png   1/7   <- today's dark baseline
    lchansi + ansidark16  on beach-light.png  0/7   <- better than the baseline
    lchansi + light16                         5/7   REJECTED (L1)
    lchansi + softlight16                     7/7
    lch     + light16                         6/7

L1 rejected: wallust has no `ansilight16`, and `lchansi` only preserves ANSI order with the `ansidark` family. The failure is a slot swap, not a tint — base0B ("green") came back #0058BF at hue 212, base0D ("blue") came back #3A9367 at hue 150. git diff would show additions in blue.

L2 validated: hue extraction was never the problem, polarity was. Split them:
- `lch` + `light16`      -> base00-07 (the light shell; #F7FFFC bg, #120D05 fg, 19.0:1)
- `lchansi` + `ansidark16` -> base08-0F (ANSI-faithful, 0/7 off)
- then darken base08-0F to >= 4.5:1 against base00

Clamp cost measured: max hue drift 0.3 deg, max delta-value 0.21, two slots untouched. All eight land at WCAG AA.

## Two gotchas found while measuring
1. The clamp INVERTS with mode. Dark floors brightness (v >= 0.55); light must darken. beach-light's third accent #C3FCDF (pale mint) sits at 1.13:1 on the light bg — invisible — and clamps to #607B6D at 4.54:1. Getting this backwards is catastrophic, not cosmetic.
2. `light16` collapses the shell ramp through the existing base16-template.json: base00 == base01 (both #F7FFFC, because light16 sets color0 ~ background) and base04 == base05 == base06. The base04/05/06 collapse is bean 9ura's known issue and AGS's alpha-ramp fix carries over. But base00 == base01 is new and worse — AGS uses base01 as $surface0, so a light bar would have zero surface separation. base01/base02 must be DERIVED by stepping base00 toward base05.

Accepted trade-off: a pale accent can only reach contrast by going muted (mint -> sage). Clamping value only for now; raising saturation as value drops is the knob if it reads drab.

Rolls up under o51v.

## Implemented (opsx:apply)
Generator rewritten pair-aware (reads pairs.nix via nix eval); colour maths extracted to wallpapers/palette-tool.py. Light path merges lch+light16 base00-07 with lchansi+ansidark16 base08-0F darkened to 4.5:1. Clamp inverts by mode. Surface derivation ended up broader than planned: the first run produced a NON-MONOTONIC dark ramp (base02 514657 lighter than the derived base03 454459), so derive_surfaces now rewrites base01-03 as fixed steps whenever the ramp is collapsed OR non-monotonic, and also derives base04/base06/base07 when they collapse onto base05 - polarity-aware, since base06 must go lighter in dark and darker in light.

Result, both modes 8/8 distinct and monotonic across base00-07 (the dark palette improved too - it previously had base02==base03). beach-light: 0/7 ANSI slots off-hue, every accent >= 4.5:1. beach-dark: 1/7 (base09 orange 55 deg off), unchanged from the pre-existing baseline.
