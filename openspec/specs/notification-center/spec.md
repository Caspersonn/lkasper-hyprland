# notification-center Specification

## Purpose
Defines the AGS notification history popover, notification bell behavior, and IPC integration.

## Requirements
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

### Requirement: Restored notifications are read-only for actions
Notifications restored from the on-disk cache at startup SHALL NOT render action buttons (their sender is no longer present to receive an invocation), while notifications received during the current session SHALL render their actions.

#### Scenario: Restored notification has no actions
- **GIVEN** a notification was restored from the cache on startup
- **WHEN** it is shown in the history
- **THEN** no action buttons are rendered for it

#### Scenario: Session notification keeps actions
- **GIVEN** a notification with actions arrives during the session
- **WHEN** it is shown in the history
- **THEN** its action buttons are rendered and invoke the notification's actions

### Requirement: Bar bell reflects notification state
The bar bell (`ags/windows/bar/notifications.tsx`) SHALL be a button that toggles the notifications popover and shows an unread count when the history is non-empty.

#### Scenario: Unread count
- **GIVEN** the history contains notifications
- **WHEN** the bar is shown
- **THEN** the bell displays the notification count
