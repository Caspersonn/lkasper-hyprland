# notification-daemon Specification

## Purpose
The AGS shell is the system notification daemon (AstalNotifd, replacing mako): it
receives notifications, shows transient popup toasts honoring urgency, timeouts,
actions, and Do Not Disturb, and relies on AstalNotifd's on-disk cache for
persisted history.
## Requirements
### Requirement: AGS shell is the notification daemon

The AGS shell SHALL act as the `org.freedesktop.Notifications` daemon by
initializing `AstalNotifd.get_default()` during `app.ts` `main()`, and `notifd`
SHALL be present in `astalLibs` in `modules/home-manager/ags.nix`.

#### Scenario: Daemon acquires the bus name
- **GIVEN** mako is not running
- **WHEN** the AGS shell starts
- **THEN** it owns the `org.freedesktop.Notifications` D-Bus name
- **AND** notifications emitted by applications are received by the shell

#### Scenario: notifd is a build input
- **WHEN** `lkasper-shell` is built
- **THEN** `notifd` is included in `astalLibs` so `AstalNotifd` is available

### Requirement: mako is retired

The configuration SHALL NOT install or start mako. The mako module
(`modules/home-manager/mako.nix`, `homeManagerModules.lkh-mako`), its
`exec-once` entry in `modules/home-manager/_hyprland/autostart.nix`, and its
`runtime.conf` block in `modules/home-manager/themes.nix` SHALL be removed.

#### Scenario: No mako in autostart
- **WHEN** the Hyprland configuration is generated
- **THEN** no `exec-once` entry references `mako`

#### Scenario: No mako module
- **WHEN** the flake is evaluated
- **THEN** `homeManagerModules.lkh-mako` no longer exists
- **AND** no mako `runtime.conf` is written by `themes.nix`

### Requirement: Popup toasts on new notifications

The shell SHALL display a popup toast on the focused monitor when a new
notification arrives (the `AstalNotifd` `notified` signal), anchored top-right
on the overlay layer without reserving space or grabbing keyboard focus. The
toast SHALL show the summary, body, and the notification's `image` when present
(otherwise its `appIcon`).

#### Scenario: New notification pops a toast
- **GIVEN** the AGS shell is the daemon and Do Not Disturb is off
- **WHEN** an application emits a notification
- **THEN** a toast appears on the focused monitor showing its summary and body

#### Scenario: Toast does not disturb layout or focus
- **WHEN** a toast is visible
- **THEN** it floats above windows without shifting them
- **AND** keyboard input continues to reach the focused application

### Requirement: Urgency-aware popup timeout

A toast SHALL hide after a timeout for `LOW` and `NORMAL` urgency (honoring the
notification's expire timeout when provided, otherwise a default of about 5
seconds), while a `CRITICAL` toast SHALL remain visible until hidden by the user
or closed by the sender. A timeout SHALL only remove the **popup**; the
notification itself SHALL remain in the daemon's list (the center's history) and
is removed only by an explicit dismiss (a close button or Clear All).

#### Scenario: Normal notification's toast hides but persists in history
- **GIVEN** a `NORMAL` urgency toast is shown
- **WHEN** the timeout elapses with no interaction
- **THEN** the toast is hidden
- **AND** the notification still appears in the daemon's `notifications` list (the center)

#### Scenario: Critical notification stays on screen
- **GIVEN** a `CRITICAL` urgency toast is shown
- **WHEN** time passes with no interaction
- **THEN** the toast remains visible

#### Scenario: Explicit dismiss removes from history
- **GIVEN** a notification is in the list (its toast shown or already timed out)
- **WHEN** the user dismisses it (a close button or Clear All)
- **THEN** `notification.dismiss()` is called and it is removed from the daemon's list

### Requirement: Maximum visible toasts

The shell SHALL show at most a fixed number of concurrent toasts (about 5,
matching the prior mako configuration); notifications beyond that SHALL NOT pop
but SHALL still be recorded in the daemon's notification list.

#### Scenario: Overflow is not popped but is recorded
- **GIVEN** the maximum number of toasts are already visible
- **WHEN** another notification arrives
- **THEN** no additional toast is shown
- **AND** the notification is present in the daemon's `notifications` list

### Requirement: Do Not Disturb suppresses toasts

When `AstalNotifd` `dontDisturb` is enabled, the shell SHALL NOT show a toast for
incoming notifications, but SHALL still record them in the notification list.

#### Scenario: DND on, no toast
- **GIVEN** `dontDisturb` is enabled
- **WHEN** an application emits a notification
- **THEN** no toast appears
- **AND** the notification is recorded in the daemon's `notifications` list

### Requirement: Notification actions

A toast SHALL render the notification's actions as buttons and invoke the
corresponding action (`notification.invoke`) when clicked, and dismissing a
toast SHALL call `notification.dismiss()`.

#### Scenario: Invoking an action
- **GIVEN** a toast for a notification that declares actions
- **WHEN** the user clicks an action button
- **THEN** that action is invoked on the notification

#### Scenario: Dismissing a toast
- **WHEN** the user dismisses a toast
- **THEN** `notification.dismiss()` is called and the toast is removed

### Requirement: Persisted history is preserved without replaying popups

The shell SHALL rely on AstalNotifd's built-in persistence (cached under
`~/.cache/astal/notifd`), so restored notifications repopulate the daemon's
`notifications` list on startup, and the shell SHALL NOT replay popups for
restored notifications at launch.

#### Scenario: History survives a restart
- **GIVEN** notifications were received in a previous session
- **WHEN** the AGS shell restarts
- **THEN** those notifications are present in the daemon's `notifications` list

#### Scenario: No popup storm on startup
- **WHEN** the AGS shell starts and restores cached notifications
- **THEN** no toasts pop for the restored notifications

### Requirement: Toast theming

Toasts SHALL be styled from the base16 palette in `ags/style.scss`, matching the
prior mako mapping (`base00` background, `base05` text, `base04` border, `base0D`
accent), and SHALL NOT hardcode colors.

#### Scenario: Themed toast
- **WHEN** a toast is shown
- **THEN** its colors derive from the shell's base16 SCSS variables

### Requirement: Popup toasts are size-bounded

A popup toast SHALL bound its dimensions so a long notification cannot stretch
across the screen. Text width SHALL be capped via the label `max-width-chars`
property (GTK4 ignores CSS `max-width`/`max-height`), and the body SHALL wrap to
a limited number of lines and then ellipsize.

#### Scenario: Long body wraps and ellipsizes
- **GIVEN** a notification with a very long body
- **WHEN** its toast is shown
- **THEN** the toast width stays bounded (around its minimum width, not the full text width)
- **AND** the body wraps to at most a few lines and then trails off with an ellipsis

#### Scenario: Long summary does not widen the toast
- **GIVEN** a notification with a long summary
- **WHEN** its toast is shown
- **THEN** the summary stays on a single line and is ellipsized rather than widening the toast

