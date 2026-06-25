---
# lkasper-hyprland-afp0
title: Workspace→screen binding bar widget
status: completed
type: task
priority: normal
created_at: 2026-06-22T12:26:22Z
updated_at: 2026-06-25T13:21:48Z
---

Replace the bar's workspaces.tsx (dots) + clients.tsx (app-icon row) with a monitor-aware workspaces widget: render workspaces as numbers with a 2.5px underline in their bound monitor's base16 accent (deterministic hash into a base16 accent pool, no hardcoding); right-click opens a screen picker popover (symbolic device icon, model, resolution, refresh, connector from hyprctl monitors -j) that runs hyprctl dispatch moveworkspacetomonitor. Drop clients.tsx entirely. Modifies the ags-bar capability.
