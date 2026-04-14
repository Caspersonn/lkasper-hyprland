## ADDED Requirements

### Requirement: WiFi power toggle
The WiFi section in `ags/windows/quick-settings/wifi.tsx` SHALL provide a pill-switch that toggles wireless state through `astal-network`.

#### Scenario: Toggle WiFi on
- **GIVEN** WiFi is disabled
- **WHEN** the user turns on the WiFi pill switch
- **THEN** the system SHALL set WiFi enabled state to true

#### Scenario: Toggle WiFi off
- **GIVEN** WiFi is enabled
- **WHEN** the user turns off the WiFi pill switch
- **THEN** the system SHALL set WiFi enabled state to false

### Requirement: Collapsed WiFi summary
The WiFi section SHALL be collapsed by default and show current network summary with expansion affordance.

#### Scenario: Show collapsed summary by default
- **GIVEN** the quick-settings panel has just opened
- **WHEN** WiFi section state is initialized
- **THEN** the section SHALL render collapsed with a header and chevron affordance

#### Scenario: Show current SSID in collapsed state
- **GIVEN** WiFi is connected
- **WHEN** the section is collapsed
- **THEN** the header SHALL display the active SSID

### Requirement: Expanded network list with connect and disconnect
When expanded, WiFi section SHALL list available access points and allow Connect/Disconnect actions.

#### Scenario: Connect to open or saved network
- **GIVEN** an expanded WiFi section with an open or previously saved network
- **WHEN** the user presses Connect on that network
- **THEN** the system SHALL activate the access point without password prompt

#### Scenario: Disconnect current network
- **GIVEN** WiFi is connected to an access point
- **WHEN** the user presses Disconnect
- **THEN** the system SHALL deactivate the active WiFi connection

### Requirement: Inline password entry for secured unsaved networks
For secured networks requiring credentials, the WiFi section SHALL provide inline password entry in-panel and use it during connection.

#### Scenario: Prompt inline password for secured unsaved network
- **GIVEN** the user selects a secured network with no saved credentials
- **WHEN** the user presses Connect
- **THEN** the WiFi section SHALL show an inline password field in the same section

#### Scenario: Connect secured network using inline password
- **GIVEN** the inline password field is visible for a secured network
- **WHEN** the user submits a password
- **THEN** the system SHALL attempt activation of that access point with the provided password

#### Scenario: Show authentication failure state
- **GIVEN** a password-based connection attempt fails authentication
- **WHEN** WiFi connection state reports auth failure
- **THEN** the section SHALL show an error state and keep password entry available for retry
