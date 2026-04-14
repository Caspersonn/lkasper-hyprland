## 1. Quick-Settings Window Scaffold

- [x] 1.1 Create `ags/windows/quick-settings/index.tsx` with one unified overlay `Astal.Window` (full-screen transparent outer container + top-right positioned inner panel)
- [x] 1.2 Implement panel open/close state in `ags/windows/quick-settings/index.tsx` and export toggle helpers used by bar modules
- [x] 1.3 Implement outside-click and Escape-to-close behavior in `ags/windows/quick-settings/index.tsx` using GTK event controllers/gestures
- [x] 1.4 Register quick-settings window from `ags/app.ts` so it is available alongside the bar

## 2. Right-Pill Integration

- [x] 2.1 Update `ags/windows/bar/right-pill.tsx` to reorder modules so notification bell is the far-right item after battery
- [x] 2.2 Update click handlers in `ags/windows/bar/right-pill.tsx` so BT/WiFi/Volume/CPU/Battery toggle the quick-settings panel and tray/bell do not
- [x] 2.3 Add trigger-highlight state plumbing between `ags/windows/bar/right-pill.tsx` and `ags/windows/quick-settings/index.tsx`

## 3. Bluetooth Section

- [x] 3.1 Create `ags/windows/quick-settings/bluetooth.tsx` with collapsed header (default) and expandable device list using `astal-bluetooth`
- [x] 3.2 Implement Bluetooth pill-switch toggle in `ags/windows/quick-settings/bluetooth.tsx` for adapter power on/off
- [x] 3.3 Implement per-device actions in `ags/windows/quick-settings/bluetooth.tsx`: Connect, Disconnect, Forget
- [x] 3.4 Add busy/transition-safe button disable states in `ags/windows/quick-settings/bluetooth.tsx` while devices are connecting/disconnecting

## 4. WiFi Section

- [x] 4.1 Create `ags/windows/quick-settings/wifi.tsx` with collapsed header (default) and expandable access-point list using `astal-network`
- [x] 4.2 Implement WiFi pill-switch toggle in `ags/windows/quick-settings/wifi.tsx` for enabled/disabled state
- [x] 4.3 Implement Connect/Disconnect actions in `ags/windows/quick-settings/wifi.tsx` using `ap.activate(null)` and WiFi disconnect behavior
- [x] 4.4 Implement inline password entry in `ags/windows/quick-settings/wifi.tsx` for secured unsaved networks using `ap.activate(password)`
- [x] 4.5 Implement WiFi auth failure UI state in `ags/windows/quick-settings/wifi.tsx` based on activation errors / `wifi.state_changed`

## 5. Audio and Brightness Sections

- [x] 5.1 Create `ags/windows/quick-settings/volume.tsx` with volume slider bound to default speaker endpoint from `astal-wireplumber`
- [x] 5.2 Implement output-device selector in `ags/windows/quick-settings/volume.tsx` to switch default speaker endpoint
- [x] 5.3 Create `ags/services/brightness.ts` to read current brightness from `/sys/class/backlight` and write updates via `brightnessctl`
- [x] 5.4 Create `ags/windows/quick-settings/brightness.tsx` and bind it to `ags/services/brightness.ts`
- [x] 5.5 Implement graceful unsupported-hardware behavior in `ags/windows/quick-settings/brightness.tsx` (hidden or disabled section)

## 6. Styling and Theme Integration

- [x] 6.1 Update `ags/services/theme.ts` `generateGtkCss()` with quick-settings panel container styles (opaque panel, radius, spacing)
- [x] 6.2 Update `ags/services/theme.ts` with trigger highlight styles that use a lighter shade of the pill background
- [x] 6.3 Update `ags/services/theme.ts` with BT/WiFi expandable section styles, chevrons, list row states, inline password and error styles
- [x] 6.4 Update `ags/services/theme.ts` with volume/brightness slider styles and section divider styles

## 7. Nix and Dependency Updates

- [x] 7.1 Update `modules/home-manager/ags.nix` to ensure `brightnessctl` is available at runtime for `ags/services/brightness.ts`
- [x] 7.2 Update `openspec/architecture.md` Phase 3 notes if needed to match final implemented behavior (single panel triggers, collapsed sections, inline password)

## 8. Verification

- [x] 8.1 Run `nix fmt`
- [x] 8.2 Run `nix flake check`
- [ ] 8.3 Launch shell and verify panel opens from BT/WiFi/Volume/CPU/Battery and does not open from tray/bell
- [ ] 8.4 Verify right-pill order visually confirms bell is far right after battery
- [ ] 8.5 Verify Bluetooth flows: power toggle, connect/disconnect, forget
- [ ] 8.6 Verify WiFi flows: toggle, connect open/saved networks, inline password for secured network, auth failure feedback
- [ ] 8.7 Verify audio flows: volume slider and output selector
- [ ] 8.8 Verify brightness slider works on supported hardware and degrades gracefully when unsupported
- [ ] 8.9 Verify click-outside and Escape close behavior
- [ ] 8.10 Verify trigger highlight appears only while panel is open
