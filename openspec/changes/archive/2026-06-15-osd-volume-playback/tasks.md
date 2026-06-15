## 1. OSD controller (state machine)

- [x] 1.1 Create `ags/windows/osd/controller.ts` with module-level state: current view (`"volume" | "media" | null`), volume data (level, mute, icon, percent), media data (title, artist, symbolic icon, playing), focused-monitor connector, a single timer handle, and a `ready` flag initialized to `false`. Expose the state reactively (`createState`/`createBinding`) for the window to consume.
- [x] 1.2 Implement `show(view, data)`: set content, resolve the focused connector from `AstalHyprland.get_default().focusedMonitor.name`, cancel any pending timer, and arm a fresh ~1.5s `setTimeout`. Make it a no-op while `ready` is `false`. (Implemented as `showVolume`/`showMedia` + `armTimer` using a tracked `GLib.timeout_add`/`source_remove`.)
- [x] 1.3 Implement `hide()` (clears current view) and wire it to the timer expiry. (Timer callback sets `view` to `null`.)
- [x] 1.4 Add `markReady()` that flips `ready` to `true`, to be called from `app.ts` after initial setup. (Encapsulated in `initOsd()` via a `READY_DELAY_MS` `GLib.timeout_add`, robust against async pipewire/MPRIS init.)

## 2. Triggers

- [x] 2.1 Subscribe to the default speaker (`AstalWp.get_default().audio.defaultSpeaker`) `notify::volume` and `notify::mute`; on change call `show("volume", …)` with level/mute/icon/percent. (Also re-subscribes on `notify::default-speaker`.)
- [x] 2.2 Track the active MPRIS player (reuse the `pickBest`/`watchPlayer`/`player-added`/`player-closed` approach from `ags/windows/bar/media.tsx`); on `notify::playback-status` play↔pause transitions call `show("media", …)`. (`notify::title` only refreshes content while media is already shown, so auto-advance never opens the OSD.)
- [x] 2.3 Add an `osdSkip()` entry point that reads the active player's current track and calls `show("media", …)`, for the `osd-skip` IPC request to invoke.

## 3. OSD window + views

- [x] 3.1 Create `ags/windows/osd/index.tsx` exporting `Osd()` that renders one window per monitor via `<For each={createBinding(App, "monitors")} cleanup={(win) => (win as Gtk.Window).destroy()}>` (mirror `ags/windows/bar/index.tsx`), with `namespace="osd"`, `layer={Astal.Layer.OVERLAY}`, `anchor={Astal.WindowAnchor.BOTTOM}`, `marginBottom={80}`, non-exclusive, `keymode={Astal.Keymode.NONE}`.
- [x] 3.2 Bind each window's `visible` to controller state: visible only when a view is active AND `monitor.get_connector()` equals the focused-monitor connector.
- [x] 3.3 Build the volume view: speaker icon + level indicator + percent, bound to controller volume state. (Read-only `Gtk.LevelBar` for the level indicator.)
- [x] 3.4 Build the media view: symbolic player icon + title + artist, bound to controller media state (no cover art).
- [x] 3.5 Render the active view based on controller current-view (latest-wins; one view shown at a time).

## 4. Wire into the app

- [x] 4.1 In `ags/app.ts`, import `Osd` and call it in `main()` alongside `Bars()`, then call `markReady()` after a zero/idle timeout so the startup `notify::volume` emission is ignored. (Startup guard lives in `initOsd()`.)
- [x] 4.2 In `ags/app.ts` `requestHandler`, handle `osd-skip` by calling `osdSkip()` and replying `res("ok")`.

## 5. Hyprland keybinds

