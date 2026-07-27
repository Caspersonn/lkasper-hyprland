---
# lkasper-hyprland-2g7g
title: Power profile indicator in the bar (icon by active profile)
status: completed
type: feature
priority: normal
created_at: 2026-07-22T11:25:20Z
updated_at: 2026-07-27T05:10:18Z
---

Add an icon-only indicator to the right of the temperature in the bar system-stats module, showing the active power profile. Icons: power-saver=󰾆, balanced=󰾅, performance=󰓅. No text. Should update when the profile changes (power-profiles-daemon). Read the active profile via D-Bus (no subprocess/PATH dependency).

## Implemented
ags/windows/bar/system-stats.tsx: icon-only power-profile indicator appended to the right of stat-temp. Reads net.hadess.PowerProfiles ActiveProfile via a Gio.DBusProxy on the system bus (reactive via g-properties-changed; no subprocess). PROFILE_ICON maps power-saver=󰾆 / balanced=󰾅 / performance=󰓅; hidden if the daemon is unavailable or the profile is unknown. style.scss: .stat-power-icon ($w-dim, 16px). Build green; bundle has the D-Bus name, ActiveProfile, all 3 glyphs, stat-power. Awaiting live verify.

## Bug + fix: indicator froze after ~10-20 profile changes
Root cause: the Gio.DBusProxy was a function-local const with no strong JS ref kept, so gjs garbage-collected it after a GC cycle, silently dropping its PropertiesChanged subscription (no error logged) -> icon stuck on the last value.
Proven with a standalone gjs test forcing System.gc() while cycling the profile: unreferenced proxy received 0/15 change signals; a module-scope-referenced proxy received 15/15.
Fix: hold the proxy in a module-level 'powerProxy' variable so it is never collected. Rebuilt; bundle has powerProxy. Awaiting live re-verify.
