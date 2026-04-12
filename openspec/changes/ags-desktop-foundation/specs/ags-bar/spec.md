## ADDED Requirements

### Requirement: Bar window properties
The bar SHALL be an `Astal.Window` with:
- `anchor`: TOP | LEFT | RIGHT (spans full width, docked to top)
- `exclusivity`: EXCLUSIVE (reserves screen space)
- `name`: "bar"
- Margins from screen edges (top, left, right) to create the floating appearance
- `namespace`: "bar" for Hyprland window rules

#### Scenario: Bar occupies top of screen
- **WHEN** the shell starts
- **THEN** a floating bar window appears at the top of the screen with margins on top, left, and right edges

### Requirement: Bar uses split-pill layout
The bar SHALL NOT use a single container. Instead, it SHALL render three separate capsule-shaped containers ("pills") within the bar window:
- **Left pill**: Workspaces
- **Center pill**: Clock + Media
- **Right pill**: System tray, Bluetooth, WiFi, Volume, CPU, Notification bell, Battery

The three pills are positioned using a `<centerbox>` with each pill as a child. There SHALL be visible gaps between the pills (they are separate visual containers, not one continuous bar).

Implementation note: Gnim JSX uses `class` for CSS class names. List rendering for workspace dots and tray icons SHALL use `<For>` to render items from Accessors. Scroll handling on the volume module SHALL use `Gtk.EventControllerScroll` (Gtk.Box has no `scroll` signal).

#### Scenario: Three separate pills visible
- **WHEN** the bar is rendered
- **THEN** three distinct capsule-shaped containers are visible with gaps between them

### Requirement: Pill capsule styling
Each pill SHALL have:
- Fully rounded capsule shape (border-radius equal to half the pill height)
- Solid opaque background using the theme's background color (no transparency, no blur)
- No visible border
- Consistent vertical padding within each pill

#### Scenario: Pill appearance
- **WHEN** the bar is rendered on a desktop with a wallpaper
- **THEN** the pills are solid-colored capsules floating above the wallpaper, with wallpaper visible in the gaps between pills

### Requirement: Workspaces module (left pill)
The workspaces module SHALL use `astal-hyprland` to display Hyprland workspaces as dots/circles:
- **Active** workspace: filled circle (solid dot)
- **Occupied** workspace (has windows, not active): outline circle (hollow dot)
- **Empty** workspace (no windows): hidden (not rendered)
- Clicking a dot SHALL switch to that workspace via `hyprland.dispatch("workspace", id)`

#### Scenario: Workspace dots reflect state
- **WHEN** workspace 3 is active and workspaces 1, 3, 5 have windows
- **THEN** workspace 3 shows as a filled dot, 1 and 5 show as outline dots, 2 and 4 are hidden

#### Scenario: Click switches workspace
- **WHEN** user clicks on a workspace dot
- **THEN** Hyprland switches to that workspace

### Requirement: Clock module (center pill)
The clock SHALL display the current time with a short day prefix, updated every second. Format: `"Mon HH:mm"` (three-letter day abbreviation + 24-hour time).

#### Scenario: Clock shows current time with day
- **WHEN** it is Monday at 14:32
- **THEN** the clock displays "Mon 14:32"

### Requirement: Media module (center pill)
The media module SHALL use `astal-mpris` to display the currently playing track in the center pill, next to the clock. It SHALL show:
- Track title and artist when media is playing (compact format: "Artist - Title")
- A separator between clock and media text
- Nothing (hidden) when no media is active — the center pill only shows the clock

#### Scenario: Media playing
- **WHEN** a media player (e.g. Spotify) is playing "Song Title" by "Artist Name"
- **THEN** the center pill displays "Mon 14:32  Artist Name - Song Title" (or separated by a visual divider)

#### Scenario: No media playing
- **WHEN** no MPRIS-compatible player is active
- **THEN** the center pill only shows the clock

### Requirement: Battery module (right pill)
The battery module SHALL use `astal-battery` to display:
- Battery percentage
- A battery icon reflecting charge level
- Charging indicator when plugged in

#### Scenario: Battery discharging
- **WHEN** battery is at 65% and discharging
- **THEN** the module shows a battery icon and "65%"

#### Scenario: Battery charging
- **WHEN** battery is charging
- **THEN** the module shows a charging icon variant

### Requirement: WiFi module (right pill)
The WiFi module SHALL use `astal-network` to display:
- A WiFi signal strength icon when connected
- A disconnected icon when not connected
- The SSID in a tooltip

#### Scenario: Connected to WiFi
- **WHEN** connected to network "HomeWiFi" with good signal
- **THEN** a strong signal icon is shown, tooltip displays "HomeWiFi"

#### Scenario: Disconnected
- **WHEN** no WiFi connection
- **THEN** a disconnected icon is shown

### Requirement: Bluetooth module (right pill)
The Bluetooth module SHALL use `astal-bluetooth` to display:
- A Bluetooth icon when the adapter is powered on
- A disabled icon when powered off
- Connected device count in tooltip

#### Scenario: Bluetooth on with connected device
- **WHEN** Bluetooth adapter is on and 1 device is connected
- **THEN** a Bluetooth connected icon is shown, tooltip shows "1 device connected"

### Requirement: Volume module (right pill)
The volume module SHALL use `astal-wireplumber` to display:
- A volume icon reflecting the current level (muted, low, medium, high)
- Scroll to adjust volume

#### Scenario: Volume at 50%
- **WHEN** default audio output is at 50%
- **THEN** a medium volume icon is shown

#### Scenario: Scroll adjusts volume
- **WHEN** user scrolls up on the volume module
- **THEN** volume increases by a step (5%)

#### Scenario: Muted
- **WHEN** audio is muted
- **THEN** a muted icon is shown

### Requirement: CPU module (right pill)
The CPU module SHALL display current CPU usage percentage, polled at a regular interval (every 2-5 seconds). It SHALL read from `/proc/stat` or use a polling command.

#### Scenario: CPU usage displayed
- **WHEN** CPU usage is 23%
- **THEN** the module displays "23%" (or "CPU 23%")

### Requirement: System tray module (right pill)
The system tray SHALL use `astal-tray` to display tray icons from running applications.

#### Scenario: Tray icons visible
- **WHEN** applications register system tray items
- **THEN** their icons appear in the tray section of the right pill

### Requirement: Notification bell placeholder (right pill)
The bar SHALL display a bell icon as a placeholder for the notification system. It SHALL be non-functional in Phase 1 (no click action, no counter). It establishes the visual position for Phase 5 (notification center sidebar).

#### Scenario: Bell icon visible
- **WHEN** the bar is rendered
- **THEN** a bell icon is visible in the right pill between CPU and battery

### Requirement: Right pill separators
Modules within the right pill SHALL have subtle visual separators between them. The separators SHALL be implemented as a left border (1px solid line at low opacity) with padding and margin, applied to all modules except the first one (system tray).

#### Scenario: Separators between right pill modules
- **WHEN** the right pill is rendered
- **THEN** thin vertical lines separate the individual status modules
