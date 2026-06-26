## 1. Foundations

- [x] 1.1 Add `jetbrains-mono` Nerd Font to the home-manager font packages and confirm it is available to ags (font family `JetBrainsMono Nerd Font`)
- [x] 1.2 Add `hyprsunset` to the hyprland home-manager packages (night-light backend)
- [x] 1.3 Add `$base-dark: #1d2021;` scss var near the base16 vars in `ags/style.scss`; confirm every other mockup colour maps to an existing base16 var
- [x] 1.4 Add island base styling in `ags/style.scss`: `.island` (bg `rgba($base-dark, 0.80)`, border 1px `rgba($subtext0, 0.16)`, border-radius 14px, box-shadow `0 8px 24px rgba(0,0,0,0.38)`, height 42px, padding), `.island-divider` (1px vertical `rgba($subtext0, 0.18)`), and shared hover bg `rgba($fg, 0.10)`
- [x] 1.5 Set the bar font family to JetBrains Mono Nerd Font in `ags/style.scss`

## 2. Bar shell + three islands

- [x] 2.1 Rewrite `ags/windows/bar/index.tsx` layout: keep per-monitor transparent layer-shell window + hotplug `For`, replace the three `.pill` boxes with three `.island` boxes (left / center / right) at 62px bar height
- [x] 2.2 Left island composition: launcher | divider | `<Workspaces/>` | divider | `<ActiveWindow/>`
- [x] 2.3 Center island composition: `<Clock/>` (calendar trigger)
- [x] 2.4 Right island composition: `<Media/>` | divider | `<Weather/>` | divider | `<SystemStats/>` | divider | `<Tray/>` | divider | `<QuickControls/>` | divider | `<NotificationBell/>` | `<PowerButton/>`
- [x] 2.5 Remove the dead `Media` import handling and any leftover pill-only wiring

## 3. Left island widgets

- [x] 3.1 App launcher button in `ags/windows/bar/index.tsx` (or a small `launcher.tsx`): NixOS Nerd Font glyph, `onClicked` execs `walker`
- [x] 3.2 Rewrite `ags/windows/bar/workspaces.tsx` to V2 dynamic existing-only workspaces: render only existing workspaces, focused = monitor-tint bg + monitor-colour number + glowing underline (CSS box-shadow), occupied = faint bg `rgba($fg,0.07)` + underline, empty = dim number no underline
- [x] 3.3 Keep the deterministic base16 monitor→accent hash from the archived change; underline = centered child ~62% width, 2px, monitor-accent colour; left-click execs `hyprctl dispatch workspace <id>`
- [x] 3.4 Remove the right-click screen-picker popover and its scss (`.screen-picker`/`.screen-row`)
- [x] 3.5 Keep representative app themed-icon(s) per workspace (current approach, no class→glyph table)
- [x] 3.6 Create `ags/windows/bar/active-window.tsx`: AstalHyprland `focusedClient` themed icon + ellipsized title (max ~280px); hide or placeholder when no client
- [x] 3.7 Style workspaces + active-window per mockup in `ags/style.scss`

## 4. Center island: clock + calendar popover

- [x] 4.1 Update `ags/windows/bar/clock.tsx`: calendar glyph (`$yellow`) + time (16px) + 1px divider + date (`$base-dark`-on-light `#d5c4a1`); drop seconds from bar face
- [x] 4.2 Create `ags/windows/bar/calendar.tsx` Gtk.Popover parented to the clock button: big time + seconds, date, month-nav chevrons (offset state), 7-col day grid (42 cells), today highlighted accent; auto-dismiss
- [x] 4.3 Style calendar popover in `ags/style.scss`

## 5. Right island: media

- [x] 5.1 Create `ags/windows/bar/media.tsx` in-bar widget (reuse AstalMpris): gradient art square + ellipsized title/artist (max ~118px) + 3-bar EQ animating only when playing (`@keyframes asgEq`); hide when no player; click opens player popover
- [x] 5.2 Create the media player popover (in `media.tsx` or `media-player.tsx`): big art, NOW PLAYING label, title/artist/album, seek bar + elapsed/total, transport (shuffle/prev/play-pause orange circle/next/repeat) via AstalMpris
- [x] 5.3 Style media widget + popover + EQ keyframes in `ags/style.scss`

## 6. Right island: weather

- [x] 6.1 Create `ags/windows/bar/weather.tsx`: fetch `wttr.in/?format=j1` over GLib/AstalIO HTTP on a 15-min GLib timeout (server-side IP geolocation), cache last payload, render stale on failure
- [x] 6.2 Map WWO weather codes → Nerd Font glyphs; in-bar widget = glyph + temp + city
- [x] 6.3 Create the weather popover: city/condition, big icon + temp, Feels/Humidity/Wind tiles, 5-slot Next-Hours forecast row
- [x] 6.4 Style weather widget + popover in `ags/style.scss`

