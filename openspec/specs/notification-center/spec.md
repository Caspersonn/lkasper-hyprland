# notification-center Specification

## Purpose
TBD - created by archiving change notifications-2-center. Update Purpose after archive.
## Requirements
### Requirement: Right-edge notification center

The AGS shell SHALL provide a notification center as a layer-shell window
anchored to the right edge spanning the full height, on the overlay layer,
without reserving space, shown and hidden by toggling the window's visibility
based on a toggle state. It is a standalone module under
`ags/windows/notifications/`, separate from QuickSettings.

#### Scenario: Opening the center
- **GIVEN** the center is closed
- **WHEN** it is toggled open
- **THEN** the panel appears at the right edge over the screen content
- **AND** it does not reserve screen space or shift other windows

#### Scenario: Closing the center leaves no residual region
- **GIVEN** the center is open
- **WHEN** it is toggled again
- **THEN** the window is hidden (unmapped)
- **AND** no part of the screen remains covered or intercepts clicks

### Requirement: Toggle via bell, keybind, and IPC

The center SHALL be toggled by clicking the bar bell, by a Hyprland keybind, and
by the `ags request toggle-notifications` IPC request handled in `ags/app.ts`.
While the center is open, clicking anywhere outside the panel SHALL close it.

#### Scenario: Bell toggles the center
- **WHEN** the user clicks the bar notification bell
- **THEN** the center opens, or closes if already open

#### Scenario: Keybind/IPC toggles the center
- **WHEN** `ags request toggle-notifications` is invoked (e.g. from the `SUPER, N` keybind)
- **THEN** the center's visibility toggles

#### Scenario: Clicking outside closes the center
- **GIVEN** the center is open
- **WHEN** the user clicks anywhere outside the panel
- **THEN** the center closes
- **AND** a click on the panel itself does not close it

### Requirement: Do Not Disturb toggle

The center header SHALL provide a Do Not Disturb toggle bound to
`AstalNotifd` `dontDisturb`, and `ags request toggle-dnd` SHALL flip the same
state.

#### Scenario: Toggling DND from the header
- **WHEN** the user activates the Do Not Disturb toggle in the center
- **THEN** `dontDisturb` flips
- **AND** subsequent notifications do not pop a toast while it is enabled (per the daemon behavior)

#### Scenario: Toggling DND via IPC
- **WHEN** `ags request toggle-dnd` is invoked
- **THEN** `dontDisturb` flips

### Requirement: Clear All

The center header SHALL provide a Clear All action that dismisses every
notification in the daemon's list.

#### Scenario: Clearing all notifications
- **GIVEN** the history contains notifications
- **WHEN** the user activates Clear All
- **THEN** every notification is dismissed (`dismiss()`)
- **AND** the history becomes empty

### Requirement: Notification history grouped by app

The center SHALL render the daemon's `notifications` list reactively, grouped by
app name, with groups ordered by their most-recent notification and items
newest-first within each group. Each item SHALL show its icon, summary, body,
and a relative time, with a per-item dismiss control. When the list is empty the
center SHALL show an explicit empty state.

#### Scenario: History reflects the daemon list
- **GIVEN** notifications exist in the daemon's list
- **WHEN** the center is open
- **THEN** they are shown grouped by app, newest first
- **AND** the list updates as notifications are added or dismissed

#### Scenario: Per-item dismiss
- **WHEN** the user dismisses a single history item
- **THEN** `notification.dismiss()` is called and the item is removed from the list

#### Scenario: Empty state
- **GIVEN** there are no notifications
- **WHEN** the center is open
- **THEN** it shows an empty-state message instead of a list

### Requirement: Restored notifications are read-only for actions

Notifications restored from the on-disk cache at startup SHALL NOT render action
buttons (their sender is no longer present to receive an invocation), while
notifications received during the current session SHALL render their actions.

#### Scenario: Restored notification has no actions
- **GIVEN** a notification was restored from the cache on startup
- **WHEN** it is shown in the history
- **THEN** no action buttons are rendered for it

#### Scenario: Session notification keeps actions
- **GIVEN** a notification with actions arrives during the session
- **WHEN** it is shown in the history
- **THEN** its action buttons are rendered and invoke the notification's actions

### Requirement: MPRIS now-playing widget

The center SHALL include a now-playing widget driven by `AstalMpris`, showing the
active player's title, artist, and icon with play/pause, next, and previous
controls, and SHALL be hidden when no player is active.

#### Scenario: Media controls
- **GIVEN** a media player is active
- **WHEN** the center is open
- **THEN** the now-playing widget shows the track and its play/pause, next, and previous controls work

#### Scenario: No player
- **GIVEN** no media player is active
- **WHEN** the center is open
- **THEN** the now-playing widget is hidden

### Requirement: Bar bell reflects state and toggles the center

The bar bell (`ags/windows/bar/notifications.tsx`) SHALL become a button that
toggles the center, indicates Do Not Disturb (a distinct icon while `dontDisturb`
is enabled), and shows an unread count when the history is non-empty.

#### Scenario: Unread count
- **GIVEN** the history contains notifications
- **WHEN** the bar is shown
- **THEN** the bell displays the notification count

#### Scenario: DND indicator
- **WHEN** `dontDisturb` is enabled
- **THEN** the bell shows a Do-Not-Disturb icon distinct from the normal bell

### Requirement: Separate from QuickSettings

The notification center SHALL be implemented as its own module and SHALL NOT
modify QuickSettings or duplicate its connectivity, power, or volume widgets.

#### Scenario: QuickSettings untouched
- **WHEN** this change is applied
- **THEN** `ags/windows/QuickSettings/` is unchanged
- **AND** the center contains no wifi/bluetooth/airplane/power/volume widgets

