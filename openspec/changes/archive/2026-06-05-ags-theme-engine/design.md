## Context

Phase 1 delivered a working AGS GTK4 bar with hardcoded Catppuccin Mocha colors in `ags/style.scss`. The Nix side (`modules/home-manager/themes.nix`) already generates per-theme `colors.json` files at `~/.local/share/lkasper-hyprland/themes/<name>/colors.json` containing Base16 palette values (base00-base0F plus `#`-prefixed background/foreground/accent). Wallpapers are deployed to `~/.local/share/lkasper-hyprland/themes/<name>/backgrounds/`. There are 18 themes defined in `modules/_themes.nix`.

Several non-AGS apps have their theme configs generated at Nix build time in `themes.nix` using `config.colorScheme.palette` (hardcoded to `tokyo-night`): Hyprland border colors (`~/.config/hypr/theme.conf`), btop (`~/.config/btop/themes/lkh-runtime.theme`), Ghostty (`~/.config/ghostty/themes/lkh-runtime`), opencode (`~/.config/opencode/themes/opencode.json`), starship (`~/.config/starship.toml`). These are currently Nix store symlinks via `home.file` and can't be overwritten at runtime.

AGS currently imports the compiled SCSS as a static string at bundle time via `import style from "./style.scss"` and passes it to `App.start({ css: style })`.

Wallpapers are managed by hyprpaper (`services.hyprpaper` in `hyprpaper.nix`), which supports runtime image switching via IPC.

## Goals / Non-Goals

**Goals:**
- Switch AGS bar theme at runtime without restarting the shell
- Propagate theme colors to Hyprland, Ghostty, btop, and starship at runtime
- Switch wallpaper per theme via hyprpaper IPC
- Persist theme selection across AGS restarts and reboots
- Support all 18 themes defined in `_themes.nix`

