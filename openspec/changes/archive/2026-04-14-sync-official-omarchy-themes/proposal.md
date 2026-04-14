## Why

This repository currently ships only a subset of Omarchy themes, so users cannot select the full official theme and background catalog from the Omarchy source. We should align with upstream `dev/themes` while keeping this project declarative and Nix-native.

## What Changes

- Add all official Omarchy theme definitions from upstream `https://github.com/basecamp/omarchy/tree/dev/themes` into this repo as committed files.
- Extend `modules/_themes.nix` with all imported theme entries so the current declarative theme mapping path remains the source of truth.
- Store and reference wallpapers from `config/themes/wallpapers/` for imported themes.
- Ensure generated theme assets (including Waybar and related runtime files) are produced for every imported theme using the existing template pipeline.
- Wire the expanded theme set into the existing selection flow used by `omarchy-theme-set` and menu-driven theme selection.
- Keep current Nix module interfaces stable while updating packaged theme content consumed by `homeManagerModules.omarchy-hyprland`.
- Do not introduce runtime GitHub fetching, dynamic imports, or monorepo-style external source wiring.

## Capabilities

### New Capabilities
- `official-omarchy-theme-catalog`: Provide the complete upstream Omarchy theme and background catalog as local declarative assets, with parity to upstream naming and selection behavior.

### Modified Capabilities
- None.

## Impact

- Affected outputs: `modules/_themes.nix`, `config/themes/wallpapers/`, `homeManagerModules.omarchy-hyprland` theme assets, and scripts under `bin/` that load/apply themes.
- Affected systems: theme template generation, runtime theme file copy/restart flow, menu-based theme selection.
- No new external runtime dependencies; theme content remains local, declarative, and committed in this repository.
