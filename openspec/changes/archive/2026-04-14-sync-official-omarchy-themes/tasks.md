## 1. Sync upstream theme assets

- [x] 1.1 Fetch and compare upstream catalog from `https://github.com/basecamp/omarchy/tree/dev/themes` against local `themes/` to identify missing official theme directories.
- [x] 1.2 Import each missing official theme directory (including `backgrounds/`) into `themes/` while preserving upstream directory names used by `bin/omarchy-theme-set` slug resolution.
- [x] 1.3 Update `modules/_themes.nix` with declarative entries for each imported theme (`base16-theme`, `vscode-theme`) so the existing registry remains authoritative.
- [x] 1.4 Verify every imported theme contains required source files for generation (`themes/<name>/colors.toml` and any upstream overrides such as `light.mode` or app-specific files).

## 2. Sync wallpaper assets declaratively

- [x] 2.1 Copy/import official wallpaper assets into `config/themes/wallpapers/` using repository-managed filenames and paths.
- [x] 2.2 Update any wallpaper lookup references to point at `config/themes/wallpapers/` without introducing runtime network fetches.
- [x] 2.3 Validate that applying each imported theme resolves wallpapers locally and remains compatible with `bin/omarchy-theme-bg-next`.

## 3. Ensure generated runtime assets remain complete

- [x] 3.1 Validate template coverage in `default/themed/` for generated outputs consumed by runtime apply flow (including Waybar runtime CSS generation).
- [x] 3.2 For each imported theme, run the existing theme generation/apply path and confirm `~/.config/omarchy/current/theme` includes generated artifacts expected by scripts (`waybar.css`, `walker.css`, `wofi.css` when applicable).

## 4. Validate selection and apply behavior across entry points

- [x] 4.1 Verify CLI apply path with `bin/omarchy-theme-set` for representative dark and light official themes, confirming `~/.config/omarchy/current/theme.name` and GNOME mode state updates.
- [x] 4.2 Verify menu apply path via `omarchy-launch-walker -m menus:omarchythemes --width 800 --minheight 400` and confirm parity with CLI behavior for the same themes.
- [x] 4.3 Validate Waybar runtime theming after theme changes by checking `~/.config/waybar/runtime.css` updates and that `waybar.service` restarts cleanly without repeated crash loops.

## 5. Finalize and verify repository state

- [x] 5.1 Update any theme index/listing files used by selection UI (for example paths consumed by `config/elephant/menus/omarchy_themes.lua`) if required by imported catalog changes.
- [x] 5.2 Run `nix fmt` and ensure only intended files changed.
- [x] 5.3 Run `nix flake check` and resolve any regressions introduced by expanded official theme assets.
