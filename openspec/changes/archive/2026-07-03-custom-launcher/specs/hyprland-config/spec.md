## ADDED Requirements

### Requirement: Launcher keybind opens the AGS launcher

`modules/home-manager/_hyprland/bindings.nix` SHALL bind `SUPER, SPACE` to `exec, ags request toggle-launcher` (declared as a `bindd` labelled `[Launcher]`), making the AGS launcher the primary application launcher. walker SHALL remain installed and autostarted but SHALL be moved to a backup bind on `SUPER CTRL, SPACE`. The `SUPER SHIFT, SPACE` toggle-bars bind SHALL be left unchanged.

#### Scenario: SUPER SPACE opens the AGS launcher

- **WHEN** the keybinds module is loaded
- **THEN** a `bindd` entry maps `SUPER, SPACE` to `exec, ags request toggle-launcher`
- **AND** no keybind maps `SUPER, SPACE` to `exec, walker`

#### Scenario: walker available on backup bind

- **WHEN** the keybinds module is loaded
- **THEN** a keybind maps `SUPER CTRL, SPACE` to `exec, walker`
- **AND** walker remains autostarted via `exec-once` in `modules/home-manager/_hyprland/autostart.nix`

#### Scenario: toggle-bars unchanged

- **WHEN** the keybinds module is loaded
- **THEN** `SUPER SHIFT, SPACE` still maps to `ags request toggle-bars`
