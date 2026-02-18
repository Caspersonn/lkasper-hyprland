# Proposal: migrate-to-flake-parts-with-import-tree

## Status: Draft

## Summary

Migrate the `lkasper-hyprland` flake from a plain `outputs = inputs@{ ... }: { ... }` structure to `flake-parts` with `import-tree`, adopting the **Dendritic Pattern** already in use in `lkasper-flake`. This restructures the monolithic `flake.nix` into a tree of self-contained, auto-discovered modules under a `modules/` directory, making the flake easier to extend, compose, and maintain.

---

## Motivation

The current flake has several structural limitations:

1. **Monolithic `flake.nix`** — all output wiring lives in one file; adding a new exposed module requires editing the top-level file.
2. **Manual `imports` threading** — each sub-module receives `inputs` as a function argument, requiring explicit plumbing across every layer (`default.nix` → sub-modules).
3. **Duplicated `omarchy.*` options declaration** — both `nixosModules.default` and `homeManagerModules.default` re-declare the same options schema, a pattern that doesn't scale.
4. **No per-system outputs** — `formatter` is hardcoded to `x86_64-linux`; adding `aarch64-linux` support would require manual duplication.
5. **Not composable with `lkasper-flake`** — the consuming flake uses flake-parts + import-tree; keeping the upstream library in a different structural idiom adds friction.

---

## Proposed Architecture

### Flake entry point

```nix
# flake.nix
{
  description = "Omarchy - Base configuration flake";

  inputs = {
    flake-parts.url   = "github:hercules-ci/flake-parts";
    import-tree.url   = "github:vic/import-tree";
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url      = "github:hyprwm/Hyprland";
    nix-colors.url    = "github:misterio77/nix-colors";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
    };
}
```

### New `modules/` tree

Each `.nix` file is a self-contained flake-parts module. `import-tree` discovers and merges them all automatically — **no `default.nix` aggregators needed anywhere in the tree**.

```
modules/
├── meta.nix                        # perSystem formatter
├── nixos/
│   ├── system.nix                  # exports flake.nixosModules.omarchy-system
│   ├── hyprland.nix                # exports flake.nixosModules.omarchy-hyprland
└── home-manager/
    ├── hyprland.nix                # exports flake.homeManagerModules.omarchy-hyprland
    ├── hyprland/
    │   ├── configuration.nix       # exports flake.homeManagerModules.omarchy-hyprland-configuration
    │   ├── autostart.nix           # exports flake.homeManagerModules.omarchy-hyprland-autostart
    │   ├── bindings.nix            # exports flake.homeManagerModules.omarchy-hyprland-bindings
    │   ├── envs.nix                # exports flake.homeManagerModules.omarchy-hyprland-envs
    │   ├── input.nix               # exports flake.homeManagerModules.omarchy-hyprland-input
    │   ├── looknfeel.nix           # exports flake.homeManagerModules.omarchy-hyprland-looknfeel
    │   └── windows.nix             # exports flake.homeManagerModules.omarchy-hyprland-windows
    ├── hyprlock.nix
    ├── hyprpaper.nix
    ├── hypridle.nix
    ├── ghostty.nix
    ├── waybar.nix
    ├── mako.nix
    ├── wofi.nix
    ├── vscode.nix
    ├── git.nix
    ├── zsh.nix
    ├── starship.nix
    ├── btop.nix
    ├── direnv.nix
    ├── fonts.nix
    └── zoxide.nix
```

No `default.nix` files exist anywhere under `modules/`. There is nothing to aggregate — every file is discovered and merged by `import-tree` directly.

### Module anatomy

Each file is a self-contained flake-parts module that declares exactly one output:

```nix
# modules/nixos/system.nix
{ inputs, ... }: {
  flake.nixosModules.omarchy-system = { config, lib, pkgs, ... }: {
    # ... existing system.nix content ...
  };
}
```

