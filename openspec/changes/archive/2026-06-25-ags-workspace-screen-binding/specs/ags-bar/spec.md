## MODIFIED Requirements

### Requirement: Workspaces module (left pill)
The workspaces module SHALL use `astal-hyprland` to always display workspaces 1 through 10 (the 10th labelled `0` to match the `SUPER, 0` keybind), each as a roomy rectangular cell containing the workspace's **representative app icon** (its last-focused client's class, shown only when the workspace exists and has a client) followed by its **id label**, with a short (~50% width, ~2.5px) **centered** underline in the accent colour of the monitor the workspace is bound to:
- **Active** workspace (focused): highlighted number with a subtle rounded background
- **Occupied** workspace (exists, not active): normal number
- **Empty** workspace (does not currently exist): still rendered, dimmed, with no app icon and an underline coloured by its persistent workspace-rule monitor (`hyprctl workspacerules -j`), falling back to the focused monitor
- **Left-click** a workspace SHALL switch to it (creating it if it does not exist)

The left pill SHALL contain only this workspaces module. The previous standalone app-icon "clients" row is removed; the per-app icon is instead folded into each workspace cell.

#### Scenario: All ten workspaces always shown
- **WHEN** only workspaces 1, 2 and 5 currently exist
- **THEN** all of 1–10 are rendered
- **AND** 3, 4, 6, 7, 8, 9 and 0 appear dimmed (empty), while 1, 2 and 5 appear normal

#### Scenario: Workspace cells reflect state, app, and bound monitor
- **WHEN** workspace 3 is active and bound to monitor `DP-1`, and workspace 2 has a terminal as its last client
- **THEN** 3 is shown highlighted, 2 shows a terminal icon before its number
- **AND** each existing workspace has a short centered underline coloured by its bound monitor's accent

#### Scenario: Left-click switches workspace
- **WHEN** the user left-clicks a workspace number
- **THEN** Hyprland switches to that workspace

## ADDED Requirements

### Requirement: Workspace monitor accent colours
Each workspace underline colour SHALL be derived from the base16 palette and SHALL NOT be hardcoded: the bound monitor's name is deterministically hashed into a fixed pool of base16 accent slots (defined in `ags/style.scss`), so a given monitor maps to the same accent across reloads.

#### Scenario: Stable, shared colour per monitor
- **WHEN** two workspaces are bound to the same monitor
- **THEN** both underlines use the same base16 accent
- **AND** that accent is unchanged after a shell restart

#### Scenario: Different monitors get different accents
- **WHEN** workspaces are spread across different monitors
- **THEN** workspaces on different monitors use different base16 accent slots (up to the pool size)

### Requirement: Workspace screen picker
Right-clicking a workspace SHALL open a popover listing each connected display with a symbolic device icon (a laptop icon when the connector matches `eDP*`, a monitor icon otherwise), its model, resolution, refresh rate, and connector name. Display specs SHALL be read from `hyprctl monitors -j`. Selecting a display SHALL run `hyprctl dispatch moveworkspacetomonitor <workspace-id> <monitor-name>`.

#### Scenario: Open the screen picker
- **WHEN** the user right-clicks a workspace
- **THEN** a popover lists each connected monitor with its icon, model, resolution, refresh rate, and connector

#### Scenario: Move a workspace to a monitor
- **GIVEN** the screen picker is open for workspace 6
- **WHEN** the user selects the `DP-1` display
- **THEN** `hyprctl dispatch moveworkspacetomonitor 6 DP-1` is run
- **AND** workspace 6's underline updates to `DP-1`'s accent colour
