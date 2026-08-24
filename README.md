# lkasper-hyprland

Personal NixOS + Hyprland desktop configuration with a custom AGS v2 (Astal) shell.

## Overview

A NixOS flake providing a complete Hyprland desktop environment with:

- **AGS v2 shell** — custom GTK4 status bar with split-pill design (workspaces, clock, media, system modules)
- **Hyprland** — tiling Wayland compositor with keybindings, window rules, and workspace management
- **Ghostty** — terminal emulator
- **Hyprlock / Hypridle** — screen locker and idle daemon
- **Btop** — system monitor with themed colors
- **Starship** — shell prompt
- **Zsh + Zoxide + Direnv** — shell environment

## Usage

Add this flake to your system configuration with [home-manager](https://github.com/nix-community/home-manager):

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    lkasper-hyprland = {
      url = "github:caspersonn/lkasper-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, lkasper-hyprland, home-manager, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      modules = [
        lkasper-hyprland.nixosModules.lkh-system
        lkasper-hyprland.nixosModules.lkh-hyprland
        home-manager.nixosModules.home-manager
        {
          "lkasper-hyprland" = {
            full_name = "Your Name";
            email_address = "your.email@example.com";
          };

          home-manager.users.your-username = {
            imports = with lkasper-hyprland.homeManagerModules; [
              lkh-themes
              lkh-ags
              lkh-hyprland
              lkh-ghostty
              lkh-hyprlock
              lkh-hyprpaper
              lkh-hypridle
              lkh-btop
              lkh-zsh
              lkh-starship
              lkh-direnv
              lkh-fonts
              lkh-zoxide
              lkh-yazi
              lkh-hyprshot
            ];
          };
        }
      ];
    };
  };
}
```

`lkh-themes` must be imported — it provides the `lkasper-hyprland.*` options and color scheme used by other modules.

## Configuration Options

Refer to [config.nix](config.nix) for available options (`full_name`, `email_address`, `primary_font`, `monitors`, `scale`, `quick_app_bindings`, `exclude_packages`).

## Themes

Colors are derived from the wallpaper. A wallpaper is a **pair** of a light and a dark
sibling image, declared in [wallpapers/pairs.nix](wallpapers/pairs.nix); the active theme is
a `(pair, mode)` selection. Every image in `wallpapers/` must belong to exactly one pair or
evaluation fails.

`wallpapers/regenerate-palettes.sh` derives a committed base16 palette per image
(`wallpapers/palettes/<image>.json`) with wallust. Dark members use `lchansi` + `ansidark16`.
Light members merge a `light16` shell (`base00`-`base07`) with `ansidark16` ANSI hues
(`base08`-`base0F`) darkened to 4.5:1 against the background, because wallust has no
`ansilight16` and its light palettes do not preserve ANSI slot order.

Adding a pair: drop both images in `wallpapers/`, declare them in `pairs.nix`, run
`nix shell nixpkgs#wallust nixpkgs#python3 nixpkgs#jq --command ./wallpapers/regenerate-palettes.sh`,
and commit the new palettes.

### Switching

| Command | Effect |
| --- | --- |
| `theme-toggle` | flip light <-> dark, keeping the pair (bound to `SUPER SHIFT, W`) |
| `theme-switch <pair>` | change pair, keeping the mode (used by the picker, `SUPER, W`) |
| `theme-apply <pair> <mode>` | set both explicitly |
| `theme-state` | print the active `<pair> <mode>` |

Nix renders a config bundle for every `(pair, mode)` into
`~/.local/share/lkasper-hyprland/themes/<pair>/<mode>/`. Switching repoints one symlink and
fans out reloads, so nothing rebuilds.

### The `current/` contract

`~/.config/lkasper-hyprland/current` is a symlink at the active bundle and is a **public
interface** for other repositories -- read it at runtime rather than depending on this flake.
`~/.config/lkasper-hyprland/state` holds the active `<pair> <mode>`.

| File | Contents |
| --- | --- |
| `colors.json` | shell palette + `mode`, `accent`, `hairline`, `shade`. `base0A`-`base0F` are remapped onto the accent triple, so it is **not** suitable for syntax highlighting |
| `colors-ansi.json` | ANSI-faithful base16 + `mode` |
| `nvim.lua` | `mode`, `background`, `colorscheme` and the wallpaper palette, as a Lua table |
| `foot.ini`, `ghostty`, `tmux.conf`, `fish.fish` | retrobox, not wallpaper-derived (see below) |
| `btop.theme`, `clipse-theme.json` | retrobox (TUIs inside the retrobox terminal) |
| `starship.toml`, `opencode.json` | wallpaper-derived per-app colour configs |
| `hypr.conf`, `hyprlock.conf`, `gtk.css` | compositor, lock screen and GTK colours |
| `wallpaper.path` | absolute path to the active image |

### Retrobox for the text tools

The terminals (foot, ghostty), tmux and neovim deliberately do **not** take the wallpaper
palette -- they use [retrobox](https://github.com/vim/vim/blob/master/runtime/colors/retrobox.vim),
neovim's bundled gruvbox-derived colourscheme. They still follow the light/dark toggle, because
retrobox has both backgrounds:

| | background | foreground |
| --- | --- | --- |
| dark | `#1c1c1c` | `#ebdbb2` |
| light | `#fbf1c7` | `#3c3836` |

The 16 ANSI values are taken verbatim from `retrobox.vim`'s `g:terminal_ansi_colors` for each
background, so terminal colours match what neovim renders exactly.

fish is included: `fish.fish` sets the `fish_color_*` / `fish_pager_color_*` variables plus
semantic `lkh_*` colours for the prompt, as **universal** variables so a toggle recolours already
open shells. Do not set these with `set -g` anywhere -- fish resolves global before universal, so
a global assignment silently shadows the bundle. neovim reads `colorscheme`
and `background` from `nvim.lua`, so it needs no palette of its own; `:ThemeReload` re-reads the
contract by hand and a file watcher picks up a toggle automatically.

btop and clipse are included too, since they render inside the retrobox terminal, and
`theme-apply` sets Claude Code's `theme` key in `~/.claude/settings.json` (it reads that at
startup, so a running session needs a restart). Note `theme_background` must
stay `true`: with it off btop paints no background and the terminal's previous contents show
through its panels.

Everything else -- the AGS shell, Hyprland borders, hyprlock, starship, opencode -- stays
wallpaper-derived.

A consumer that finds the path missing should fall back to its own default colourscheme.

## License

This project is released under the MIT License.
