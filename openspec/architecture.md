# Target Architecture: Custom AGS Desktop

This document describes the complete target state for the `feature/ags` branch. It serves as shared context across all phase changes. The migration replaces the omarchy framework entirely with a custom AGS v2 shell on NixOS + Hyprland.

## Naming Convention

The project is named `lkasper-hyprland`. All `omarchy`/`omarchy-nix` naming is replaced:

| What | Old (omarchy) | New (lkasper-hyprland) |
|------|---------------|------------------------|
| Nix option namespace | `config.omarchy.*` | `config.lkasper-hyprland.*` |
| Option definition | `omarchyOptions` | `lkasperHyprlandOptions` |
| Flake module names | `omarchy-themes`, `omarchy-hyprland`, etc. | `lkh-themes`, `lkh-hyprland`, etc. |
| Runtime data path | `~/.local/share/omarchy/` | `~/.local/share/lkasper-hyprland/` |
| Config path | `~/.config/omarchy/` | `~/.config/lkasper-hyprland/` |
| Theme file names | `omarchy-runtime` | `lkh-runtime` |
| AGS binary | — | `lkasper-shell` |
| Flake description | `"Omarchy - Base configuration flake"` | `"lkasper-hyprland - Personal Hyprland desktop"` |

Note: `lkh-` is used as a short prefix for flake module names and theme file names to keep them concise.

## Branch Strategy

All work happens on `feature/ags` (big-bang migration). Main branch remains untouched as working fallback until migration is validated and ready to merge.

## Visual Design

- **Style**: Minimal & clean, Marble Shell-inspired (GNOME-like, lots of whitespace, subtle)
- **Bar**: Top, floating, split into 3 separate capsule pills (Left / Center / Right) with gaps between them
  - Left pill: Workspace dots (filled = active, outline = occupied, hidden = empty)
  - Center pill: Clock + short day ("Mon 14:32") + media info when playing (artist - title)
  - Right pill: System tray, Bluetooth, Network (WiFi or wired), Volume, CPU, Battery, Notification bell (bell always far right)
  - Pill shape: Fully rounded capsule (border-radius = height / 2)
  - Pill background: Solid opaque (theme background color, no transparency)
  - Separators: Subtle border-left between right pill modules
- **Quick settings / Control center**: Single unified control center panel below the right pill. Opens when any right pill icon is clicked except tray and notification bell. Contains QuickActions row (user info + lock/logout), toggle tiles grid (Network, BT, DND, NightLight), sliders (volume, brightness), and inline drill-down pages via Revealer animation. Trigger icons get highlighted background when open. Click outside or Escape to close.
- **Notification center**: Right sidebar (slides in from right edge, full height)
- **Launcher**: Centered spotlight-style overlay
- **Notifications**: Toast pop-ups + notification center sidebar with history
- **OSD**: Minimal volume/brightness overlay

## Themes

Runtime switching between curated themes:
- Gruvbox Dark
- Gruvbox Light
- Catppuccin Mocha (dark)
- Catppuccin Latte (light)
- +1 TBD

Source: Base16 palettes from `nix-colors`. Nix generates JSON palette files per theme at build time. AGS reads palettes at runtime and applies CSS dynamically.

## Technology Stack

| Layer              | Technology                                    |
|--------------------|-----------------------------------------------|
| OS                 | NixOS (nixos-unstable)                        |
| Flake framework    | flake-parts + import-tree                     |
| User environment   | home-manager                                  |
| Compositor         | Hyprland                                      |
| Shell (bar, UI)    | AGS v2 (Astal) — GTK4, TypeScript, SCSS      |
| Terminal           | Ghostty                                       |
| Prompt             | Zsh + Starship                                |
| Lock screen        | Hyprlock                                      |
| Idle daemon        | Hypridle                                      |
| Wallpaper          | swaybg (controlled by AGS theme engine)       |
| Screenshots        | grim + slurp (via hyprshot)                   |
| Clipboard          | cliphist                                      |
| File manager       | TBD                                           |
| Color schemes      | nix-colors (Base16)                           |

