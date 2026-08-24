---
# lkasper-hyprland-r2np
title: "duplicate child name in GtkStack" warning, 238x per boot (not yet rooted out)
status: todo
type: bug
priority: low
created_at: 2026-08-25T00:00:00Z
updated_at: 2026-08-25T00:00:00Z
---

    gjs[...]: While adding page: duplicate child name in GtkStack: Troubleshooting
    gjs[...]: While adding page: duplicate child name in GtkStack: Urgency

238 occurrences in one boot, from the lkasper-shell process (confirmed: the pid's cmdline is
gjs running /run/user/1000/*-ags.js). Harmless - GTK keeps the first page and warns - but noisy.

## What is established
- The page names are only ever `Troubleshooting` and `Urgency`.
- They arrive in bursts (4-10 within the same second) spread over hours, which matches
  notifications arriving rather than a UI being opened.
- The string is NOT in the shell's compiled bundle, NOT in libgtk-4, and libadwaita is not even
  loaded into the process (checked /proc/<pid>/maps: only libgtk-4 is mapped). So the names are
  runtime data, not a literal from any library or from our code.
- Our source uses no `Gtk.Stack`, no `add_named`, and no `Adw` anywhere.
- The only `add_named` in the process comes from gnim (the ags-js-lib JSX runtime):

      if (child instanceof Gtk3.Stack && child.name !== "" && child.name !== null
          && getType(child) === "named") { return parent.add_named(child, child.name); }

  so the JSX runtime routes named children into a stack, and two children ended up sharing a name.
- The notification views use `<For each={...}>` with no explicit key, and the only `name=` in that
  tree is the per-monitor window name, which is unique.

## Best current hypothesis
"Troubleshooting" and "Urgency" look like notification content (a Slack channel called
Troubleshooting is very plausible on this machine), reaching a Stack through the gnim/Astal
notification path. Not proven - pinning it down means reading a minified bundle or building
ags-js-lib with symbols, which was out of proportion to a harmless warning.

## Next step if it becomes worth fixing
Reproduce deliberately: send two notifications with the same summary via `notify-send` and see
whether the warning count increases by the expected amount. That would confirm the notification
path and identify which name field is being used as the stack page name.

Unrelated to the light/dark theming work (predates it).