## 7. Right island: system stats

- [x] 7.1 Create `ags/windows/bar/system-stats.tsx` (reuse `cpu.tsx` pattern): 2s GLib timeout poll — CPU % from `/proc/stat` jiffy deltas, RAM % from `/proc/meminfo`, temp from `/sys/class/thermal/thermal_zone*/temp`
- [x] 7.2 Render CPU (green glyph + % + thin animated bar), RAM (purple glyph + % + bar), temp (red thermometer glyph + °); hide temp when no sensor resolves
- [x] 7.3 Style system-stats cluster + progress bars in `ags/style.scss`

## 8. Right island: tray + quick controls + bell + power

- [x] 8.1 Update `ags/windows/bar/tray.tsx`: monochrome glyph row (`$subtext0`), hover → accent; keep AstalTray themed item icons
- [x] 8.2 Create `ags/windows/bar/quick-controls.tsx`: brightness + volume + wifi + bt glyphs + battery icon + % (reuse existing volume/battery/network/bluetooth logic); click opens control center popover
- [x] 8.3 Update notification bell widget: red count badge; click opens notifications popover; keep `toggle-notifications` IPC working
- [x] 8.4 Create `ags/windows/bar/power.tsx`: red-tinted power glyph button; opens power menu popover
- [x] 8.5 Style tray / quick-controls / bell badge / power button in `ags/style.scss`

## 9. Control center popover

- [x] 9.1 Create `ags/windows/bar/control-center.tsx` Gtk.Popover cannibalizing `ags/windows/QuickSettings/` logic: 2×2 toggle grid (on = accent-tint tile, off = surface tile)
- [x] 9.2 Toggles: Wi-Fi (AstalNetwork), Bluetooth (AstalBluetooth), DND (AstalNotifd dontDisturb, same state as `toggle-dnd`), Night Light (`hyprsunset` exec); each with sub-label (SSID / device / state)
- [x] 9.3 Volume slider (AstalWp sink) + brightness slider (`brightnessctl get/set/max` exec) as Gtk.Scale
- [x] 9.4 Power-profile 3-segment control (`powerprofilesctl get/set`: power-saver/balanced/performance → Saver/Balanced/Turbo)
- [x] 9.5 Style control center popover + toggle tiles + sliders + segmented control in `ags/style.scss`

## 10. Notifications popover + power menu

- [x] 10.1 Convert notification center to a Gtk.Popover anchored to the bell (reuse AstalNotifd wiring from `ags/windows/notifications/center.tsx`): header + Clear-all, list of cards (per-app icon chip, title, time, body) + per-item dismiss + "You're all caught up" empty state
- [x] 10.2 Remove the slide-in `window.notification-center` layer-shell window; keep `notifications/popups.ts` toasts untouched; keep `toggle-notifications` IPC opening/closing the popover
- [x] 10.3 Create the power menu popover (in `power.tsx`): Lock (`hyprlock`), Suspend (`systemctl suspend`), Log out (`hyprctl dispatch exit`), Reboot (`systemctl reboot`), Shut down (`systemctl poweroff`) rows with colored glyphs
- [x] 10.4 Style notifications popover + power menu in `ags/style.scss`

## 11. Cleanup + retired surfaces

- [x] 11.1 Delete `ags/windows/QuickSettings/` (quick-settings.tsx, quick-settings-panel.tsx) and remove its imports/wiring
- [x] 11.2 Fold the needed widget logic into combined widgets: `volume.tsx`, `network.tsx`, `bluetooth.tsx`, `battery.tsx` → `quick-controls.tsx`; `cpu.tsx` → `system-stats.tsx`
- [x] 11.3 Delete the standalone widget files once their logic is folded in: `ags/windows/bar/{cpu,wifi,bluetooth,network,volume,battery}.tsx` (no longer referenced from `index.tsx`)
- [x] 11.4 Remove obsolete pill scss (`.pill`, left/center/right-pill margins) from `ags/style.scss`
- [x] 11.5 Confirm IPC keybinds still resolve: `toggle-notifications`, `toggle-dnd`, `toggle-bars`

## 12. Verification

- [x] 12.1 `nix fmt` the touched Nix files
- [x] 12.2 `nix flake check`
- [ ] 12.3 Manual: launch ags, verify all three islands render, every popover opens/auto-dismisses, workspaces reflect focus/occupancy with monitor accent, weather/stats populate, control center toggles + sliders work, notifications + power menu act correctly
