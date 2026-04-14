## Context

Phase 1 established the split-pill AGS bar and Phase 2 added runtime theming. The right pill now contains actionable status items (BT, WiFi, Volume, CPU, Battery, Bell), but there is no integrated control surface for radio management, network switching, or output selection.

For Phase 3, the desired UX is a single unified quick-settings panel opened from right-pill icons (except tray and bell), with lightweight visual feedback (lighter pill-shade highlight) on trigger icons while open. Bluetooth and WiFi sections must support real device/network management, not only toggles.

Technical constraints:
- AGS v2 GTK4 + Astal stack is already in place (`astal-bluetooth`, `astal-network`, `astal-wireplumber` are available)
- The project now uses runtime-generated GTK CSS from `ags/services/theme.ts`; quick-settings styles must be added there
- No Astal brightness library exists, so brightness must be implemented via sysfs/CLI integration
- The panel should behave as a shell surface (overlay, outside-click close), not a simple in-bar widget

## Goals / Non-Goals

**Goals:**
- Add one unified quick-settings dropdown panel below the right side of the bar
- Open the panel from BT/WiFi/Volume/CPU/Battery icons; exclude tray and notification bell
- Keep BT/WiFi collapsed by default and expandable on demand
- Support Bluetooth device actions (Connect/Disconnect/Forget)
- Support WiFi network actions (Connect/Disconnect) with inline password entry for secured unsaved networks
- Add volume slider + output selector and brightness slider
- Keep styling consistent with the existing capsule-based visual system and runtime theme engine

**Non-Goals:**
- Build notification-center behavior in this phase (bell remains notification-only trigger in later phase)
- Implement full WPA-Enterprise UI workflow (Phase 3 targets common WPA-PSK/open network flows)
- Introduce a new design system or external UI framework
- Implement full multi-monitor panel orchestration in this phase (focus on single active monitor behavior)

## Decisions

### 1. Panel architecture: full-screen overlay window + positioned inner panel

Implement quick settings as a dedicated `Astal.Window` overlay anchored to all edges (`TOP|LEFT|BOTTOM|RIGHT`) with transparent outer area and an inner panel aligned to top-right using margins.

**Why:** This pattern is used successfully by both colorshell and marble-shell. It provides robust outside-click dismissal and keyboard capture while keeping positioning flexible.

**Alternative considered:** A smaller `TOP|RIGHT` anchored popup window only. Rejected because outside-click close is harder to implement reliably without an overlay surface.

### 2. Close behavior: gesture-based outside click + Escape

Use gesture handlers on outer and inner containers:
- outer click closes the panel
- inner click marks the event as inside so the panel stays open
- Escape closes panel

**Why:** Layer-shell windows do not provide built-in popover dismissal semantics.

**Alternative considered:** Focus-loss-only close. Rejected because focus behavior is less predictable with shell-layer windows and pointer interactions.

### 3. Right-pill trigger policy and ordering

Panel opens on click from BT/WiFi/Volume/CPU/Battery icons. Tray and bell do not open quick settings. Notification bell is kept at the far right after battery.

**Why:** Matches user interaction decisions and keeps notification behavior decoupled from quick settings.

### 4. Trigger icon visual state: lighter pill-shade highlight

When panel is open, trigger icons use a lighter shade of the pill background, not accent color.

**Why:** Keeps emphasis subtle and consistent with current visual language.

**Alternative considered:** Accent-color highlight. Rejected for being too strong/noisy in the right-pill cluster.

### 5. Section interaction model: collapsed headers + expandable revealers

BT and WiFi sections are collapsed by default and expand via section header/chevron. Use a shared state (`expandedSection`) so only one section expands at a time.

**Why:** Preserves compact panel height while supporting deep controls.

**Alternative considered:** Always-expanded lists. Rejected due to excessive vertical growth and clutter.

### 6. Bluetooth behavior via astal-bluetooth primitives

Use `AstalBluetooth.get_default()` with:
- adapter powered toggle
- device list rendering from `bt.devices`
- actions: `connect_device`, `disconnect_device`, `remove_device`

**Why:** Native Astal Bluetooth APIs already expose everything required for Connect/Disconnect/Forget workflows.

### 7. WiFi behavior via astal-network `AccessPoint.activate(password?)`

Use `ap.activate(null)` for open or already-saved networks and `ap.activate(password)` for secured unsaved networks. Keep password input inline in the WiFi section.

Track connection outcomes via callback errors and `wifi.state_changed` (e.g., `NEED_AUTH`, `FAILED`, `ACTIVATED`).

**Why:** Astal already wraps the NM connection creation path for WPA-PSK. This avoids duplicating raw NM setup logic for common cases.

**Alternative considered:** Always build connections manually with `NM.SimpleConnection` + settings. Rejected as unnecessary complexity for baseline Phase 3 requirements.

### 8. Audio behavior via astal-wireplumber

Use existing wireplumber objects for:
- volume slider binding to default speaker endpoint
- mute/state icon behavior
- output device selection from available speaker endpoints

**Why:** Aligns with current bar audio implementation and avoids introducing additional audio abstractions.

### 9. Brightness control via lightweight local service

Add a small brightness utility/service that reads `/sys/class/backlight/*` and writes levels via `brightnessctl`. Add `brightnessctl` package in HM dependencies.

**Why:** No Astal brightness library is available; this is the established approach in AGS shells.

### 10. Monitor strategy for this phase: focused/single monitor behavior, no full multi-instance management

For Phase 3, panel opening targets the active/focused monitor behavior. Keep implementation simple and avoid full per-monitor window orchestration unless needed by real usage.

**Why:** Reduces implementation scope and complexity while leaving room for a follow-up enhancement if multi-monitor edge cases appear.

## Risks / Trade-offs

- [Position drift with bar size changes] A fixed top margin below the bar may need tuning if bar height changes significantly with theme/font scaling. → Mitigation: centralize bar/panel spacing constants and adjust in one place.
- [WiFi password UX edge cases] Wrong password and reconnect flows need clear inline error states to avoid silent failures. → Mitigation: map `wifi.state_changed` failure reasons to visible user feedback.
- [Bluetooth action race conditions] Device connect/disconnect can be asynchronous and transient. → Mitigation: disable action buttons while device is in connecting/disconnecting state.
- [Brightness backend variability] Some systems expose different backlight devices/permissions. → Mitigation: detect availability; hide/disable brightness section gracefully when unsupported.
- [Future multi-monitor complexity] A simple focused-monitor approach may not satisfy all setups. → Mitigation: keep window creation encapsulated so `forMonitors`/`forFocusedMonitor` style expansion can be added later.

## Migration Plan

1. Add quick-settings window scaffold under `ags/windows/quick-settings/` with overlay + inner panel positioning.
2. Wire right-pill click handlers to open/close panel and apply trigger highlight class state.
3. Implement BT and WiFi collapsed sections with expandable lists and per-item actions.
4. Implement volume/output and brightness sections.
5. Extend `generateGtkCss()` in `ags/services/theme.ts` with quick-settings styles and trigger highlight styles.
6. Update Nix package dependencies (add `brightnessctl` if missing).
7. Verify open/close behavior, action flows, and styling under at least dark + light themes.

Rollback strategy: disable panel open handlers and keep existing icon behavior; remove quick-settings window from app entry points without affecting bar/theme engine core.

## Open Questions

- Should CPU/Battery eventually expose advanced controls/details in this panel, or remain open-only triggers permanently?
- Should WiFi scanning be manual (refresh button) or periodic while section is expanded?
- For multi-monitor users, should panel strictly follow focused monitor or the monitor containing the clicked bar instance once multi-bar is introduced?
