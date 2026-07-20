---
# lkasper-hyprland-4612
title: Launcher-spawned apps die when the AGS bar crashes (not detached)
status: completed
type: bug
priority: normal
created_at: 2026-07-21T09:48:13Z
updated_at: 2026-07-21T10:14:06Z
---

Apps launched from the custom AGS launcher (item.app.launch() -> Gio GAppInfo.launch) are spawned inside the lkasper-shell systemd user service's cgroup. When the shell crashes/restarts, systemd kills the whole control group, so every app started via the launcher dies too.

Fix: launch apps OUTSIDE the AGS cgroup so they survive a shell crash - delegate the spawn to the compositor/session (Hyprland exec via IPC, or uwsm app / systemd-run --user --scope) instead of Gio launch.

Part of feature bean lkasper-hyprland-9ura (AGS shell).
