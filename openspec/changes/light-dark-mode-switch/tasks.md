## 0. Cleanup

- [x] 0.1 Delete the palettes for the four unpaired wallpapers (`wood-dark`, `planet-zoo`, `princess-mononoke`, `studio-ghibli-style`)
- [x] 0.2 Delete the dead `modules/_themes.nix` registry (referenced by nothing)
- [x] 0.3 Add `wallpaper.ignored/` to `.gitignore`
- [x] 0.4 Repoint `hyprpaper.nix` off the removed `wood-dark.png` (the tree currently does not evaluate)

## 1. Pair registry

- [x] 1.1 Add `wallpapers/pairs.nix` declaring the `beach` pair (light + dark members)
- [x] 1.2 Assert at eval time that every image in `wallpapers/` is a member of exactly one pair, with a message naming the offender
- [x] 1.3 Assert that no image is claimed by two pairs or by both roles of one pair
- [x] 1.4 Verify an unpaired image fails evaluation

## 2. Light palette pipeline

- [x] 2.1 Make the generator pair-aware: iterate pairs, derive the flavour from each member's role
- [x] 2.2 Light pipeline: `lch`+`light16` for base00–07, `lchansi`+`ansidark16` for base08–0F, merged (design D3)
- [x] 2.3 Invert the contrast clamp for light mode — darken to >= 4.5:1 against base00, preserving hue (D4)
- [x] 2.4 Derive `base01`/`base02` for light palettes by stepping base00 toward base05, so surfaces stay separable (D5)
- [x] 2.5 Record `mode` in every palette file
- [x] 2.6 Regenerate and commit both `beach` palettes
- [x] 2.7 Verify: light palette has light polarity, 0/7 ANSI slots off-hue, all accents >= 4.5:1, base00/01/02 distinct

## 3. Runtime theme bundle

- [x] 3.1 Rewrite `themes.nix` to build a config bundle per (pair, mode): `colors.json`, `colors-ansi.json`, `foot.ini`, `btop.theme`, `ghostty`, `starship.toml`, `hypr.conf`, `hyprlock.conf`, `gtk.css`, `opencode.json`, `nvim.lua`, `wallpaper.path`
- [x] 3.2 Remove the four `if [ ! -f ]` activation guards and the `current/theme.name` pointer
- [x] 3.3 Establish `~/.config/lkasper-hyprland/current` as a runtime-owned symlink plus a `state` file; create only when absent so a rebuild does not stomp a runtime selection
- [x] 3.4 `theme-apply <pair> <mode>` — relink `current`, set the wallpaper via hyprpaper IPC, write `state`, fan out reloads
- [x] 3.5 `theme-toggle` — read `state`, flip the mode, call `theme-apply`
- [x] 3.6 `theme-switch <pair>` — change pair, preserve mode
- [x] 3.7 Verify the bundle exists for every (pair, mode) and the config evaluates

## 4. Consumer wiring

- [x] 4.1 foot: hand-written `foot.ini` with a top-level `include=` into `current/`, `settings = { }` to disable home-manager's file; reload with `SIGUSR1`
- [x] 4.2 Hyprland: repoint `configuration.nix` `extraConfig` source from `hypr/theme.conf` at `current/hypr.conf` (extraConfig is appended last, so it wins); remove the static `col.active_border` / `col.inactive_border` from `looknfeel.nix`; reload with `hyprctl reload`
- [x] 4.3 hyprlock: `settings.source` + `sourceFirst`, colours via `$lkh_*` hyprlang variables
- [x] 4.4 btop / ghostty / starship / opencode / gtk: activation symlinks from each app's config path into `current/`
- [x] 4.7 ghostty: trigger the `reload-config` D-Bus action so it re-themes live rather than only on a full restart
- [x] 4.5 Remove the stale `hypr/theme.conf` in activation (it was sourced last and silently overrode `looknfeel.nix`)
- [x] 4.6 Verify each consumer's config path resolves through `current/`

