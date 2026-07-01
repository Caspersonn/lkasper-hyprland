## MODIFIED Requirements

### Requirement: Island styling
Each island SHALL have:
- A rounded-rectangle shape (border-radius ~14px, not a full capsule)
- A solid (opaque) dark fill derived from a `$base-dark` base16 variable (no hardcoded colour literals, no translucency)
- A 1px border
- No drop shadow
- No backdrop blur (not expressible in GTK4)

Interactive sections SHALL show a subtle hover background.

#### Scenario: Island appearance
- **WHEN** the bar is rendered over a wallpaper
- **THEN** the islands are solid dark rounded rectangles with a border and no drop shadow, and the wallpaper is not visible through the islands (only in the gaps between them)

#### Scenario: Hover feedback
- **WHEN** the pointer is over an interactive section
- **THEN** that section shows a subtle hover background
