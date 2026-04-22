## Context

Phase 1 established the split-pill AGS bar and Phase 2 added runtime theming. The right pill now contains actionable status items (BT, WiFi, Volume, CPU, Battery, Bell), but there is no integrated control surface for radio management, network switching, or output selection.

For Phase 3, the desired UX is a control center panel (inspired by colorshell) with a tile + inline page drill-down pattern. The panel contains a QuickActions header, a 2-column tile grid for system toggles, sliders for volume/brightness, and detail pages that reveal inline via Revealer animation when tiles or slider "more" buttons are clicked.

Technical constraints:
- AGS v2 GTK4 + Astal stack is already in place (`astal-bluetooth`, `astal-network`, `astal-wireplumber`, `astal-notifd` are available)
- The project uses runtime-generated GTK CSS from `ags/services/theme.ts`; control center styles must be added there
- No Astal brightness library exists, so brightness must be implemented via sysfs/CLI integration
- Night Light requires `hyprsunset` (Hyprland ecosystem tool)
- The panel should behave as a shell surface (PopupWindow overlay, outside-click close), not a simple in-bar widget

## Goals / Non-Goals

**Goals:**
- Add one unified control center panel below the right side of the bar
- Open the panel from BT/WiFi/Volume/CPU/Battery icons; exclude tray and notification bell
- QuickActions row with user avatar, username, uptime, lock, and logout buttons
- Tile grid with Network, Bluetooth, DND, and NightLight toggles
- Tiles with optional arrow drill-down into inline detail pages
- Volume slider with "more" button opening Sound device page
- Brightness slider with "more" button opening Brightness detail page
- Build reusable Tile, Page, Pages, and PageButton widgets (colorshell pattern)
- Keep styling consistent with the existing capsule-based visual system and runtime theme engine

**Non-Goals:**
- Build notification center or notification history in this phase (Phase 5)
- Implement full WPA-Enterprise UI workflow (Phase 3 targets common WPA-PSK/open network flows)
- Introduce a new design system or external UI framework
- Implement full multi-monitor panel orchestration (focus on single active monitor)
- Add microphone slider (scope limited to volume + brightness)

## Decisions

### 1. Panel architecture: PopupWindow overlay with positioned inner panel

Implement the control center as a full-screen `PopupWindow` overlay (anchored to all edges) with transparent outer area and an inner panel aligned to top-right using margins. This is the same pattern colorshell uses for its control center.

**Why:** PopupWindow provides built-in outside-click dismissal, Escape-key handling, and keyboard capture. The full-screen overlay makes dismiss behavior reliable.

**Alternative considered:** A smaller `TOP|RIGHT` anchored popup. Rejected because outside-click close is harder to implement reliably without an overlay surface.

### 2. Close behavior: gesture-based outside click + Escape

PopupWindow handles this natively:
- Clicking outside the inner panel closes it
- Escape key closes the panel
- Clicking a trigger icon again toggles it closed

**Why:** Layer-shell windows do not provide built-in popover dismissal semantics. PopupWindow encapsulates this pattern.

### 3. Control center layout: QuickActions → Tiles → Sliders (with inline Pages)

The panel is structured vertically:
1. QuickActions row (user info + action buttons)
2. Tiles grid (2-column FlowBox of toggleable tiles)
3. Sliders (volume + brightness with "more" buttons)
4. Pages appear inline below their parent zone (tiles or sliders) via Revealer

**Why:** This is the colorshell control center pattern. It provides a compact surface for common toggles and sliders, with drill-down for advanced settings without leaving the panel.

### 4. Tile + inline Page drill-down pattern

Each tile is a GObject-registered widget with icon toggle area, title, description, state, and optional arrow. Clicking the arrow (or content area) opens a detail Page inline within the same panel zone via Gtk.Revealer slide-down animation. Only one page can be open at a time per zone.

**Why:** This is more compact and contextual than flat collapsible sections. Users see the tile grid at a glance and drill down only when needed. The Revealer animation provides smooth transitions.

**Alternative considered:** Flat collapsible sections (original spec design). Rejected as less compact and less intuitive for toggle+detail workflows.

### 5. Two Pages zones: tiles and sliders each manage their own

Tiles have their own `Pages` instance, sliders have their own. This means a tile detail page and a slider detail page can theoretically coexist, and toggling within a zone only affects that zone.

**Why:** Matches colorshell's approach. Prevents volume device selection from closing a Bluetooth device list.

### 6. Right-pill trigger policy and ordering

Panel opens on click from BT/WiFi/Volume/CPU/Battery icons. Tray and bell do not open quick settings. Notification bell is at far right after battery.

**Why:** Matches user interaction decisions and keeps notification behavior decoupled from quick settings.

### 7. Trigger icon visual state: lighter pill-shade highlight

When panel is open, trigger icons use a lighter shade of the pill background, not accent color.

**Why:** Keeps emphasis subtle and consistent with current visual language.

### 8. Bluetooth tile + page via astal-bluetooth

