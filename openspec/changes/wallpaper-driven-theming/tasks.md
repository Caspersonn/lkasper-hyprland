## 0. Wallpapers in-repo (static only)

- [x] 0.1 Copy the static wallpapers (`.png`/`.jpg`) from `~/lkasper-flake/wallpapers/` into `wallpapers/` and `git add` them (flake only sees tracked files)
- [x] 0.2 Repoint `hyprpaper.nix` (and the `lkasper-flake` path) at the in-repo wallpaper copy

## 1. Palette generation (committed base16)

- [x] 1.1 Add `wallust` to the flake (dev shell / packages)
- [x] 1.2 Create a `regenerate-palettes` command that runs `wallust` over `wallpapers/*` and writes a base16 JSON (base00–base0F) per wallpaper to a committed location
- [x] 1.3 Run it and commit a palette for every wallpaper in the current set
- [x] 1.4 Verify each committed palette contains all 16 base16 slots

## 2. Nix colour pipeline (whole desktop)

- [x] 2.1 Rework `_themes.nix` / `themes.nix` to register one theme per wallpaper, sourced from its committed palette (drop the hardcoded `"gruvbox"` pick)
- [x] 2.2 Wire `config.colorScheme` to the active wallpaper's palette (default = current wallpaper); confirm foot / btop / hyprlock / Hyprland borders / ghostty / starship / opencode still derive from it
- [x] 2.3 Emit runtime `themes/<name>/colors.json` for every wallpaper and keep the `current/theme.name` pointer
- [x] 2.4 Build the home configuration and verify all base16 consumers evaluate

## 3. AGS runtime colour layer

- [x] 3.1 Spike: confirm GTK `@define-color` + `App.apply_css` vs regenerated-CSS fallback (design D4)
- [x] 3.2 Split AGS styles — structure stays compiled, the colour layer becomes a runtime-injected palette provider
- [x] 3.3 Load the active `colors.json` at startup and apply the colour provider
- [x] 3.4 Recolour live on change (watch `current` / `colors.json`, re-apply) with no shell restart
- [x] 3.5 Remove the gruvbox `$…` and `$w-*` vars from `style.scss`; map every colour, including semantics (base0B/base0A/base08), to the palette
- [ ] 3.6 Verify the running shell recolours live on a manual palette change

## 4. Switch orchestration

- [x] 4.1 Implement `theme-switch <wallpaper>`: set wallpaper via hyprpaper IPC, repoint `current/theme.name`, reload apps
- [x] 4.2 Reload matrix: `hyprctl` (borders), AGS `apply_css`, terminals/btop via their reload path
- [ ] 4.3 Verify a switch recolours Hyprland + AGS immediately and completes without error

## 5. Wallpaper picker overlay

- [ ] 5.1 Create `ags/windows/wallpaper-picker/` — per-monitor Astal overlay, thumbnail grid of available wallpapers, marks the active one
- [ ] 5.2 Keyboard + click selection; Escape / backdrop closes without changing the wallpaper
- [ ] 5.3 Selection invokes `theme-switch` and closes the picker
- [ ] 5.4 Register `toggle-wallpaper-picker` in `app.ts` + a keybind in `bindings.nix` (optional bar button)
- [ ] 5.5 Verify the picker opens, lists wallpapers, and selecting one switches + recolours

## 6. Guardrails

- [ ] 6.1 Fallback palette when the active wallpaper has no committed palette (no crash, nothing unstyled)
- [ ] 6.2 Decide/implement light-dark policy and an optional min-contrast clamp for bar/overlay text (design open questions)

## 7. Wrap-up

- [ ] 7.1 Verify implementation against specs (`opsx:verify`)
- [ ] 7.2 Link this change to bean `lkasper-hyprland-9ura` and tick its todos
