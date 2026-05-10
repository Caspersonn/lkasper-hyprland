## Why

Theme changes are currently tied to `omarchy.theme` and require a Nix rebuild, which makes iterative desktop theming slow and discourages experimentation. We need an Omarchy-style runtime launcher and theme switcher so users can change themes instantly from Hyprland keybinds.

## What Changes

- Add a custom launcher flow for Hyprland that matches Omarchy behavior: `SUPER ALT, SPACE` opens an Omarchy-style menu and includes a Theme entrypoint.
- Add runtime theme switching commands that apply a selected theme without `home-manager switch`/system rebuild, including targeted app reloads/restarts.
- Introduce runtime theme state under the user config directory so theme selection persists across sessions.
- Add explicit home-manager wiring for scripts/keybinds and keep declarative defaults in `omarchy.*` as fallback bootstrap values.
- Normalize all shipped shell script interpreters to `#!/usr/bin/env bash` for NixOS compatibility.

## Capabilities

### New Capabilities
- `custom-launcher-menu`: Provide a dedicated launcher command and keybind integration in `homeManagerModules.omarchy-hyprland` for Omarchy-style submenu entrypoints, including Theme.
- `runtime-theme-switching`: Provide runtime theme list/current/set commands that update active theme state and refresh themed applications without rebuild, while staying compatible with `omarchy.theme` defaults from `homeManagerModules.omarchy-themes`.

### Modified Capabilities
- None.

## Impact

- Targets: home-manager modules and shared flake plumbing; no new NixOS module output required.
- Affected outputs/options: `homeManagerModules.omarchy-hyprland`, `homeManagerModules.omarchy-themes`, `omarchy.theme`, and Hyprland keybind definitions under `modules/home-manager/_hyprland/`.
- Affected code areas: launcher/theming scripts in `bin/`, HM modules that consume `config.colorScheme.palette.base0X`, and runtime state paths under `~/.config/omarchy/current/`.
- Dependencies/systems: Hyprland keybinds, menu frontend (initially wofi-compatible), and app reload hooks for waybar/mako/hyprland-adjacent UI components.
