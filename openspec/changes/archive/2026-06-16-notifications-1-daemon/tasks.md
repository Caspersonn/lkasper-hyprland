## 1. Build inputs

- [x] 1.1 Add `notifd` to the `astalLibs` list in `modules/home-manager/ags.nix` so `AstalNotifd` is available to the bundle.

## 2. Become the daemon

- [x] 2.1 In `ags/app.ts`, import `AstalNotifd` and call `AstalNotifd.get_default()` in `main()` so the shell acquires `org.freedesktop.Notifications` at startup. (Done via `initPopups()` called from `main()`, which runs `AstalNotifd.get_default()` after the GTK app is up — mirrors `initOsd()`.)

## 3. Popup toasts (new `ags/windows/notifications/` module)

- [x] 3.1 Create a popup controller (`ags/windows/notifications/popups.ts`) holding the reactive list of active popups; add on `notifd.connect("notified", id => …)` (resolve via `notifd.get_notification(id)`) and remove on `notifd.connect("resolved", id => …)`.
- [x] 3.2 Create the popup window (`ags/windows/notifications/index.tsx`): one window per monitor via `<For each={createBinding(App, "monitors")} cleanup={…}>`, shown on the focused monitor (reactive `createBinding(hypr, "focusedMonitor")`), `layer={Astal.Layer.OVERLAY}`, `anchor=TOP|RIGHT`, non-exclusive, `keymode={Astal.Keymode.NONE}`; render the popup list newest-first.
- [x] 3.3 Build the notification card: summary, body, `image` (file path) when present else `appIcon`, action buttons. Action click → `notification.invoke(actionId)`; close button → `notification.dismiss()`.
- [x] 3.4 Per-card urgency-aware timeout (tracked `GLib.timeout_add` + `source_remove`): `LOW`/`NORMAL` auto-dismiss (honor `expireTimeout` if > 0, else ~5s); `CRITICAL` (and `expireTimeout === 0`) sticky.
- [x] 3.5 Enforce the max-visible cap (5): only the newest N render as toasts; the rest stay in `notifd.notifications` (no popup).
- [x] 3.6 Suppress popups when `notifd.dontDisturb` is true (still recorded in the list; no toast).
- [x] 3.7 Wire the popup window into `main()` in `ags/app.ts` (`NotificationPopups()` + `initPopups()`) alongside the bar/OSD.
- [x] 3.8 Add toast styling to `ags/style.scss` using the base16 variables (`base00`/`base05`/`base04`/`base0D` → `$bg`/`$fg`/`$surface0`/accent), ~420px wide, urgency-critical border. No hardcoded colors.

## 4. Retire mako

- [x] 4.1 Remove the `"mako"` `exec-once` entry from `modules/home-manager/_hyprland/autostart.nix`.
- [x] 4.2 Delete `modules/home-manager/mako.nix` (removes `homeManagerModules.lkh-mako`).
- [x] 4.3 Remove the mako `runtime.conf` block (`.config/mako/runtime.conf`) from `modules/home-manager/themes.nix`.
- [x] 4.4 Consumer-side caveat (surfaced, no edit here): the downstream/home configuration that consumes this flake must drop any explicit `homeManagerModules.lkh-mako` import — it is not referenced within this repo. Flagged in the apply report.

## 5. Persistence spike (verify built-in behavior)

- [x] 5.1 Manual spike (user, live session): no-replay confirmed — repeated `pkill lkasper-shell; lkasper-shell &` restarts during testing never produced a popup storm. History retention is AstalNotifd's built-in `~/.cache/astal/notifd` cache (confirmed in the library); it will be fully exercised once `notifications-2-center` renders the restored list.

## 6. Build & verify

- [x] 6.1 `nix fmt` the changed Nix files (`ags.nix`, `autostart.nix`, `themes.nix`) — 0 changes.
- [x] 6.2 Build-check the bundle: built the pinned `ags` CLI from the flake input and ran `ags bundle app.ts` — exit 0 (605 KB), so the new `notifications/` module + `AstalNotifd` usage compile.
- [x] 6.3 Manual cutover (user, after rebuild): verified — themed toasts appear from the AGS daemon (mako retired). Popups were repositioned below the bar (`Exclusivity.NORMAL`). Also caught and fixed an out-of-repo competitor: `swaynotificationcenter` was D-Bus-activatable in the system flake (`~/lkasper-flake/modules/programs/desktop/hyprland.nix:40`) and hijacked the name when the shell was down; removed.
