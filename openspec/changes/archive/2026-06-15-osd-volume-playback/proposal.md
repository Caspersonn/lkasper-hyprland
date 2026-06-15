## Why

Adjusting volume or controlling media playback currently gives no on-screen
feedback — the only volume indicator lives in the bar's tray area, and there is
no playback feedback at all. A transient on-screen display (OSD) that briefly
shows the current volume level or the now-playing track makes these actions
legible at a glance, the way GNOME/KDE shells do.

This change targets the **home-manager** side: the AGS shell source (`ags/`,
built by `homeManagerModules.lkh-ags` into the `lkasper-shell` binary) and the
Hyprland keybinds in `modules/home-manager/_hyprland/bindings.nix`.

Tracking bean: [lkasper-hyprland-25yp](../../../.beans/lkasper-hyprland-25yp--osd-volume-playback-and-capslock.md)

## What Changes

- Add an OSD overlay window to the AGS shell that appears transiently on the
  **focused monitor only**, anchored bottom-center on the `OVERLAY` layer,
  never grabbing keyboard focus, and auto-hiding after a short timeout (~1.5s)
  that re-arms on every new trigger.
- The OSD swaps between two content views (latest trigger wins, one shared
  window and timer):
  - **Volume view** — speaker icon, a level indicator, and the volume percent,
    driven reactively by WirePlumber (`AstalWp` `notify::volume` / `notify::mute`).
  - **Media view** — an action icon (play / pause / skip-forward / skip-backward)
    plus the track title and artist (symbolic icons only, no cover art).
- Drive the media view from the media keys: each of `XF86AudioPlay`/`Pause`/
  `Next`/`Prev` appends `ags request osd-media <action>` after its `playerctl`
  command, and the AGS `requestHandler` shows the media view with the icon for
  that action — play/pause shows the resulting state's icon (self-correcting via
  `notify::playback-status`), next/prev show a directional skip icon. The
  handler resolves the player fresh on each press (robust to player restarts).
  This keyboard-only model also means a track auto-advance — which MPRIS reports
  identically to a user skip — never triggers the OSD.
- Suppress the spurious initial `notify::volume` emission at shell startup so
  the OSD does not flash on login.
- **Out of scope (deferred):** the capslock OSD from the tracking bean.
  Capslock has no reactive push event in the stack (confirmed: `AstalHyprland`
  exposes only `keyboard-layout`, no capslock signal), so it needs a separate
  polling/IPC approach and will be its own change.

## Capabilities

### New Capabilities
- `ags-osd`: A transient on-screen display in the AGS shell that shows volume
  and media-playback feedback on the focused monitor, driven by reactive
  WirePlumber/MPRIS signals plus an IPC trigger for explicit media skips, with
  auto-hide and latest-wins content.

### Modified Capabilities
<!-- None. Appending `ags request osd-skip` to the media-key bindings does not
     change any existing requirement of the `hyprland-config` capability (its
     requirements concern omarchy-free keybinds and autostart); the new
     keybind behavior is owned by the `ags-osd` capability. -->

## Impact

- **AGS shell source (`ags/`)**, rebuilt by `homeManagerModules.lkh-ags`:
  - New OSD window module (new files under `ags/windows/osd/`).
  - `ags/app.ts` — register the OSD window in `main()` and handle the
    `osd-media <action>` request in `requestHandler`.
  - `ags/style.scss` — OSD styling (base16-derived colors, consistent with the
    bar's pill aesthetic).
- **`modules/home-manager/_hyprland/bindings.nix`** — append `ags request
  osd-media <action>` to all four media `bindl` entries (`XF86AudioPlay`,
  `XF86AudioPause`, `XF86AudioNext`, `XF86AudioPrev`).
- **Dependencies:** no new *library* inputs — `AstalWp`, `AstalMpris`, and
  `AstalHyprland` are already in the shell's `astalLibs` build inputs. The IPC
  trigger does require the **`ags` CLI** (`agsPkgs.default`) on the user's
  `PATH` so `ags request` can reach the running shell; this is added to
  `home.packages` in `modules/home-manager/ags.nix` (it also fixes the
  pre-existing `ags request toggle-bars` keybind, which was likewise broken
  without the CLI installed).
- **Behavioral:** volume keys, mute, play/pause, and media next/prev now
  produce a brief overlay on the active monitor; no change to the actions
  themselves.
