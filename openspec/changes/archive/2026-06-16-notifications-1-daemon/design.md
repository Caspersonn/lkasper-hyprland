## Context

The system notification daemon today is **mako** — a home-manager module
(`modules/home-manager/mako.nix`, `services.mako`), base16-themed via a
`runtime.conf` block in `themes.nix`, and autostarted from
`modules/home-manager/_hyprland/autostart.nix`. The AGS shell does not handle
notifications at all (the bar's `NotificationBell` is a static icon).

`AstalNotifd` is the Astal notification-daemon library: `get_default()` acquires
the `org.freedesktop.Notifications` D-Bus name and the process *becomes* the
daemon. Its typelib is already in the store (`astal-notifd-0.1.0`) but `notifd`
is not in `astalLibs` in `ags.nix` yet. The daemon exposes `notifications`,
`dontDisturb`, `ignoreTimeout`, signals `notified(id)` / `resolved(id, reason)`,
and `get_notification(id)`; each `Notification` has `appName`, `appIcon`,
`summary`, `body`, `image`, `actions`, `urgency` (LOW/NORMAL/CRITICAL), `time`,
plus `dismiss()` and `invoke(actionId)`.

The OSD work established the patterns this reuses: layer-shell windows, the
per-monitor `<For each={createBinding(App, "monitors")}>` + focused-connector
approach, GLib timers, and `ags request` IPC.

## Goals / Non-Goals

**Goals:**
- Make the AGS shell the notification daemon via `AstalNotifd`.
- Popup toasts at **mako parity**: focused-monitor, top-right stack, urgency-aware
  timeout, max-visible cap, action buttons, base16 theming.
- Respect Do Not Disturb (`dontDisturb`) by suppressing popups.
- Retire mako (module + autostart + themed `runtime.conf`).
- Confirm AstalNotifd's built-in persistence with a runtime spike.

**Non-Goals (deferred to `notifications-2-center` or later):**
- The slide-out notification center and history rendering.
- The DND *toggle UI*, the bell unread-count badge, Clear All.
- Same-app **grouping** of popups (popups are a flat stack here).
- Inline reply, per-notification hover-to-pause.
- Touching QuickSettings.

## Decisions

### D1: AGS becomes the daemon via `AstalNotifd.get_default()` in `main()`

Calling `AstalNotifd.get_default()` once during `app.ts` `main()` acquires the
FDN bus name and starts serving notifications. There is no "client" mode — you
cannot observe other apps' notifications without being the daemon — so this is a
full replacement of mako, not an addition.

- *Alternative — keep mako and have AGS read its notifications:* impossible;
  mako exposes no such API and only one process owns the bus name.

### D2: Retire mako as part of this change (clean cutover)

Remove `modules/home-manager/mako.nix` (drops `homeManagerModules.lkh-mako`),
the `"mako"` `exec-once` line, and the mako `runtime.conf` block in `themes.nix`.
The cutover only works if mako is not running when the AGS daemon starts — at
switch time the user must kill mako or re-login.

- **Caveat:** within this repo `lkh-mako` is only *defined* (no internal import
  list), so deleting the file is sufficient here; but any **downstream home
  configuration that imports `lkh-mako` explicitly must also drop that import**,
  or evaluation fails.

### D3: Popups as a focused-monitor layer-shell stack

Reuse the OSD's per-monitor `<For>` + focused-connector pattern: one popup
window per monitor, the stack rendered only on the focused monitor. `OVERLAY`
layer, no exclusivity, `Keymode.NONE` (no keyboard grab — pointer still works,
which action buttons need), anchored top-right to match mako. A reactive list of
active popups is driven by `notified` (add) and `resolved` (remove); newest on
top.

- *Alternative — one shared window with reassigned monitor:* rejected, same
  GTK4 layer-shell reassignment fragility the OSD avoided.

### D4: Urgency-aware per-popup timeout

Each popup arms a tracked `GLib` timeout: `LOW`/`NORMAL` auto-dismiss (honor the
notification's `expire_timeout` if set, else ~5 s, matching mako's
`default-timeout=5000`); `CRITICAL` is **sticky** (no auto-dismiss, cleared only
by the user or the app). Dismiss calls `notification.dismiss()`, which fires
`resolved` and removes the card.

### D5: DND suppresses popups only

When `notifd.dontDisturb` is true, the `notified` handler does **not** create a
popup, but the notification is still recorded in `notifications[]` for the
center. The toggle UI is `notifications-2-center`'s job.

### D6: Max-visible cap; overflow lives in history

Show at most ~5 popups (mako's `max-visible`); additional concurrent
notifications are not popped but remain in `notifications[]`. No popup grouping
in this change.

### D7: Persistence is built-in — verify, don't build

`AstalNotifd` caches notifications and images to `~/.cache/astal/notifd` and
restores `notifications[]` on startup. Restored notifications must **not** replay
as popups on launch — `notified` fires only for genuinely new notifications, so
the startup-restored list populates silently. A spike confirms both the restore
and the no-replay behavior; the restored history is consumed by change 2.

### D8: Theming reuses the base16 palette

New `.notification`/popup classes in `ags/style.scss` use the existing SCSS
variables, matching mako's mapping (`base00` background, `base05` text, `base04`
border, `base0D` accent/progress), ~420 px wide. Render `notification.image`
when present, else `appIcon`.

## Risks / Trade-offs

- **Bus-name conflict during cutover** → if mako and the AGS daemon both run, the
  second silently fails to acquire the name. Mitigation: remove mako from
  autostart and kill it / re-login at switch time.
- **Notifications now depend on shell uptime** → a shell crash drops live
  notifications until restart (mako was independent). Accepted; persisted
  history survives via the cache.
- **Action buttons on an overlay layer** → the popup window must accept pointer
  input (it does on `OVERLAY` with `Keymode.NONE`); verify clicks invoke actions.
- **Downstream `lkh-mako` import** → must be removed wherever this flake's home
  config is consumed (outside this repo).
- **Image rendering** → raw image data is cached to a file by the daemon; render
  the path. Oversized images bounded by CSS.

## Migration Plan

Ship via home-manager rebuild (`lkasper-shell` rebuilt with `notifd`). At switch
time ensure mako is gone: drop it from autostart, then `pkill mako` (or
re-login) so the AGS daemon can claim the bus name. Rollback: restore
`mako.nix` + the autostart line + the `runtime.conf` block, and remove the
`AstalNotifd` init.

## Open Questions

- Hover-to-pause the dismiss timer — nice-to-have, deferred.
- Exact max-visible (default 5, mako parity) and default timeout (5 s) are
  tunable without spec impact.
