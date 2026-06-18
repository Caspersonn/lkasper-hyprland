---
# lkasper-hyprland-nn80
title: Notification center (AGS, SwayNC-style)
status: completed
type: task
priority: normal
created_at: 2026-06-16T09:56:51Z
updated_at: 2026-06-18T14:47:34Z
openspec-link:
  - openspec/changes/archive/2026-06-16-notifications-1-daemon
  - openspec/changes/archive/2026-06-18-notifications-2-center
---

Replace mako with an AGS/AstalNotifd notification stack, SwayNC-style. Chained OpenSpec changes: notifications-1-daemon (become the daemon + popup toasts, retire mako) then notifications-2-center (slide-out center: persisted history, DND, Clear All, MPRIS widget, bell toggle). Kept separate from QuickSettings.
