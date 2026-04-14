## Why

The bar's right pill shows status icons (BT, WiFi, Volume, CPU, Battery) but clicking them does nothing useful. Users need a way to quickly toggle radios, adjust volume/brightness, manage WiFi networks, and manage Bluetooth devices without opening a terminal or external app. This is Phase 3 of the AGS desktop migration.

## What Changes

- New unified quick-settings dropdown panel window, anchored below the right pill
- Opens when any right pill icon is clicked except tray and notification bell
- Trigger icons (BT, WiFi, Volume, CPU, Battery) get a lighter background highlight when panel is open
- Bluetooth section: pill-switch toggle + expandable paired device list with Connect/Disconnect/Forget actions per device
- WiFi section: pill-switch toggle + expandable network list with Connect/Disconnect, inline password entry for secured networks
- Volume section: slider + output device selector
- Brightness section: slider
- BT/WiFi sections collapsed by default (show current connection + chevron), expand on section header click
- Click outside or toggle icon to close panel
- Solid opaque background matching pill styling
- **BREAKING**: Notification bell moves from between CPU and Battery to far right of right pill (after Battery). Requires reordering in `right-pill.tsx`.
- Bar icon click handlers updated: BT/WiFi/Volume/CPU/Battery onClick toggles the quick-settings panel instead of current no-op or TUI launch

## Capabilities

### New Capabilities
- `quick-settings-panel`: The dropdown panel window, its layout, open/close behavior, positioning, icon highlight state, and overall panel styling
- `quick-settings-bluetooth`: Bluetooth toggle, device list (collapsed/expandable), per-device Connect/Disconnect/Forget actions using astal-bluetooth
- `quick-settings-wifi`: WiFi toggle, network list (collapsed/expandable), Connect/Disconnect actions, inline password entry for secured networks using astal-network
- `quick-settings-audio`: Volume slider with output device selector using astal-wireplumber
- `quick-settings-brightness`: Brightness slider using sysfs or brightnessctl

### Modified Capabilities
<!-- No existing main specs to modify -->

## Impact

- **AGS project** (`ags/`): New `windows/quick-settings/` directory with index.tsx + section components. New brightness service or utility.
- **Bar components** (`ags/windows/bar/`): `right-pill.tsx` reordered (bell to far right). BT/WiFi/Volume/CPU/Battery onClick handlers changed to toggle panel. Icon highlight CSS class when panel open.
- **Theme engine** (`ags/services/theme.ts`): `generateGtkCss()` extended with quick-settings panel styles, highlight states, pill-switch styles, slider styles, device list styles.
- **Nix module** (`modules/home-manager/ags.nix`): May need `brightnessctl` in packages. No new Astal library deps (BT/Network/WirePlumber already included).
- **Hyprland config**: May need layer rule for quick-settings window (blur, animation).
