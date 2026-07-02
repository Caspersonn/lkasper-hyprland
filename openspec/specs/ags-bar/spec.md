# ags-bar Specification

## Purpose
Defines the AGS top bar layout, island styling, workspace behavior, and top-level bar module composition.
## Requirements
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

### Requirement: Bar uses three-island layout
The bar SHALL render three separate rounded-rectangle containers ("islands") within the transparent bar window, positioned with a `<centerbox>` and visible gaps between them:
- **Left island**: app launcher button | workspaces | active-window widget
- **Center island**: clock face
- **Right island**: media widget | weather | system stats | system tray | quick-controls cluster | notifications bell | power button

Sections within an island SHALL be separated by 1px vertical dividers. The individual section widgets are specified by their own capabilities (`ags-active-window`, `ags-media`, `ags-weather`, `ags-system-stats`, `ags-control-center`, `ags-power-menu`, `ags-calendar`).

Implementation note: Gnim JSX uses `class` for CSS class names. List rendering for workspace dots and tray icons SHALL use `<For>` to render items from Accessors.

#### Scenario: Three separate islands visible
- **WHEN** the bar is rendered
- **THEN** three distinct rounded-rectangle islands are visible with gaps between them

#### Scenario: Island composition
- **WHEN** the bar is rendered
- **THEN** the left island shows the launcher, workspaces, and active-window; the center shows the clock; the right shows media, weather, system stats, tray, quick-controls, the notifications bell, and the power button

### Requirement: Island styling
Each island SHALL have:
- A rounded-rectangle shape (border-radius ~14px, not a full capsule)
- A solid (opaque) dark fill derived from a `$base-dark` base16 variable (no hardcoded colour literals, no translucency)
- A 1px border
- No drop shadow
- No backdrop blur (not expressible in GTK4)

Interactive sections SHALL show a subtle hover background.

#### Scenario: Island appearance
- **WHEN** the bar is rendered over a wallpaper
- **THEN** the islands are solid dark rounded rectangles with a border and no drop shadow, and the wallpaper is not visible through the islands (only in the gaps between them)

#### Scenario: Hover feedback
- **WHEN** the pointer is over an interactive section
- **THEN** that section shows a subtle hover background

### Requirement: Workspaces module (left island)
The workspaces module SHALL use `astal-hyprland` to render the currently existing workspaces only (not a fixed 1..10 set), each as a pill-shaped cell containing app icons for the windows on the workspace (one icon per client window, capped, using the current themed-icon approach) and its id number, with a centered underline coloured by the monitor the workspace is bound to:
- **Focused** workspace: monitor-tinted background + monitor-coloured number + a glowing underline
- **Occupied** workspace (exists, not focused): faint background + dimmer underline
- **Empty/absent** workspace: dim number, no underline
- **Left-click** a workspace SHALL switch to it

The underline width SHALL scale with the number of clients (apps) on the workspace: a base width for a single client, growing by a fixed increment per additional client, clamped to a maximum so the underline never overflows the cell. The cell's icon row SHALL show one icon per client window (not deduplicated by app class), capped, so that the icon row and the underline both reflect the same window count — opening the same app twice adds both a second icon and underline width. The underline height, radius, and monitor-accent colour are unaffected by the client count. The right-click screen picker is not part of this module.

#### Scenario: Only existing workspaces shown
- **WHEN** workspaces 1, 2 and 5 exist
- **THEN** only 1, 2 and 5 are rendered (no fixed 3,4,6..10 cells)

#### Scenario: Focused/occupied/empty styling
- **WHEN** workspace 2 is focused and workspace 5 is occupied
- **THEN** 2 shows the monitor-tinted background, monitor-coloured number, and glowing underline, while 5 shows a faint background and dimmer underline

#### Scenario: Underline grows with app count
- **WHEN** a workspace has one client
- **THEN** its underline is drawn at the base width
- **AND WHEN** more clients are opened on that workspace
- **THEN** its underline widens by a fixed increment per additional client
- **AND** the underline width is clamped to a maximum so it never overflows the cell

#### Scenario: Icons track window count
- **WHEN** two windows of the same application are open on a workspace
- **THEN** the cell shows two icons (one per window, up to the icon cap), not a single deduplicated icon
- **AND** the underline reflects the same window count

#### Scenario: Left-click switches workspace
- **WHEN** the user left-clicks a workspace
- **THEN** Hyprland switches to that workspace

### Requirement: Workspace monitor accent colours
Each workspace underline colour SHALL be derived from the base16 palette and SHALL NOT be hardcoded: the bound monitor's name is deterministically hashed into a fixed pool of base16 accent slots (defined in `ags/style.scss`), so a given monitor maps to the same accent across reloads.

#### Scenario: Stable, shared colour per monitor
- **WHEN** two workspaces are bound to the same monitor
- **THEN** both underlines use the same base16 accent
- **AND** that accent is unchanged after a shell restart

#### Scenario: Different monitors get different accents
- **WHEN** workspaces are spread across different monitors
- **THEN** workspaces on different monitors use different base16 accent slots (up to the pool size)

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

### Requirement: Popover float gap

Bar popovers SHALL float a consistent, measured vertical gap below the bar rather than anchoring flush to their trigger button, and SHALL NOT carry a drop shadow.

The gap SHALL be applied once via `margin-top` on the shared `.popover-wrap > contents` rule in `ags/style.scss`, so it reaches all bar popovers (calendar, media, weather, control center, notifications, power) — every one of which builds its `Gtk.Popover` with `set_has_arrow(false)` and `add_css_class("popover-wrap")`.

#### Scenario: Popover floats below the bar

- **Given** a bar popover (e.g. calendar, weather, control center) is closed
- **When** its trigger button in the bar is clicked
- **Then** the popover appears with a consistent vertical gap between the bar and the popover card
- **And** the popover card reads as a distinct floating surface, not glued to the bar

#### Scenario: Popovers share one gap value

- **Given** the gap is defined via `margin-top` on `.popover-wrap > contents`
- **When** any of the six bar popovers opens
- **Then** each floats with the same vertical gap below the bar

#### Scenario: Popovers carry no drop shadow

- **Given** any bar popover is open
- **Then** `.popover-wrap > contents` retains `box-shadow: none`
- **And** the floating read is provided by the gap and the solid `$base-dark` card, not by elevation

