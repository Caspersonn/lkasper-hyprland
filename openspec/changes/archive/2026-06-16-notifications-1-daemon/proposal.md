## Why

You currently run **mako** as the system notification daemon. To build a
SwayNC-style notification experience inside the AGS shell, the shell itself must
become the `org.freedesktop.Notifications` daemon via **AstalNotifd** — only one
process can own that D-Bus name, so this *replaces* mako. This change is the
foundation: the daemon plus popup toasts (mako parity). The slide-out
notification center is the chained follow-up.

> **Chained change — Part 1 of 2.** This change is consumed by
> [`notifications-2-center`](../notifications-2-center/proposal.md), which adds
> the slide-out center and depends on the AGS shell being the AstalNotifd daemon.

This change targets the **home-manager** side: the AGS shell source (`ags/`,
built by `homeManagerModules.lkh-ags` into `lkasper-shell`), the mako module
(`homeManagerModules.lkh-mako`), and the Hyprland autostart
(`modules/home-manager/_hyprland/autostart.nix`).

Tracking bean: [lkasper-hyprland-nn80](../../../.beans/lkasper-hyprland-nn80--notification-center-ags-swaync-style.md)

## What Changes

- Add `notifd` to `astalLibs` in `modules/home-manager/ags.nix` so the shell
  can use `AstalNotifd`.
- Initialize `AstalNotifd.get_default()` in `ags/app.ts` so the AGS shell
  acquires the `org.freedesktop.Notifications` name and becomes the daemon.
- Add a popup-toast layer-shell window (new `ags/windows/notifications/`,
  top-right, stacked) at **mako parity**: per-notification timeout
  (urgency-aware — `critical` never auto-dismisses), a max-visible cap with
  overflow, group-by-app, action buttons (`notification.invoke`), and base16
  theming matching the current mako colors (`base00`/`base05`/`base04`/`base0D`).
- **BREAKING (local): retire mako.** Remove `homeManagerModules.lkh-mako`
  (`modules/home-manager/mako.nix`), drop `"mako"` from `exec-once` in
  `autostart.nix`, and drop the mako `runtime.conf` block in `themes.nix`. Two
  daemons cannot own the bus name simultaneously.
- Wire DND plumbing (`AstalNotifd` `dontDisturb`): popups are suppressed when
  enabled. (The DND *toggle UI* lives in the chained center change.)
- Confirm AstalNotifd's built-in persistence with a runtime spike — it caches
  notifications and images to `~/.cache/astal/notifd` and restores
  `notifications[]` on startup. The persisted history is consumed by
  `notifications-2-center`.

## Capabilities

### New Capabilities
- `notification-daemon`: The AGS shell acts as the system notification daemon
  (AstalNotifd) — receiving notifications, rendering popup toasts, honoring
  urgency/timeouts/actions, and suppressing popups under Do Not Disturb —
  replacing mako.

### Modified Capabilities
<!-- None. mako has no spec; QuickSettings is untouched. The autostart change
     (dropping the mako exec-once line) does not alter an existing requirement
     of the `hyprland-config` capability and is captured under Impact. -->

## Impact

- **home-manager modules:** `homeManagerModules.lkh-ags` gains `notifd`;
  `homeManagerModules.lkh-mako` is removed.
- **AGS shell (`ags/`)**, rebuilt by `lkh-ags`: `ags/app.ts` (daemon init),
  new `ags/windows/notifications/` popup module, `ags/style.scss` (toast styles).
- **`modules/home-manager/_hyprland/autostart.nix`** — remove the `"mako"`
  `exec-once` entry.
- **`modules/home-manager/themes.nix`** — remove the mako `runtime.conf` block.
- **Behavioral:** notifications now depend on the AGS shell being alive (mako
  was an independent process) — a shell crash drops live notifications until it
  restarts, though persisted history survives via the AstalNotifd cache.
- **Dependencies:** no new packages — the `notifd` Astal library is already in
  the store; it just isn't in `astalLibs` yet.