## AGS Shell Components

```
AGS v2 Shell (single GTK4 application: lkasper-shell)
├── Bar (Astal.Window, top, floating, exclusive)
│   ├── LEFT PILL (capsule): Workspace dots (astal-hyprland)
│   │     ● active  ○ occupied  (empty hidden)
│   ├── CENTER PILL (capsule): Clock "Mon HH:mm" + Media (astal-mpris, shown when playing)
│   └── RIGHT PILL (capsule): Tray (astal-tray) │ BT (astal-bluetooth)
│         │ Network (astal-network, WiFi or wired) │ Volume (astal-wireplumber)
│         │ CPU (poll) │ Battery (astal-battery) │ Notification bell (far right)
│
├── Quick Settings / Control Center (popup below right pill)
│   │   PopupWindow overlay, opens on BT/WiFi/Volume/CPU/Battery click (not tray, not bell)
│   │   Trigger icons get highlighted background when panel is open
│   ├── QuickActions: User avatar + name + uptime │ Lock │ Logout
│   ├── Tiles (2-col FlowBox grid, toggle + optional drill-down)
│   │   ├── Network: WiFi/wired toggle, SSID/status, arrow → Network page
│   │   ├── Bluetooth: adapter power toggle, device name, arrow → Bluetooth page
│   │   ├── Do Not Disturb: notification mute toggle (no detail page)
│   │   └── Night Light: hyprsunset toggle, temp display, arrow → NightLight page
│   ├── Sliders (button + slider + "more" → detail page)
│   │   ├── Volume (speaker): astal-wireplumber → Sound page (device selector, per-app streams)
│   │   └── Brightness: backlight sysfs → Brightness page (multi-device control)
│   └── Reusable widgets
│       ├── Tile: GObject-registered toggleable tile (icon, title, description, state, arrow)
│       ├── Page: detail view (header, content, bottom buttons)
│       └── Pages: Revealer-based manager (one page open at a time per zone)
│
├── Launcher (spotlight-style overlay window)
│   ├── App search (astal-apps)
│   ├── File search
│   ├── Calculator
│   ├── Clipboard history (cliphist integration)
│   ├── Theme switcher
│   └── Emoji picker
│
├── Notification Center (right sidebar, slides in from right edge, full height)
│   ├── Toast pop-ups (astal-notifd)
│   ├── Notification history with per-app grouping
│   ├── Clear all
│   └── Do Not Disturb toggle
│
├── OSD (transient overlay)
│   ├── Volume
│   └── Brightness
│
└── Theme Engine (service)
    ├── Reads Base16 palette JSON files (generated by Nix)
    ├── Generates SCSS variables → compiles with dart-sass → app.apply_css()
    ├── Writes configs for non-AGS apps:
    │   ├── Hyprland (border colors) → hyprctl reload
    │   ├── Ghostty (theme file) → restart
    │   ├── btop (theme) → restart
    │   └── Hyprlock (colors)
    ├── Switches wallpaper per theme (swaybg)
    └── Persists current theme selection
```

## Repository Structure (Target)

