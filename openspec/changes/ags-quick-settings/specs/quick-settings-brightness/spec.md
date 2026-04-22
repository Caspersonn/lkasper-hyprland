## ADDED Requirements

### Requirement: Brightness slider
The sliders component in `ags/windows/quick-settings/sliders.tsx` SHALL include a brightness slider row with button, slider bound to the default backlight device, and a "more" button opening the Brightness detail page. The entire brightness row SHALL be hidden when no backlight is available.

#### Scenario: Adjust brightness from slider
- **GIVEN** a supported backlight device is available
- **WHEN** the user drags the brightness slider
- **THEN** the system SHALL write the corresponding brightness level to the active backlight backend

#### Scenario: Reflect current brightness
- **GIVEN** brightness is changed externally
- **WHEN** the control center is open
- **THEN** the slider SHALL update to reflect the current brightness level

#### Scenario: Set max brightness via button
- **GIVEN** the brightness slider row is rendered
- **WHEN** the user clicks the brightness button
- **THEN** the system SHALL set brightness to the maximum value

#### Scenario: Open Brightness page via more button
- **GIVEN** the brightness slider row is rendered
- **WHEN** the user clicks the "more" (go-next) button
- **THEN** the Brightness detail page SHALL open in the sliders Pages zone

#### Scenario: Hide brightness row when unsupported
- **GIVEN** no writable backlight device is detected
- **WHEN** the control center renders
- **THEN** the brightness slider row SHALL be hidden without affecting other sliders

### Requirement: Brightness detail page
The Brightness page in `ags/windows/quick-settings/modules/brightness-page.tsx` SHALL provide per-backlight device sliders and a default backlight selector when multiple backlights are available.

#### Scenario: Show per-backlight sliders
- **GIVEN** the Brightness page is open and one or more backlight devices exist
- **WHEN** the page is rendered
- **THEN** each backlight device SHALL have its own labeled slider with min/max range

#### Scenario: Select default backlight
- **GIVEN** the Brightness page is open and multiple backlight devices exist
- **WHEN** the user clicks a non-default backlight entry
- **THEN** the system SHALL set that backlight as the default used by the main brightness slider

#### Scenario: Hide device selector for single backlight
- **GIVEN** only one backlight device exists
- **WHEN** the Brightness page is rendered
- **THEN** the device selector section SHALL be hidden, showing only the slider

### Requirement: Brightness runtime dependency
Home-manager AGS module configuration in `modules/home-manager/ags.nix` SHALL include `brightnessctl` for brightness writes.

#### Scenario: Provide brightness command at runtime
- **GIVEN** the AGS shell is built and launched
- **WHEN** brightness write operations are requested
- **THEN** brightnessctl SHALL be available in runtime PATH
