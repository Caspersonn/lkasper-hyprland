# wallpaper-theme-switching Specification (delta)

## MODIFIED Requirements

### Requirement: Whole-desktop recolour from the active wallpaper

The active theme SHALL be a (pair, mode) pair. Selecting a pair or changing the mode SHALL set the corresponding wallpaper image and recolour every themed surface from that image's palette: the AGS shell (bar, overlays, popups), the terminal, btop, hyprlock, GTK applications, starship, opencode and Hyprland borders.

#### Scenario: Switch recolours all surfaces
- **WHEN** a pair is selected
- **THEN** the wallpaper for that pair's current-mode member is set AND all themed surfaces use that image's palette

#### Scenario: Mode change recolours all surfaces
- **WHEN** the mode is changed
- **THEN** the wallpaper switches to the other member of the current pair AND all themed surfaces use that member's palette

### Requirement: Defined per-app reload behaviour

The switch SHALL reload each themed app through its supported mechanism; apps that cannot hot-reload SHALL pick up the new theme on their next launch or new window, and the switch SHALL complete without error regardless.

#### Scenario: Mixed reload capabilities
- **WHEN** a switch occurs
- **THEN** the AGS shell, Hyprland borders, the wallpaper, foot terminals and GTK applications update immediately, btop / ghostty / starship / opencode update on their next instance, and the switch reports success without blocking

#### Scenario: A reload target is absent
- **WHEN** a switch occurs and a themed app is not running or not installed
- **THEN** the switch skips that app and still completes successfully

### Requirement: Fallback when a palette is missing

WHEN the active theme has no committed palette, the system SHALL fall back to a last-known or default theme and SHALL NOT crash or leave surfaces uncoloured. The fallback SHALL respect the requested mode where a palette for that mode exists.

#### Scenario: Missing palette
- **WHEN** a theme without a committed palette becomes active
- **THEN** the desktop uses the fallback palette and no themed surface is left unstyled

#### Scenario: Corrupt palette file
- **WHEN** the active palette file cannot be parsed
- **THEN** the AGS shell renders with its built-in fallback palette rather than unstyled

## ADDED Requirements

### Requirement: Single-keybind mode toggle

The system SHALL provide a single keybind that flips the desktop between light and dark mode without a rebuild, applying the change to every themed surface.

#### Scenario: Toggle dark to light
- **WHEN** the desktop is in dark mode and the toggle keybind is pressed
- **THEN** the desktop switches to the light member of the current pair and every themed surface adopts the light palette

#### Scenario: Toggle light to dark
- **WHEN** the desktop is in light mode and the toggle keybind is pressed
- **THEN** the desktop switches to the dark member of the current pair and every themed surface adopts the dark palette

#### Scenario: No rebuild required
- **WHEN** the toggle runs
- **THEN** no Nix evaluation or rebuild occurs and the change is visible immediately on the live surfaces

### Requirement: Mode is preserved across pair changes

Changing the wallpaper pair SHALL NOT change the current mode.

#### Scenario: Pair change in light mode
- **WHEN** the desktop is in light mode and a different pair is selected
- **THEN** the new pair's light member becomes active and the desktop stays in light mode

### Requirement: Theme state survives a rebuild

The active (pair, mode) selection SHALL be runtime-owned state. A rebuild SHALL NOT reset a selection made at runtime, and a first-ever activation SHALL establish a default selection.

#### Scenario: Rebuild after a runtime switch
- **WHEN** the user switches theme at runtime and then rebuilds the configuration
- **THEN** the runtime selection is still active after the rebuild

#### Scenario: First activation
- **WHEN** the configuration is activated and no selection exists yet
- **THEN** a default (pair, mode) selection is established

### Requirement: One indirection for every consumer

The active theme SHALL be exposed at a single well-known path, and every themed application SHALL read its colours through that path. Switching SHALL be a single atomic repoint of that path.

#### Scenario: Consumer reads through the pointer
- **WHEN** a themed app loads its colour configuration
- **THEN** it resolves through the well-known active-theme path rather than a build-time copy

#### Scenario: Atomic switch
- **WHEN** a switch occurs
- **THEN** the active-theme path is repointed in one operation and never observed in a partially-updated state

### Requirement: Light and dark parity for the shell

The AGS shell SHALL be legible in both modes. Surface, hairline and shadow treatments SHALL adapt to the active mode rather than assuming a dark background.

#### Scenario: Shell in light mode
- **WHEN** the desktop is in light mode
- **THEN** bar and overlay surfaces are distinguishable from their background, separators are visible, and text meets the contrast target

#### Scenario: Surfaces separable in both modes
- **WHEN** the shell renders an island or popup in either mode
- **THEN** the surface is visually distinct from the window background behind it

### Requirement: GTK applications follow the active mode

GTK and libadwaita applications SHALL follow the active mode at runtime. No session-level setting SHALL pin them to a single polarity.

#### Scenario: libadwaita app follows the toggle
- **WHEN** the mode is toggled while a libadwaita application is open
- **THEN** that application switches polarity without being restarted

#### Scenario: No env-var pin
- **WHEN** the session environment is inspected
- **THEN** no variable forces a fixed GTK theme or disables the settings portal

### Requirement: Editor colour contract

The active theme SHALL publish an ANSI-faithful palette and the active mode at the well-known path, in a form a separate editor configuration can consume without a build-time dependency on this repository.

#### Scenario: Editor reads the contract
- **WHEN** an editor configuration reads the published palette
- **THEN** it obtains ANSI-faithful base16 values and the active mode

#### Scenario: Contract absent
- **WHEN** the published palette is not present on a machine
- **THEN** the consuming editor configuration falls back to its own default colourscheme

#### Scenario: Editor palette is not the shell palette
- **WHEN** the published editor palette is compared with the shell palette
- **THEN** the editor palette retains distinct ANSI slots rather than the shell's accent remapping

### Requirement: Third-party applications follow the active mode

Applications that cannot consume the wallpaper palette SHALL still follow the active mode's
polarity through the standard desktop colour-scheme signal, and that signal SHALL be emitted on
every mode change so following applications update without a restart.

#### Scenario: Colour-scheme change is broadcast
- **WHEN** the mode is toggled
- **THEN** the desktop colour-scheme setting changes and a change notification is emitted on the
  standard settings interface

#### Scenario: Browser follows the mode
- **WHEN** the mode is toggled while the browser is running
- **THEN** the browser's chrome and page content adopt the new polarity without a restart

#### Scenario: Electron application follows the mode
- **WHEN** the mode is toggled while an Electron application configured to follow the system is
  running
- **THEN** that application adopts the new polarity without a restart

#### Scenario: Application pinned to a fixed theme
- **WHEN** an application's own appearance setting is pinned to light or dark rather than
  "follow the system"
- **THEN** the mode change does not alter it, and this is a per-application setting outside the
  scope of this system

