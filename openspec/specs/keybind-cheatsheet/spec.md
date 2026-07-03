# keybind-cheatsheet Specification

## Purpose
TBD - created by archiving change keybind-cheatsheet. Update Purpose after archive.
## Requirements
### Requirement: Cheatsheet overlay window

The AGS shell SHALL provide a centered floating modal window (module `ags/windows/shortcuts/`) that lists Hyprland keybinds. The window SHALL be a layer-shell surface on `Astal.Layer.OVERLAY` anchored to fill the output, containing a dimmed backdrop and a centered card. It SHALL be hidden by default and shown on request.

#### Scenario: Overlay opens on request

- **WHEN** the shell receives the `toggle-shortcuts` request and the overlay is hidden
- **THEN** the overlay becomes visible, centered over the focused output, dimming the background

#### Scenario: Overlay toggles closed

- **WHEN** the shell receives the `toggle-shortcuts` request and the overlay is visible
- **THEN** the overlay is hidden

### Requirement: Toggle wiring in the shell entry point

`ags/app.ts` SHALL dispatch the `toggle-shortcuts` request to a `toggleShortcuts()` handler and SHALL call the overlay's initializer from `main()`, mirroring the existing notification-center toggle pattern.

#### Scenario: Request routed

- **WHEN** `ags request toggle-shortcuts` is invoked
- **THEN** the `requestHandler` calls the shortcuts toggle and responds `ok`

#### Scenario: Overlay initialized at startup

- **WHEN** the shell `main()` runs
- **THEN** the shortcuts overlay is constructed and registered without becoming visible

### Requirement: Keybind data sourced from hyprctl at open time

On each open, the overlay SHALL read live keybinds via `hyprctl binds -j` (through `execAsync`) and SHALL display only entries whose `has_description` is true, ignoring all undescribed binds.

#### Scenario: Only described binds appear

- **WHEN** the overlay opens
- **THEN** it runs `hyprctl binds -j`
- **AND** binds with `has_description == false` (e.g. media keys, mouse binds, undescribed workspace binds) are excluded from the display

#### Scenario: Data is fresh

- **WHEN** binds change and the overlay is reopened
- **THEN** the displayed list reflects the current `hyprctl binds -j` output without requiring a shell restart

### Requirement: Group and label parsed from the description convention

Each described bind's `description` SHALL be parsed as `[Group] Label`: the bracketed prefix is the group, the remainder is the row label. A description without a bracketed prefix SHALL fall back to the group `Other`. Rows SHALL be visually grouped by group.

#### Scenario: Bracketed description split

- **WHEN** a bind has description `"[Windows] Kill active window"`
- **THEN** it renders under group `Windows` with label `Kill active window`

#### Scenario: Missing group falls back

- **WHEN** a described bind has no bracketed prefix
- **THEN** it renders under group `Other`

### Requirement: Modifier and key rendered as keycap chips

Each row SHALL render its accelerator as a sequence of keycap chips: the `modmask` bitmask decoded into `Super/Ctrl/Alt/Shift` chips (in that order) followed by the prettified key. Key prettification SHALL map at least `slash→/`, `Return→⏎`, `Escape→Esc`, `Backspace→⌫`, and the arrow keysyms `left/right/up/down` to `←/→/↑/↓`.

#### Scenario: Modmask decoded

- **WHEN** a bind has `modmask` 65 (SUPER+SHIFT) and key `N`
- **THEN** the row shows chips `Super` `Shift` `N`

#### Scenario: Key prettified

- **WHEN** a bind has key `slash`
- **THEN** the key chip shows `/`

### Requirement: Consecutive workspace binds collapse into a range row

When multiple described binds share the same group, `modmask`, and dispatcher and their keys are consecutive digits, the overlay SHALL collapse them into a single row showing a range chip (e.g. `1 – 0`) rather than one row per digit.

#### Scenario: Workspace switch binds collapse

- **WHEN** `SUPER, 1`…`SUPER, 0` all carry the description `[Workspaces] Switch to workspace`
- **THEN** the overlay renders one row labelled `Switch to workspace` with a `1 – 0` range chip

### Requirement: Overlay dismissal

The overlay SHALL close when the user presses `Escape` (via a keyboard grab / `EventControllerKey`) or clicks the dimmed backdrop outside the card.

#### Scenario: Escape closes

- **WHEN** the overlay is visible and `Escape` is pressed
- **THEN** the overlay is hidden

#### Scenario: Backdrop click closes

- **WHEN** the overlay is visible and the user clicks the backdrop outside the card
- **THEN** the overlay is hidden

