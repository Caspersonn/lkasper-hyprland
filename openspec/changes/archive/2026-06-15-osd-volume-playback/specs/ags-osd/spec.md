## ADDED Requirements

### Requirement: OSD overlay window

The AGS shell SHALL provide an on-screen display (OSD) window rendered on the
`Astal.Layer.OVERLAY` layer, anchored bottom-center with a bottom margin. The
window SHALL NOT reserve screen space (no `EXCLUSIVE` exclusivity) and SHALL NOT
acquire keyboard focus (`Astal.Keymode.NONE`).

#### Scenario: Floats without disturbing layout
- **GIVEN** the AGS shell is running
- **WHEN** the OSD becomes visible
- **THEN** it is drawn above tiled windows and the bar
- **AND** no window or the bar shifts position to make room for it
- **AND** keyboard input continues to reach the focused application

#### Scenario: Positioned bottom-center
- **WHEN** the OSD is shown
- **THEN** it is horizontally centered on the monitor
- **AND** offset from the bottom edge by a fixed margin

### Requirement: OSD appears on the focused monitor only

The OSD SHALL be displayed only on the monitor that currently holds focus
(resolved from `AstalHyprland` `focusedMonitor`, matched to the corresponding
`Gdk.Monitor` by connector name), and SHALL NOT appear on other connected
monitors. The OSD SHALL remain functional across monitor hot-plug/unplug by
reusing the bar's reactive per-monitor window pattern
(`<For each={createBinding(App, "monitors")}>` in `ags/windows/`).

#### Scenario: Shown on the focused monitor in a multi-monitor setup
- **GIVEN** two monitors A and B are connected and B is focused
- **WHEN** a volume or media trigger fires
- **THEN** the OSD appears on monitor B
- **AND** no OSD appears on monitor A

#### Scenario: Follows focus changes
- **GIVEN** monitor A is focused
- **WHEN** focus moves to monitor B and a trigger fires
- **THEN** the OSD appears on monitor B

#### Scenario: Survives monitor unplug
- **GIVEN** the OSD windows exist for two monitors
- **WHEN** one monitor is disconnected
- **THEN** the AGS shell does not crash
- **AND** the OSD continues to work on the remaining monitor

### Requirement: Volume OSD feedback

The OSD SHALL display the current output volume — a speaker icon, a level
indicator, and the volume percentage — whenever the default WirePlumber
speaker's volume or mute state changes (`AstalWp` `notify::volume` /
`notify::mute`), independent of what caused the change.

#### Scenario: Volume key adjustment
- **WHEN** the user presses a volume-up or volume-down key
- **THEN** the OSD shows the volume view with the updated level and percentage

#### Scenario: Mute toggle
- **WHEN** the user toggles mute
- **THEN** the OSD shows the volume view reflecting the muted state

#### Scenario: Source-agnostic
- **GIVEN** the volume changes from any source (a keybind or the QuickSettings slider)
- **WHEN** the speaker's volume property changes
- **THEN** the OSD shows the volume view

### Requirement: Media OSD content

The media view of the OSD SHALL display, left to right, a symbolic action icon
indicating the media action that triggered it, the track title and artist, and
the media player's source icon (its desktop-entry icon) at the right edge. It
SHALL NOT render album cover art.

#### Scenario: Shows action icon, track, and source icon
- **GIVEN** the media OSD is shown for a media-key action
- **THEN** it displays a symbolic action icon for that action on the left
- **AND** the current track title and artist
- **AND** the media player's source icon on the right

#### Scenario: No album cover art
- **WHEN** the media view is shown
- **THEN** it does not render album cover art

### Requirement: Media OSD triggered by media-key actions via IPC

The Hyprland media keybinds SHALL each invoke `ags request osd-media <action>`
after their `playerctl` command — `playpause` for `XF86AudioPlay` and
`XF86AudioPause`, `next` for `XF86AudioNext`, and `prev` for `XF86AudioPrev` (in
`modules/home-manager/_hyprland/bindings.nix`). The AGS `requestHandler` in
`ags/app.ts` SHALL show the media view with an action icon chosen from
`<action>`: `next` → a skip-forward icon, `prev` → a skip-backward icon, and
`playpause` → the resulting playback state's icon (a play icon when playing, a
pause icon when paused). The handler SHALL resolve the current player fresh on
each request so it is robust to player restarts. Track auto-advance, and
playback changes originating from any source other than these keybinds, SHALL
NOT trigger the OSD.

#### Scenario: Next shows a skip-forward icon
- **GIVEN** a media player is active
- **WHEN** the user presses the next media key
- **THEN** `ags request osd-media next` is invoked
- **AND** the OSD shows the media view with a skip-forward icon and the new track

#### Scenario: Previous shows a skip-backward icon
- **GIVEN** a media player is active
- **WHEN** the user presses the previous media key
- **THEN** the OSD shows the media view with a skip-backward icon

#### Scenario: Play shows a play icon
- **GIVEN** media is paused
- **WHEN** the user presses play/pause and the result is playing
- **THEN** the OSD shows the media view with a play icon

#### Scenario: Pause shows a pause icon
- **GIVEN** media is playing
- **WHEN** the user presses play/pause and the result is paused
- **THEN** the OSD shows the media view with a pause icon

#### Scenario: Play/pause icon self-corrects
- **GIVEN** `playerctl play-pause` toggles asynchronously so the playback status is not yet updated when the request arrives
- **WHEN** the OSD is showing a playpause action and `notify::playback-status` subsequently fires while the OSD is visible
- **THEN** the OSD updates to the correct play or pause icon

#### Scenario: Auto-advance does not trigger the OSD
- **GIVEN** a track is playing
- **WHEN** the track ends and the player auto-advances without a media-key press
- **THEN** no OSD appears

#### Scenario: Robust to player restart
- **GIVEN** the media player was restarted after the shell started
- **WHEN** the user presses a media key
- **THEN** the OSD still appears for the current player

### Requirement: Auto-hide with re-arming timeout

The OSD SHALL hide automatically after a short timeout (~1.5 seconds) measured
from the most recent trigger. Each new trigger SHALL reset the timeout and
replace the displayed content (latest trigger wins), using a single shared
window and a single shared timer so that at most one OSD view is visible at a
time.

#### Scenario: Auto-hide after timeout
- **GIVEN** the OSD is visible following a trigger
- **WHEN** no further trigger occurs
- **THEN** the OSD hides after the timeout elapses

#### Scenario: Repeated triggers re-arm the timer
- **GIVEN** the OSD is visible
- **WHEN** another trigger fires before the timeout elapses
- **THEN** the timeout is reset
- **AND** the OSD remains visible

#### Scenario: Latest trigger wins
- **GIVEN** the volume view is visible
- **WHEN** a media trigger fires
- **THEN** the OSD switches to the media view
- **AND** only one OSD view is shown at a time

### Requirement: No OSD flash at shell startup

The OSD SHALL NOT appear as a result of signal emissions that occur during AGS
shell initialization (for example, the initial `notify::volume` emitted when the
WirePlumber binding is first established).

#### Scenario: No flash on login
- **WHEN** the AGS shell starts at login
- **THEN** no OSD is shown until a genuine user-initiated volume change, playback transition, or skip request occurs