```nix
# modules/home-manager/ghostty.nix
{ inputs, ... }: {
  flake.homeManagerModules.omarchy-ghostty = { config, lib, pkgs, ... }: {
    # ... existing ghostty.nix content ...
  };
}
```

The consumer (`lkasper-flake`) then composes whichever modules it wants:

```nix
# in lkasper-flake: modules/users/casper/desktop/hyprland/default.nix
{ inputs, ... }: {
  flake.modules.homeManager.casper-hyprland = { config, lib, pkgs, ... }: {
    imports = with inputs.omarchy-nix.homeManagerModules; [
      omarchy-hyprland
      omarchy-hyprland-configuration
      omarchy-ghostty
      omarchy-waybar
      # ...
    ];
  };
}
```

### Inputs access

With flake-parts, `inputs` is available in every module as a module argument — no manual threading required.

### Formatter

Becomes a `perSystem` output, automatically covering all declared systems:

```nix
# modules/meta.nix
{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-tree;
  };
}
```

---

## Files Changed

| File | Change |
|---|---|
| `flake.nix` | Rewritten: adopt `flake-parts.lib.mkFlake` + `import-tree ./modules` |
| `flake.lock` | Updated: add `flake-parts`, `import-tree` inputs |
| `modules/nixos/default.nix` | **Deleted** — aggregator no longer needed |
| `modules/nixos/system.nix` | Wrap in flake-parts module; export `flake.nixosModules.omarchy-system` |
| `modules/nixos/hyprland.nix` | Wrap in flake-parts module; export `flake.nixosModules.omarchy-hyprland` |
| `modules/home-manager/default.nix` | **Deleted** — aggregator no longer needed |
| `modules/home-manager/*.nix` | Wrap each in flake-parts module; export `flake.homeManagerModules.omarchy-<name>` |
| `modules/home-manager/hyprland/*.nix` | Wrap each in flake-parts module; export `flake.homeManagerModules.omarchy-hyprland-<name>` |
| `modules/meta.nix` | New file: `perSystem` formatter |
| `config.nix` | No change |
| `lib/`, `bin/`, `config/` | No change |

---

## Breaking Changes

The public API changes. The old single-module outputs:

```nix
nixosModules.default
homeManagerModules.default
```

Are replaced by granular per-module outputs:

```nix
nixosModules.omarchy-system
nixosModules.omarchy-hyprland
homeManagerModules.omarchy-hyprland
homeManagerModules.omarchy-ghostty
homeManagerModules.omarchy-waybar
# ... one per module file
```

The `lkasper-flake` consumer will need to update its `omarchy-nix` import to reference the specific modules it wants rather than `inputs.omarchy-nix.nixosModules.default`. This is a deliberate improvement — consumers can now opt into only the modules they need rather than taking everything.

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `import-tree` auto-discovers every `.nix` in `modules/`; sub-files under `hyprland/` must each be valid flake-parts modules | Every file — including `hyprland/*.nix` sub-files — declares its own `flake.homeManagerModules.omarchy-hyprland-<name>` output; there are no bare NixOS/HM modules left at the file level |
| Existing files use a curried `inputs:` argument pattern that is incompatible with flake-parts | Audit every file for the `inputs: { ... }:` pattern and replace with the flake-parts module wrapper `{ inputs, ... }: { flake.*.* = { ... }; }` |
| Evaluation regression after restructuring | `nix eval .#nixosModules.omarchy-system`, `nix eval .#homeManagerModules.omarchy-ghostty`, and `nix flake check` smoke tests after each sub-tree migration |
| `home-manager.flakeModules.home-manager` not needed (this flake doesn't define `homeConfigurations`) | Only include `flake-parts.flakeModules.modules`; do not add the HM flakeModule |

---

## Out of Scope

- Adding new modules or features
- Migrating to a new nixpkgs channel
- Changing the `omarchy.*` options schema
- Adding Neovim configuration
