## ADDED Requirements

### Requirement: Volume slider control
The audio section in `ags/windows/quick-settings/volume.tsx` SHALL expose a volume slider bound to the current default speaker endpoint from `astal-wireplumber`.

#### Scenario: Increase or decrease output volume
- **GIVEN** an active default speaker endpoint exists
- **WHEN** the user drags the volume slider
- **THEN** the system SHALL update output volume to the slider value

#### Scenario: Reflect external volume changes
- **GIVEN** volume is changed by another source (hotkey or app)
- **WHEN** the panel is open
- **THEN** the slider position SHALL update to reflect the current endpoint volume

### Requirement: Output device selector
The audio section SHALL provide an output selector listing available speaker endpoints and allow switching default output.

#### Scenario: Show available output devices
- **GIVEN** wireplumber reports one or more speaker endpoints
- **WHEN** the output selector is opened
- **THEN** the selector SHALL list available endpoints with a clear current default indication

#### Scenario: Switch default output device
- **GIVEN** at least two speaker endpoints are available
- **WHEN** the user selects a non-default endpoint
- **THEN** the system SHALL set that endpoint as default output
