## MODIFIED Requirements

### Requirement: Notifications popover
The AGS shell SHALL provide notifications as a `Gtk.Popover` anchored to the bar's notification bell, rather than a right-edge layer-shell window. The popover SHALL auto-dismiss on outside click (native `Gtk.Popover` behaviour). It is a module under `ags/windows/bar/`/`ags/windows/notifications/`.

#### Scenario: Opening the popover
- **GIVEN** the popover is closed
- **WHEN** the bell is clicked
- **THEN** the notifications popover opens anchored to the bell

#### Scenario: Closing leaves no residual region
- **GIVEN** the popover is open
- **WHEN** the user clicks outside it
- **THEN** the popover closes and intercepts no further clicks

### Requirement: Toggle via bell, keybind, and IPC
The notifications popover SHALL be toggled by clicking the bar bell and by the `ags request toggle-notifications` IPC request handled in `ags/app.ts` (e.g. from the `SUPER, N` keybind). Outside-click dismissal is handled natively by the popover.

#### Scenario: Bell toggles the popover
- **WHEN** the user clicks the bar notification bell
- **THEN** the popover opens, or closes if already open

#### Scenario: Keybind/IPC toggles the popover
- **WHEN** `ags request toggle-notifications` is invoked
- **THEN** the popover's visibility toggles

### Requirement: Notification history list
The popover SHALL render the daemon's `notifications` list reactively. Each item SHALL show its app icon, title/summary, body, and a relative time, with a Clear-all action in the header and a per-item dismiss control. When the list is empty the popover SHALL show an explicit "all caught up" empty state.

#### Scenario: History reflects the daemon list
- **GIVEN** notifications exist in the daemon's list
- **WHEN** the popover is open
- **THEN** they are shown as cards and the list updates as notifications are added or dismissed

#### Scenario: Clear all
- **GIVEN** the list is non-empty
- **WHEN** the user activates Clear all
- **THEN** every notification is dismissed and the list becomes empty

#### Scenario: Empty state
- **GIVEN** there are no notifications
- **WHEN** the popover is open
- **THEN** it shows the "all caught up" empty state

## REMOVED Requirements

### Requirement: Do Not Disturb toggle
**Reason**: DND control moves to the control center's Night-Light/DND toggle grid; the same `AstalNotifd` `dontDisturb` state and `ags request toggle-dnd` IPC remain.
**Migration**: See the `ags-control-center` capability.

### Requirement: MPRIS now-playing widget
**Reason**: Now-playing media moves to the dedicated media widget and player popover.
**Migration**: See the `ags-media` capability.

### Requirement: Separate from QuickSettings
**Reason**: QuickSettings is removed entirely; the constraint is obsolete.
**Migration**: None; control functions live in the control-center popover.
