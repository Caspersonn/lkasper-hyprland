## 1. Flake & Input Changes

- [x] 1.1 Add `astal` flake input to `flake.nix` (`github:aylur/astal`)
- [x] 1.2 Add `ags` flake input to `flake.nix` (`github:aylur/ags`, with `inputs.astal.follows = "astal"`)
- [x] 1.3 Remove `walker` and `elephant` inputs from `flake.nix`
- [x] 1.4 Update `flake.nix` description from `"Omarchy - Base configuration flake"` to `"lkasper-hyprland - Personal Hyprland desktop"`
- [x] 1.5 Run `nix flake lock` to generate lock entries

## 2. Remove & Rewrite Modules

- [x] 2.1 Remove `modules/home-manager/walker.nix`
- [x] 2.2 Remove `modules/home-manager/waybar.nix`
- [x] 2.3 Remove `modules/home-manager/wofi.nix` (replaced by AGS launcher in future phase)
- [x] 2.4 Remove `modules/home-manager/mako.nix` (replaced by AGS notifications in future phase)
- [x] 2.5 Rewrite `modules/home-manager/themes.nix`:
  - KEEP: `config.omarchy.*` option declarations (import config.nix)
  - KEEP: nix-colors HM module import + `config.colorScheme`
  - KEEP: `home.packages` (from _packages.nix)
  - KEEP: GTK theme configuration
  - KEEP: Per-theme palette files (convert TOML → JSON for AGS)
  - KEEP: Per-theme wallpaper deployment
  - KEEP: Declarative configs for retained apps (hypr/theme.conf, btop, ghostty, opencode, starship)
  - REMOVE: bin/ scripts deployment
  - REMOVE: omarchy PATH/sessionPath additions
  - REMOVE: waybar/wofi/mako/walker runtime files + all .tpl templates
  - REMOVE: theme-default, theme-list, light.mode files
- [x] 2.6 Clean up `modules/home-manager/_hyprland/envs.nix`: remove OMARCHY_PATH and omarchy bin/ PATH, keep Wayland env vars
- [x] 2.7 Remove `config/waybar/` directory (no longer needed)
- [x] 2.8 Remove `config/walker/` directory (no longer needed)
- [x] 2.9 Remove omarchy bin/ scripts that are no longer used (review which scripts have no remaining consumers)
- [x] 2.10 Rename `omarchy` → `lkasper-hyprland` across all retained modules:
  - `config.nix`: `omarchyOptions` → `lkasperHyprlandOptions`
  - `themes.nix` + `system.nix`: `options.omarchy` → `options.lkasper-hyprland`, `config.omarchy` → `config.lkasper-hyprland`
  - All retained modules with `cfg = config.omarchy` (ghostty, bindings, envs, configuration, system)
  - All flake module names: `omarchy-*` → `lkh-*` (e.g. `omarchy-themes` → `lkh-themes`)
  - Runtime paths: `~/.local/share/omarchy/` → `~/.local/share/lkasper-hyprland/`
  - Config paths: `~/.config/omarchy/` → `~/.config/lkasper-hyprland/`
  - Theme file names: `omarchy-runtime` → `lkh-runtime` (btop, ghostty)

## 3. AGS Project Setup

- [x] 3.1 Create `ags/app.ts` — GTK4 entry point with `app.start()`, importing style.scss, creating Bar window
- [x] 3.2 Create `ags/tsconfig.json` — TypeScript config for AGS/GJS environment
- [x] 3.3 Create `ags/env.d.ts` — type declarations for SCSS/CSS module imports
- [x] 3.4 Create `ags/style.scss` — root stylesheet with Catppuccin Mocha color variables, split-pill layout, capsule styling, separators, workspace dots
- [x] 3.5 Create `ags/windows/` directory structure for bar components

## 4. Bar Implementation

