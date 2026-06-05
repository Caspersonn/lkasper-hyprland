## 1. Theme Engine Core

- [x] 1.1 Create `ags/services/theme.ts` -- implement the theme engine module with:
  - `loadTheme(name: string)`: reads `~/.local/share/lkasper-hyprland/themes/<name>/colors.json`, generates GTK CSS with Base16-to-Catppuccin color mapping, applies via `app.reset_css()` + `app.apply_css()`
  - `getCurrentTheme()`: returns current theme name
  - `getThemeList()`: lists available themes by enumerating `~/.local/share/lkasper-hyprland/themes/` directories
  - `[currentTheme, setCurrentTheme]` reactive state via `createState`
- [x] 1.2 Implement Base16-to-GTK-CSS color mapping in `theme.ts` -- map palette keys to Catppuccin-named color roles per the mapping table in `specs/theme-engine/spec.md`. Generate complete GTK CSS string with all styles from `style.scss` using `alpha()` instead of SCSS `rgba()`
- [x] 1.3 Implement CSS application -- call `app.reset_css()` then `app.apply_css(generatedCss)` after successful generation

## 2. Non-AGS App Propagation

- [x] 2.1 Implement Hyprland propagation in `theme.ts` -- write `~/.config/hypr/theme.conf` with `general { col.active_border = rgba(<base0D>aa) }` and `group { col.border_active }` format, then call `hyprctl reload`
- [x] 2.2 Implement Ghostty propagation in `theme.ts` -- write `~/.config/ghostty/themes/lkh-runtime` with full terminal palette (background, foreground, selection, palette entries) matching the format in `themes.nix`, then send SIGUSR1 to Ghostty process for reload
- [x] 2.3 Implement btop propagation in `theme.ts` -- write `~/.config/btop/themes/lkh-runtime.theme` with all `theme[*]` entries matching the format in `themes.nix`
- [x] 2.4 Implement starship propagation in `theme.ts` -- write `~/.config/starship.toml` with prompt color configuration matching the format in `themes.nix`

## 3. Wallpaper Switching

- [x] 3.1 Implement wallpaper switching in `theme.ts` -- read first file (alphabetically) from `~/.local/share/lkasper-hyprland/themes/<name>/backgrounds/`, switch via hyprpaper IPC: `hyprctl hyprpaper preload <path>` then `hyprctl hyprpaper wallpaper ",<path>"`
- [x] 3.2 Write wallpaper path to `~/.config/lkasper-hyprland/current/wallpaper` for hyprlock consumption
- [x] 3.3 Handle themes with no wallpapers -- if `backgrounds/` is empty or missing, skip hyprpaper calls and retain current wallpaper

## 4. Persistence

- [x] 4.1 Implement theme persistence in `theme.ts` -- write theme name to `~/.config/lkasper-hyprland/current/theme.name` after successful theme application; create directory if needed
- [x] 4.2 Implement theme restoration on startup -- read `~/.config/lkasper-hyprland/current/theme.name` and call `loadTheme()`. Fall back to `catppuccin` if file missing or theme unavailable

## 5. AGS Integration

- [x] 5.1 Update `ags/app.ts` -- add `requestHandler` to `App.start()` that dispatches `theme set <name>`, `theme get`, and `theme list` to the theme service
- [x] 5.2 Update `ags/app.ts` -- call theme engine initialization in `main()` before `Bar()` to apply persisted theme before windows show

## 6. Nix Module Updates

- [x] 6.1 Update `modules/home-manager/ghostty.nix` -- add `theme = "lkh-runtime"` to `programs.ghostty.settings`
- [x] 6.2 Refactor `modules/home-manager/themes.nix` -- move app theme configs (hypr/theme.conf, btop/lkh-runtime.theme, ghostty/lkh-runtime, starship.toml) from `home.file` to `home.activation.writeThemeDefaults`. Activation script uses `lib.hm.dag.entryAfter [ "writeBoundary" ]`, creates directories with `mkdir -p`, and only writes each file if it doesn't already exist (`if [ ! -f ... ]`). Keep `opencode.json` in `home.file` (no runtime reload).
- [x] 6.3 Ensure `~/.config/lkasper-hyprland/current/` directory is created by the activation script

