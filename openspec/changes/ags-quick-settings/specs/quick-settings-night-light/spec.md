## ADDED Requirements

### Requirement: NightLight tile
The NightLight tile in `ags/windows/quick-settings/modules/night-light-tile.tsx` SHALL provide a toggleable tile for hyprsunset night light control with temperature display and drill-down arrow.

#### Scenario: Enable Night Light
- **GIVEN** Night Light is off (identity mode)
- **WHEN** the user clicks the tile icon area
- **THEN** the system SHALL disable hyprsunset identity mode (activating the color filter)

#### Scenario: Disable Night Light
- **GIVEN** Night Light is active (non-identity mode)
- **WHEN** the user clicks the tile icon area
- **THEN** the system SHALL enable hyprsunset identity mode (removing the color filter)

#### Scenario: Show temperature in description
- **GIVEN** Night Light is active
- **WHEN** the tile is rendered
- **THEN** the description SHALL display the current temperature (e.g., "4500K") and optionally the gamma percentage

#### Scenario: Show disabled description
- **GIVEN** Night Light is off
- **WHEN** the tile is rendered
- **THEN** the description SHALL show "Disabled"

#### Scenario: Tile hidden when hyprsunset not installed
- **GIVEN** hyprsunset is not available on the system
- **WHEN** the tiles grid is rendered
- **THEN** the NightLight tile SHALL be hidden

#### Scenario: Open NightLight page from tile
- **GIVEN** the NightLight tile is visible
- **WHEN** the user clicks the content area or arrow
- **THEN** the NightLight settings page SHALL open in the tiles Pages zone

### Requirement: NightLight settings page
The NightLight page in `ags/windows/quick-settings/modules/night-light-page.tsx` SHALL provide temperature and gamma sliders for fine-tuning the night light filter.

#### Scenario: Adjust temperature
- **GIVEN** the NightLight page is open
- **WHEN** the user drags the temperature slider
- **THEN** the system SHALL update the hyprsunset temperature to the slider value

#### Scenario: Adjust gamma
- **GIVEN** the NightLight page is open
- **WHEN** the user drags the gamma slider
- **THEN** the system SHALL update the hyprsunset gamma to the slider value

#### Scenario: Reflect current values
- **GIVEN** the NightLight page is open
- **WHEN** temperature or gamma values change externally
- **THEN** the sliders SHALL update to reflect the current values
