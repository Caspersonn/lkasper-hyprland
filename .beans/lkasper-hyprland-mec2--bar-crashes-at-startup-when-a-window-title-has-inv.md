---
# lkasper-hyprland-mec2
title: Bar crashes at startup when a window title has invalid UTF-8 (AstalHyprland init fails)
status: todo
type: bug
priority: high
created_at: 2026-07-30T14:40:27Z
updated_at: 2026-07-30T14:40:27Z
---

Startup crash chain observed 2026-07-30 16:35:
1. A client (BambuStudio, title 'Clicker_F\xf3sil_x1' — latin-1 0xF3 for 'ó', not UTF-8) is open.
2. Hyprland 0.55.0 passes the raw title through IPC JSON unsanitized: hyprctl -j clients/workspaces contain an invalid UTF-8 byte (verified live: 'INVALID UTF-8 at byte 1115').
3. AstalHyprland init parses that JSON with json-glib -> 'hyprland.vala:28: could not initialize: JSON data must be UTF-8 encoded' -> get_default() yields null.
4. workspaces.tsx createBinding(hypr, 'workspaces') -> JS ERROR cannot get property 'workspaces' on 'null' -> whole bar fails to build.

The portal Settings/Inhibit warnings in the same log are unrelated noise.

Workaround: close/retitle the offending window (rename the project file to ASCII), then restart the shell.
Fix options: (a) report upstream to Hyprland — IPC should sanitize titles to valid UTF-8 (regression vs sanitizeUtf8 work); (b) AstalHyprland could parse leniently; (c) defensive: shell could null-guard AstalHyprland.get_default() and degrade (no workspaces module) instead of dying.
