## ADDED Requirements

### Requirement: Persist current theme selection
The theme engine SHALL write the current theme name to `~/.config/lkasper-hyprland/current/theme.name` after each successful theme switch. The file SHALL contain only the theme name as plain text (no newline suffix required).

#### Scenario: Theme name persisted after switch
- **WHEN** `loadTheme("gruvbox")` completes successfully
- **THEN** `~/.config/lkasper-hyprland/current/theme.name` contains `gruvbox`

#### Scenario: Persistence directory does not exist
- **WHEN** a theme is applied and `~/.config/lkasper-hyprland/current/` does not exist
- **THEN** the engine creates the directory and writes the file

### Requirement: Restore persisted theme on startup
The theme engine SHALL read `~/.config/lkasper-hyprland/current/theme.name` on AGS startup and apply the stored theme. If the file does not exist or the named theme is not available, the engine SHALL fall back to `catppuccin`.

#### Scenario: Restore previously selected theme
- **WHEN** AGS starts and `~/.config/lkasper-hyprland/current/theme.name` contains `gruvbox`
- **THEN** the theme engine applies the gruvbox theme (CSS, wallpaper, non-AGS propagation)

#### Scenario: No persisted theme (first boot)
- **WHEN** AGS starts and `~/.config/lkasper-hyprland/current/theme.name` does not exist
- **THEN** the theme engine applies `catppuccin` (Catppuccin Mocha) as the default theme

#### Scenario: Persisted theme no longer available
- **WHEN** AGS starts and `~/.config/lkasper-hyprland/current/theme.name` contains a theme name that has no corresponding `colors.json`
- **THEN** the theme engine logs a warning and falls back to `catppuccin`

### Requirement: Startup theme application before windows show
The theme engine SHALL apply the persisted (or default) theme during `App.start({ main() })` before any AGS windows become visible. This means `app.apply_css()` with the compiled theme CSS MUST be called before `Bar()` or any other window constructor.

#### Scenario: No theme flash on startup
- **WHEN** AGS starts with a persisted theme
- **THEN** the bar appears with the correct theme colors from the first frame (no flash of default/wrong colors)

### Requirement: Expose current theme as reactive state
The theme engine SHALL export the current theme name as reactive state (via `createState`) so that AGS components can bind to theme changes if needed (e.g., future theme indicator in the bar).

#### Scenario: Component reacts to theme change
- **WHEN** a component binds to the theme engine's current theme state
- **THEN** the binding updates when the theme changes via `loadTheme()`
