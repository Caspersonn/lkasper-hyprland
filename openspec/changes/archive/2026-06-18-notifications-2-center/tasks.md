## 1. Center state & daemon binding

- [x] 1.1 Create the center's shared state (in `ags/windows/notifications/center.tsx`): `notifd` (set by `initCenter()` via `AstalNotifd.get_default()`), a `centerVisible` `createState`, exported `toggleCenter()` and `toggleDnd()`, plus reactive `createBinding(notifd, "notifications")` / `createBinding(notifd, "dontDisturb")` used in the component.
- [x] 1.2 Dead-action handling: implemented as a deterministic `restoredIds` snapshot taken in `initCenter()` (all notifications present at startup = restored), rather than a `notified`-driven live set — same outcome, no signal-ordering race. `isLive = !restoredIds.has(id)`.

## 2. Center window

- [x] 2.1 Created `ags/windows/notifications/center.tsx` exporting `NotificationCenter()`: layer `<window>` `class="notification-center"` `namespace="notification-center"`, `OVERLAY`, `anchor=TOP|BOTTOM|RIGHT`, `Exclusivity.NORMAL`, `Keymode.NONE`, shown/hidden via `visible={centerVisible}`. (Initially used an always-mapped `Revealer` slide, but the layer-shell surface didn't collapse — left a residual full-height region that also lacked the window `class` for its transparent background — so switched to toggling `visible`, which unmaps cleanly; slide animation deferred.)
- [x] 2.2 Header: a `<togglebutton>` Do Not Disturb bound to `dontDisturb` (click → `toggleDnd()`) and a Clear All `<button>` that dismisses every notification (`clearAll()` iterates a copy of `notifd.get_notifications()`).
- [x] 2.3 History: `createComputed` over the `notifications` binding grouping by `appName` (groups ordered most-recent-first, items newest-first), rendered with `<For>` over groups → group header (app + count) + `HistoryCard` per item (icon, summary, body, relative time, dismiss). In a `Gtk.ScrolledWindow`.
- [x] 2.4 Action buttons render only when `!restoredIds.has(id)`; a live action calls `notification.invoke(actionId)`.
- [x] 2.5 Empty state: a "No notifications" label shown when the list is empty (the grouped list is hidden via a `createComputed` visibility toggle).
- [x] 2.6 Click-outside-to-close (added during apply): the window spans all four anchors (full-screen); a transparent `hexpand` backdrop box left of the panel carries a `Gtk.GestureClick` whose `pressed` handler calls `toggleCenter()`. Clicks on the panel don't reach the backdrop, so only outside clicks close it.

## 3. MPRIS now-playing widget

- [x] 3.1 `CenterMedia` in `center.tsx` reuses the `pickBest`/`watch` active-player approach; shows title/artist/icon with previous / play-pause / next buttons (`AstalMpris` `previous` / `play_pause` / `next`); hidden when no player is active.

## 4. Bar bell

- [x] 4.1 Rewrote `ags/windows/bar/notifications.tsx` as a `<button>` → `toggleCenter()`; `iconName` bound to `dontDisturb` (notifications-disabled glyph under DND, bell otherwise); `.nc-badge` label shows the `notifications` count when > 0.

## 5. App wiring + IPC

- [x] 5.1 `ags/app.ts` `main()` calls `initCenter()` (first, so `notifd` is set before render) and `NotificationCenter()`.
- [x] 5.2 `ags/app.ts` `requestHandler` handles `toggle-notifications` (→ `toggleCenter()`) and `toggle-dnd` (→ `toggleDnd()`), each replying `ok`.

## 6. Keybinds

- [x] 6.1 Added `"SUPER, N, exec, ags request toggle-notifications"` and `"SUPER SHIFT, N, exec, ags request toggle-dnd"` to `modules/home-manager/_hyprland/bindings.nix`.

## 7. Styling

- [x] 7.1 Added `window.notification-center` styles to `ags/style.scss` (panel, header DND/Clear All, group headers, history cards with `max-width-chars` body bounding, media widget) plus `.nc-badge`, all from base16 variables. No hardcoded colors.

## 8. Build & verify

- [x] 8.1 Build-check: built the pinned `ags` CLI and ran `ags bundle app.ts` — exit 0 (658 KB), so the center + bell + IPC compile.
- [x] 8.2 `nix fmt modules/home-manager/_hyprland/bindings.nix` — 0 changes.
- [x] 8.3 Manual verification (user): verified iteratively across the session — `SUPER, N`/bell opens & closes the center (close-fix: visibility toggle), history grouped by app with dismiss + Clear All, DND toggle, restored-notification read-only actions, MPRIS widget, bell count/DND glyph. Follow-up fixes confirmed: click-outside-to-close (full-screen backdrop), panel width (`hexpand={false}`), bell icon recolor + position, and the timeout-hides-but-keeps-in-history fix.
