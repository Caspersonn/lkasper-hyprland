# ags-bar-monitors Specification

## Purpose
TBD - created by archiving change ags-monitor-hotplug. Update Purpose after archive.
## Requirements
### Requirement: Bar on every monitor present at launch
The ags shell (`ags/app.ts`) SHALL create one bar window for each monitor reported by `App.get_monitors()` at startup, so the initial display set is fully covered without a restart.

#### Scenario: Single monitor at launch
- **GIVEN** exactly one monitor is connected when ags starts
- **WHEN** `App.start` runs `main()`
- **THEN** exactly one bar window is created and shown on that monitor

#### Scenario: Multiple monitors at launch
- **GIVEN** two or more monitors are connected when ags starts
- **WHEN** `App.start` runs `main()`
- **THEN** one bar window is created and shown on each connected monitor

### Requirement: Bar created on monitor hot-plug
The shell SHALL subscribe to monitor-added events for the lifetime of the process and create a bar for any monitor connected after startup, without requiring an ags restart.

#### Scenario: Monitor connected after startup
- **GIVEN** ags is already running with bars on the current monitors
- **WHEN** an additional monitor is connected
- **THEN** a new bar window is created and shown on the newly connected monitor

#### Scenario: Add is idempotent
- **GIVEN** a monitor already has a bar tracked by the shell
- **WHEN** an add event reports that same monitor again
- **THEN** no second bar is created for that monitor

### Requirement: Bar destroyed on monitor removal
The shell SHALL subscribe to monitor-removed events and destroy the bar associated with a disconnected monitor, leaving no orphaned or leaked windows.

#### Scenario: Monitor disconnected
- **GIVEN** ags is running with a bar on a monitor that is tracked in the per-monitor bar map
- **WHEN** that monitor is disconnected
- **THEN** the bar window for that monitor is destroyed and removed from the tracking map
- **AND** bars on the remaining monitors are unaffected

### Requirement: Unique window name per monitor with shared namespace
Each bar window (`ags/windows/bar/index.tsx`) SHALL be assigned a window `name` unique to its monitor (derived from the monitor connector, e.g. `bar-DP-1`, with a fallback identifier when the connector is unavailable) while keeping a shared `namespace` of `bar` so Hyprland layer rules apply uniformly to all bars.

#### Scenario: Names are distinct across monitors
- **GIVEN** two or more monitors each have a bar
- **WHEN** the windows are registered with `App`
- **THEN** every bar window has a distinct `name`
- **AND** every bar window shares the `namespace` value `bar`

#### Scenario: Connector unavailable
- **GIVEN** a monitor whose connector property is null
- **WHEN** its bar is created
- **THEN** the bar is assigned a unique fallback `name` and is still created successfully

### Requirement: Toggle keybind works for any monitor count
The bar-toggle keybind (`SUPER SHIFT, SPACE` in `modules/home-manager/_hyprland/bindings.nix`) SHALL toggle the visibility of all bars regardless of the number of connected monitors, replacing the previous single-name `ags toggle bar` lookup.

#### Scenario: Toggle with multiple monitors
- **GIVEN** bars exist on two or more monitors
- **WHEN** the user presses `SUPER SHIFT, SPACE`
- **THEN** the visibility of every bar is toggled together

#### Scenario: Toggle with one monitor
- **GIVEN** a bar exists on a single monitor
- **WHEN** the user presses `SUPER SHIFT, SPACE`
- **THEN** that bar's visibility is toggled

