---
# lkasper-hyprland-wdgk
title: 'OSD triggerMedia: always-true conditional with duplicated branches and stray console.log'
status: completed
type: bug
priority: normal
created_at: 2026-07-21T11:37:59Z
updated_at: 2026-07-21T11:47:32Z
---

In ags/windows/osd/controller.ts triggerMedia(), the branch `if (action === "next" || "prev")` is always true ("prev" is a truthy string literal, not a comparison), the else branch is unreachable, both branches are byte-identical apart from a leftover `console.log("Next")` debug statement.

Harmless today (branches identical) but a real latent bug + debug noise. Fixed as part of the ags cleanup (bean lkasper-hyprland-jjo9): collapsed to a single setMedia/present path and removed the console.log.