- [x] 5.1 In `modules/home-manager/_hyprland/bindings.nix`, append `ags request osd-skip` to the `XF86AudioNext` and `XF86AudioPrev` `bindl` entries (e.g. `", XF86AudioNext, exec, playerctl next && ags request osd-skip"`).
- [x] 5.2 Install the `ags` CLI (`agsPkgs.default`) into `home.packages` in `modules/home-manager/ags.nix` so `ags request` can reach the running shell. (The CLI was never installed — without it both the new `osd-skip` and the pre-existing `ags request toggle-bars` keybinds silently fail. The bundled shell registers under gnim's default instance name `ags`, which `ags request` targets by default, so no instance flag is needed.)

## 6. Styling

- [x] 6.1 In `ags/style.scss`, add an OSD block using the existing SCSS variables (`$bg`, `$fg`, `$accent`, pill radius) so it matches the bar; style the volume level indicator and the media labels. No new hardcoded colors.

## 7. Build & verify

- [x] 7.1 Run `nix fmt` on the changed Nix files. (`bindings.nix` formatted — 0 changes; `nix fmt` parses the file, confirming the keybind edit is syntactically valid.)
- [x] 7.2 Run `nix flake check` (and/or build `lkasper-shell`) to confirm the `ags bundle` compiles with the new `osd/` modules. (Built the pinned `ags 3.1.0` CLI from the flake input and ran `ags bundle --gtk 4 app.ts …`: exit 0. Verified the bundler genuinely parses the new modules — a clean entry importing `./windows/osd` + `./windows/osd/controller` bundles, while a deliberately-broken entry fails with a parse error.)
- [ ] 7.3 Manual verification (requires a rebuild + live Hyprland session — left for the user): volume up/down/mute show the volume OSD on the focused monitor only; play/pause shows the media OSD; next/prev (media keys) show the media OSD; track auto-advance does **not**; no OSD flashes on login; the OSD auto-hides after ~1.5s and re-arms on repeated triggers; the OSD still works after unplugging a monitor.

## 8. Media action icons (revises the media trigger to all four media keys)

This supersedes the original `osd-skip`/reactive-play-pause approach from tasks 2.2, 2.3, 4.2, and 5.1.

- [x] 8.1 In `ags/app.ts` `requestHandler`, replace the `osd-skip` branch with an `osd-media` branch that reads the action from `argv` (`playpause` | `next` | `prev`) and calls the controller's media trigger with it. (`argv[0] === "osd-media"` → `triggerMedia(argv[1] ?? "playpause")`.)
- [x] 8.2 In `ags/windows/osd/controller.ts`, replace `osdSkip` with `triggerMedia(action)`: resolve the player with a fresh `pickBest()` each call, map the action to an icon (`next` → `media-skip-forward-symbolic`, `prev` → `media-skip-backward-symbolic`, `playpause` → play/pause icon from `playbackStatus`), set the media state (title/artist/icon), and present the media view.
- [x] 8.3 Remove the reactive `notify::playback-status` *trigger* that opened the media OSD. Keep `notify::playback-status` / `notify::title` watchers that only **refresh content while the OSD is visible**: the play/pause icon refreshes only when the last action was `playpause` (so next/prev keep their directional icon); the title/artist refresh after a skip settles.
- [x] 8.4 Confirm the media view's leading icon binds to the controller's media `icon` state (already the case — the icon field now carries the action glyph, so `ags/windows/osd/index.tsx` needs no change).
- [x] 8.5 In `modules/home-manager/_hyprland/bindings.nix`, change all four media keys to append `&& ags request osd-media <action>` (`playpause` for Play/Pause, `next` for Next, `prev` for Prev).
- [x] 8.6 In `ags/style.scss`, confirm the media action icon is styled consistently with the volume icon (reuses `.osd-icon` — no change needed).
- [x] 8.7 Re-bundle (`ags bundle app.ts …`) to confirm it compiles (exit 0, 575 KB); `nix fmt` the changed Nix file (0 changes).
- [ ] 8.8 Manual verification (user, after rebuild + shell restart): next shows a skip-forward icon, prev shows skip-backward, play shows the play icon, pause shows the pause icon; each appears with the correct track; auto-advance shows nothing.
- [x] 8.9 Add the media player's source icon (its desktop-entry icon) at the right edge of the media view: add `entry` to `MediaData` in `controller.ts` (set from `player.entry`), render a right-aligned `<image>` in `ags/windows/osd/index.tsx` (title/artist column gets `hexpand` to push it right), and style `.osd-entry-icon` in `ags/style.scss`.
