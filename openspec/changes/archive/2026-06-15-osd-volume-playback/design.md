## Context

The AGS shell (`ags/`, built into `lkasper-shell` by `homeManagerModules.lkh-ags`)
is a gnim/Astal GTK4 desktop shell. It already has the building blocks this
change needs:

- `ags/windows/bar/volume.tsx` reads the default speaker via
  `AstalWp.get_default().audio.defaultSpeaker` and binds `volume` / `mute` /
  `volumeIcon`.
- `ags/windows/bar/media.tsx` tracks the active MPRIS player via
  `AstalMpris.get_default()`, picking the best player and watching
  `notify::playback-status` / `notify::title`.
- `ags/windows/bar/index.tsx` renders one window per monitor reactively with
  `<For each={createBinding(App, "monitors")} cleanup={(win) => win.destroy()}>`
  — the pattern proven to survive monitor hot-plug/unplug.
- `ags/app.ts` already routes IPC via `requestHandler` (it handles
  `toggle-bars`).

What does **not** exist yet: any transient/overlay layer-shell window. The bar
is `EXCLUSIVE` (reserves space) and QuickSettings is a GTK popover; notifications
are handled by external `mako`. The OSD is the shell's first `OVERLAY`,
non-space-reserving, auto-hiding window.

Confirmed constraint from exploration: MPRIS cannot distinguish a user-initiated
skip from a track auto-advance — both surface as a `notify::title` change with
status staying `PLAYING`. Only the keypress itself disambiguates them.

## Goals / Non-Goals

**Goals:**
- A transient OSD on the focused monitor showing volume and media-playback feedback.
- Reactive triggers for volume (up/down/mute) and play/pause with **zero keybind changes**.
- IPC trigger (`osd-skip`) for explicit next/previous, appended to two `bindl` lines.
- Auto-hide after ~1.5s, re-arming on each trigger, latest-trigger-wins, single window.
- No OSD flash at shell startup.
- base16/SCSS theming consistent with the bar's pill aesthetic.

**Non-Goals:**
- Capslock OSD (deferred — no reactive signal exists; separate change).
- Brightness OSD (out of scope for this change).
- Album cover art in the media view (symbolic player icon only).
- Replacing `mako` notifications.
- Mirroring the OSD across all monitors, or any click/hover interaction with it.

## Decisions

### D1: Volume is reactive; all media triggers go through IPC with an action arg

Volume changes are pushed by `AstalWp` (`notify::volume`, `notify::mute`), so
the volume OSD subscribes directly and shows feedback regardless of source
(keybind, QuickSettings slider, external app) with **no keybind edits**.

The media OSD is driven entirely by the media keys: each of
`XF86AudioPlay`/`Pause`/`Next`/`Prev` appends `ags request osd-media <action>`
after its `playerctl` command, and `requestHandler` opens the media view. The
handler resolves the player with a fresh `pickBest()` on every request, so it
does not depend on a reactive subscription that can be missed when a player is
added before its bus name is set — the cause of play/pause flaking out after a
media-player restart.

- *Alternative — keep play/pause reactive (`notify::playback-status`) and only
  skip via IPC (the original design):* rejected; the reactive path is fragile
  across player restarts, fires on background/app-side status changes, and
  cannot carry the action identity needed for per-action icons.
- *Alternative — trigger media on `notify::title`:* rejected; fires on every
  auto-advance, which the user does not want.

Trade-off: play/pause/skip performed inside the player's own UI does not open
the OSD (only the media keys do). This is consistent — next/prev can never be
distinguished from auto-advance on the app side anyway.

### D2: One OSD window per monitor via the bar's `<For>` pattern; show only the focused one

The OSD reuses `<For each={createBinding(App, "monitors")}
cleanup={(win) => win.destroy()}>` to maintain one OSD window per monitor.
Visibility is gated so only the window whose connector matches the focused
monitor is shown on a trigger.

- *Alternative — a single window whose `gdkmonitor` is reassigned to the focused
  monitor at show-time:* rejected; layer-shell monitor reassignment in GTK4 is
  unreliable and is exactly the class of bug that broke the bar on hot-plug
  before the `<For>` fix.
