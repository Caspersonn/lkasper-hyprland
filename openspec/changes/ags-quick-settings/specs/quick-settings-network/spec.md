## ADDED Requirements

### Requirement: Network tile
The Network tile in `ags/windows/quick-settings/modules/network-tile.tsx` SHALL provide a toggleable tile for WiFi/wired network state with connection info and drill-down arrow.

#### Scenario: Show WiFi SSID when connected via WiFi
- **GIVEN** the primary network type is WiFi and it is connected
- **WHEN** the tile is rendered
- **THEN** the tile title SHALL display the active SSID

#### Scenario: Show "Wired" when connected via wired
- **GIVEN** the primary network type is wired
- **WHEN** the tile is rendered
- **THEN** the tile title SHALL display a wired network label

#### Scenario: Show connection status in description
- **GIVEN** the network tile is rendered
- **WHEN** the network state changes
- **THEN** the description SHALL reflect "Connected", "Connecting...", or "Disconnected"

#### Scenario: Toggle WiFi off
- **GIVEN** primary network is WiFi and it is enabled
- **WHEN** the user clicks the tile icon area
- **THEN** the system SHALL set WiFi enabled state to false

#### Scenario: Toggle WiFi on
- **GIVEN** primary network is WiFi and it is disabled
- **WHEN** the user clicks the tile icon area
- **THEN** the system SHALL set WiFi enabled state to true

#### Scenario: Toggle wired networking off
- **GIVEN** primary network is wired and connected
- **WHEN** the user clicks the tile icon area
- **THEN** the system SHALL disable networking via nmcli

#### Scenario: Tile icon reflects network type and state
- **GIVEN** the network tile is rendered
- **WHEN** network type or state changes
- **THEN** the icon SHALL update: WiFi signal icon when WiFi, wired icon when wired, no-route icon when disconnected

#### Scenario: Open Network page from tile
- **GIVEN** the Network tile is visible
- **WHEN** the user clicks the content area or arrow
- **THEN** the Network detail page SHALL open in the tiles Pages zone

### Requirement: Network detail page
The Network page in `ags/windows/quick-settings/modules/network-page.tsx` SHALL list network devices and WiFi access points with connect/disconnect actions.

#### Scenario: Show network devices
- **GIVEN** the Network page is open
- **WHEN** network devices exist (excluding loopback)
- **THEN** a "Devices" section SHALL list each interface with type icon and name

#### Scenario: Show WiFi access points
- **GIVEN** the primary network is WiFi and the Network page is open
- **WHEN** access points are available
- **THEN** a "Wi-Fi" section SHALL list each AP with SSID, signal icon, and security indicator

#### Scenario: Connect to open or saved network
- **GIVEN** an expanded Network page with an open or previously saved network
- **WHEN** the user clicks the AP entry
- **THEN** the system SHALL activate the access point without password prompt

#### Scenario: Disconnect current WiFi network
- **GIVEN** WiFi is connected to an access point
- **WHEN** the user clicks the disconnect button on the active AP
- **THEN** the system SHALL deactivate the active WiFi connection

#### Scenario: Prompt inline password for secured unsaved network
- **GIVEN** the user selects a secured network with no saved credentials
- **WHEN** the user clicks the AP entry
- **THEN** the system SHALL show an inline password field

#### Scenario: Connect secured network using inline password
- **GIVEN** the inline password field is visible for a secured network
- **WHEN** the user submits a password
- **THEN** the system SHALL attempt activation with the provided password

#### Scenario: Show authentication failure state
- **GIVEN** a password-based connection attempt fails
- **WHEN** connection state reports auth failure
- **THEN** the page SHALL show an error state and keep password entry available for retry

#### Scenario: Scan for networks from page header
- **GIVEN** the Network page is open and primary is WiFi
- **WHEN** the user clicks the scan header button
- **THEN** the system SHALL trigger a WiFi scan

#### Scenario: More settings bottom button
- **GIVEN** the Network page is open
- **WHEN** the user clicks "More Settings"
- **THEN** the system SHALL close the control center and launch nm-connection-editor
