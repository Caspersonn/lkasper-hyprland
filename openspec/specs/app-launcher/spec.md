# app-launcher Specification

## Purpose
TBD - created by archiving change custom-launcher. Update Purpose after archive.
## Requirements
### Requirement: Launcher overlay window

The AGS shell SHALL provide a launcher overlay implemented at `ags/windows/launcher/index.tsx` as a layer-shell window on `Astal.Layer.OVERLAY`, anchored to all edges with `Astal.Exclusivity.IGNORE` and `Astal.Keymode.EXCLUSIVE`, rendering a dimmed backdrop behind a centered card, consistent with the keybind cheatsheet overlay chrome and the gruvbox palette variables in `ags/style.scss`.

#### Scenario: Overlay renders centered over a dimmed backdrop

- **WHEN** the launcher is toggled visible
- **THEN** a centered card is shown over a dimmed full-screen backdrop on the focused monitor
- **AND** the card uses existing gruvbox palette variables (no new hardcoded colors)

### Requirement: Toggle wiring

The launcher SHALL export `initLauncher()` and `toggleLauncher()`, `main()` in `ags/app.ts` SHALL call `initLauncher()`, and the `requestHandler` in `ags/app.ts` SHALL toggle the launcher when it receives the `toggle-launcher` request.

#### Scenario: ags request toggles the launcher

- **WHEN** `ags request toggle-launcher` is invoked while the launcher is hidden
- **THEN** the launcher becomes visible with the search entry focused
- **WHEN** `ags request toggle-launcher` is invoked while the launcher is visible
- **THEN** the launcher is hidden

### Requirement: AstalApps data source

The launcher SHALL enumerate and launch applications via `AstalApps`, and `apps` SHALL be present in the `astalLibs` list in `ags/flake.nix` so `gi://AstalApps` resolves at bundle time. Results SHALL be produced by the `AstalApps` fuzzy query over the current search text.

#### Scenario: Query filters apps fuzzily

- **WHEN** the user types text into the search entry
- **THEN** the result list shows applications matching that text via the `AstalApps` fuzzy query
- **AND** each result row shows the application icon and name

#### Scenario: Empty query lists apps

- **WHEN** the search entry is empty
- **THEN** the launcher shows the full application list (frequency-ordered per AstalApps), uncapped and scrollable

### Requirement: Keyboard navigation and launch

The launcher SHALL be fully keyboard operable: the search entry holds typing focus, `Up`/`Down` SHALL move a highlighted selection through the filtered results (clamped to the result bounds), and `Enter` SHALL launch the highlighted application via `AstalApps` `.launch()` and then close the launcher. The highlighted selection SHALL be tracked by a stable application key (not a list index) so it stays correct as the result list changes, and a highlight SHALL always be present (defaulting to the first result on open and on each keystroke). Mouse hover over a row SHALL move the highlight to that row, and the highlighted row SHALL be scrolled into view.

#### Scenario: Arrow keys move the selection

- **WHEN** results are shown and the user presses `Down` (or `Up`)
- **THEN** the highlighted selection moves to the next (or previous) result without leaving the search entry
- **AND** the selection does not move past the first or last result
- **AND** the newly highlighted row is scrolled into view

#### Scenario: Hover moves the selection

- **WHEN** the user hovers the pointer over a result row
- **THEN** the highlight moves to that row, matching what `Enter` would launch

#### Scenario: Enter launches the highlighted app

- **WHEN** results are shown and the user presses `Enter`
- **THEN** the highlighted application (the first result when the user has not moved the selection) is launched via `AstalApps` `.launch()`
- **AND** the launcher closes

### Requirement: Dismissal

The launcher SHALL close on `Escape` and on a click outside the card (backdrop click) without launching any application.

#### Scenario: Escape closes without launching

- **WHEN** the launcher is visible and the user presses `Escape`
- **THEN** the launcher closes and no application is launched

#### Scenario: Backdrop click closes

- **WHEN** the user clicks the dimmed backdrop outside the card
- **THEN** the launcher closes and no application is launched

