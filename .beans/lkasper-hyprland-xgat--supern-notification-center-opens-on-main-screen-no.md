---
# lkasper-hyprland-xgat
title: SUPER+N notification center opens on main screen, not focused monitor
status: completed
type: bug
priority: normal
created_at: 2026-07-20T16:19:23Z
updated_at: 2026-07-20T18:05:55Z
---

SUPER+N (toggle-notifications -> toggleCenter) always opens the notification center on the first/main monitor. Clicking the bar bell works per-monitor, but the keybind uses popovers[0].

Root cause: ags/windows/notifications/center.tsx keeps popovers in a plain array (one per bar/monitor, in creation order) and toggleCenter() pops popovers[0].

Fix: key popovers by monitor connector; toggleCenter resolves AstalHyprland focusedMonitor.name (== gdkmonitor connector, same convention as notifications/index.tsx PopupWindow) and toggles that monitor's popover, closing any open on other monitors. Thread the connector via NotificationBell -> NotificationPopover.

Part of feature bean lkasper-hyprland-9ura (AGS shell).
