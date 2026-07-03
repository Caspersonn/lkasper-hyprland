# Design — Keybind cheatsheet overlay

## Context

Binds live in `modules/home-manager/_hyprland/bindings.nix` as declarative strings across `bind`, `bindm`, `bindel`, `bindl`, `bindp` plus `cfg.quick_app_bindings`. The `#` comments group them (*End active session*, *Screenshots*, *Control tiling*…) but are Nix-only and gone at runtime.

Runtime facts confirmed against the live session:
- `hyprctl binds -j` works from the AGS shell and returns all live binds (83 at time of writing).
- Every bind currently reports `"has_description": false` / `"description": ""` because the config uses plain `bind`, not `bindd`.
- Mods arrive as a **bitmask** (`modmask`): `SHIFT=1, CAPS=2, CTRL=4, ALT=8, MOD2=16, MOD3=32, SUPER/LOGO=64, MOD5=128`. Observed: `SUPER=64`, `SUPER SHIFT=65`, `SUPER CTRL=68`, `SUPER SHIFT CTRL=69`, `SUPER ALT=72`.
- `dispatcher` and `arg` come through raw (e.g. `exec` / `ghostty`), and `key` is the raw keysym name (`slash`, `Return`, `left`, digits `1`…`0`).

The AGS shell already has the patterns this feature needs: a layer-shell overlay window (`ags/windows/osd/index.tsx` — `<window layer={Astal.Layer.OVERLAY}>`), a `requestHandler` toggle dispatch (`ags/app.ts:12`), a toggle-by-name lifecycle (`ags/windows/notifications/center.tsx` `toggleCenter`), and `execAsync` usage for external commands.

## Goals / Non-Goals

**Goals**
- One source of truth for both the keybind and its label (no drift).
- Centered floating modal matching the reference "Keyboard shortcuts" webapp modal.
- Automatic noise filtering: only opted-in (described) binds appear.
- Grouped, dense layout with keycap chips; `ESC`/backdrop-click to close.

**Non-Goals**
- No editing of binds from the overlay (read-only).
- No per-monitor duplication logic beyond what the compositor does; a single window is acceptable.
- No search/filter box in v1 (reference image has none).
- Not migrating *every* bind — media/mouse/volume binds intentionally stay plain `bind` and hidden.

## Decisions

### D1 — Data source: `bindd` + `hyprctl binds -j` (one source of truth)

Migrate meaningful binds from `bind` to `bindd`. The description travels with the bind, so changing one changes both. The overlay shows only `has_description == true` entries, which makes noise-filtering a natural opt-in.

Alternatives rejected:
- **Raw `hyprctl` only** — accurate but shows raw dispatcher/arg (`exec ghostty`), no friendly labels or grouping.
- **Hardcoded label map in AGS** — drifts the moment a bind changes; two sources of truth keyed by mod+key.
- **Generate JSON from Nix comments** — comments aren't structured data; fragile parsing.

### D2 — Grouping via `[Group] Label` description convention

Encode the group inside the description as a bracketed prefix: `"[Windows] Kill active window"`. The shell splits on the first `] ` into `{group, label}`; a description with no bracket falls back to group `Other`. Groups render as columns/sections in the modal (like the reference's two-column layout).

### D3 — Centered modal via full-screen layer-shell window + dimmed backdrop

`<window>` anchored to all four edges (fills the output), `layer={Astal.Layer.OVERLAY}`, `exclusivity={Astal.Exclusivity.IGNORE}`. Inside: a `.sc-backdrop` box (semi-transparent, `halign/valign=FILL`) carrying a `GestureClick` that closes; a `.sc-modal` box (`halign/valign=CENTER`) is the card. This reuses the OSD window recipe, adding the backdrop + centering.

### D4 — Keyboard handling: `keymode={Astal.Keymode.EXCLUSIVE}` + `EventControllerKey`

The window grabs the keyboard while visible so `ESC` reliably closes it (attach a `Gtk.EventControllerKey`, close on `Escape`). This matches launcher-style transient modals. Toggling visibility off releases the grab.

### D5 — Toggle lifecycle mirrors the notification center

Add `initShortcuts()` (constructs the window, registers a module-level visibility handle) and `toggleShortcuts()` to a new `ags/windows/shortcuts/` module; call `initShortcuts()` from `main()` and dispatch `toggle-shortcuts` from `requestHandler`. Data is (re)fetched via `execAsync(["hyprctl","binds","-j"])` on each open so the sheet is always current.

### D6 — Workspace-number binds collapse into range rows

`SUPER 1-0` and `SUPER SHIFT 1-0` are described in Nix, but the shell collapses a run of binds that share the same `{group, modmask, dispatcher}` and whose keys are consecutive digits into one row with a range chip (`1 – 0`). Keeps the sheet complete without 20 near-identical lines.

### D7 — Key prettify map

Raw keysyms are mapped to glyphs/short forms for chips: `slash→/`, `Return→⏎`, `Escape→Esc`, `left/right/up/down→←/→/↑/↓`, `Backspace→⌫`, `minus→-`, `equal→=`, `comma→,`, `period→.`, digits pass through. Mods decode to `Super/Shift/Ctrl/Alt` chips (order: Super, Ctrl, Alt, Shift).

## Risks / Trade-offs

- **Verbose Nix** (descriptions inline on ~30 binds) → acceptable; declarative and self-documenting.
- **`EXCLUSIVE` keyboard grab blocks other apps while open** → fine for a transient modal; visibility-off releases it. If it feels heavy, `ON_DEMAND` is a drop-in fallback.
- **Collapse heuristic mis-grouping** (D6) → scoped strictly to consecutive-digit keys sharing group+mod+dispatcher; anything else renders as individual rows.
- **`bindd` arg-position mistakes** → `bindd` inserts the description as an extra field before the dispatcher; a malformed line silently drops the bind. Mitigation: `hyprctl binds` after rebuild to confirm count + `has_description`.

## Migration Plan

1. Convert meaningful `bind` entries to `bindd` with `[Group] Label` descriptions; add the `SUPER, slash` overlay bind.
2. Build the AGS `shortcuts/` module + styles; wire `app.ts`.
3. `ags bundle app.ts` compiles clean; rebuild home-manager; verify `hyprctl binds -j` shows `has_description: true` for migrated binds and the overlay renders.
4. Rollback = revert `bindings.nix` + remove the `shortcuts/` wiring (plain `bind` still works).

## Open Questions

- Exact final group taxonomy (`Windows`, `Workspaces`, `System`, `Screenshots`, `Media`, `Session`…) — refine during migration.
- Whether the overlay should also list `bindp`/`bindel` entries (power profiles, brightness) — default: describe power profiles, leave volume/brightness media keys hidden.
