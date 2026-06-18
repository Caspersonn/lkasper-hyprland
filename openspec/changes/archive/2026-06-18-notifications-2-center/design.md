## Context

`notifications-1-daemon` (archived) made the AGS shell the `org.freedesktop.Notifications`
daemon via `AstalNotifd`, added popup toasts under `ags/windows/notifications/`
(`popups.ts` + `index.tsx`), and relies on AstalNotifd's on-disk cache
(`~/.cache/astal/notifd`) to persist `notifications[]` across restarts. The bar's
`NotificationBell` (`ags/windows/bar/notifications.tsx`) is still a static icon.

This change adds the slide-out **notification center** into that same module —
a separate surface from the existing QuickSettings popover, which is left
untouched. Reusable patterns from prior work: layer-shell windows + the focused
behavior, `ags request` IPC (`toggle-bars`, `osd-media`), `createBinding` over
GObject properties, and the `AstalMpris` active-player tracking in
`ags/windows/bar/media.tsx`.

Relevant `AstalNotifd` surface: `notifications` (list, reactive via
`createBinding(notifd, "notifications")`), `dontDisturb` (get/set), and per
-`Notification` `dismiss()` / `invoke(actionId)` / `actions` / `appName` /
`summary` / `body` / `image` / `appIcon` / `time`. There is no bulk "clear all" —
it is `dismiss()` over the list.

## Goals / Non-Goals

**Goals (added during apply):**
- Clicking outside the panel closes the center.

**Goals:**
- A right-edge, full-height slide-out center toggled by the bar bell, a keybind, and IPC.
- Header with a Do Not Disturb toggle and Clear All.
- Notification history grouped by app, newest first, with per-item dismiss, rendering the persisted `notifications[]` reactively.
- Restored (pre-session) notifications are read-only — no action buttons (their D-Bus sender is gone).
- An MPRIS now-playing widget with transport controls.
- Bar bell: toggles the center, shows an unread count and a DND indicator.
- Stay entirely separate from QuickSettings.

**Non-Goals:**
- Folding in / duplicating QuickSettings' connectivity/power/volume widgets.
- Inline reply, per-notification snooze, Esc-to-close.
- Touching the popup-toast behavior from change 1.

## Decisions

### D1: Reuse the daemon; bind the center to its reactive state

The center calls `AstalNotifd.get_default()` (the same singleton the popups use)
and renders `createBinding(notifd, "notifications")` and
`createBinding(notifd, "dontDisturb")`. No new daemon, no duplicated state.

### D2: Toggle the window's visibility (not a Revealer)

The center is a layer-shell window anchored on **all four edges** (full-screen),
`OVERLAY`, non-exclusive, with `class="notification-center"` (so the window CSS —
transparent background — actually matches). It is shown and hidden by binding the
window's `visible` to a module-level `centerVisible` state. The full-screen
surface holds a transparent **backdrop** (left, `hexpand`) with a `GestureClick`
that calls `toggleCenter()`, and the opaque `.nc-panel` aligned to the right —
so a click anywhere outside the panel closes the center (see D7b).

The originally-planned always-mapped `Revealer` slide was implemented first but
**did not collapse the layer-shell surface**: when the revealer hid its child the
window kept its width, leaving a full-height region on the right that (a) showed
the window's default background — the window also lacked a `class`, so its
transparent CSS never matched — and (b) would still intercept clicks even once
transparent. Toggling `visible` unmaps the surface entirely, which is the
reliable fix. Trade-off: no slide animation (deferred; could later be done by
animating the panel's margin while keeping a click-passthrough input region).

Toggling is driven by `toggleCenter()` (exported), invoked by the bell, the
keybind (via IPC), and `ags request toggle-notifications`. `Keymode.NONE`
(pointer still works for buttons/scroll; no keyboard grab). Esc-to-close is a
non-goal for now.

### D7b: Click-outside-to-close via a full-screen backdrop

To close on an outside click, the window spans the whole screen (all anchors)
rather than just the panel strip. A transparent, `hexpand` backdrop box to the
left of the panel carries a `Gtk.GestureClick` whose `pressed` handler calls
`toggleCenter()`. Clicks on the panel hit the panel's own widgets and never
reach the backdrop, so only outside clicks close it. While open the surface is
modal over the desktop (transparent except the panel); the bar stays interactive
because the window is `Exclusivity.NORMAL` and does not cover the bar's zone.

- *Alternative — a transparent backdrop `<button>`:* rejected; buttons carry
  hover/active visuals. A `GestureClick` on a plain box has none.

### D3: History grouped by app

A `createComputed` over `notifications` groups by `appName`, orders groups by
their most-recent notification, and sorts newest-first within each group. Each
group renders a header (app name + count); each item is a history card (icon,
summary, body, relative time, a dismiss button). Empty list → an explicit
"No notifications" state.

### D4: Live vs. restored — dead-action handling

The center keeps a session `liveIds: Set<number>` populated by its own
`notifd.connect("notified", …)` hook. Notifications already present at startup
(restored from the cache) are **not** in the set, so their action buttons are
hidden — invoking them would no-op since the sender is gone. Notifications that
arrive during the session are live and render working action buttons.

### D5: Clear All / dismiss / DND via the daemon

Clear All iterates `notifd.notifications` and calls `dismiss()` on each (no bulk
API). Per-item dismiss is `notification.dismiss()`. The header DND toggle and the
`toggle-dnd` IPC both set `notifd.dontDisturb = !notifd.dontDisturb`.

### D6: Bar bell becomes the toggle

`ags/windows/bar/notifications.tsx` becomes a button: `onClicked` → `toggleCenter()`;
`iconName` bound to `dontDisturb` (a "notifications-disabled" glyph under DND,
the normal bell otherwise); an unread badge shows `notifications.length` when > 0.

### D7: MPRIS widget reuses the media pattern

The now-playing widget reuses the `pickBest`/`watchPlayer` active-player approach
from `ags/windows/bar/media.tsx`, showing title/artist/icon plus play-pause /
next / previous buttons (`AstalMpris` `play_pause` / `next` / `previous`),
visible only when a player exists.

### D8: IPC verbs + keybinds

`ags/app.ts` `requestHandler` handles `toggle-notifications` (→ `toggleCenter()`)
and `toggle-dnd` (→ toggle `dontDisturb`). Keybinds in `bindings.nix`:
`SUPER, N` → `ags request toggle-notifications`, `SUPER SHIFT, N` →
`ags request toggle-dnd` (both free; only `CTRL SUPER, N` is taken by nmtui).

## Risks / Trade-offs

- **Collapsed revealer capturing pointer** → mitigated by zero-width collapse and
  right-only anchor; fallback is toggling `window.visible`.
- **Dead-action misclassification** → wire the `notified` hook at center init so
  the restored snapshot is captured before any new notification is processed.
- **Clear All fan-out** → dismissing many notifications fires many `resolved`
  events; harmless (popups already gone), but bounded by normal history sizes.
- **History growth** → primary control is Clear All; an optional soft retention
  cap (dismiss oldest beyond N) is a follow-up, not required here.
- **Grouping reactivity** → recompute on every `notifications` change; fine for
  realistic counts.

## Migration Plan

Purely additive: new `ags/windows/notifications/center.tsx` (+ any helper),
edits to `bar/notifications.tsx`, `app.ts`, `style.scss`, and two `bindl`-free
`bind` keybinds. Rebuild + restart the shell. Rollback: revert these and restore
the static bell.

## Open Questions

- Slide animation duration and exact group-header styling — tunable, no spec impact.
- Click-outside / Esc to close and a soft retention cap — candidate follow-ups.
