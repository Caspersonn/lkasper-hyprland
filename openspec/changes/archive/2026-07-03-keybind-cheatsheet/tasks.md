# Tasks — Keybind cheatsheet overlay

## 1. Migrate binds to bindd

- [x] 1.1 In `modules/home-manager/_hyprland/bindings.nix`, convert meaningful `bind` entries to `bindd` with `[Group] Label` descriptions (Windows, Workspaces, System, Screenshots, Session, Tiling, Media/power as decided).
- [x] 1.2 Add the overlay bind: `"SUPER, slash, [System] Show keybindings, exec, ags request toggle-shortcuts"`.
- [x] 1.3 Describe the workspace-number binds (`SUPER 1-0`, `SUPER SHIFT 1-0`) with a shared `[Workspaces] …` label so the shell can collapse them.
- [x] 1.4 Leave `bindm`, `bindel`, `bindl` (mouse/media) as plain binds (hidden).
- [x] 1.5 `nix fmt` and rebuild home-manager; verify with `hyprctl binds -j` that migrated binds show `has_description: true`.

## 2. AGS shortcuts overlay module

- [x] 2.1 Create `ags/windows/shortcuts/index.tsx` with a layer-shell `<window>` (OVERLAY, anchor all edges, `Astal.Exclusivity.IGNORE`, `keymode={Astal.Keymode.EXCLUSIVE}`), a `.sc-backdrop` box, and a centered `.sc-modal` card with a header.
- [x] 2.2 Implement `initShortcuts()` and `toggleShortcuts()` (module-level visibility handle) mirroring `ags/windows/notifications/center.tsx`.
- [x] 2.3 On open, `execAsync(["hyprctl","binds","-j"])`, parse JSON, filter `has_description`.
- [x] 2.4 Parse `[Group] Label` → `{group, label}` (fallback group `Other`); group rows by group.
- [x] 2.5 Decode `modmask` → `Super/Ctrl/Alt/Shift` chips; prettify key (`slash→/`, `Return→⏎`, `Escape→Esc`, `Backspace→⌫`, arrows→`←/→/↑/↓`).
- [x] 2.6 Collapse consecutive-digit binds sharing group+modmask+dispatcher into one range-chip row (`1 – 0`).
- [x] 2.7 Add `EventControllerKey` closing on `Escape` and a `GestureClick` on the backdrop closing the overlay.

## 3. Wire into the shell

- [x] 3.1 In `ags/app.ts`, import from `./windows/shortcuts`, add a `toggle-shortcuts` branch to `requestHandler`, and call `initShortcuts()` in `main()`.

## 4. Styles

- [x] 4.1 In `ags/style.scss`, add `.sc-backdrop` (dim), `.sc-modal` (card), group columns/sections, `.sc-row`, and `.sc-key` keycap chip styles. Use existing SCSS palette variables; no new hardcoded colors.

## 5. Verify

- [x] 5.1 `ags bundle app.ts /tmp/opencode/lkasper-shell.js` compiles clean (only pre-existing `nth()` deprecation warnings acceptable).
- [x] 5.2 `openspec validate keybind-cheatsheet` passes.
- [x] 5.3 Manual: `SUPER, slash` opens the centered modal; groups + chips render; workspace row collapses to `1 – 0`; `Escape` and backdrop-click close it.