```
flake.nix                           # flake-parts entry; inputs: nixpkgs, hyprland, nix-colors,
                                    #   home-manager, astal, ags, flake-parts, import-tree
ags/                                # AGS v2 TypeScript project
  app.ts                            # GTK4 entry point
  tsconfig.json
  env.d.ts
  style.scss                        # Root stylesheet (imports partials)
  windows/
    bar/
      index.tsx                     # Bar window (Astal.Window, 3 split capsule pills)
      left-pill.tsx                 # Left pill container (workspaces)
      center-pill.tsx               # Center pill container (clock + media)
      right-pill.tsx                # Right pill container (tray, bt, network, vol, cpu, battery, bell)
      workspaces.tsx                # Hyprland workspace dots (astal-hyprland)
      clock.tsx                     # Clock ("Mon HH:mm")
      media.tsx                     # MPRIS media info (hidden when no player)
      battery.tsx                   # Battery (upower, hidden when no battery present)
      network.tsx                   # Network (WiFi or wired, astal-network)
      bluetooth.tsx                 # Bluetooth (bluez)
      volume.tsx                    # Volume (WirePlumber)
      cpu.tsx                       # CPU usage (poll /proc/stat)
      tray.tsx                      # System tray
      notifications.tsx             # Bell icon + counter
    quick-settings/
      index.tsx                     # Control center popup window layout
      quick-actions.tsx             # User info + lock + logout buttons
      sliders.tsx                   # Volume + brightness sliders with "more" buttons
      widgets/
        tile.tsx                    # Reusable Tile component (GObject-registered)
        page.tsx                    # Page class + PageButton helper
        pages.tsx                   # Pages manager (Revealer-based open/close/toggle)
      modules/
        network-tile.tsx            # Network toggle tile
        bluetooth-tile.tsx          # Bluetooth toggle tile
        dnd-tile.tsx                # DND toggle tile
        night-light-tile.tsx        # NightLight toggle tile
        network-page.tsx            # Network detail page (devices, WiFi APs)
        bluetooth-page.tsx          # Bluetooth detail page (device list + actions)
        night-light-page.tsx        # NightLight settings page (temp + gamma sliders)
        sound-page.tsx              # Sound output device selector + per-app streams
        brightness-page.tsx         # Brightness/backlight detail page
    launcher/
      index.tsx                     # Spotlight overlay window
      apps.tsx                      # App search provider
      files.tsx                     # File search provider
      calculator.tsx                # Calculator provider
      clipboard.tsx                 # Clipboard history provider
      themes.tsx                    # Theme switcher provider
      emoji.tsx                     # Emoji picker provider
    notifications/
      index.tsx                     # Notification center panel
      toast.tsx                     # Toast pop-up window
    osd/
      index.tsx                     # Volume/brightness OSD overlay
  services/
    theme.ts                        # Theme engine (read palettes, compile SCSS, propagate)
  lib/
    utils.ts                        # Shared utilities
  styles/
    _variables.scss                 # Color variables (dynamic in Phase 2, hardcoded in Phase 1)
    _bar.scss                       # Bar styles
    _quick-settings.scss            # Quick-settings styles
    _launcher.scss                  # Launcher styles
    _notifications.scss             # Notification styles
    _osd.scss                       # OSD styles

modules/
  _packages.nix                     # Central package list
  _themes.nix                       # Theme definitions (name → nix-colors scheme)
  meta.nix                          # perSystem formatter + homeManagerModules option
  nixos/
    system.nix                      # PipeWire, greetd, networking, fonts
    hyprland.nix                    # programs.hyprland at system level
  home-manager/
    ags.nix                         # Build AGS shell, install binary, declare Astal lib deps
    themes.nix                      # nix-colors setup, config.omarchy options, palette JSONs,
                                    #   wallpapers, GTK theme, declarative configs for retained apps
    hyprland.nix                    # wayland.windowManager.hyprland (imports _hyprland/)
    _hyprland/
      autostart.nix                 # exec-once: lkasper-shell, swaybg
      keybinds.nix                  # Direct keybinds (no omarchy wrappers)
      configuration.nix             # Monitor config, default apps
      envs.nix                      # Wayland env vars
      input.nix                     # Keyboard, mouse, touchpad
      looknfeel.nix                 # Gaps, borders, animations
      windows.nix                   # Window/layer rules
    ghostty.nix                     # Terminal config
    hyprlock.nix                    # Lock screen
    hypridle.nix                    # Idle daemon
    hyprpaper.nix                   # (may be replaced by swaybg in themes.nix)
    hyprshot.nix                    # Screenshots
    btop.nix                        # System monitor
    zsh.nix                         # Shell config
    starship.nix                    # Prompt
    direnv.nix                      # Dev environments
    fonts.nix                       # Font packages
    zoxide.nix                      # Directory jumper

config/
  themes/wallpapers/                # Wallpaper images per theme
```

