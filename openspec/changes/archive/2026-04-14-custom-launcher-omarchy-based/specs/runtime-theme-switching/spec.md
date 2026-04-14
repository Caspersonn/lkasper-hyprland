## ADDED Requirements

### Requirement: Runtime theme state and command API
The project SHALL provide runtime theme commands `omarchy-theme-list`, `omarchy-theme-current`, and `omarchy-theme-set` in `~/.local/share/omarchy/bin`, and `omarchy-theme-set` SHALL persist the active selection in `~/.config/omarchy/current/theme.name` with active theme assets under `~/.config/omarchy/current/theme/`.

#### Scenario: Set active runtime theme
- **GIVEN** a supported fixed theme exists in the project theme set
- **WHEN** the user runs `omarchy-theme-set <theme-name>`
- **THEN** `~/.config/omarchy/current/theme.name` is updated to `<theme-name>` and the runtime theme directory is refreshed

### Requirement: Theme switching works without rebuild
Selecting a runtime theme SHALL apply the new theme in the current user session without requiring `nixos-rebuild` or `home-manager switch`, and SHALL trigger configured reload/restart hooks for themed user applications.

#### Scenario: Apply theme in current session
- **GIVEN** the user has an active graphical session managed by Hyprland
- **WHEN** the user selects a theme from the launcher theme submenu
- **THEN** the selected theme is applied in-session and configured UI components are reloaded/restarted without a rebuild step

### Requirement: Declarative fallback compatibility
When runtime theme state is missing or invalid, theming SHALL fall back to declarative defaults derived from `omarchy.theme` in `modules/home-manager/themes.nix`.

#### Scenario: Initialize from declarative default
- **GIVEN** `~/.config/omarchy/current/theme.name` does not exist
- **WHEN** the theming initialization path runs for the user session
- **THEN** runtime state is initialized from the configured `omarchy.theme` default so themed apps still render consistently

### Requirement: Portable bash shebang for theme scripts
Theme runtime scripts shipped in `bin/` and installed under `~/.local/share/omarchy/bin` SHALL use `#!/usr/bin/env bash` as the interpreter line.

#### Scenario: Run theme script on NixOS
- **GIVEN** `/bin/bash` is not present on the host system
- **WHEN** the user runs `omarchy-theme-set <theme-name>`
- **THEN** the script runs successfully using bash resolved from `env`
