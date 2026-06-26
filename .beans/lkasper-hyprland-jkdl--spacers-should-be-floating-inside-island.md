---
# lkasper-hyprland-jkdl
title: Spacers should be floating inside island
status: completed
type: task
priority: normal
created_at: 2026-06-26T09:52:42Z
updated_at: 2026-06-26T10:25:45Z
---

The spacers are currently going from top to bottom connect, in the original design there are floating and about 50% to 75% size in the island

Implemented by vertically centering the shared island spacers and the clock spacer, keeping them at 22px inside the 42px island height. Verified with the nested headless Hyprland/noVNC harness and screenshot /tmp/opencode/hypr-headless-vnc/bar-jkdl.png.
