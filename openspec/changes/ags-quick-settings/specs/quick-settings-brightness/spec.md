## ADDED Requirements

### Requirement: Brightness slider in quick-settings panel
The quick-settings panel SHALL include a brightness slider below the audio section, implemented in `ags/windows/quick-settings/brightness.tsx` using a brightness backend service.

#### Scenario: Adjust brightness from panel
- **GIVEN** a supported backlight device is available
- **WHEN** the user drags the brightness slider
- **THEN** the system SHALL write the corresponding brightness level to the active backlight backend

#### Scenario: Reflect current brightness in slider value
- **GIVEN** current brightness is changed externally
- **WHEN** the panel is open
- **THEN** the slider SHALL update to reflect the current brightness level

### Requirement: Graceful behavior when brightness backend is unavailable
If no supported brightness backend is found, the panel SHALL degrade gracefully without breaking other quick-settings sections.

#### Scenario: Hide or disable brightness controls on unsupported hardware
- **GIVEN** no writable backlight device is detected
- **WHEN** the quick-settings panel renders
- **THEN** the panel SHALL either hide the brightness section or show it disabled with a clear unavailable state

### Requirement: Brightness runtime dependency
Home-manager AGS module configuration in `modules/home-manager/ags.nix` SHALL include a backend command dependency suitable for brightness writes.

#### Scenario: Provide brightness command at runtime
- **GIVEN** the AGS shell is built and launched
- **WHEN** brightness write operations are requested by the brightness service
- **THEN** the required command-line backend SHALL be available in runtime PATH