## Theme System Architecture

```
BUILD TIME (Nix)                              RUNTIME (AGS)
══════════════                                ═══════════════

nix-colors                                    Theme Engine (services/theme.ts)
    │                                              │
    ▼                                              │
modules/_themes.nix                                │ reads
  gruvbox-dark → base16 scheme                     │
  gruvbox-light → base16 scheme                    ▼
  catppuccin-mocha → base16 scheme          ~/.local/share/themes/<name>/colors.json
  catppuccin-latte → base16 scheme                 │
    │                                              │ generates SCSS
    ▼                                              ▼
modules/home-manager/themes.nix             $SCSS_VARIABLES
  generates per theme:                             │
  ~/.local/share/themes/                           │ dart-sass compile
    <name>/colors.json                             ▼
    <name>/wallpapers/                      CSS string
                                                   │
                                                   │ app.apply_css()
                                                   ▼
                                            AGS windows re-styled
                                                   │
                                                   │ writes configs
                                                   ▼
                                            Hyprland → hyprctl reload
                                            Ghostty → restart
                                            btop → restart
                                            Hyprlock → colors updated
                                            swaybg → new wallpaper
```

## Phased Migration Plan

### Phase 1: `ags-desktop-foundation`
Foundation and status bar.
- Nix flake input changes (add astal + ags, remove walker/elephant)
- Remove replaced modules (waybar, walker, wofi, mako)
- Rewrite themes.nix in-place (strip omarchy infra, keep nix-colors/options/GTK/palettes/retained app configs)
- Clean up envs.nix (remove OMARCHY_PATH, keep Wayland vars)
- AGS project setup (app.ts, tsconfig, SCSS, Nix build)
- Split-pill bar: 3 capsule pills (L: workspace dots, C: clock + media, R: status icons)
- Solid opaque capsule styling, subtle separators in right pill
- Hyprland config cleanup (remove omarchy references, AGS autostart)
- Hardcoded Catppuccin Mocha theme (no runtime switching until Phase 2)

### Phase 2: `ags-theme-engine`
Runtime theme switching.
- Nix generates Base16 palette JSON files per theme
- AGS theme service reads palettes, generates SCSS, compiles, applies CSS
- Theme propagation to non-AGS apps (Hyprland, Ghostty, btop, Hyprlock)
- Wallpaper switching per theme
- Persist and restore theme selection

### Phase 3: `ags-quick-settings`
Control center panel (colorshell-inspired tile + inline page pattern).
- Single unified control center as a PopupWindow overlay below the right pill
- Opens when any right pill icon is clicked (except tray and notification bell)
- Trigger icons (BT, WiFi, Volume, CPU, Battery) get highlighted/light background when panel is open
- **QuickActions row**: User avatar (from ~/.face), username, uptime, lock button (hyprlock), logout button (opens logout menu)
- **Tiles grid**: 2-column FlowBox of toggleable Tile widgets, each with icon, title, description, state, and optional arrow for drill-down
  - Network: toggle WiFi/wired on/off, shows SSID/connection status, arrow → Network detail page (device list, WiFi AP list with connect/disconnect, inline password for secured)
  - Bluetooth: toggle adapter power, shows connected device name/battery, arrow → Bluetooth detail page (paired/discovered device list with connect/disconnect/forget)
  - Do Not Disturb: toggle notification muting via astal-notifd (no detail page, toggleOnClick)
  - Night Light: toggle hyprsunset, shows temperature, arrow → NightLight settings page (temperature + gamma sliders). Hidden when hyprsunset not installed.