## 7. Wallpaper Cycling

- [x] 7.1 Implement `nextWallpaper()` in `theme.ts` -- reads current wallpaper from persistence file, finds next in sorted list (wraps around), applies via hyprpaper IPC, persists new path. Uses `currentTheme()` for theme name (no argument needed). Returns boolean.
- [x] 7.2 Add `wallpaper next` IPC command in `app.ts` requestHandler -- calls `nextWallpaper()`, returns success/failure message

## 8. Verification

- [x] 8.1 Run `nix fmt` and fix any formatting issues
- [x] 8.2 Run `nix flake check` and verify no errors
- [x] 8.3 Build and deploy (`home-manager switch`), verify mutable theme config files are created as real files (not symlinks)
- [x] 8.4 Test theme switch: `ags request "theme set gruvbox"` -- verify bar colors change, wallpaper switches, hyprland borders update, ghostty theme file written + reload
- [x] 8.5 Test wallpaper cycling: `ags request "wallpaper next"` -- verify wallpaper changes and cycles through all theme wallpapers
- [x] 8.6 Test persistence: restart AGS, verify it restores the last theme
- [x] 8.7 Test home-manager switch after runtime theme change -- verify runtime theme is NOT overwritten by activation script

## 9. Bar Visual Improvements

- [x] 9.1 Update `ags/style.scss` -- workspace dots: reduce `$dot-size` to 6px, add `transition: min-width 200ms ease` to `.workspace-dot`, set `.workspace-dot.active` to `min-width: 18px` for horizontal expansion effect (Marble Shell inspired). Add client icon styles.
- [x] 9.2 Create `ags/windows/bar/clients.tsx` -- new component showing deduplicated app icons from Hyprland clients. Uses `createBinding(hypr, "clients")` to get client list, deduplicates by `client.class` (keep most recent), renders each as a button with the app icon. On click: `client.focus()`. Icons resolved from `client.class` as icon name.
- [x] 9.3 Update `ags/windows/bar/left-pill.tsx` -- add `<Clients />` component after `<Workspaces />` with a separator between them
- [x] 9.4 Fix `ags/windows/bar/battery.tsx` -- change `createBinding(bat, "iconName")` to `createBinding(bat, "batteryIconName")` for level-specific battery icons
- [x] 9.5 Update `ags/services/theme.ts` -- add new workspace dot sizes, transition, and client icon styles to runtime GTK CSS generator

## 10. Bar Polish

- [x] 10.1 Change accent color from `base0D` (blue) to `base0C` (cyan/teal) in `ags/services/theme.ts` -- used for active workspace dot
- [x] 10.2 Rewrite `ags/windows/bar/media.tsx` -- single-player display with GObject signal connections (`notify::playback-status`, `notify::title`, `notify::artist`) for reactive updates. Picks best player (PLAYING > PAUSED). Stays visible when paused. Shows source icon from `player.entry` (e.g. spotify, firefox). Filters out `playerctld` proxy.
- [x] 10.3 Add `.media-entry`, `.media-icon` styles to `ags/services/theme.ts` -- 16px icon, 6px right margin
- [x] 10.4 Fix autostart race condition in `modules/home-manager/_hyprland/autostart.nix` -- add `sleep 1 &&` before `lkasper-shell` to prevent crash when Hyprland IPC socket is not yet ready
- [x] 10.5 Add CPU icon to `ags/windows/bar/cpu.tsx` -- `cpu-symbolic` icon to the right of the percentage label, with `.cpu-icon` style (14px, 4px left margin) in `theme.ts`
- [x] 10.6 Fix `switchWallpaper` in `ags/services/theme.ts` -- check if current wallpaper (from WALLPAPER_FILE) already belongs to the target theme before switching. If yes, keep it. Only switch to first wallpaper when changing to a different theme.