**Non-Goals:**
- Hyprlock runtime theming (no IPC mechanism; remains build-time via `config.colorScheme.palette`)
- Opencode runtime theming (no reload mechanism; remains build-time)
- User-defined custom themes (only Nix-generated palettes)
- Theme switching UI (that's Phase 4 launcher; Phase 2 provides the service + CLI/IPC trigger)

## Decisions

### 1. GTK CSS generation directly from palette (no SCSS at runtime)

The theme engine generates a complete GTK CSS string directly from the Base16 palette JSON, inlining all color values. It uses GTK CSS `alpha()` function instead of SCSS `rgba()`. The generated CSS replaces the bundle-time CSS via `app.reset_css()` + `app.apply_css()`.

**Why:** The current `style.scss` only uses SCSS for variables and `rgba($var, alpha)`. GTK CSS has native `alpha(@color, value)` support. Generating GTK CSS directly eliminates the dart-sass runtime dependency, avoids needing SCSS source files at runtime, and removes the complexity of load-path overrides.

**Alternative considered:** Runtime SCSS compilation with dart-sass. Rejected because it requires bundling SCSS source files alongside the binary, adding dart-sass as a runtime dependency, and resolving Nix store paths at runtime -- all unnecessary complexity when GTK CSS can do the same thing natively.

### 2. Base16 to Catppuccin variable mapping

The theme engine maps the 16 Base16 palette slots to the ~27 Catppuccin-named variables used in the stylesheet. Multiple Catppuccin variables map to the same Base16 slot (e.g., `$teal`, `$sapphire`, `$sky` all map to `base0C`). This is acceptable because the bar currently uses only ~9 distinct colors.

**Why:** Base16 provides 16 colors; Catppuccin has 27. The mapping loses some nuance between similar shades but is sufficient for the minimal bar UI. The generated GTK CSS inlines the final hex values directly, so no variable resolution is needed.

### 3. Theme engine as singleton module, not GObject service

Implement the theme engine as a plain TypeScript module (`ags/services/theme.ts`) exporting functions (`loadTheme`, `getCurrentTheme`, `getThemeList`) and reactive state (via `createState`). Not a GObject-based Astal service.

**Why:** The theme engine doesn't expose GObject properties that other Astal libraries need to bind to. It's consumed only by AGS code internally. A plain module with exported state is simpler and sufficient.

### 4. Non-AGS app propagation: write config files + reload

For each non-AGS app, the theme engine writes the config file in the same format that `themes.nix` currently generates, then triggers a reload:

| App | Config file written | Reload mechanism |
|-----|-------------------|------------------|
| Hyprland | `~/.config/hypr/theme.conf` | `hyprctl reload` |
| Ghostty | `~/.config/ghostty/themes/lkh-runtime` | `kill -SIGUSR1 $(pgrep ghostty)` |
| btop | `~/.config/btop/themes/lkh-runtime.theme` | No reload (picks up on next launch) |
| starship | `~/.config/starship.toml` | No reload (picks up on next prompt) |

**Why:** Reuses the exact file paths and formats already established in `themes.nix`. Ghostty does not auto-watch theme files -- it only watches its main config file. Sending SIGUSR1 forces a config reload which picks up the updated theme.

### 5. Mutable config files via home.activation

Move non-AGS app theme configs from `home.file` (which creates immutable Nix store symlinks) to `home.activation` (which runs a shell script during `home-manager switch` to create mutable real files). The activation script only writes defaults if the file doesn't exist yet, preserving the theme engine's runtime changes across `home-manager switch`.

**Why:** `home.file` entries become symlinks to the Nix store, which is read-only. The theme engine needs to overwrite these files at runtime. `home.activation` runs after the `writeBoundary` phase and can create real, mutable files. The "only write if missing" guard ensures `home-manager switch` doesn't clobber the user's runtime theme choice.

**Config files moved:** `~/.config/hypr/theme.conf`, `~/.config/btop/themes/lkh-runtime.theme`, `~/.config/ghostty/themes/lkh-runtime`, `~/.config/starship.toml`. The `opencode.json` stays in `home.file` since it has no runtime reload mechanism.

### 6. Wallpaper switching via hyprpaper IPC

The theme engine picks the first wallpaper (alphabetically) from `~/.local/share/lkasper-hyprland/themes/<name>/backgrounds/`, then uses hyprpaper IPC to switch: `hyprctl hyprpaper preload <path>` followed by `hyprctl hyprpaper wallpaper ",<path>"`. Also writes the path to `~/.config/lkasper-hyprland/current/wallpaper` for hyprlock.

**Why:** The setup already uses hyprpaper (not swaybg). Hyprpaper supports runtime wallpaper switching via IPC, so no process kill/relaunch is needed.

**Alternative considered:** Kill + relaunch swaybg. Rejected because hyprpaper is already configured and has IPC support.

### 7. Persistence: plain text file

Store the current theme name in `~/.config/lkasper-hyprland/current/theme.name`. On AGS startup, read this file and apply the theme. If the file doesn't exist, fall back to `catppuccin` (Catppuccin Mocha).

**Why:** Simple, human-readable, no dependencies. Matches the path convention already used (`~/.config/lkasper-hyprland/current/`).

### 8. Theme trigger mechanism: AGS IPC request

Themes are switched by sending an AGS request: `ags request "theme set <name>"`. The `requestHandler` in `app.ts` dispatches to the theme service. This allows keybinds, future launcher, or CLI scripts to trigger theme changes.

**Why:** AGS has built-in IPC via `App.start({ requestHandler })`. No need for external sockets or DBus.

### 9. Ghostty theme reference

Add `theme = "lkh-runtime"` to `ghostty.nix` settings so Ghostty actually loads the theme file generated by themes.nix / the theme engine.

**Why:** The theme file at `~/.config/ghostty/themes/lkh-runtime` exists but Ghostty never references it. Without this setting, Ghostty ignores the file entirely.

### 10. Workspace dots: smaller + active horizontal expansion

Reduce workspace dots from 8px to 6px. Active workspace dot expands horizontally to 18px (pill shape) with a 200ms CSS transition. Inactive occupied dots remain 6x6 perfect circles. Inspired by Marble Shell's workspace indicator.

**Why:** Current 8px dots appear too large and ovoid in the pill container. Smaller dots with horizontal expansion for the active workspace provide a cleaner, more refined visual indicator while clearly communicating which workspace is focused.

### 11. Hyprland client icons in left pill

Add deduplicated app icons to the left pill, after the workspace dots with a separator. Each open application class gets one icon (even if multiple windows exist). Clicking an icon focuses the most recent window of that app. Uses `createBinding(hypr, "clients")` for reactivity and `client.class` as icon name.

**Why:** Marble Shell shows open application icons alongside workspace dots. This provides at-a-glance visibility of which apps are running and enables quick window focus without workspace switching. Deduplication keeps the bar clean.

**Alternative considered:** Show all windows (including duplicates). Rejected because multiple terminals/browser windows would clutter the bar.

### 12. Battery icon: use `batteryIconName` instead of `iconName`

Switch from UPower's generic `iconName` (returns static `battery-good-symbolic` regardless of level) to AstalBattery's `batteryIconName` (returns `battery-level-XX-symbolic` per percentage and charging state).

**Why:** `iconName` always shows the same icon. `batteryIconName` provides level-specific icons that visually represent the actual battery percentage.

## Risks / Trade-offs

- [Race condition on startup] themes.nix writes build-time defaults via activation (only if missing), then AGS overwrites with persisted theme. On fresh boot, activation writes tokyo-night defaults; AGS immediately applies persisted theme. Brief flash possible but unlikely since AGS applies theme before showing windows.
- [Wallpaper path assumptions] Theme engine assumes first file alphabetically in backgrounds/ directory. Some themes may have multiple wallpapers. Acceptable for Phase 2; Phase 4 launcher can add wallpaper selection.
- [File write permissions] Theme engine writes to `~/.config/` paths. If paths don't exist (first boot before home-manager), writes fail. Mitigation: Theme engine creates directories before writing.
- [home.activation idempotency] The "only write if missing" guard means if a config file gets corrupted or deleted, `home-manager switch` will recreate it with defaults. But if the user wants to reset to defaults, they need to delete the file and re-run `home-manager switch`.
- [GTK CSS completeness] The generated GTK CSS must reproduce all styles from `style.scss` with different color values. Any new style additions to `style.scss` must also be replicated in the GTK CSS generator in `theme.ts`. This coupling is a maintenance risk.
