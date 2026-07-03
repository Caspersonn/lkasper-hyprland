# hyprland-config Specification

## ADDED Requirements

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