- *Alternative — mirror the OSD on all monitors:* rejected; the user wants
  focused-monitor only.

The focused monitor is resolved from `AstalHyprland.get_default().focusedMonitor`
(its `.name` is the connector), matched to the per-window `Gdk.Monitor`
`get_connector()` — the same key the bar uses.

### D3: A single OSD controller (state machine) with one shared timer

A small module-level controller holds the OSD state: current view
(`"volume" | "media" | null`), the values to display, the focused-monitor
connector, and one timer handle. Every trigger calls a single `show(view, data)`
that sets content, marks the focused monitor visible, and re-arms the timer;
the timer's expiry hides all OSD windows. Latest trigger wins because there is
one piece of state and one timer.

- *Alternative — separate windows/timers per content type:* rejected; could
  stack a volume and a media OSD simultaneously and duplicates timer logic.

### D4: Suppress the startup volume emission with a "ready" guard

`createBinding`/the WirePlumber binding emits an initial `notify::volume` during
setup, which would flash a volume OSD on login. A module-level `ready` flag
starts `false` and is flipped `true` after initial synchronous setup (via a
zero/idle timeout in `main()`); `show()` is a no-op while `ready` is false.

- *Alternative — compare against a stored "last volume":* rejected; more state,
  and the first real change after login would still need special-casing.

### D5: Timeout via a tracked GLib timeout, reused theming

The auto-hide uses a single tracked `setTimeout` (gnim/`ags` timer); each
`show()` cancels the previous handle before arming a new one. Styling reuses the
existing SCSS variables in `ags/style.scss` (`$bg`, `$fg`, `$accent`, pill
radius) so the OSD matches the bar; no new hardcoded colors are introduced.

### D6: Per-action media icons — action in the IPC arg, play/pause derived from state

The media view's leading glyph reflects the action: `next` →
`media-skip-forward-symbolic`, `prev` → `media-skip-backward-symbolic`, and
`playpause` → the resulting playback state (`media-playback-start-symbolic` when
playing, `media-playback-pause-symbolic` when paused). next/prev are momentary
actions with no corresponding state to read, so their icon is fixed for the
OSD's lifetime; play/pause is a state, read from `player.playbackStatus`.

Because `playerctl play-pause` toggles asynchronously, the status can be stale
when `osd-media playpause` arrives, so the controller keeps a
`notify::playback-status` watcher that refreshes the glyph **only while the OSD
is visible and the last action was playpause** — self-correcting within ~100 ms.
A `notify::title` watcher likewise refreshes the title/artist while visible
(covers the new track settling in after a skip). Neither watcher opens the OSD;
opening is exclusively the IPC handler's job.

- *Alternative — infer the new play/pause state by inverting the pre-press
  state:* rejected; reading the pre-press state is equally racy and more fragile
  than letting the status-notify settle it.

## Risks / Trade-offs

- **Skips made inside the player's own UI are not shown** → only the keyboard
  media keys ping `osd-skip`; clicking "next" inside Spotify shows nothing.
  Accepted: matches the user's intent ("when *I* press next/prev").
- **Startup flash if the `ready` guard is mistimed** → at worst a single volume
  OSD flashes once on login (cosmetic, self-clears after the timeout).
- **Focused-monitor mismatch during rapid focus changes** → resolved at
  trigger-time from `focusedMonitor`, so the OSD lands on whatever is focused at
  that instant; acceptable.
- **GTK4 window lifecycle on monitor unplug** → mitigated by reusing the proven
  `<For>` + `cleanup` destroy pattern rather than manual window bookkeeping.
- **Two rapid different triggers** → latest-wins may replace a just-shown view
  quickly; acceptable and expected.

## Migration Plan

Purely additive. Ship via a home-manager rebuild (`lkasper-shell` is rebuilt
from `ags/` by `homeManagerModules.lkh-ags`). Rollback is reverting the change:
delete the OSD window module, its `app.ts` wiring, the SCSS block, and restore
the two `bindl` media-key lines. No state or data migration.

## Open Questions

- None blocking. The exact level-indicator style (linear bar vs. text-only) and
  the precise timeout value (~1.5s) are tunable during implementation without
  affecting the spec.
