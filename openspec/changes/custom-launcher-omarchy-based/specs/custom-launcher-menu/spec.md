## ADDED Requirements

### Requirement: Omarchy-style custom launcher keybind entrypoint
The home-manager Hyprland configuration SHALL provide a dedicated custom launcher command entrypoint that is bound in `modules/home-manager/_hyprland/bindings.nix` to `SUPER ALT, SPACE` and executes `omarchy-menu` from `~/.local/share/omarchy/bin`.

#### Scenario: Open custom launcher from keybind
- **GIVEN** `homeManagerModules.omarchy-hyprland` is enabled for the active user session
- **WHEN** the user presses `SUPER ALT, SPACE`
- **THEN** Hyprland executes `omarchy-menu` and opens the custom launcher UI

### Requirement: Theme submenu entrypoint for direct invocation
The custom launcher implementation SHALL support direct submenu invocation through `omarchy-menu theme`, and Hyprland keybinds SHALL expose a dedicated chord for that command.

#### Scenario: Open theme submenu directly
- **GIVEN** runtime launcher scripts are installed under `~/.local/share/omarchy/bin`
- **WHEN** the user triggers the keybind mapped to `omarchy-menu theme`
- **THEN** the theme-selection submenu opens without first rendering the top-level launcher menu

### Requirement: Portable bash shebang for launcher scripts
Launcher scripts shipped in `bin/` and installed under `~/.local/share/omarchy/bin` SHALL use `#!/usr/bin/env bash` as the interpreter line.

#### Scenario: Run launcher script on NixOS
- **GIVEN** `/bin/bash` is not present on the host system
- **WHEN** the user executes `omarchy-launch-walker` or `omarchy-menu`
- **THEN** the script starts successfully using bash resolved from `env`
