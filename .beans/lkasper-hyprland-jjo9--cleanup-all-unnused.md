---
# lkasper-hyprland-jjo9
title: CleanUp all unnused in ags directory
status: todo
type: bug
priority: critical
created_at: 2026-06-26T12:40:43Z
updated_at: 2026-06-26T12:45:47Z
---

We should clean up the `ags/` directory of things that are not being used.

What are the things:
- Functions
- Files
- Classes
- variables (of all kind)
- styles in css
- Imports


How do we determine if its unnused?
- By using the grep function we determine if its unnused, this is the source of truth.
- If things can be combined in to a single thing
    - examples are; functions that do the same thing, styles that have the same attribute settings, multiple of the same types or variables
