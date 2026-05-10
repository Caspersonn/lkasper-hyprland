## ADDED Requirements

### Requirement: Do Not Disturb tile
The DND tile in `ags/windows/quick-settings/modules/dnd-tile.tsx` SHALL provide a simple toggleable tile for notification muting via astal-notifd with toggleOnClick behavior and no detail page.

#### Scenario: Enable Do Not Disturb
- **GIVEN** DND is currently off
- **WHEN** the user clicks anywhere on the DND tile (icon or content area)
- **THEN** the system SHALL set notifd dontDisturb to true and the tile state SHALL reflect enabled

#### Scenario: Disable Do Not Disturb
- **GIVEN** DND is currently on
- **WHEN** the user clicks anywhere on the DND tile
- **THEN** the system SHALL set notifd dontDisturb to false and the tile state SHALL reflect disabled

#### Scenario: Show enabled/disabled description
- **GIVEN** the DND tile is rendered
- **WHEN** DND state changes
- **THEN** the description SHALL show "Enabled" when active or "Disabled" when inactive

#### Scenario: No arrow or detail page
- **GIVEN** the DND tile is rendered
- **WHEN** the tile is displayed
- **THEN** no arrow icon SHALL be shown and no page SHALL be associated with this tile
