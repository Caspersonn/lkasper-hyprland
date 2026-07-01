## Why

Bean: `.beans/lkasper-hyprland-zdci--remove-box-shadown-around-every-module-in-ags.md`

The ASG V2 bar (bean `lkasper-hyprland-p9k5`) gave the bar islands a drop shadow and a translucent fill. The shadow reads as visual noise and the translucency lets the wallpaper bleed through without any blur backing it (the `bar` namespace is not blurred in Hyprland). We want a flatter, calmer bar: no shadow and solid islands.

## What Changes

- Remove the island drop shadow. The only live application is `.island { box-shadow: $island-shadow }` in `ags/style.scss`; the now-dead `$island-shadow` variable is deleted with it.
- Make the islands a solid (opaque) fill instead of translucent. The single `$island-fill` variable (consumed by `.island` and `window.bar .clock`) changes from `rgba($base-dark, 0.8)` to solid `$base-dark`, so all three islands (left, center clock, right) become opaque in one edit.
- No layout, widget, blur-rule, or dependency changes — purely the island surface treatment in the AGS stylesheet.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `ags-bar`: the "Island styling" requirement changes — islands SHALL have a solid `$base-dark` fill (no translucency) and SHALL NOT carry a drop shadow. Border and rounded-rectangle shape are retained.

## Impact

- **Targets**: home-manager AGS shell sources under `ags/` (consumed by the home-manager ags integration). No NixOS modules or shared flake plumbing affected; no `homeManagerModules.*` option surface change.
- **Files**: `ags/style.scss` only — remove `$island-shadow` (var + `.island` usage) and flip `$island-fill` to solid `$base-dark`. ~3 edited lines.
- **Deps / blur**: none. The `bar` namespace is not blurred (only `wofi` is), so going opaque removes no blur dependency.
- **Verification**: `nix fmt`.
