---
# lkasper-hyprland-8vhq
title: Invalid max-width in style.scss spams the journal (129x per boot)
status: completed
type: bug
priority: normal
created_at: 2026-08-25T00:00:00Z
updated_at: 2026-08-25T00:00:00Z
---

    gjs[395363]: CSS Error :1082:3 No property named "max-width"

129 occurrences in a single boot, and it is the ONLY CSS error the shell produces.

`ags/style.scss:1244` had `max-width: 540px;` in `.soltty-card`. GTK CSS has no `max-width`
property at all - it is a web CSS property. GTK parses the declaration, errors, and ignores it,
every time the stylesheet is applied (so it repeats on every theme re-apply and widget restyle).

Two consequences worth noting:
- The declaration never did anything, so commit 1baf1cd "fix: Soltty max-width" did not actually
  constrain anything.
- Removing it is behaviour-neutral. The real width constraint was already in place and correct:
  `ags/windows/soltty/index.tsx` uses `maxWidthChars` + `ellipsize={Pango.EllipsizeMode.END}` in
  five places, which is the GTK way to stop long text widening a card. `min-width: 540px` stays.

Fix: deleted the declaration. Verified the rebuilt bundle contains zero `max-width` occurrences
while `min-width: 540px` and the rest of the `.soltty-card` rule are intact.

General rule for this stylesheet: GTK CSS is not web CSS. Width capping belongs on the label
(`maxWidthChars`, `ellipsize`) or the widget, never in a `max-width` declaration.