- [x] 4.1 Create `ags/windows/bar/index.tsx` — Bar window component (Astal.Window, anchor TOP|LEFT|RIGHT, exclusivity EXCLUSIVE, floating margins, `<centerbox>` positioning three pill containers)
- [x] 4.2 Create `ags/windows/bar/left-pill.tsx` — Left pill capsule container wrapping workspaces
- [x] 4.3 Create `ags/windows/bar/center-pill.tsx` — Center pill capsule container wrapping clock + media
- [x] 4.4 Create `ags/windows/bar/right-pill.tsx` — Right pill capsule container wrapping all status modules with separators
- [x] 4.5 Create `ags/windows/bar/workspaces.tsx` — Workspace dots using astal-hyprland (filled=active, outline=occupied, hidden=empty, click to switch)
- [x] 4.6 Create `ags/windows/bar/clock.tsx` — Clock module ("Mon HH:mm" format, 1-second interval)
- [x] 4.7 Create `ags/windows/bar/media.tsx` — Media module using astal-mpris (artist - title in center pill, hidden when no player)
- [x] 4.8 Create `ags/windows/bar/battery.tsx` — Battery module using astal-battery (icon, percentage, charging state)
- [x] 4.9 Create `ags/windows/bar/wifi.tsx` — WiFi module using astal-network (signal icon, disconnected state, SSID tooltip)
- [x] 4.10 Create `ags/windows/bar/bluetooth.tsx` — Bluetooth module using astal-bluetooth (icon, device count tooltip)
- [x] 4.11 Create `ags/windows/bar/volume.tsx` — Volume module using astal-wireplumber (icon by level, scroll to adjust, mute state)
- [x] 4.12 Create `ags/windows/bar/cpu.tsx` — CPU module (percentage from /proc/stat, polled every 3 seconds)
- [x] 4.13 Create `ags/windows/bar/tray.tsx` — System tray module using astal-tray
- [x] 4.14 Create `ags/windows/bar/notifications.tsx` — Notification bell placeholder (static bell icon, non-functional)

## 5. Nix Build Integration

- [x] 5.1 Create `modules/home-manager/ags.nix` — home-manager module that builds AGS shell via `ags bundle`, installs binary, declares Astal library dependencies
- [x] 5.2 Verify build with `nix build` or `home-manager build`

## 6. Hyprland Configuration Updates

- [x] 6.1 Update `modules/home-manager/_hyprland/autostart.nix` — replace waybar exec-once with `lkasper-shell`, remove omarchy-theme-set exec-once, remove swaybg if still referencing omarchy paths
- [x] 6.2 Update `modules/home-manager/_hyprland/bindings.nix` — remove all `omarchy-menu` and `omarchy-launch-*` references, replace with direct app commands. Note: `quick_app_bindings` from `config."lkasper-hyprland"` is still used and kept.
- [x] 6.3 Review `modules/home-manager/hyprland.nix` and `_hyprland/configuration.nix` for remaining omarchy script references in comments and clean up

## 7. Verification

- [x] 7.1 Run `nix fmt` to verify formatting
- [x] 7.2 Run `nix flake check` to verify flake validity
- [x] 7.3 Update `README.md` to reflect new project name, AGS shell, updated module names, and removed omarchy references

## 8. Fix AGS Import Paths & API Usage

Build failed because AGS v2 uses different import paths and API names than initially assumed. The actual AGS JS lib (`ags-js-lib`) re-exports from `gnim` — there is no `"astal"` module, no `Variable`, no `bind`. Fix all bar components.

**Import path mapping:**
- `"astal"` → `"ags"` (exports: createState, createBinding, createComputed, Accessor, For, With)
- `"astal/file"` → `"ags/file"` (exports: readFile, writeFile, monitorFile)
- `"ags/gtk4/widget"` → `"ags/gtk4"` (exports: Astal, Gtk, Gdk — no widget.ts exists)
- `"ags/time"` — new import for createPoll

**API mapping:**
- `bind(obj, "prop")` → `createBinding(obj, "prop")`
- `Variable(init)` → `createState(init)` returns `[getter, setter]`
- `Variable("").poll(interval, fn)` → `createPoll(init, interval, fn)` from `"ags/time"`
- `bind(variable)` → just use the accessor directly (getter function)
- `.as(fn)` → works on Accessor (both createBinding and createPoll return Accessor)

