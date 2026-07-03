# hyprland-config Specification

## Purpose
TBD - created by archiving change ags-desktop-foundation. Update Purpose after archive.
## Requirements
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

### Requirement: Meaningful keybinds carry descriptions via bindd

Meaningful keybinds in `modules/home-manager/_hyprland/bindings.nix` SHALL be declared with `bindd` (bind-with-description) and SHALL embed a human-readable description using the `[Group] Label` convention, so the description is available at runtime through `hyprctl binds -j`. Non-discoverable binds (multimedia keys, mouse binds) MAY remain plain `bind` and are intentionally excluded from the cheatsheet.

#### Scenario: Described bind is queryable at runtime

- **WHEN** the Hyprland config is generated and loaded
- **THEN** `hyprctl binds -j` reports `has_description: true` with a `[Group] Label` description for each migrated bind

#### Scenario: Noise binds stay undescribed

- **WHEN** the config defines multimedia (`bindel`/`bindl`) or mouse (`bindm`) binds
- **THEN** those binds remain plain (no description) and are therefore hidden from the cheatsheet overlay

### Requirement: Keybind opens the cheatsheet overlay

`bindings.nix` SHALL define a keybind (`SUPER, slash`) that runs `ags request toggle-shortcuts`, itself described as `[System] Show keybindings`.

#### Scenario: Overlay keybind present

- **WHEN** the keybinds module is loaded
- **THEN** a `bindd` entry maps `SUPER, slash` to `exec, ags request toggle-shortcuts` with description `[System] Show keybindings`

