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

Theme colors are set declaratively via nix-colors (Base16 palettes). The default theme is `tokyo-night`. Per-theme color palettes are deployed as JSON to `~/.local/share/lkasper-hyprland/themes/<name>/colors.json`.

Available built-in themes are defined in [modules/_themes.nix](modules/_themes.nix).

## License

This project is released under the MIT License.
