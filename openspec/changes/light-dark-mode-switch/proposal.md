## Why

The desktop is force-dark by design. `regenerate-palettes.sh` hardcodes wallust's `ansidark16`, the archived `wallpaper-driven-theming` change explicitly resolved *"force dark, no light-mode variant"*, and `envs.nix` pins `GTK_THEME=Adwaita-dark` for the whole session. There is no way to work in light mode, and no single control that would move the whole desktop between polarities.

Worse, the runtime half of the theming pipeline is only half-wired. `theme-switch` recolours the AGS shell and Hyprland borders live, but foot, ghostty, btop, starship, hyprlock and opencode read colours baked at build time. The four config files that *look* runtime-managed are written by an activation script guarded with `if [ ! -f ]`, so they are written once and never updated again — changing the active wallpaper and rebuilding silently does nothing to them.

We want one keybind that flips the entire desktop between light and dark, instantly, without a rebuild.

## What Changes

- **Wallpapers become pairs.** A wallpaper is no longer a standalone image but a **pair** of a light and a dark sibling, declared in `wallpapers/pairs.nix`. Switching mode swaps the image *and* the palette. An eval-time assertion rejects any image in `wallpapers/` that is not a member of exactly one pair. **BREAKING**: theme state changes from a single wallpaper slug to a `(pair, mode)` tuple.
- **Light palettes are generated natively.** The generator gains a light pipeline: wallust `light16` supplies the shell (`base00`–`base07`), wallust `lchansi` + `ansidark16` supplies ANSI-faithful hues (`base08`–`base0F`), and the accents are clamped *down* to meet contrast on a light background. See design D2/D3 for why the obvious single-run approach does not work.
- **All themed app configs move to a runtime bundle.** Nix renders a complete config bundle for **every** `(pair, mode)` combination into the store; `~/.config/lkasper-hyprland/current` is a symlink pointing at the active one. Every consumer reads through that symlink, so one relink re-themes the whole desktop. **BREAKING**: retires the `if [ ! -f ]` activation guards and the `current/theme.name` pointer file.
- **A single keybind toggles mode.** `theme-toggle` reads the current state, flips the mode, and applies. `theme-switch <pair>` changes pair while preserving mode.
- **GTK apps stop being pinned to dark.** `GTK_THEME=Adwaita-dark` and `ADW_DISABLE_PORTAL=1` are removed and `programs.dconf.enable` is switched on, so the already-correct `xdg-desktop-portal-gtk` Settings portal can carry `color-scheme` to libadwaita apps live.
- **AGS gains a light mode.** The eight hardcoded `rgba(255,255,255,…)` / `rgba(0,0,0,…)` values in `style.scss` become `hairline` / `shade` named colours injected per mode, plus a small light-mode delta stylesheet. The structural stylesheet stays single-source.
- **Neovim gets a contract, not an implementation.** The bundle emits `nvim.lua` and `colors-ansi.json` under `current/`, so the separate `nixvim` repo can follow the palette by reading a well-known path with no flake-level coupling. The nixvim side is out of scope here.
- **Cleanup**: the four wallpapers without light siblings (`wood-dark`, `planet-zoo`, `princess-mononoke`, `studio-ghibli-style`) and their palettes are removed; the dead `modules/_themes.nix` registry is deleted, and the write-once `hypr/theme.conf` (which was sourced last and silently overrode `looknfeel.nix`'s border colours) is removed in favour of the bundle.

## Capabilities

### Modified Capabilities
- `wallpaper-palette-generation`: palettes are generated per **pair member**, with a light pipeline and mode-aware contrast clamping; pairing is enforced at eval time.
- `wallpaper-theme-switching`: theme state becomes `(pair, mode)`; a mode toggle exists; propagation moves from build-time baking to a runtime bundle behind a single symlink, covering every themed app.
- `wallpaper-picker`: the picker lists **pairs** rather than images, previews the sibling matching the current mode, and preserves mode on selection.

## Impact

- **Nix modules**: `modules/home-manager/themes.nix` (major rewrite — bundle generation + switch scripts), `foot.nix`, `btop.nix`, `hyprlock.nix`, `hyprpaper.nix`, `_hyprland/looknfeel.nix`, `_hyprland/envs.nix`, `_hyprland/bindings.nix`, `modules/nixos/hyprland.nix`. `modules/_themes.nix` is deleted.
- **Generator**: `wallpapers/regenerate-palettes.sh` rewritten pair-aware; new `wallpapers/pairs.nix`.
- **AGS shell**: `ags/theme.ts` (mode-aware token injection), new `ags/_tokens.scss` and `ags/light.scss`, `ags/style.scss` (tokenise the eight hardcoded values), `ags/windows/wallpaper-picker/index.tsx` (pairs).
- **Cross-repo**: `~/.config/lkasper-hyprland/current/` becomes a documented public interface consumed by the `nixvim` repo. `lkasper-flake` needs no change.
- **Related beans**: overarching `lkasper-hyprland-o51v`; sub-beans `f0lk` (activation guards), `mkrd` (dead theme.conf), `pw1t` (GTK pinned dark), `2m3q` (pair registry), `mpzy` (light palette pipeline), `4qcy` (runtime bundle), `dr7u` (AGS light mode), `9k58` (nvim contract).
- **Non-goals**: the nixvim-side implementation; light/dark icon-theme variants (`Gruvbox-Plus-Dark` is dark-only and stays); Qt app theming beyond what `adwaita-qt` already follows; sourcing light siblings for the four removed wallpapers.
