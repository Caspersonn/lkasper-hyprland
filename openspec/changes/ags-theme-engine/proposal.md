## Why

Phase 1 (`ags-desktop-foundation`) shipped a working AGS bar with hardcoded Catppuccin Mocha colors in `style.scss`. The Nix side already generates per-theme `colors.json` palettes and deploys wallpapers, but nothing reads them at runtime. Users are stuck on one theme with no way to switch. Phase 2 adds the runtime theme engine so AGS can dynamically restyle itself and propagate colors to non-AGS apps.

## What Changes

- New AGS theme service (`ags/services/theme.ts`) that reads Base16 palette JSON files from `~/.local/share/lkasper-hyprland/themes/<name>/colors.json`, generates GTK CSS with inlined color values, and applies the result via `app.apply_css()`
- Theme propagation to non-AGS apps: write runtime config files for Hyprland (border colors via `hyprctl reload`), Ghostty (theme file + SIGUSR1 reload), btop (theme file), and starship (config). Hyprlock colors remain build-time from `config.colorScheme.palette` (no runtime override mechanism)
- Add `theme = "lkh-runtime"` to `ghostty.nix` settings so Ghostty references the runtime theme file
- Wallpaper switching per theme via hyprpaper IPC (`hyprctl hyprpaper preload` + `wallpaper`)
- Persist current theme selection to `~/.config/lkasper-hyprland/current/theme.name` and restore on AGS startup
- Refactor `themes.nix`: move app theme config files from `home.file` (Nix store symlinks) to `home.activation` (mutable real files) so the theme engine can overwrite them at runtime. Activation script only writes defaults if the file doesn't exist yet, preserving runtime theme choices across `home-manager switch`.
- **BREAKING**: Non-AGS app theme configs are no longer Nix store symlinks. They become mutable files managed by the theme engine at runtime, with build-time defaults written by `home.activation`.

This change targets home-manager modules (`homeManagerModules.lkh-themes`, `homeManagerModules.lkh-ags`, `homeManagerModules.lkh-ghostty`) and the AGS TypeScript project.

## Capabilities

### New Capabilities
- `theme-engine`: AGS service that reads Base16 palettes, generates GTK CSS, applies it at runtime, and propagates colors to non-AGS apps
- `theme-persistence`: Persist and restore theme selection across sessions, including wallpaper state

### Modified Capabilities

(none -- no existing specs to modify)

## Impact

- `ags/app.ts`: Must initialize theme engine on startup (load persisted theme, apply CSS) and add `requestHandler` for IPC
- `ags/style.scss`: No structural changes -- theme engine generates complete GTK CSS replacements at runtime
- `ags/services/theme.ts`: New file -- core theme engine service
- `modules/home-manager/themes.nix`: Move app theme configs from `home.file` to `home.activation`, ensure `colors.json` + wallpaper paths are correct
- `modules/home-manager/ghostty.nix`: Add `theme = "lkh-runtime"` setting
- Runtime files written by theme engine:
  - `~/.config/lkasper-hyprland/current/theme.name` (persisted selection)
  - `~/.config/lkasper-hyprland/current/wallpaper` (path for hyprlock)
  - `~/.config/hypr/theme.conf` (border colors)
  - `~/.config/ghostty/themes/lkh-runtime` (terminal palette)
  - `~/.config/btop/themes/lkh-runtime.theme` (btop colors)
  - `~/.config/starship.toml` (prompt colors)
