## Why

The bar's right pill shows status icons (BT, WiFi, Volume, CPU, Battery) but clicking them does nothing useful. Users need a way to quickly toggle radios, adjust volume/brightness, manage WiFi networks, and manage Bluetooth devices without opening a terminal or external app. This is Phase 3 of the AGS desktop migration.

## What Changes

- New unified control center panel window (PopupWindow overlay), anchored below the right pill
- Opens when any right pill icon is clicked except tray and notification bell
- Trigger icons (BT, WiFi, Volume, CPU, Battery) get a lighter background highlight when panel is open
- **QuickActions row**: user avatar (from ~/.face), username, uptime display, lock button (launches hyprlock), logout button (opens logout menu)
- **Tiles grid**: 2-column FlowBox of toggleable Tile widgets with icon, title, description, state, and optional arrow for drill-down pages
  - Network tile: WiFi/wired toggle + SSID/status → Network page (devices, WiFi APs, connect/disconnect, inline password)
  - Bluetooth tile: adapter power toggle + device name/battery → Bluetooth page (paired/discovered devices, connect/disconnect/forget)
  - Do Not Disturb tile: toggle notification muting via astal-notifd (no detail page)
  - Night Light tile: toggle hyprsunset + temperature → NightLight page (temperature + gamma sliders)
- **Sliders**: button + slider + "more" button → detail pages
  - Volume slider: mute toggle + default speaker + "more" → Sound page (output device selector, per-app streams)
  - Brightness slider: brightness button + backlight slider + "more" → Brightness page (multi-backlight control)
- **Inline Pages system**: Tiles and sliders drill down into detail pages within the panel via Gtk.Revealer slide-down animation. One page open at a time per zone.
- **Reusable widgets**: Tile (GObject-registered), Page (detail view class), Pages (Revealer manager), PageButton (list item)
- Click outside or Escape to close panel
- Solid opaque background matching pill styling
- **BREAKING**: Notification bell moves from between CPU and Battery to far right of right pill (after Battery). Requires reordering in `right-pill.tsx`.
- Bar icon click handlers updated: BT/WiFi/Volume/CPU/Battery onClick toggles the quick-settings panel

## Capabilities

### New Capabilities
- `quick-settings-panel`: The control center window, layout (QuickActions → Tiles → Sliders), open/close behavior, positioning, trigger icon highlight state, and panel styling
- `quick-settings-quick-actions`: QuickActions row with user avatar, username, uptime, lock button, logout button
- `quick-settings-widgets`: Reusable Tile widget (GObject-registered toggle tile), Page class (header/content/buttons detail view), Pages manager (Revealer-based open/close/toggle), PageButton helper
- `quick-settings-network`: Network toggle tile (WiFi/wired on/off, SSID/status, arrow) + Network detail page (device list, WiFi AP list, connect/disconnect, inline password for secured)
- `quick-settings-bluetooth`: Bluetooth toggle tile (adapter power, device name/battery, arrow) + Bluetooth detail page (paired/discovered devices, connect/disconnect/forget actions)
- `quick-settings-dnd`: Do Not Disturb toggle tile (notification muting via astal-notifd, toggleOnClick, no detail page)
- `quick-settings-night-light`: NightLight toggle tile (hyprsunset toggle, temperature display, arrow) + NightLight settings page (temperature + gamma sliders). Hidden when hyprsunset not installed.
- `quick-settings-audio`: Volume slider (mute toggle, default speaker binding, "more" button) + Sound detail page (output device selector, per-app audio stream sliders)
- `quick-settings-brightness`: Brightness slider (backlight binding, "more" button) + Brightness detail page (multi-backlight control). Hidden gracefully when unsupported.

### Modified Capabilities
<!-- No existing main specs to modify -->

## Impact

- **AGS project** (`ags/`): New `windows/quick-settings/` directory with index.tsx, quick-actions.tsx, sliders.tsx, `widgets/` (tile.tsx, page.tsx, pages.tsx), and `modules/` (tile and page files per feature). New brightness service or utility.
- **Bar components** (`ags/windows/bar/`): `right-pill.tsx` reordered (bell to far right). BT/WiFi/Volume/CPU/Battery onClick handlers changed to toggle panel. Icon highlight CSS class when panel open.
- **Theme engine** (`ags/services/theme.ts`): `generateGtkCss()` extended with control center styles: panel container, QuickActions, tile grid, tile states (enabled/disabled), slider rows, page views, PageButton list items, trigger highlight states.
- **Nix module** (`modules/home-manager/ags.nix`): Add `brightnessctl` and `hyprsunset` in packages. No new Astal library deps (BT/Network/WirePlumber/Notifd already included).
- **Hyprland config**: May need layer rule for quick-settings window (blur, animation).
