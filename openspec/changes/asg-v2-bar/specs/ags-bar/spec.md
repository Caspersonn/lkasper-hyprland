## MODIFIED Requirements

### Requirement: Bar uses three-island layout
The bar SHALL render three separate rounded-rectangle containers ("islands") within the transparent bar window, positioned with a `<centerbox>` and visible gaps between them:
- **Left island**: app launcher button | workspaces | active-window widget
- **Center island**: clock face
- **Right island**: media widget | weather | system stats | system tray | quick-controls cluster | notifications bell | power button

Sections within an island SHALL be separated by 1px vertical dividers. The individual section widgets are specified by their own capabilities (`ags-active-window`, `ags-media`, `ags-weather`, `ags-system-stats`, `ags-control-center`, `ags-power-menu`, `ags-calendar`).

#### Scenario: Three separate islands visible
- **WHEN** the bar is rendered
- **THEN** three distinct rounded-rectangle islands are visible with gaps between them

#### Scenario: Island composition
- **WHEN** the bar is rendered
- **THEN** the left island shows the launcher, workspaces, and active-window; the center shows the clock; the right shows media, weather, system stats, tray, quick-controls, the notifications bell, and the power button

### Requirement: Island styling
Each island SHALL have:
- A rounded-rectangle shape (border-radius ~14px, not a full capsule)
- A translucent dark fill derived from a `$base-dark` base16 variable (no hardcoded colour literals)
- A 1px border and a drop shadow
- No backdrop blur (not expressible in GTK4); the translucent fill plus border and shadow stand in for the design's frosted glass

Interactive sections SHALL show a subtle hover background.

#### Scenario: Island appearance
- **WHEN** the bar is rendered over a wallpaper
- **THEN** the islands are translucent dark rounded rectangles with a border and shadow, with wallpaper visible in the gaps

#### Scenario: Hover feedback
- **WHEN** the pointer is over an interactive section
- **THEN** that section shows a subtle hover background

### Requirement: Workspaces module (left island)
The workspaces module SHALL use `astal-hyprland` to render the currently existing workspaces only (not a fixed 1..10 set), each as a pill-shaped cell containing the workspace's representative app icon (current themed-icon approach) and its id number, with a centered underline (~62% width, ~2px) coloured by the monitor the workspace is bound to:
- **Focused** workspace: monitor-tinted background + monitor-coloured number + a glowing underline
- **Occupied** workspace (exists, not focused): faint background + dimmer underline
- **Empty/absent** workspace: dim number, no underline
- **Left-click** a workspace SHALL switch to it

The right-click screen picker is not part of this module.

#### Scenario: Only existing workspaces shown
- **WHEN** workspaces 1, 2 and 5 exist
- **THEN** only 1, 2 and 5 are rendered (no fixed 3,4,6..10 cells)

#### Scenario: Focused/occupied/empty styling
- **WHEN** workspace 2 is focused and workspace 5 is occupied
- **THEN** 2 shows the monitor-tinted background, monitor-coloured number, and glowing underline, while 5 shows a faint background and dimmer underline

#### Scenario: Left-click switches workspace
- **WHEN** the user left-clicks a workspace
- **THEN** Hyprland switches to that workspace

### Requirement: Clock face (center island)
The center island SHALL show a clock face composed of a calendar glyph, the current time, a 1px divider, and the current date. Clicking the clock SHALL open the calendar popover (specified by `ags-calendar`).

#### Scenario: Clock shows time and date
- **WHEN** it is Monday 25 June, 14:32
- **THEN** the clock shows the calendar glyph, "14:32", a divider, and the date

#### Scenario: Clock opens the calendar
- **WHEN** the user clicks the clock
- **THEN** the calendar popover opens

### Requirement: System tray module (right island)
The system tray SHALL use `astal-tray` to display tray items as a row of monochrome glyphs within the right island; hovering an item SHALL tint it with the accent colour.

#### Scenario: Tray items visible
- **WHEN** applications register tray items
- **THEN** their icons appear in the tray section of the right island

#### Scenario: Hover tint
- **WHEN** the pointer hovers a tray item
- **THEN** that item is tinted with the accent colour

### Requirement: Island dividers
Sections within an island SHALL be separated by subtle 1px vertical dividers at low opacity (no hardcoded colour literals). The previous right-pill left-border separator scheme is replaced by these dividers.

#### Scenario: Dividers between sections
- **WHEN** an island with multiple sections is rendered
- **THEN** thin vertical dividers separate the sections

## ADDED Requirements

### Requirement: App launcher button
The left island SHALL begin with an app launcher button showing the NixOS glyph. Clicking it SHALL `exec` `walker` (matching the `SUPER, SPACE` Hyprland keybind).

#### Scenario: Launch the app launcher
- **WHEN** the user clicks the launcher button
- **THEN** `walker` is launched

### Requirement: Quick-controls cluster (right island)
The right island SHALL include a quick-controls cluster of status glyphs — brightness, volume, Wi-Fi, Bluetooth — plus a battery icon and percentage. The battery icon and colour SHALL reflect charge level and charging state, and the volume glyph SHALL reflect level/mute. Clicking the cluster SHALL open the control-center popover (specified by `ags-control-center`).

#### Scenario: Cluster opens the control center
- **WHEN** the user clicks the quick-controls cluster
- **THEN** the control-center popover opens

#### Scenario: Battery indication
- **WHEN** the battery is at 65% and discharging
- **THEN** the cluster shows a battery icon for that level and "65%"

#### Scenario: Volume glyph reflects state
- **WHEN** audio is muted
- **THEN** the cluster shows a muted volume glyph

## REMOVED Requirements

### Requirement: Bar uses split-pill layout
**Reason**: Replaced by the three-island layout.
**Migration**: See "Bar uses three-island layout".

### Requirement: Pill capsule styling
**Reason**: Replaced by island styling (rounded rectangles, not capsules).
**Migration**: See "Island styling".

### Requirement: Workspace screen picker
**Reason**: Dropped per design decision; right-click screen picker removed.
**Migration**: None; workspaces are left-click only.

### Requirement: Media module (center pill)
**Reason**: Media moves to the right island with its own player popover.
**Migration**: See the `ags-media` capability.

### Requirement: CPU module (right pill)
**Reason**: CPU usage is now part of the system stats cluster (with RAM and temperature).
**Migration**: See the `ags-system-stats` capability.

### Requirement: Battery module (right pill)
**Reason**: Battery indication folds into the quick-controls cluster.
**Migration**: See "Quick-controls cluster (right island)".

### Requirement: WiFi module (right pill)
**Reason**: Wi-Fi indication folds into the quick-controls cluster; full control lives in the control center.
**Migration**: See "Quick-controls cluster (right island)" and the `ags-control-center` capability.

### Requirement: Bluetooth module (right pill)
**Reason**: Bluetooth indication folds into the quick-controls cluster; full control lives in the control center.
**Migration**: See "Quick-controls cluster (right island)" and the `ags-control-center` capability.

### Requirement: Volume module (right pill)
**Reason**: Volume indication folds into the quick-controls cluster; the volume slider lives in the control center.
**Migration**: See "Quick-controls cluster (right island)" and the `ags-control-center` capability.

### Requirement: Notification bell placeholder (right pill)
**Reason**: The bell is now a functional control opening the notifications popover.
**Migration**: See the `notification-center` capability.

### Requirement: Right pill separators
**Reason**: Replaced by island dividers.
**Migration**: See "Island dividers".
