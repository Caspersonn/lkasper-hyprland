---
# lkasper-hyprland-t9xi
title: Notification center popover collapses to one notification
status: completed
type: bug
priority: normal
created_at: 2026-07-20T16:13:46Z
updated_at: 2026-07-20T16:16:56Z
---

The notification center popover (bell icon -> toggleCenter) opens very small, showing only ~1 notification even when several exist.

Root cause: ags/windows/notifications/center.tsx NotificationPopover() wraps the list in a Gtk.ScrolledWindow with only `vexpand`. Inside a Gtk.Popover the child is given its natural size and a ScrolledWindow reports a minimal natural height, so it collapses to ~1 card instead of growing to fit content.

Fix: give .np-scroll GTK4 content-height constraints — propagateNaturalHeight + minContentHeight (floor so it isn't tiny) + maxContentHeight (cap, then scroll). Drop the no-op vexpand.

Part of feature bean lkasper-hyprland-9ura (AGS shell) work.
