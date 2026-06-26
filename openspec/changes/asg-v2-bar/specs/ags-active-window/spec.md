## ADDED Requirements

### Requirement: Active window widget
The left island SHALL display the focused client's app icon and its title, sourced reactively from `AstalHyprland` `focusedClient`. The app icon SHALL use the current themed-icon approach (derived from the client class), not a class→glyph table. The title SHALL be ellipsized to a maximum width (~280px). When no client is focused, the widget SHALL render nothing (or a neutral placeholder) rather than stale text.

#### Scenario: Shows the focused client
- **WHEN** a client is focused
- **THEN** the widget shows that client's app icon and its title

#### Scenario: Updates on focus change
- **WHEN** focus moves to a different client
- **THEN** the widget updates to the newly focused client's icon and title

#### Scenario: Long titles are ellipsized
- **WHEN** the focused client's title exceeds the maximum width
- **THEN** the title is truncated with an ellipsis rather than widening the island

#### Scenario: No focused client
- **WHEN** the focused workspace has no client
- **THEN** the widget renders nothing (or a neutral placeholder) and shows no stale title
