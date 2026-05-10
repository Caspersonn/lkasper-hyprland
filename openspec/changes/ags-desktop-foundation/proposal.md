## Why

The current desktop configuration is built on top of the omarchy framework, which introduces unnecessary complexity: a menu system we don't use, themes that render poorly, bash scripts for orchestration that should be declarative, and sed-based template rendering. We want to replace omarchy entirely with a custom AGS v2 (Astal) shell on NixOS + Hyprland, giving full control over every component.

This change covers **Phase 1 only**: project foundation, Nix module structure, and the status bar. Subsequent phases are separate changes:
- Phase 2: `ags-theme-engine` — runtime theme switching
- Phase 3: `ags-quick-settings` — quick-settings popup (BT, WiFi, Volume)
- Phase 4: `ags-launcher` — spotlight-style launcher
- Phase 5: `ags-notifications` — toast + notification center + DND
- Phase 6: `ags-osd-peripherals` — OSD, hyprlock, hypridle, screenshots, clipboard

All work happens on the `feature/ags` branch. This is a big-bang migration: the branch diverges from main and will contain the complete new configuration. Main remains untouched until the migration is validated and ready to merge.

## What Changes

- **BREAKING**: Remove all omarchy dependencies and framework code (omarchy menu, omarchy-* scripts, omarchy.* options, walker/elephant launcher)
- **BREAKING**: Remove waybar entirely, replaced by AGS bar
- Create new Nix module structure targeting `homeManagerModules` without omarchy abstractions
- Set up AGS v2 project (GTK4, TypeScript, SCSS) with Nix build integration via `ags bundle`
- Build a floating top bar with: workspaces (left), media + clock (center), tray/bluetooth/wifi/volume/cpu/notifications-bell/battery (right)
- Correct AGS JSX usage (class prop, list rendering, scroll handlers) to avoid runtime crashes and render errors
- Configure Hyprland with keybinds directly (no omarchy-menu indirection)
- Configure Ghostty terminal
- Set up basic SCSS theming structure (hardcoded single theme for now; runtime theme engine is Phase 2)
- Fix hyprpaper wallpaper configuration to point to existing Catppuccin wallpaper (`1-totoro.png`)

## Capabilities

### New Capabilities
- `ags-shell`: AGS v2 project setup, Nix build/install, app entry point, SCSS pipeline, GTK4 window management
- `ags-bar`: Floating top status bar with all modules (workspaces, clock, media, system tray, bluetooth, wifi, volume, cpu, notification bell, battery)
- `hyprland-config`: Hyprland window manager configuration (keybinds, settings, autostart) without omarchy wrappers
- `nix-module-structure`: Clean Nix flake module layout for home-manager without omarchy framework

### Modified Capabilities

## Impact

- **Nix modules**: All `modules/home-manager/*.nix` files will be rewritten or replaced. `modules/nixos/` system modules may be simplified.
- **Config files**: `config/waybar/` removed. New `ags/` directory for the AGS TypeScript project.
- **Flake inputs**: Add `astal` (libraries) and `ags` (CLI/bundler) flake inputs. Remove `walker` and `elephant` inputs.
- **Dependencies**: Add `ags`, `gjs`, `glib`, `gobject-introspection`, `wrapGAppsHook4` (GTK4-specific, not Hook3), Astal libraries (hyprland, mpris, battery, bluetooth, network, wireplumber, tray, notifd). Remove `waybar`, `walker`, omarchy scripts.
- **Home-manager outputs**: `homeManagerModules` will expose new modules instead of omarchy-prefixed ones.
- **Runtime**: AGS process replaces waybar. Hyprland autostart updated.
