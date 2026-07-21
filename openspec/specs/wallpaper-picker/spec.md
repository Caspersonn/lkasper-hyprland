# wallpaper-picker Specification

## Purpose
TBD - created by archiving change wallpaper-driven-theming. Update Purpose after archive.
## Requirements
### Requirement: Wallpaper picker overlay

The system SHALL provide an AGS overlay that lists the available wallpapers (those with a committed palette) as thumbnails and indicates which one is active.

#### Scenario: Picker lists wallpapers
- **WHEN** the picker is opened
- **THEN** it shows one thumbnail per available wallpaper and marks the currently active wallpaper

### Requirement: Toggle and dismiss

The picker SHALL be opened and closed by a keybind (and MAY also be opened from a bar button), and SHALL close on selection or when Escape is pressed.

#### Scenario: Toggle with keybind
- **WHEN** the picker keybind is pressed
- **THEN** the picker opens if closed and closes if open

#### Scenario: Dismiss without changing
- **WHEN** the picker is open and Escape is pressed (or a click lands outside it)
- **THEN** the picker closes and the active wallpaper is unchanged

### Requirement: Selection triggers the switch

Selecting a wallpaper in the picker (by click or keyboard) SHALL trigger the theme switch for that wallpaper and close the picker.

#### Scenario: Select a wallpaper
- **WHEN** the user selects a wallpaper in the picker
- **THEN** the theme switch runs for that wallpaper and the picker closes

