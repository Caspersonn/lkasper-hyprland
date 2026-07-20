---
# lkasper-hyprland-olzi
title: Soltty recent list shows no duration for the running/zero-duration entry
status: completed
type: bug
priority: normal
created_at: 2026-07-21T09:39:42Z
updated_at: 2026-07-21T09:46:44Z
---

In the soltty overlay RECENT list, the duration is missing for the running (most-recent) entry: soltty 'list --json' returns duration=0 with end=null until a timer stops, so fmtDur renders '0h 00m'. Completed entries do show their duration.

Fix (ags/windows/soltty/service.ts refreshRecent): add entrySeconds() that uses the numeric 'duration' when >0, else derives seconds from start->end (or start->now for a still-running entry); fmtDur formats seconds cleanly (Hh MMm / Mm / <1m / dash). So every recent row shows a real duration.

Part of feature bean lkasper-hyprland-9ura (AGS shell).
