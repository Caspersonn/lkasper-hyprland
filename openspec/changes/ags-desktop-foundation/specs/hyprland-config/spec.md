## ADDED Requirements

### Requirement: Hyprland keybinds without omarchy wrappers
All keybinds in `modules/home-manager/_hyprland/keybinds.nix` SHALL invoke applications directly without `omarchy-menu` or `omarchy-launch-*` wrapper scripts.

#### Scenario: App launcher keybind
- **WHEN** the keybinds module is loaded
- **THEN** no keybind references `omarchy-menu`, `omarchy-launch`, or any `omarchy-*` script

### Requirement: AGS shell autostart
Hyprland SHALL start the AGS shell on login via `exec-once` in the autostart configuration at `modules/home-manager/_hyprland/autostart.nix`. It SHALL NOT start waybar.

#### Scenario: Shell starts on login
- **WHEN** Hyprland session starts
- **THEN** `exec-once = lkasper-shell` (or the built AGS binary name) is present in the Hyprland config
- **THEN** no `exec-once` line references `waybar`

### Requirement: Remove omarchy option references
The Hyprland configuration modules SHALL NOT reference `config.omarchy.*` options for features that are replaced by direct configuration (menus, theme scripts, etc.). Existing Hyprland window management settings (gaps, borders, animations) MAY be preserved.

#### Scenario: No omarchy menu references
- **WHEN** the Hyprland configuration is generated
- **THEN** no generated config line contains `omarchy-menu` or `omarchy-theme-set`

### Requirement: Basic Hyprland settings preserved
Core Hyprland settings (general gaps, decoration, animations, input) SHALL be preserved or set to sensible defaults. These are configured in `modules/home-manager/hyprland.nix`.

#### Scenario: Functional window management
- **WHEN** Hyprland starts
- **THEN** windows can be moved, resized, and switched between workspaces using keybinds
