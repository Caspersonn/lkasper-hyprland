# Custom launcher

Epic: [`lkasper-hyprland-ja0e`](../../../.beans/lkasper-hyprland-ja0e--custom-launcher-same-fundamentals-as-keybind-cheat.md)

## Why

The desktop launches apps through walker, an external launcher whose theming lives outside this shell and does not match the gruvbox-themed AGS surfaces (bar, notification center, keybind cheatsheet). Now that the keybind cheatsheet has established a reusable layer-shell overlay pattern, a first-party AGS launcher can share those fundamentals and give the launcher a consistent look and lifecycle, while keeping walker installed as a fallback.

## What Changes

- **New AGS capability** `ags/windows/launcher/` — a centered floating modal (layer-shell overlay) built on the same shell fundamentals as the keybind cheatsheet (all-edge OVERLAY, dimmed backdrop, centered card, `EXCLUSIVE` keymode, `ESC`/backdrop dismissal, gruvbox palette). It shows a text entry on top and a vertical single-column list of applications (icon + name per row) below.
- **App source**: enumerate and launch applications via `AstalApps`, using its fuzzy query for live filtering as the user types. This requires **adding `apps` to `astalLibs`** in the nested `ags/flake.nix`, which is not currently wired in.
- **Keyboard navigation** (must-have): the entry holds typing focus while `Up`/`Down` move a highlighted selection through the filtered results and `Enter` launches the selected app; `ESC` closes without launching.
- **Launch**: plain `AstalApps` `.launch()` (no `uwsm app --` prefix for now).
- **Replace walker as the primary launcher**: `SUPER, SPACE` → `ags request toggle-launcher`; walker keeps a backup bind on `SUPER CTRL, SPACE`. `toggle-bars` stays on `SUPER SHIFT, SPACE`. Walker itself stays installed and autostarted (only rebinding, not removing it).
- **Bar launcher button**: `ags/windows/bar/index.tsx` launcher button opens the AGS launcher (`ags request toggle-launcher`) instead of exec-ing walker.
- **Wire** a `toggle-launcher` branch into the `app.ts` `requestHandler` and an `initLauncher()` call in `main()`, mirroring the existing shortcuts/notification-center toggle pattern.
- **Add SCSS** for the launcher backdrop, modal card, search entry, and result rows using existing palette variables.
- **Out of scope** (v1): non-app modes such as calculator, run-command, or emoji. The window is structured to leave room for such modes later, but none are implemented here.

## Capabilities

### New Capabilities

- `app-launcher`: the AGS launcher overlay window, its `AstalApps` fuzzy-search data source, keyboard-driven selection + launch, and open/close lifecycle.

### Modified Capabilities

- `hyprland-config`: `SUPER, SPACE` SHALL open the AGS launcher instead of walker, and walker SHALL move to a backup bind (`SUPER CTRL, SPACE`).

## Impact

- **AGS shell**: new `ags/windows/launcher/index.tsx`; `ags/app.ts` (request branch + init); `ags/style.scss` (launcher styles); `ags/windows/bar/index.tsx` (launcher button target).
- **Nested flake**: `ags/flake.nix` — add `apps` to `astalLibs` so `gi://AstalApps` resolves at bundle time.
- **Home-manager / Hyprland**: `modules/home-manager/_hyprland/bindings.nix` (rebind `SUPER, SPACE`, add `SUPER CTRL, SPACE` walker backup).
- **Runtime dependency**: `AstalApps` (new); `ags request` (already used). Walker remains installed/autostarted as a fallback.
- No NixOS-module changes.
