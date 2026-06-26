# ags-media Specification

## Purpose
Defines the AGS bar media widget and media player popover.

## Requirements
### Requirement: In-bar media widget
The right island SHALL display, when an `AstalMpris` player is active, the album art, the track title and artist (ellipsized), and an animated equalizer indicator that animates only while playback is playing. When no player is active the widget SHALL be hidden. Clicking the widget SHALL open the media player popover.

#### Scenario: Playing
- **WHEN** a player is active and playing
- **THEN** the widget shows the art, title, and artist, and the equalizer animates

#### Scenario: Paused
- **WHEN** the active player is paused
- **THEN** the equalizer animation stops while the track details remain visible

#### Scenario: No player
- **WHEN** no MPRIS player is active
- **THEN** the media widget is hidden

#### Scenario: Open the player popover
- **WHEN** the user clicks the media widget
- **THEN** the media player popover opens

### Requirement: Media player popover
The media player popover SHALL show large album art, the track title, artist, and album, a seek progress bar with elapsed and total times, and transport controls (shuffle, previous, play/pause, next, repeat) driven by `AstalMpris`. The popover SHALL auto-dismiss on outside click.

#### Scenario: Transport controls operate the player
- **WHEN** the user activates previous, play/pause, or next
- **THEN** the corresponding `AstalMpris` action runs on the active player

#### Scenario: Progress reflects position
- **WHEN** the popover is open during playback
- **THEN** the progress bar and elapsed time advance with the track position

#### Scenario: Shuffle and repeat
- **WHEN** the user toggles shuffle or repeat
- **THEN** the player's shuffle/loop state changes and the control reflects it
