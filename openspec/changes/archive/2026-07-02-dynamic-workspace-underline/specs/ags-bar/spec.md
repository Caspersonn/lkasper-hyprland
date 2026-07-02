## MODIFIED Requirements

### Requirement: Workspaces module (left island)
The workspaces module SHALL use `astal-hyprland` to render the currently existing workspaces only (not a fixed 1..10 set), each as a pill-shaped cell containing app icons for the windows on the workspace (one icon per client window, capped, using the current themed-icon approach) and its id number, with a centered underline coloured by the monitor the workspace is bound to:
- **Focused** workspace: monitor-tinted background + monitor-coloured number + a glowing underline
- **Occupied** workspace (exists, not focused): faint background + dimmer underline
- **Empty/absent** workspace: dim number, no underline
- **Left-click** a workspace SHALL switch to it

The underline width SHALL scale with the number of clients (apps) on the workspace: a base width for a single client, growing by a fixed increment per additional client, clamped to a maximum so the underline never overflows the cell. The cell's icon row SHALL show one icon per client window (not deduplicated by app class), capped, so that the icon row and the underline both reflect the same window count — opening the same app twice adds both a second icon and underline width. The underline height, radius, and monitor-accent colour are unaffected by the client count. The right-click screen picker is not part of this module.

#### Scenario: Only existing workspaces shown
- **WHEN** workspaces 1, 2 and 5 exist
- **THEN** only 1, 2 and 5 are rendered (no fixed 3,4,6..10 cells)

#### Scenario: Focused/occupied/empty styling
- **WHEN** workspace 2 is focused and workspace 5 is occupied
- **THEN** 2 shows the monitor-tinted background, monitor-coloured number, and glowing underline, while 5 shows a faint background and dimmer underline

#### Scenario: Underline grows with app count
- **WHEN** a workspace has one client
- **THEN** its underline is drawn at the base width
- **AND WHEN** more clients are opened on that workspace
- **THEN** its underline widens by a fixed increment per additional client
- **AND** the underline width is clamped to a maximum so it never overflows the cell

#### Scenario: Icons track window count
- **WHEN** two windows of the same application are open on a workspace
- **THEN** the cell shows two icons (one per window, up to the icon cap), not a single deduplicated icon
- **AND** the underline reflects the same window count

#### Scenario: Left-click switches workspace
- **WHEN** the user left-clicks a workspace
- **THEN** Hyprland switches to that workspace
