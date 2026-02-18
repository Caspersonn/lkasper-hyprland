# Tasks: migrate-to-flake-parts-with-import-tree

## Status: Complete

---

## Task 1 — Add `flake-parts` and `import-tree` inputs

**File:** `flake.nix`

- [x] Add `flake-parts.url = "github:hercules-ci/flake-parts"` to `inputs`
- [x] Add `import-tree.url = "github:vic/import-tree"` to `inputs`
- [x] Run `nix flake update flake-parts import-tree` to lock them

---

## Task 2 — Rewrite `flake.nix` outputs

**File:** `flake.nix`

- [x] Replace `outputs` body with `flake-parts.lib.mkFlake` using `import-tree ./modules`
- [x] Remove inline `nixosModules`, `homeManagerModules`, and `formatter` declarations

---

## Task 3 — Delete aggregator `default.nix` files

**Files:** `modules/nixos/default.nix`, `modules/home-manager/default.nix`

- [x] Delete `modules/nixos/default.nix`
- [x] Delete `modules/home-manager/default.nix`

---

## Task 4 — Create `modules/meta.nix`

**File:** `modules/meta.nix` (new)

- [x] Create `meta.nix` with `perSystem` formatter and `homeManagerModules` option declaration

---

## Task 5 — Wrap NixOS modules in flake-parts syntax

**Files:** `modules/nixos/system.nix`, `modules/nixos/hyprland.nix`

- [x] Wrap `system.nix` → `flake.nixosModules.omarchy-system`
- [x] Wrap `hyprland.nix` → `flake.nixosModules.omarchy-hyprland`

---

## Task 6 — Wrap home-manager modules in flake-parts syntax

**Files:** all `.nix` files under `modules/home-manager/`

- [x] Create `modules/home-manager/themes.nix` → `flake.homeManagerModules.omarchy-themes` (extracts colorScheme/gtk/neovim/packages logic from old default.nix)
- [x] Wrap `hyprland.nix` → `flake.homeManagerModules.omarchy-hyprland`
- [x] Wrap `hyprlock.nix` → `flake.homeManagerModules.omarchy-hyprlock`
- [x] Wrap `hyprpaper.nix` → `flake.homeManagerModules.omarchy-hyprpaper`
- [x] Wrap `hypridle.nix` → `flake.homeManagerModules.omarchy-hypridle`
- [x] Wrap `ghostty.nix` → `flake.homeManagerModules.omarchy-ghostty`
- [x] Wrap `waybar.nix` → `flake.homeManagerModules.omarchy-waybar`
- [x] Wrap `mako.nix` → `flake.homeManagerModules.omarchy-mako`
- [x] Wrap `wofi.nix` → `flake.homeManagerModules.omarchy-wofi`
- [x] Wrap `vscode.nix` → `flake.homeManagerModules.omarchy-vscode`
- [x] Wrap `git.nix` → `flake.homeManagerModules.omarchy-git`
- [x] Wrap `zsh.nix` → `flake.homeManagerModules.omarchy-zsh`
- [x] Wrap `starship.nix` → `flake.homeManagerModules.omarchy-starship`
- [x] Wrap `btop.nix` → `flake.homeManagerModules.omarchy-btop`
- [x] Wrap `direnv.nix` → `flake.homeManagerModules.omarchy-direnv`
- [x] Wrap `fonts.nix` → `flake.homeManagerModules.omarchy-fonts`
- [x] Wrap `zoxide.nix` → `flake.homeManagerModules.omarchy-zoxide`
- [x] Rename `modules/packages.nix` → `modules/_packages.nix` (import-tree exclusion)
- [x] Rename `modules/themes.nix` → `modules/_themes.nix` (import-tree exclusion)
- [x] Rename `modules/home-manager/hyprland/` → `modules/home-manager/_hyprland/` (import-tree exclusion — plain HM sub-modules)

---

## Task 7 — Smoke test

- [x] `nix flake check` passes
- [x] `nix fmt` runs successfully (33 files formatted)

---

## Task 8 — Update `openspec/project.md`

- [x] Update Tech Stack with `flake-parts` and `import-tree`
- [x] Update Repository Structure to reflect new layout
- [x] Update module anatomy description
- [x] Update output names from `nixosModules.default` / `homeManagerModules.default` to granular per-module names
