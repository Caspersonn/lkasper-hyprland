## Why

With the AGS shell acting as the notification daemon (from
`notifications-1-daemon`), add the **SwayNC-style notification center**: a
right-edge slide-out panel showing persisted history, Do Not Disturb control,
and a now-playing widget. It is a **new, self-contained AGS module kept entirely
separate from the existing QuickSettings** — QuickSettings is left untouched and
its connectivity/power/volume widgets are not duplicated here.

> **Chained change — Part 2 of 2.** Depends on
> [`notifications-1-daemon`](../notifications-1-daemon/proposal.md): it requires
> the AGS shell to be the AstalNotifd daemon and to expose the persisted
> `notifications[]` history.

This change targets the **home-manager** side: the AGS shell source (built by
`homeManagerModules.lkh-ags` into `lkasper-shell`) and the Hyprland keybinds
(`modules/home-manager/_hyprland/bindings.nix`).

Tracking bean: [lkasper-hyprland-nn80](../../../.beans/lkasper-hyprland-nn80--notification-center-ags-swaync-style.md)

## What Changes

- New self-contained AGS module under `ags/windows/notifications/` (separate
  from `ags/windows/QuickSettings/`; QuickSettings is **not** modified).
- A right-edge slide-out **control center** (layer-shell, full height,
  `revealer` slide-in) containing:
  - **Header** — a Do Not Disturb toggle (`AstalNotifd` `dontDisturb`) and a
    **Clear All** action.
  - **MPRIS now-playing widget** (`AstalMpris`) with basic transport controls.
  - **Notification history** — grouped by app, newest first, per-item dismiss,
    rendering AstalNotifd's persisted `notifications[]`.
- **Restored history is read-only for actions**: after a restart the originating
  app's D-Bus sender is gone, so action buttons on restored notifications are
  hidden/disabled. A retention cap bounds the persisted cache.
- The bar bell (`ags/windows/bar/notifications.tsx`, currently a static icon)
  becomes the center **toggle**, with an unread-count badge and a DND indicator.
- **IPC + keybind** (mirrors `swaync-client -t`/`-d`): handle
  `toggle-notifications` and `toggle-dnd` in the `ags/app.ts` `requestHandler`,
  and add a Hyprland keybind in `bindings.nix`.
- Deliberately does **not** duplicate QuickSettings' wifi/bluetooth/airplane,
  volume/mic, or power widgets — those remain QuickSettings' responsibility.

## Capabilities

### New Capabilities
- `notification-center`: A slide-out notification center in the AGS shell —
  persisted, grouped, dismissable history; a Do Not Disturb toggle; Clear All;
  an MPRIS now-playing widget; and a bar-bell toggle with unread/DND indicators —
  implemented as a standalone module separate from QuickSettings.

### Modified Capabilities
<!-- None. QuickSettings is untouched. This builds on the `notification-daemon`
     capability introduced by notifications-1-daemon. -->

## Impact

- **`homeManagerModules.lkh-ags`** — `lkasper-shell` rebuilt from the new
  `ags/windows/notifications/` center files.
- **`ags/app.ts`** — register the center window and handle
  `toggle-notifications` / `toggle-dnd` requests.
- **`ags/windows/bar/notifications.tsx`** — bell becomes the toggle (unread
  badge + DND state).
- **`ags/style.scss`** — center theming (base16).
- **`modules/home-manager/_hyprland/bindings.nix`** — keybind to toggle the
  center and DND.
- **Depends on** `notifications-1-daemon` — requires the AGS shell to be the
  AstalNotifd daemon and the persisted notification cache.
- **QuickSettings module is untouched.**