- **Sliders**: button + slider + "more" button opening detail pages
  - Volume (speaker): mute toggle + slider bound to default speaker endpoint from astal-wireplumber. "More" → Sound page (output device selector + per-app stream sliders)
  - Brightness: brightness button + slider bound to backlight via sysfs/brightnessctl. "More" → Brightness page (multi-backlight control). Hidden gracefully when unsupported.
- **Inline Pages system**: Tiles and sliders open detail pages within the panel via Gtk.Revealer slide-down animation. Only one page open at a time per zone (tiles Pages instance, sliders Pages instance). Pages have header (title, description, action buttons), scrollable content, and optional bottom buttons.
- **Reusable widgets**: Tile (GObject-registered toggle tile), Page (detail page class with header/content/buttons), Pages (Revealer-based page manager), PageButton (list item button)
- CPU/Battery have no dedicated tile or detail page (clicking them just opens the panel)
- Trigger icon highlight: lighter shade of pill background (not accent)
- Click outside or Escape to close
- Solid opaque background, matching capsule radius
- Notification bell moved to far right of right pill (after battery)
- Nix dependencies: brightnessctl (for brightness writes), hyprsunset (for night light)

### Phase 4: `ags-launcher`
Spotlight-style launcher.
- Centered overlay with search input
- Providers: apps (astal-apps), files, calculator, clipboard (cliphist), theme switcher, emoji picker
- Keyboard-driven navigation
- Hyprland keybind to toggle

### Phase 5: `ags-notifications`
Notification system.
- Toast pop-ups via astal-notifd
- Notification center as right sidebar (slides in from right edge, full screen height)
- Per-app grouping
- Clear all button
- Do Not Disturb toggle (in notification center + bar bell icon)
- Bell icon shows unread count
- Solid opaque background, matching visual style

### Phase 6: `ags-osd-peripherals`
OSD and remaining peripherals.
- Volume/brightness OSD overlay
- Hyprlock configuration (themed)
- Hypridle configuration
- Screenshot integration (grim + slurp, keybinds)
- Clipboard manager (cliphist, accessible via launcher)

## Flake Inputs (Target)

| Input          | Source                          | Purpose                          |
|----------------|---------------------------------|----------------------------------|
| `nixpkgs`      | `NixOS/nixpkgs` @ unstable     | Core package set                 |
| `hyprland`     | `hyprwm/Hyprland`              | Compositor                       |
| `nix-colors`   | `misterio77/nix-colors`        | Base16 color schemes             |
| `home-manager` | `nix-community/home-manager`   | Home-manager module system       |
| `astal`        | `aylur/astal`                   | Astal libraries (battery, bluetooth, network, etc.) |
| `ags`          | `aylur/ags` (follows astal)     | AGS CLI, bundler, home-manager module |
| `flake-parts`  | `hercules-ci/flake-parts`      | Flake module framework           |
| `import-tree`  | `vic/import-tree`              | Auto-discover Nix modules        |

## Astal Libraries Used

| Library             | Purpose                    | Used in              |
|---------------------|----------------------------|----------------------|
| `astal4`            | GTK4 base widgets          | All windows          |
| `astal-io`          | File, process, IPC utils   | Theme engine, CPU    |
| `astal-hyprland`    | Hyprland IPC               | Workspaces           |
| `astal-mpris`       | Media player control       | Media module         |
| `astal-battery`     | Battery status (upower)    | Battery module       |
| `astal-bluetooth`   | Bluetooth (bluez)          | BT module, QS panel  |
| `astal-network`     | Network (NetworkManager)   | WiFi module, QS panel |
| `astal-wireplumber` | Audio (WirePlumber)        | Volume module, QS, OSD |
| `astal-tray`        | System tray                | Tray module          |
| `astal-notifd`      | Notification daemon        | Notifications        |
| `astal-apps`        | Desktop app query          | Launcher             |
