# Omarchy Nix

Omarchy-nix (Omanix?) is an opinionated NixOS flake to help you get started as fast as possible with NixOS and Hyprland. It is primarily a reimplementation of [DHH's Omarchy](https://github.com/basecamp/omarchy) project - an opinionated Arch/Hyprland setup for modern web development.

__This isn't meant to be full feature parity with Omarchy and likely never will be, especially with how fast the feature development and funding has been for that project. Instead, think of this as more of a launch pad to get your own similar Nix config set up!__

I've personally moved to using regular Arch Omarchy full-time for a number of reasons. I'm not actively working on this repo but if you'd like to contribute please send a PR :) 

## Quick Start

To get started you'll first need to set up a fresh [NixOS](https://nixos.org/) install. Just download and create a bootable USB and you should be good to go.


Once ready, add this flake to your system configuration, you'll also need [home-manager](https://github.com/nix-community/home-manager) as well:
(You can find my personal nix setup [here](https://github.com/henrysipp/nix-setup) too if you need a reference.)
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    omarchy-nix = {
        url = "github:caspersonn/lkasper-hyprland";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, omarchy-nix, home-manager, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      modules = [
        omarchy-nix.nixosModules.omarchy-system
        omarchy-nix.nixosModules.omarchy-hyprland
        home-manager.nixosModules.home-manager
        {
          # Configure omarchy
          omarchy = {
            full_name = "Your Name";
            email_address = "your.email@example.com";
          };

          home-manager = {
            users.your-username = {
              imports = with omarchy-nix.homeManagerModules; [
                omarchy-themes
                omarchy-hyprland
                omarchy-walker
                omarchy-ghostty
                omarchy-waybar
                omarchy-wofi
                omarchy-mako
                omarchy-hyprlock
                omarchy-hyprpaper
                omarchy-hypridle
                omarchy-btop
                omarchy-git
                omarchy-zsh
                omarchy-starship
                omarchy-direnv
                omarchy-fonts
                omarchy-vscode
                omarchy-zoxide
              ];
            };
          };
        }
      ];
    };
  };
}
```

> **Note:** Each module is imported individually, giving you full control over which components to include. `omarchy-themes` must be imported to provide the `omarchy.*` options and color scheme used by the other modules.

## Configuration Options

I've specified some basic configuration options to help you get started with initial setup, as well as some simple overrides for common configuration settings I found I was modifying often. These are likely subject to change with future versions as I iron things out.

Refer to [the root configuration](https://github.com/henrysipp/omarchy-nix/blob/main/config.nix) file for more information on what options are available.

### Themes

Theme switching is runtime-based (imperative), not a static Nix option.

Use the included commands to switch instantly without running `home-manager switch`:

```bash
omarchy-theme-list
omarchy-theme-set "Gruvbox Light"
omarchy-theme-current
```

Available built-in themes:
- `tokyo-night` (default)
- `kanagawa`
- `everforest`
- `catppuccin-macchiato`
- `nord`
- `gruvbox`
- `gruvbox-light`

Theme assets are rendered into `~/.config/omarchy/current/theme/` and apps are reloaded by the `omarchy-restart-*` scripts.

## License

This project is released under the MIT License, same as the original Omarchy.
