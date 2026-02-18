# Project: lkasper-hyprland (Omarchy Nix)

## Purpose

A NixOS flake that provides a fully-themed Hyprland desktop environment as reusable NixOS and home-manager modules. Consumers import it as a flake input and configure it via a unified `omarchy.*` options namespace. The project is forked/inspired by Omarchy and extended for personal use.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Nix (NixOS modules, home-manager modules) |
| Flake framework | `flake-parts` (hercules-ci/flake-parts) |
| Module discovery | `import-tree` (vic/import-tree) |
| Compositor | Hyprland (upstream flake: `hyprwm/Hyprland`) |
| Package set | `nixpkgs` @ `nixos-unstable` |
| User environment | `home-manager` (nix-community) |
| Theming | `nix-colors` (base16 color schemes, wallpaper extraction) |
| Terminal | Ghostty |
| Shell | Zsh + Starship + zplug |
| Status bar | Waybar |
| Launcher | Wofi |
| Notifications | Mako |
| Editor | Neovim (system), VSCode (home) |
| Lock screen | Hyprlock |
| Wallpaper | Hyprpaper |
| Idle daemon | Hypridle |
| Clipboard | Clipse + wl-clip-persist |

## Repository Structure

```
flake.nix                        # flake-parts entry point; import-tree auto-loads all modules/
config.nix                       # Declares all omarchy.* NixOS/HM options (plain function)
lib/
  selected-wallpaper.nix         # Resolves active wallpaper path from config (plain function)
modules/
  _packages.nix                  # Central package list (excluded from import-tree by _ prefix)
  _themes.nix                    # Theme name → base16 scheme + VSCode theme (excluded)
  meta.nix                       # perSystem formatter + declares homeManagerModules option
  nixos/
    system.nix                   # omarchy-system: PipeWire, greetd/tuigreet, networking, fonts
    hyprland.nix                 # omarchy-hyprland: programs.hyprland at system level
  home-manager/
    themes.nix                   # omarchy-themes: colorScheme, GTK theme, wallpapers, neovim
    hyprland.nix                 # omarchy-hyprland: wayland.windowManager.hyprland + polkit
    _hyprland/                   # Plain HM sub-modules (excluded from import-tree by _ prefix)
      configuration.nix          # Default apps, monitor config, plugins (hyprsplit, hyprspace)
      autostart.nix              # exec-once / exec entries
      bindings.nix               # All keybindings
      envs.nix                   # Wayland env vars, NVIDIA detection, cursor theme
      input.nix                  # Keyboard, mouse, touchpad (all mkDefault)
      looknfeel.nix              # Gaps, borders, rounding, blur, animations, dwindle
      windows.nix                # windowrule and layerrule definitions
    hyprlock.nix / hyprpaper.nix / hypridle.nix
    ghostty.nix / waybar.nix / mako.nix / wofi.nix
    vscode.nix / git.nix / zsh.nix / starship.nix
    btop.nix / direnv.nix / fonts.nix / zoxide.nix
bin/
  omarchy-show-keybindings       # Bash: parse hyprland.conf and display bindings in wofi
config/
  themes/wallpapers/             # Bundled wallpaper images (5 themes)
  waybar/style.css               # Waybar base stylesheet (imports generated theme.css)
openspec/                        # Spec-driven development artifacts (OpenSpec)
```

## Flake Outputs

Each `.nix` file under `modules/` is a self-contained flake-parts module that declares one output:

| Output | Declared in |
|---|---|
| `nixosModules.omarchy-system` | `modules/nixos/system.nix` |
| `nixosModules.omarchy-hyprland` | `modules/nixos/hyprland.nix` |
| `homeManagerModules.omarchy-themes` | `modules/home-manager/themes.nix` |
| `homeManagerModules.omarchy-hyprland` | `modules/home-manager/hyprland.nix` |
| `homeManagerModules.omarchy-<name>` | `modules/home-manager/<name>.nix` (one per app) |
| `formatter.<system>` | `modules/meta.nix` |

## Module Anatomy

Every file in `modules/` (except `_`-prefixed ones) follows this shape:

