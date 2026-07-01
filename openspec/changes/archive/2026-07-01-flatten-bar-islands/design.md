## Context

The ASG V2 bar (bean `lkasper-hyprland-p9k5`, archived at `openspec/changes/archive/2026-06-26-asg-v2-bar/`) styles the bar islands with a translucent fill and a drop shadow. All of this lives in a single stylesheet, `ags/style.scss`, driven by two variables:

- `$island-shadow: 0 8px 24px rgba(0, 0, 0, 0.38)` — applied once, at `.island { box-shadow: $island-shadow }`.
- `$island-fill: rgba($base-dark, 0.8)` — consumed by `.island` and `window.bar .clock`, so it governs the fill of all three islands (left, center clock, right).

Every other `box-shadow` declaration in the file is already `none`. The `bar` Hyprland namespace is not blurred (only `wofi` is), so the current translucency shows raw, unblurred wallpaper through the islands. This change is purely a surface-treatment tweak — no widget, layout, or dependency changes.

## Goals / Non-Goals

**Goals:**
- Remove the island drop shadow entirely.
- Make the islands opaque using the existing `$base-dark` base16 variable (no hardcoded colours).
- Keep the change confined to `ags/style.scss`.

**Non-Goals:**
- Changing island borders, radius, layout, dividers, or hover behaviour.
- Adding or removing any Hyprland blur rule.
- Touching any NixOS/home-manager option surface.

## Decisions

- **Solid colour = `$base-dark` (`#1d2021`).** Flip `$island-fill` from `rgba($base-dark, 0.8)` to solid `$base-dark`. Keeps the current darkest tone; one edit covers all three islands. Alternative considered: `$base` (`#282828`), rejected because the clock hover already targets `$base` and we want the resting fill to stay the darker tone.
- **Delete the dead `$island-shadow` variable.** Once `.island`'s `box-shadow` is removed, the variable has no remaining consumers; leaving it would be dead code. Alternative: leave it dangling — rejected as needless cruft.
- **Single-file, variable-driven edit.** Prefer editing the existing variables over per-rule overrides so the island look stays defined in one place.

## Risks / Trade-offs

- [Wallpaper no longer peeks through islands] → Intended; the gaps between islands still reveal the wallpaper, preserving the floating-island read.
- [Loss of depth cue from the shadow] → Accepted; the border and rounded shape still separate islands from the background.

## Migration Plan

Edit `ags/style.scss`, run `nix fmt`, rebuild the home-manager generation to pick up the AGS style. Rollback is reverting the three lines.

## Open Questions

None.
