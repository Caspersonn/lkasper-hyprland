# Keybind cheatsheet overlay

Epic: [`lkasper-hyprland-36ce`](../../../.beans/lkasper-hyprland-36ce--keybind-cheatsheet-overlay.md)

## Why

Hyprland keybinds are only discoverable by reading `bindings.nix`; the `#` comments that group and explain them are Nix-only and evaporate at runtime. There is no way to recall "what was that shortcut" without leaving the desktop and opening a source file. A single overlay, opened by a shortcut, should list the available binds the way a webapp's "Keyboard shortcuts" modal does.

## What Changes

- **Migrate meaningful binds** in `modules/home-manager/_hyprland/bindings.nix` from `bind` to `bindd` (bind-with-description), embedding a `[Group] Label` description convention (e.g. `"SUPER, Q, [Windows] Kill active window, killactive,"`). Noise binds (media keys, mouse binds) stay plain `bind` and are therefore hidden from the sheet.
- **Add an overlay keybind**: `SUPER, slash` → `exec, ags request toggle-shortcuts` (itself a `bindd` labelled `[System] Show keybindings`).
- **New AGS capability** `ags/windows/shortcuts/` — a centered floating modal (layer-shell overlay) that on open runs `hyprctl binds -j`, keeps only entries with `has_description`, parses the `[Group] Label` prefix, decodes the mod bitmask + prettifies the key into keycap chips, and renders grouped rows. `ESC` or a backdrop click closes it.
- **Workspace-number binds** (`SUPER 1-0`, `SUPER SHIFT 1-0`) are described in Nix and **collapsed by the shell** into single range rows (e.g. `1 – 0  Switch to workspace`) so the sheet stays dense and clean.
- **Wire** a `toggle-shortcuts` branch into the `app.ts` `requestHandler` and an `initShortcuts()` call in `main()`, mirroring the existing notification-center toggle pattern.
- **Add SCSS** for the backdrop, modal card, group columns, and keycap chips.

## Capabilities

### New Capabilities

- `keybind-cheatsheet`: the AGS overlay window, its `hyprctl binds -j` data pipeline (filter/parse/decode/collapse), and the grouped keycap-chip rendering + open/close lifecycle.

### Modified Capabilities

- `hyprland-config`: meaningful keybinds SHALL carry human-readable descriptions via `bindd` using the `[Group] Label` convention, and a new keybind SHALL open the cheatsheet overlay.

## Impact

- **Home-manager / Hyprland**: `modules/home-manager/_hyprland/bindings.nix` (bind → bindd migration + new overlay bind).
- **AGS shell**: new `ags/windows/shortcuts/index.tsx`; `ags/app.ts` (request + init); `ags/style.scss` (modal + chip styles).
- **Runtime dependency**: `hyprctl` (already on PATH in the AGS wrapper) and `ags request` (already used by other binds).
- No NixOS-module or flake-plumbing changes.