- [x] 8.1 Fix `ags/app.ts` and `ags/windows/bar/index.tsx` — change `import { App }` → `import App` (default export from `"ags/gtk4/app"`), change `"ags/gtk4/widget"` → `"ags/gtk4"` in index.tsx
- [x] 8.2 Fix `ags/windows/bar/workspaces.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.3 Fix `ags/windows/bar/clock.tsx` — change `"astal"` → `"ags"` + `"ags/time"`, `Variable().poll()` → `createPoll()`
- [x] 8.4 Fix `ags/windows/bar/media.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.5 Fix `ags/windows/bar/battery.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.6 Fix `ags/windows/bar/wifi.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.7 Fix `ags/windows/bar/bluetooth.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.8 Fix `ags/windows/bar/volume.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`
- [x] 8.9 Fix `ags/windows/bar/cpu.tsx` — change `"astal"` + `"astal/file"` → `"ags"` + `"ags/file"` + `"ags/time"`, `Variable().poll()` → `createPoll()`
- [x] 8.10 Fix `ags/windows/bar/tray.tsx` — change `"astal"` → `"ags"`, `bind()` → `createBinding()`

## 9. Fix Runtime Issues

Post-build runtime errors discovered after deploying with `home-manager switch`.

- [x] 9.1 Fix `modules/home-manager/ags.nix` — change `wrapGAppsHook3` → `wrapGAppsHook4`. AGS is a GTK4 application; `wrapGAppsHook3` injects GTK3 GI typelibs alongside GTK4 ones, causing duplicate type registration (glib 2.86 vs 2.84, pango 1.57 vs 1.56) and a GJS abort on `GDesktopAppInfoLookup`.
- [x] 9.2 Fix `lib/selected-wallpaper.nix` — update wallpaper path from nonexistent `~/Pictures/Wallpapers/1-Pawel-Czerwinski-Abstract-Purple-Blue.jpg` to `~/Pictures/Wallpapers/catppuccin/1-totoro.png` (matches Catppuccin Mocha theme for Phase 1). Hyprpaper was failing to load any wallpaper.

## 10. Fix GI Typelib Conflict and Ghostty Config

The `wrapGAppsHook4` fix (9.1) did NOT resolve the GJS crash. Root cause: the separate `astal` flake input uses a different nixpkgs revision than the `ags` flake, producing `glib-2.84.4` + `gtk4-4.18.6` (astal) alongside `glib-2.86.3` + `gtk4-4.20.3` (ags/system). The wrapGAppsHook merges all GI typelib paths, causing duplicate type registration.

- [x] 10.1 Remove `astal` flake input from `flake.nix`. Remove `inputs.astal.follows = "astal"` from ags input. The AGS flake re-exports all Astal packages built against its own nixpkgs.
- [x] 10.2 Update `modules/home-manager/ags.nix` — change `inputs.astal.packages.${system}` → `inputs.ags.packages.${system}` for all Astal library buildInputs.
- [x] 10.3 Run `nix flake lock` to update lockfile (astal now resolved through `ags/astal` with `ags/astal/nixpkgs` following `ags/nixpkgs`).
- [x] 10.4 Fix `modules/home-manager/ghostty.nix` — remove `config-file = "~/.config/lkasper-hyprland/current/theme/ghostty.conf"`. This directory doesn't exist (created by removed omarchy-theme-set). Ghostty theme colors are already baked into `~/.config/ghostty/themes/lkh-runtime` by themes.nix at build time.
- [x] 10.5 Remove `wrapGAppsHook4` and `gobject-introspection` from `ags.nix` — `wrapGAppsHook4` from `pkgs` injects system nixpkgs' gtk4/glib closure into `GI_TYPELIB_PATH`, producing duplicate store paths for glib-2.86.3 (same version, different nix hash). GJS aborts on duplicate type registration regardless of version match. Fix: use `pkgs.makeWrapper` and manually set `GI_TYPELIB_PATH` to only Astal library typelib dirs (from AGS flake). GJS finds base typelibs (Gio, Gtk, GLib) through its compiled-in search paths.

## 11. Fix AGS JSX Runtime Errors

Runtime failures exposed outdated JSX usage. Gnim JSX uses `class`, list rendering needs `<For>`, and scroll handling must use event controllers.

- [x] 11.1 Replace `className`/`cssClasses` with `class` in all AGS bar components
- [x] 11.2 Render workspaces and tray items with `<For>` instead of returning JSX from Accessors
- [x] 11.3 Move volume scroll handling to `Gtk.EventControllerScroll` (GtkBox has no `scroll` signal)
- [x] 11.4 Bind media label/visibility directly instead of returning JSX from Accessors
