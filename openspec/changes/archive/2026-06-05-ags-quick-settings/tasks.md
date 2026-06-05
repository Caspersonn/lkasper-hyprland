## 1. Reusable Widget Foundations

- [x] 1.1 Create `ags/windows/quick-settings/widgets/tile.tsx` with GObject-registered Tile widget (icon, title, description, state, hasArrow, toggleOnClick, enable/disable/signals)
- [x] 1.2 Create `ags/windows/quick-settings/widgets/page.tsx` with Page class (id, title, description, headerButtons, bottomButtons, content, create()) and PageButton helper component
- [x] 1.3 Create `ags/windows/quick-settings/widgets/pages.tsx` with Pages manager (Revealer-based open/close/toggle, one page at a time, slide-down animation)

## 2. Control Center Window Scaffold

- [x] 2.1 Create `ags/windows/quick-settings/index.tsx` with PopupWindow overlay (full-screen transparent outer, inner panel top-right) containing vertical layout: QuickActions → Tiles → Sliders
- [x] 2.2 Register quick-settings window from `ags/app.ts` so it is available alongside the bar

## 3. QuickActions Row

- [x] 3.1 Create `ags/windows/quick-settings/quick-actions.tsx` with user avatar (from ~/.face), username, hostname, polled uptime, lock button, logout button
- [x] 3.2 Implement lock button (close panel + launch hyprlock) and logout button (close panel + open logout menu)

## 4. Tile Modules

- [x] 4.1 Create `ags/windows/quick-settings/modules/network-tile.tsx` with WiFi/wired toggle, SSID/status display, connection state icon, arrow → Network page
- [x] 4.2 Create `ags/windows/quick-settings/modules/bluetooth-tile.tsx` with adapter power toggle, connected device name/battery, connection state icon, arrow → Bluetooth page
- [x] 4.3 Create `ags/windows/quick-settings/modules/dnd-tile.tsx` with toggleOnClick DND toggle via astal-notifd, enabled/disabled description, no arrow
- [x] 4.4 Create `ags/windows/quick-settings/modules/night-light-tile.tsx` with hyprsunset identity toggle, temperature display, arrow → NightLight page, hidden when hyprsunset not installed

## 5. Tiles Container

- [x] 5.1 Wire tiles into a 2-column FlowBox grid in `ags/windows/quick-settings/index.tsx` with a tiles Pages instance for drill-down pages

## 6. Sliders

- [x] 6.1 Create `ags/windows/quick-settings/sliders.tsx` with volume slider row (mute button + slider bound to default speaker + "more" button → Sound page)
- [x] 6.2 Add brightness slider row (brightness button + slider bound to default backlight + "more" button → Brightness page), hidden when no backlight available
- [x] 6.3 Wire sliders Pages instance for detail pages

## 7. Detail Page Modules

- [x] 7.1 Create `ags/windows/quick-settings/modules/network-page.tsx` with device list, WiFi AP list (connect/disconnect), inline password for secured networks, auth failure state, scan button, "More Settings" bottom button
- [x] 7.2 Create `ags/windows/quick-settings/modules/bluetooth-page.tsx` with known devices section, discovered devices section, connect/disconnect/forget actions, connecting spinner, start/stop discovery header button, "More Settings" bottom button
- [x] 7.3 Create `ags/windows/quick-settings/modules/night-light-page.tsx` with temperature slider and gamma slider bound to hyprsunset
- [x] 7.4 Create `ags/windows/quick-settings/modules/sound-page.tsx` with output device selector (speakers list with selected indicator) and per-app audio stream sliders
- [x] 7.5 Create `ags/windows/quick-settings/modules/brightness-page.tsx` with per-backlight device sliders and default backlight selector (when multiple exist)

## 8. Right-Pill Integration

- [x] 8.1 Update `ags/windows/bar/right-pill.tsx` to reorder modules so notification bell is the far-right item after battery
- [x] 8.2 Update click handlers in `ags/windows/bar/right-pill.tsx` so BT/WiFi/Volume/CPU/Battery toggle the control center panel and tray/bell do not
- [x] 8.3 Add trigger-highlight state plumbing between `ags/windows/bar/right-pill.tsx` and `ags/windows/quick-settings/index.tsx`

## 9. Styling and Theme Integration

- [x] 9.1 Update `ags/services/theme.ts` `generateGtkCss()` with control center container styles (opaque panel, radius, padding, spacing)
- [x] 9.2 Update `ags/services/theme.ts` with QuickActions styles (user avatar, user-host, uptime, button row)
- [x] 9.3 Update `ags/services/theme.ts` with tile grid styles (tile background, icon area, enabled state, hover, arrow, FlowBox spacing)
- [x] 9.4 Update `ags/services/theme.ts` with slider row styles (mute button, slider, "more" button)
- [x] 9.5 Update `ags/services/theme.ts` with Page/PageButton styles (page container, header, sub-headers, page-button list items, selected state, extra-buttons, bottom-buttons)
- [x] 9.6 Update `ags/services/theme.ts` with trigger highlight styles using a lighter shade of the pill background

## 10. Nix and Dependency Updates

- [x] 10.1 Update `modules/home-manager/ags.nix` to ensure `brightnessctl` is available at runtime
- [x] 10.2 Update `modules/home-manager/ags.nix` to ensure `hyprsunset` is available at runtime

## 11. Verification

- [x] 11.1 Run `nix fmt`
- [x] 11.2 Run `nix flake check`
- [ ] 11.3 Launch shell and verify panel opens from BT/WiFi/Volume/CPU/Battery and does not open from tray/bell
- [ ] 11.4 Verify right-pill order visually confirms bell is far right after battery
- [ ] 11.5 Verify QuickActions: avatar, username, uptime, lock launches hyprlock, logout opens menu
- [ ] 11.6 Verify tiles: Network toggle + page, Bluetooth toggle + page, DND toggle, NightLight toggle + page
- [ ] 11.7 Verify sliders: volume slider + mute + Sound page device selector, brightness slider + Brightness page
- [ ] 11.8 Verify inline Pages: one page at a time per zone, Revealer animation, close behavior
- [ ] 11.9 Verify click-outside and Escape close behavior
- [ ] 11.10 Verify trigger highlight appears only while panel is open
- [ ] 11.11 Verify brightness degrades gracefully when no backlight available
- [ ] 11.12 Verify NightLight tile hidden when hyprsunset not installed