## 5. GTK light/dark

- [x] 5.1 Remove `GTK_THEME` and `ADW_DISABLE_PORTAL` from both `home.sessionVariables` and the Hyprland `env` block
- [x] 5.2 Enable `programs.dconf` in `modules/nixos/hyprland.nix`
- [x] 5.3 `theme-apply` sets `color-scheme` and `gtk-theme` via `gsettings`
- [x] 5.4 Emit `gtk.css` in the bundle and symlink it for GTK3 and GTK4
- [x] 5.5 Fix the portal so GTK can follow at all: add `xdg-desktop-portal-gtk` to the *home-manager* `xdg.portal.extraPortals` (bean `xq4d`)
- [ ] 5.6 Verify a libadwaita app follows the toggle live (needs a relogin — the env vars are session-scoped)

## 6. AGS light mode

- [x] 6.1 Extract the SCSS helpers and colour tokens into `ags/_tokens.scss`
- [x] 6.2 Tokenise the eight hardcoded `rgba(255,255,255,…)` / `rgba(0,0,0,…)` sites to `hairline` / `shade`
- [x] 6.3 Add `ags/light.scss` carrying the light-mode deltas (shadow weight, translucency)
- [x] 6.4 `theme.ts`: read `mode` from `colors.json`, inject `hairline`/`shade` per mode, append the light sheet in light mode
- [x] 6.5 Read the palette through `current/` and detect a switch without a restart
- [x] 6.6 Verify the AGS bundle builds and contains both sheets
- [ ] 6.7 Verify live: toggling recolours the bar and overlays, and light mode is legible

## 7. Picker and keybind

- [x] 7.1 Picker lists pairs; each thumbnail previews the member matching the current mode
- [x] 7.2 Selection invokes `theme-switch <pair>` and preserves mode
- [x] 7.3 Add the mode-toggle keybind to `bindings.nix`
- [x] 7.4 Verify the picker lists one tile per pair and selection keeps the mode

## 8. Editor contract

- [x] 8.1 Emit `nvim.lua` and `colors-ansi.json` in the bundle, carrying the ANSI-faithful palette and the mode
- [x] 8.2 Document the `current/` contract in the README
- [x] 8.3 Confirm the editor palette keeps distinct ANSI slots rather than the shell's accent remapping

## 9. Wrap-up

- [x] 9.1 Verify implementation against specs (`opsx:verify`)
- [x] 9.2 Link this change to bean `lkasper-hyprland-o51v` and its sub-beans

## 10. Third-party GUI applications

- [x] 10.1 Verify the colour-scheme change is broadcast on the portal Settings interface on every toggle
- [x] 10.2 Firefox: `policies.Preferences` pinning portal use and system-following toolbar/content themes
- [x] 10.3 teams-for-linux: confirm `followSystemTheme` (already defaults true in 2.11 and listens live) — no config needed
- [x] 10.4 Slack / Aonsoku: determine the mechanism (both Electron via `nativeTheme`) and record that their in-app appearance setting must be "follow the system"

## 11. Retrobox for the text tools

- [x] 11.1 Extract the authoritative retrobox palette (both backgrounds) from neovim's `retrobox.vim`
- [x] 11.2 Generate `foot.ini`, `ghostty` and a new `tmux.conf` bundle file from it, per mode
- [x] 11.3 `nvim.lua` carries `colorscheme` + `background`; neovim needs no palette of its own
- [x] 11.4 tmux: drop `tmuxPlugins.gruvbox`, `source-file -q` the bundle, reload via `tmux source-file` + `refresh-client -S` in theme-apply
- [x] 11.5 nixvim: `config/themes/retrobox.nix` reading the contract, with an fs watcher, `:ThemeReload` and a standalone fallback
- [x] 11.6 Verify all 16 ANSI slots match `retrobox.vim` for both terminals in both modes
- [x] 11.7 Verify both tmux.conf files parse in a real tmux server, and nvim resolves the contract both ways
- [x] 11.8 fish: emit `fish.fish` per mode with `set -U` colours; drop the hardcoded gruvbox palette and make the prompt palette-driven; reload from theme-apply
- [x] 11.9 Verify fish renders both prompts with empty stderr in both modes and pager contrast is fixed
- [x] 11.10 btop: generate its theme from retrobox and set `theme_background = true` so it stops showing terminal content through its panels
- [x] 11.11 clipse: emit `clipse-theme.json` per mode (full 26-key schema) and symlink it as `custom_theme.json`
- [x] 11.12 claude code: theme-apply sets the `theme` key in `~/.claude/settings.json` atomically, preserving all other keys
- [x] 11.13 Audit every generated colour for >= 3:1 against its own background in both modes; retire `rb.dim` from "faint but visible" roles

