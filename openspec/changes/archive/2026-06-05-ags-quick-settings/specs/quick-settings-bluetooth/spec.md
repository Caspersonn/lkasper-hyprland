## ADDED Requirements

### Requirement: Bluetooth tile
The Bluetooth tile in `ags/windows/quick-settings/modules/bluetooth-tile.tsx` SHALL provide a toggleable tile for Bluetooth adapter power with connected device info and drill-down arrow.

#### Scenario: Toggle Bluetooth on via tile icon
- **GIVEN** Bluetooth adapter is powered off
- **WHEN** the user clicks the Bluetooth tile icon area
- **THEN** the system SHALL set the adapter powered state to on

#### Scenario: Toggle Bluetooth off via tile icon
- **GIVEN** Bluetooth adapter is powered on
- **WHEN** the user clicks the Bluetooth tile icon area
- **THEN** the system SHALL set the adapter powered state to off

#### Scenario: Show connected device name in tile
- **GIVEN** a Bluetooth device is connected
- **WHEN** the tile is rendered
- **THEN** the tile title SHALL display the connected device alias and the description SHALL show battery percentage if available

#### Scenario: Show default title when no device connected
- **GIVEN** no Bluetooth device is connected
- **WHEN** the tile is rendered
- **THEN** the tile title SHALL display "Bluetooth"

#### Scenario: Tile icon reflects connection state
- **GIVEN** the Bluetooth tile is rendered
- **WHEN** adapter power or connection state changes
- **THEN** the icon SHALL update: bluetooth-active when connected, bluetooth when powered but disconnected, bluetooth-disabled when powered off

#### Scenario: Tile hidden when Bluetooth unavailable
- **GIVEN** no Bluetooth adapter is available on the system
- **WHEN** the tiles grid is rendered
- **THEN** the Bluetooth tile SHALL be hidden

#### Scenario: Open Bluetooth page from tile
- **GIVEN** the Bluetooth tile is visible
- **WHEN** the user clicks the content area or arrow
- **THEN** the Bluetooth detail page SHALL open in the tiles Pages zone

### Requirement: Bluetooth detail page
The Bluetooth page in `ags/windows/quick-settings/modules/bluetooth-page.tsx` SHALL list known and discovered devices with connect, disconnect, and forget actions.

#### Scenario: Show known devices
- **GIVEN** the Bluetooth page is open
- **WHEN** paired or trusted devices exist
- **THEN** a "Devices" section SHALL list them with device alias, icon, and battery info when connected

#### Scenario: Show discovered devices
- **GIVEN** the Bluetooth page is open and adapter is discovering
- **WHEN** new unpaired devices are found
- **THEN** a "New Devices" section SHALL list them

#### Scenario: Connect a paired disconnected device
- **GIVEN** a paired Bluetooth device is disconnected
- **WHEN** the user clicks the device entry
- **THEN** the system SHALL pair (if needed) and connect the device, showing a spinner while connecting

#### Scenario: Disconnect a connected device
- **GIVEN** a Bluetooth device is connected
- **WHEN** the user clicks the disconnect button for that device
- **THEN** the system SHALL disconnect the device

#### Scenario: Forget a device
- **GIVEN** a device is paired/trusted and listed
- **WHEN** the user clicks the forget/remove button
- **THEN** the system SHALL remove the device from the adapter

#### Scenario: Start/stop discovery from page header
- **GIVEN** the Bluetooth page is open
- **WHEN** the user clicks the discovery header button
- **THEN** the system SHALL start discovery if not discovering, or stop discovery if already discovering

#### Scenario: Stop discovery when page closes
- **GIVEN** the Bluetooth page is open and discovery is active
- **WHEN** the page is closed
- **THEN** discovery SHALL be stopped

#### Scenario: More settings bottom button
- **GIVEN** the Bluetooth page is open
- **WHEN** the user clicks "More Settings"
- **THEN** the system SHALL close the control center and launch an external Bluetooth settings app
