## ADDED Requirements

### Requirement: Control center popover
The right-island quick-controls cluster SHALL open a control-center `Gtk.Popover` containing, in order: a 2×2 toggle grid (Wi-Fi, Bluetooth, Do Not Disturb, Night Light), a volume slider, a brightness slider, and a power-profile segmented control. Tiles in the "on" state SHALL use an accent-tinted style and tiles in the "off" state a muted surface style. The popover SHALL auto-dismiss on outside click. This popover supersedes the former QuickSettings panel.

#### Scenario: Open from the quick-controls cluster
- **WHEN** the user clicks the quick-controls cluster
- **THEN** the control-center popover opens showing the toggle grid, sliders, and power-profile control

#### Scenario: Tile on/off styling
- **WHEN** a toggle is on
- **THEN** its tile shows the accent-tinted style
- **AND** when off it shows the muted surface style

### Requirement: Connectivity and mode toggles
The toggle grid SHALL bind: Wi-Fi to `AstalNetwork`, Bluetooth to `AstalBluetooth`, Do Not Disturb to `AstalNotifd` `dontDisturb` (the same state flipped by `ags request toggle-dnd`), and Night Light to a `hyprsunset` toggle via `exec`. Each tile SHALL reflect current state and flip it on activation, showing a sub-label (e.g. SSID or device) where applicable.

#### Scenario: Toggle Wi-Fi
- **WHEN** the user activates the Wi-Fi tile
- **THEN** Wi-Fi is enabled or disabled and the tile reflects the new state

#### Scenario: Toggle Bluetooth
- **WHEN** the user activates the Bluetooth tile
- **THEN** the Bluetooth adapter powers on or off and the tile reflects it

#### Scenario: Toggle Do Not Disturb
- **WHEN** the user activates the DND tile
- **THEN** `dontDisturb` flips, consistent with `ags request toggle-dnd`

#### Scenario: Toggle Night Light
- **WHEN** the user activates the Night Light tile
- **THEN** `hyprsunset` is toggled and the tile reflects the new state

### Requirement: Volume and brightness sliders
The control center SHALL provide a volume slider bound to the default `AstalWp` sink and a brightness slider backed by `brightnessctl` (`get`/`set`/`max`). Dragging a slider SHALL apply the new level live.

#### Scenario: Adjust volume
- **WHEN** the user drags the volume slider
- **THEN** the default sink volume changes to match

#### Scenario: Adjust brightness
- **WHEN** the user drags the brightness slider
- **THEN** `brightnessctl set` applies the new brightness level

### Requirement: Power-profile segmented control
The control center SHALL provide a three-segment control (Saver / Balanced / Turbo) backed by `powerprofilesctl`, mapping to the daemon profiles power-saver / balanced / performance. The active segment SHALL reflect the current profile and selecting a segment SHALL set it.

#### Scenario: Reflect active profile
- **WHEN** the control center opens
- **THEN** the segment matching the current `powerprofilesctl` profile is shown active

#### Scenario: Set a profile
- **WHEN** the user selects Turbo
- **THEN** `powerprofilesctl set performance` is run and the segment becomes active
