# wallpaper-theme-switching Specification

## Purpose
TBD - created by archiving change wallpaper-driven-theming. Update Purpose after archive.
## Requirements
### Requirement: Whole-desktop recolour from the active wallpaper

Selecting a wallpaper SHALL set it as the active wallpaper and recolour every themed surface from that wallpaper's palette: the AGS shell (bar, overlays, popups), the terminal, btop, hyprlock, and Hyprland borders.

#### Scenario: Switch recolours all surfaces
- **WHEN** a wallpaper is selected
- **THEN** the wallpaper is set AND all themed surfaces use that wallpaper's base16 palette

### Requirement: Single palette source, no static colours

All themed colours SHALL reference the active wallpaper's palette; no component SHALL define hardcoded colour palette values. Semantic colours (ok, warn, crit) SHALL map to base16 slots (base0B, base0A, base08) derived from the wallpaper.

#### Scenario: No hardcoded palette remains
- **WHEN** the AGS styles and Nix theme modules are inspected
- **THEN** they contain no hardcoded colour palette values, only references to the active palette

#### Scenario: Semantics come from the wallpaper
- **WHEN** the active wallpaper changes
- **THEN** ok/warn/crit indicators (e.g. battery, alerts) take their colours from the new palette's base0B/base0A/base08

### Requirement: Live AGS recolour without rebuild

The running AGS shell SHALL consume the active palette at runtime and recolour on a switch without rebuilding or restarting the shell process.

#### Scenario: AGS recolours live
- **WHEN** the active wallpaper changes while the shell is running
- **THEN** the bar, overlays and popups recolour within a short time and the shell process is not restarted

### Requirement: Defined per-app reload behaviour

The switch SHALL reload each themed app through its supported mechanism; apps that cannot hot-reload SHALL pick up the new palette on their next launch or new window, and the switch SHALL complete without error regardless.

#### Scenario: Mixed reload capabilities
- **WHEN** a switch occurs
- **THEN** Hyprland borders and the AGS shell update immediately, terminals/btop update via their reload path or on next instance, and the switch reports success without blocking

### Requirement: Fallback when a palette is missing

WHEN the active wallpaper has no committed palette, the system SHALL fall back to a last-known or default palette and SHALL NOT crash or leave surfaces uncoloured.

#### Scenario: Missing palette
- **WHEN** a wallpaper without a committed palette becomes active
- **THEN** the desktop uses the fallback palette and no themed surface is left unstyled