```nix
{ inputs, ... }: {
  flake.nixosModules.omarchy-foo = { config, lib, pkgs, ... }: {
    # plain NixOS / home-manager module config
  };
}
```

`inputs` is available as a standard flake-parts argument — no currying or explicit threading needed.

## Key Design Patterns

### flake-parts + import-tree (Dendritic Pattern)
`flake-parts` provides the module system for the flake. `import-tree ./modules` auto-discovers and merges every `.nix` file in the tree. Files/directories prefixed with `_` are ignored by import-tree and used as plain Nix helpers.

### Unified Option Namespace
`omarchy.*` options are declared in each entry-point module (`omarchy-system` on the NixOS side, `omarchy-themes` on the HM side). All other modules consume `config.omarchy.*` without re-declaring options.

### Pervasive base16 Theming
Every visual application reads `config.colorScheme.palette.base0X`. Changing `omarchy.theme` recolors the entire desktop atomically — Ghostty, Waybar, Hyprlock, Mako, Wofi, btop, Hyprland borders all derive from the same palette.

### Generated Themes
`generated_light` / `generated_dark` modes use `nix-colors.lib.contrib.colorSchemeFromPicture` to extract a full base16 palette from any wallpaper at build time, propagating those colors to all themed apps automatically.

### Package Exclusion Safety
Only `discretionaryPackages` (defined in `modules/_packages.nix`) can be filtered via `omarchy.exclude_packages`. Core Hyprland and system packages are always included.

## Configuration Options (`omarchy.*`)

| Option | Type | Default | Purpose |
|---|---|---|---|
| `full_name` | `str` | required | Git user name |
| `email_address` | `str` | required | Git email |
| `theme` | enum | `"tokyo-night"` | Active color theme |
| `theme_overrides.wallpaper_path` | `nullOr path` | `null` | Custom wallpaper (required for generated themes) |
| `primary_font` | `str` | `"Liberation Sans 11"` | Terminal/UI font |
| `vscode_settings` | `attrs` | `{}` | Extra VSCode user settings |
| `monitors` | `listOf str` | `[]` | Hyprland monitor configuration lines |
| `scale` | `int` | `1` | Display HiDPI scale factor |
| `quick_app_bindings` | `listOf str` | 9 defaults | SUPER+key → app launch bindings |
| `exclude_packages` | `listOf package` | `[]` | Remove specific discretionary packages |

## Available Themes

`tokyo-night`, `kanagawa`, `everforest`, `nord`, `gruvbox`, `gruvbox-light`, `catppuccin-macchiato`, `custom`, `generated_light`, `generated_dark`

## Flake Inputs

| Input | Source | Purpose |
|---|---|---|
| `nixpkgs` | `NixOS/nixpkgs` @ `nixos-unstable` | Core package set |
| `hyprland` | `hyprwm/Hyprland` | Upstream Hyprland compositor |
| `nix-colors` | `misterio77/nix-colors` | base16 schemes + wallpaper color extraction |
| `home-manager` | `nix-community/home-manager` | HM module system + flakeModules.home-manager |
| `flake-parts` | `hercules-ci/flake-parts` | Flake module framework |
| `import-tree` | `vic/import-tree` | Auto-discover modules from directory tree |

## Conventions

- Nix files are formatted with `nixfmt-tree` (via `nix fmt`)
- All visual theming is driven by `config.colorScheme.palette.base0X` — never hardcode colors
- `mkDefault` is used for user-overridable defaults (e.g. input settings) so consumers can override
- Discretionary packages use the `exclude_packages` pattern rather than module enable flags
- Plain helper files (not flake-parts modules) are prefixed with `_` so import-tree skips them
- Plain HM sub-module directories are prefixed with `_` for the same reason
- `inputs` is available in every flake-parts module as a standard argument — no manual threading
- `omarchy.*` options are declared once per side (NixOS: `system.nix`; HM: `themes.nix`)
- Hyprland sub-configs live under `modules/home-manager/_hyprland/` and are imported by `hyprland.nix`

## Pending / Known TODOs

- Neovim configuration (currently just `programs.neovim.enable = true`)
- VSCode theme auto-injection is disabled (was "super annoying on the fly")
