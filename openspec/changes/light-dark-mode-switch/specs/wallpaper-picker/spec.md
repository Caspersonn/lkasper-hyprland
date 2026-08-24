# wallpaper-picker Specification (delta)

## MODIFIED Requirements

### Requirement: Wallpaper picker overlay

The system SHALL provide an AGS overlay that lists the available wallpaper **pairs** as thumbnails and indicates which pair is active. Each thumbnail SHALL preview the pair member matching the current mode.

#### Scenario: Picker lists pairs
- **WHEN** the picker is opened
- **THEN** it shows one thumbnail per available pair and marks the currently active pair

#### Scenario: Thumbnail follows the mode
- **WHEN** the picker is opened in light mode
- **THEN** each thumbnail shows that pair's light member
- **AND WHEN** the picker is opened in dark mode
- **THEN** each thumbnail shows that pair's dark member

### Requirement: Selection triggers the switch

Selecting a pair in the picker (by click or keyboard) SHALL trigger the theme switch for that pair, preserving the current mode, and close the picker.

#### Scenario: Select a pair
- **WHEN** the user selects a pair in the picker
- **THEN** the theme switch runs for that pair, the mode is unchanged, and the picker closes