## Notes

- 5.5 and 6.7 are live-desktop checks and need the user at the machine; everything else is
  verified by build and by exercising the scripts against a sandboxed `HOME`.
- Local `nix build` of this repo only sees git-tracked files, so `ags/_tokens.scss`,
  `ags/light.scss`, `wallpapers/pairs.nix` and `wallpapers/palette-tool.py` must be committed
  before a from-source build resolves them.
- 4.2 corrected mid-implementation: `hypr/theme.conf` was NOT dead. It is sourced from
  `_hyprland/configuration.nix` `extraConfig`, which home-manager appends last, so the
  write-once file silently overrode `looknfeel.nix`. See bean mkrd.
- 3.3 hardened after a live failure: the previous layout left `current` as a real directory, so
  the `! -e` guard skipped creating both the symlink and the state file, and Hyprland's `source=`
  then found no match. Activation and `theme-apply` now share a migration fragment and the guard
  is `! -L || ! -d`, which also self-heals a dangling symlink. See bean `4qcy`.
- 5.x reopened after live testing: GTK/Firefox could never follow, because the XDG portal had no
  `Settings` interface at all. Root cause was NOT dconf (which works) but home-manager's
  `xdg.portal` shadowing the system portal directory, so `gtk.portal` was invisible. See bean
  `xq4d`; the dconf hypothesis in `pw1t` is corrected.
- ghostty needed more than a symlink: with `gtk-single-instance = true`, new windows come from the
  process that already loaded the old theme, so only a full restart would have re-themed it.
  Now driven by its `reload-config` D-Bus action.
- Third-party apps follow POLARITY only, never the wallpaper palette — none of Slack, Aonsoku,
  teams-for-linux or Firefox accepts an arbitrary base16 palette. See bean `v8re`.
- 10.x live round 2: slack/teams switched one way only because `GTK_THEME=Adwaita-dark` was still
  in the running session (Chromium weighs the GTK theme name alongside the portal, and the pinned
  dark theme wins the disagreement). Activation now clears the stale vars from the systemd user
  environment; a relogin is still needed for apps launched from hyprland keybinds. Aonsoku 0.14.0
  cannot follow at all — its renderer owns the choice and pushes it into `nativeTheme`, with no
  "system" value in the enum. Needs upstream. See bean `v8re`.
- The text tools (foot, ghostty, tmux, neovim) deliberately LEFT the wallpaper pipeline for
  retrobox, while still following the light/dark toggle. Shell chrome stays wallpaper-derived.
  See bean `t3wx`; supersedes the mini.base16 plan in `9k58`.
- tmux reload must not assume the socket path: with `TMUX_TMPDIR` set (as here, `/run/user/1000`)
  a hyprland keybind cannot find the server via the default `/tmp` location and the reload was
  skipped silently. theme-apply now scans candidate socket dirs and sources into every server.
- claude code uses the `*-ansi` theme variants so it inherits the retrobox terminal palette; its
  built-in `dark` theme assumes a near-black background and measured 1.50:1 against retrobox's
  #1c1c1c. The exact enum could not be verified (compressed binary, no settings validation) -
  confirm via the in-app `/theme` picker.

