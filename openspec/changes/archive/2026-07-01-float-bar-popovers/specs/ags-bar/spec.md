## ADDED Requirements

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
