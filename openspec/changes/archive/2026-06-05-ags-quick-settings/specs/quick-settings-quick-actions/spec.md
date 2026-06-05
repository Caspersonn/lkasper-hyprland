## ADDED Requirements

### Requirement: QuickActions row layout
The QuickActions component in `ags/windows/quick-settings/quick-actions.tsx` SHALL render a horizontal row at the top of the control center containing user info on the left and action buttons on the right.

#### Scenario: Render user info
- **GIVEN** the control center is open
- **WHEN** the QuickActions row is rendered
- **THEN** the left side SHALL display the user avatar (from ~/.face if it exists), username, and hostname

#### Scenario: Render uptime
- **GIVEN** the control center is open
- **WHEN** the QuickActions row is rendered
- **THEN** an uptime indicator SHALL be shown, polled periodically via `uptime -p`

#### Scenario: Hide avatar when no face file exists
- **GIVEN** ~/.face does not exist
- **WHEN** the QuickActions row is rendered
- **THEN** the avatar area SHALL be hidden and the username/hostname SHALL still display

### Requirement: Lock button
The QuickActions row SHALL include a lock button that launches the lock screen.

#### Scenario: Lock session from control center
- **GIVEN** the control center is open
- **WHEN** the user clicks the lock button
- **THEN** the system SHALL close the control center and launch hyprlock

### Requirement: Logout button
The QuickActions row SHALL include a logout button that opens the logout menu.

#### Scenario: Open logout menu from control center
- **GIVEN** the control center is open
- **WHEN** the user clicks the logout button
- **THEN** the system SHALL close the control center and open the logout menu window