Tile: adapter powered toggle, shows connected device name + battery percentage, arrow opens Bluetooth page.
Page: lists known devices (paired/trusted) and discovered devices, with connect/disconnect/forget actions per device. Connecting state shows spinner. Header button to start/stop discovery.

**Why:** Native Astal Bluetooth APIs expose everything required. Follows colorshell's `TileBluetooth` + `BluetoothPage` pattern.

### 9. Network tile + page via astal-network

Tile: WiFi/wired toggle, shows SSID or connection status, arrow opens Network page.
Page: lists network devices (interfaces), WiFi access points with connect/disconnect, inline password entry for secured unsaved networks, auth failure feedback.

**Why:** Follows colorshell's `TileNetwork` + `PageNetwork` pattern. Handles both WiFi and wired via `AstalNetwork.Primary`.

### 10. DND tile via astal-notifd

Simple toggle tile with `toggleOnClick` — no arrow, no detail page. Toggles `dontDisturb` on the notifd instance. Shows "Enabled"/"Disabled" description.

**Why:** DND is a simple boolean toggle that doesn't need a detail page.

### 11. NightLight tile + page via hyprsunset

Tile: toggles hyprsunset identity mode, shows current temperature when active, arrow opens NightLight page. Hidden when hyprsunset is not installed.
Page: temperature slider (min/max range) + gamma slider.

**Why:** Follows colorshell's `TileNightLight` + `PageNightLight` pattern.

### 12. Volume slider + Sound page via astal-wireplumber

Slider: mute toggle button + slider bound to default speaker endpoint + "more" button → Sound page.
Sound page: output device selector (list speakers, highlight default, click to switch) + per-app audio stream sliders (app icon + name + volume slider).

**Why:** Aligns with current bar audio implementation. Sound page follows colorshell's `PageSound` pattern.

### 13. Brightness slider + page via sysfs/brightnessctl

Slider: brightness icon button + slider bound to default backlight + "more" button → Brightness page. Hidden when no backlight available.
Brightness page: per-backlight device sliders (when multiple displays), default backlight selector.

**Why:** No Astal brightness library available; sysfs + brightnessctl is the established approach. Follows colorshell's `PageBacklight` pattern.

### 14. QuickActions row

User avatar (from ~/.face if exists), username, uptime (polled), lock button (launches hyprlock, closes panel), logout button (opens logout menu, closes panel).

**Why:** Provides quick access to session actions. Follows colorshell's QuickActions pattern but scoped to lock + logout only (no color picker, screenshot, or wallpaper picker in this phase).

### 15. Monitor strategy: focused/single monitor

Panel opens on the focused monitor. No full per-monitor window orchestration in this phase.

**Why:** Reduces scope while leaving room for multi-monitor expansion later.

## Risks / Trade-offs

- [Position drift with bar size changes] Fixed top margin may need tuning if bar height changes. → Mitigation: centralize bar/panel spacing constants.
- [WiFi password UX edge cases] Wrong password and reconnect flows need clear inline error states. → Mitigation: map connection failure reasons to visible user feedback.
- [Bluetooth action race conditions] Device connect/disconnect is async and transient. → Mitigation: disable action buttons and show spinner while connecting/disconnecting.
- [Brightness backend variability] Some systems expose different backlight devices/permissions. → Mitigation: detect availability; hide brightness section gracefully when unsupported.
- [hyprsunset availability] NightLight tile depends on hyprsunset being installed. → Mitigation: check availability at runtime and hide tile when not present.
- [Future multi-monitor complexity] Simple focused-monitor approach may not satisfy all setups. → Mitigation: keep window creation encapsulated for later expansion.

## Migration Plan

1. Create reusable widget foundations: Tile, Page, Pages, PageButton under `ags/windows/quick-settings/widgets/`.
2. Create control center PopupWindow scaffold in `ags/windows/quick-settings/index.tsx` with layout zones (QuickActions → Tiles → Sliders).
3. Implement QuickActions row (user info + lock + logout).
4. Implement tile modules: Network, Bluetooth, DND, NightLight tiles in `modules/`.
5. Implement tiles container with FlowBox grid.
6. Implement sliders (Volume, Brightness) with "more" buttons.
7. Implement detail page modules: Network, Bluetooth, NightLight, Sound, Brightness pages in `modules/`.
8. Wire right-pill click handlers to open/close panel and apply trigger highlight.
9. Extend `generateGtkCss()` in `ags/services/theme.ts` with control center styles.
10. Update Nix dependencies (brightnessctl, hyprsunset).
11. Verify all flows: tiles, sliders, pages, open/close, styling.

Rollback strategy: disable panel open handlers and remove quick-settings window from app entry points without affecting bar/theme engine core.

## Open Questions

- Should CPU/Battery eventually expose controls in this panel, or remain open-only triggers permanently?
- Should WiFi scanning be manual (refresh button) or periodic while Network page is expanded?
- For multi-monitor users, should panel follow focused monitor or the monitor containing the clicked bar instance?
