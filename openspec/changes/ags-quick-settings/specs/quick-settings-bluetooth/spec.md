## ADDED Requirements

### Requirement: Bluetooth power toggle
The Bluetooth section in `ags/windows/quick-settings/bluetooth.tsx` SHALL provide a pill-switch that toggles adapter power through `astal-bluetooth`.

#### Scenario: Toggle Bluetooth on
- **GIVEN** Bluetooth is powered off
- **WHEN** the user turns on the Bluetooth pill switch
- **THEN** the system SHALL set the adapter powered state to on

#### Scenario: Toggle Bluetooth off
- **GIVEN** Bluetooth is powered on
- **WHEN** the user turns off the Bluetooth pill switch
- **THEN** the system SHALL set the adapter powered state to off

### Requirement: Collapsed Bluetooth summary
The Bluetooth section SHALL be collapsed by default and show a concise summary row (status plus current device name when connected).

#### Scenario: Show collapsed summary by default
- **GIVEN** the quick-settings panel has just opened
- **WHEN** Bluetooth section state is initialized
- **THEN** the section SHALL render collapsed with a header and chevron affordance

#### Scenario: Show connected device in collapsed state
- **GIVEN** at least one Bluetooth device is connected
- **WHEN** the section is collapsed
- **THEN** the header SHALL display the connected device name

### Requirement: Expanded Bluetooth device actions
When expanded, Bluetooth section SHALL list known devices from `astal-bluetooth` and expose Connect, Disconnect, and Forget actions where applicable.

#### Scenario: Connect a paired disconnected device
- **GIVEN** a paired trusted Bluetooth device is disconnected
- **WHEN** the user presses Connect for that device
- **THEN** the system SHALL invoke device connect behavior and update UI state while connecting

#### Scenario: Disconnect a connected device
- **GIVEN** a Bluetooth device is connected
- **WHEN** the user presses Disconnect for that device
- **THEN** the system SHALL invoke device disconnect behavior and reflect disconnected status

#### Scenario: Forget a device
- **GIVEN** a device is paired and listed
- **WHEN** the user presses Forget for that device
- **THEN** the system SHALL remove the device from adapter known devices and remove it from the section list
