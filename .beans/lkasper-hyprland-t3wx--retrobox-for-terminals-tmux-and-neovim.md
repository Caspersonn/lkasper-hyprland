---
# lkasper-hyprland-t3wx
title: Retrobox for terminals, tmux and neovim (fixed palette, still mode-following)
status: completed
type: feature
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

tmux, the terminals and neovim use retrobox instead of the wallpaper palette. This is a partial,
deliberate walk-back of wallpaper-driven theming for the text tools: shell chrome (AGS bar,
Hyprland borders, hyprlock, btop, starship, opencode) stays wallpaper-derived, while the things
you read code in get a stable, hand-tuned palette.

Decided with the user:
- retrobox FOLLOWS the light/dark toggle rather than being pinned dark - retrobox ships both
  backgrounds, so the keybind stays meaningful.
- foot is included, not just ghostty. Leaving foot wallpaper-derived would have put two terminals
  with different colours side by side (foot is used by the clipse / nmtui / btop keybinds).

## Source of truth
Ghostty has NO retrobox theme (only "Retro", "Retro Legends" and Gruvbox variants), so the
palette is generated rather than referenced. The authoritative values come from neovim's bundled
`share/nvim/runtime/colors/retrobox.vim`, which carries a `g:terminal_ansi_colors` list per
background:

    dark   bg #1c1c1c  fg #ebdbb2   surface #303030  selection #2a405a  accent #d79921
    light  bg #fbf1c7  fg #3c3836   surface #e5d4b1  selection #b0d0d0  accent #b57614

Verified programmatically: all 16 ANSI slots in the generated ghostty AND foot files match
`retrobox.vim` byte-for-byte, in both modes. So terminal colours are exactly what neovim renders.

## Wiring
- themes.nix: a fixed `retrobox` attrset per mode; `foot.ini`, `ghostty` and a new `tmux.conf`
  bundle file are generated from it. `nvim.lua` now carries `colorscheme = "retrobox"` and
  `background = light|dark` (the wallpaper palette is still emitted as `wallpaper_background`
  plus `palette` for anything that wants it).
- theme-apply: reloads tmux with `tmux source-file` when a server is running, alongside the
  existing foot SIGUSR1 and ghostty reload-config.
- lkasper-flake tmux.nix: dropped `tmuxPlugins.gruvbox` (it forced its own theme) and added
  `source-file -q ~/.config/lkasper-hyprland/current/tmux.conf`. `-q` so a missing file is not an
  error.
- nixvim repo: new `config/themes/retrobox.nix`; melange disabled. It `dofile`s the contract,
  applies `background` + `colorscheme`, watches the resolved `current/` directory with
  `vim.uv.new_fs_event` for live re-apply, and adds a `:ThemeReload` command. Falls back to
  retrobox dark when the contract is absent, so nixvim stays usable standalone.

## Verified
- 16/16 ANSI slots match retrobox.vim for ghostty and foot, dark and light.
- Both generated tmux.conf files parse in a real tmux server (`source-file` + `show-options -g`).
- nixvim built, and run headless against each contract: dark -> `dark / retrobox`,
  light -> `light / retrobox`, no contract -> `dark / retrobox` with no error.

Supersedes the mini.base16 plan in bean 9k58 - neovim no longer needs the wallpaper palette at
all, so the N1/N3 "flat auto-generated highlighting" trade-off disappears.

Rolls up under o51v.

## tmux auto-reload on the keybind: was implemented, but not instant
User reported the toggle should re-source tmux. It already did (theme-apply runs
`tmux source-file` when a server is live), and measured on the machine it does keep tmux in
lockstep - two toggles with TMUX unset (mimicking the hyprland keybind environment):

    state=beach light  status-style=fg=#3c3836,bg=#e5d4b1
    state=beach dark   status-style=fg=#ebdbb2,bg=#303030
    state=beach light  status-style=fg=#3c3836,bg=#e5d4b1

Two reasons it read as broken:

1. The running tmux server was started at 12:04, BEFORE `current/tmux.conf` existed in the
   bundle, so its startup `source-file -q` found nothing (the `-q` making that silent) and it
   held stale styles until the first toggle. New servers are fine; this was a one-off
   transitional state.
2. Real gap, now fixed: `source-file` sets the options but does not force a repaint, so the
   status bar only picked up new colours on the next `status-interval` tick - measured at 5s on
   this machine. Added `tmux refresh-client -S` after the source so the bar redraws immediately.

Also confirmed no client/server binary mismatch: the running server and theme-apply's PATH both
resolve to the same tmux-3.6a store path, so `source-file` is not silently failing on protocol
version.

## fish was hardcoded gruvbox dark (unreadable in light mode)
`lkasper-flake modules/users/shared/fish.nix` set a fixed gruvbox-DARK palette in
`interactiveShellInit`, plus literal gruvbox hexes in `fish_prompt` / `fish_right_prompt`.
Measured against the retrobox light background (#fbf1c7):

    fish_color_normal / param      #ebdbb2   1.21:1   invisible
    fish_pager_color_completion    #ebdbb2   1.21:1   invisible  <- the file list in the report
    fish_color_command             #b8bb26   1.82:1   invisible
    fish_color_comment             #a89984   2.45:1   weak

Fix: the bundle emits a `fish.fish` per mode using `set -U` (universal) variables - the standard
`fish_color_*` / `fish_pager_color_*` set plus semantic `lkh_red/green/yellow/blue/magenta/cyan/
fg/dim` for the prompt. Universals are the key choice: fish notifies running instances when they
change, so a toggle recolours OPEN shells rather than only new ones.

fish.nix now sources the bundle in `interactiveShellInit` and the prompt functions reference the
`lkh_*` variables. A `for pair in name:hex ...` loop sets globals ONLY when the variable is not
already defined (`set -q` sees universals), so nixvim-style standalone use still has colours
without shadowing the bundle. Scope order matters here: fish resolves local -> function ->
global -> universal, so leaving the old `set -g` lines in place would have silently shadowed
every universal and the whole mechanism would have looked broken.

Colour mapping trick: the prompt/semantic colours use ANSI slots 9-14 for BOTH modes. In the
dark palette those are the bright variants, in the light palette they are the darker variants -
so one index set gives correct polarity in both without a second mapping table.

After: pager completion 1.21:1 -> 10.22:1.

### Bug caught by rendering, not by syntax checking
My regex rewrite of `set_color( --bold)? <hex>` used `m.group(1)` directly, which is `None` when
`--bold` is absent, emitting `set_colorNone $lkh_blue` in 8 places. `fish -n` passed clean -
`set_colorNone` is a syntactically valid command name and only fails at runtime. Only actually
executing `fish_prompt` surfaced it. Worth remembering: syntax-checking generated shell code is
not enough, render it.

Verified after the fix: both modes render `fish_prompt` and `fish_right_prompt` with empty
stderr, and the emitted escape sequences differ correctly per mode (green arrow b8bb26 dark vs
79740e light, user 83a598 vs 076678).

## btop unreadable in light mode - two causes, one of them not colour at all
btop was left wallpaper-derived while the terminal moved to retrobox. Measured against the
retrobox light terminal background:

    div_line     #AEB2AD   1.89:1   the box frames were essentially invisible
    main_bg      #F7FFFC   vs terminal #fbf1c7 - close but not equal, so a visible panel seam

But the thing actually making it unreadable was NOT colour: `theme_background = false` meant btop
never painted its own background, so the previous terminal contents showed through behind the
panels. In the user's screenshot you can read leftover file names (bindings.nix,
configuration.nix, envs.nix) ghosting through the memory and network boxes.

Fix, extending the retrobox decision to btop (it is a TUI inside the retrobox terminal, so it
belongs with the text tools):
- btop.theme generated from the retrobox palette per mode, so `main_bg` now equals the terminal
  background EXACTLY in both modes - no seam.
- `theme_background = true` in btop.nix, so it paints its own background and nothing bleeds
  through.
- `div_line` / `inactive_fg` use retrobox's comment grey (#928374), which is mid-grey and so works
  in both polarities - 4.64:1 on dark, 3.24:1 on light, versus 1.89:1 before.

Verified all box and text colours in both modes; every one is >= 3:1 against its own background.
One measured caveat: `hi_fg` (the single-letter keyboard shortcuts) is #b57614 at 3.33:1 in light
mode - below AA for small text. It is retrobox's own yellow, so it matches upstream rather than
inventing a colour; worth revisiting if the shortcut letters read badly in practice.

## clipse + claude code
Same class again: TUIs running inside the retrobox terminal with their own dark-assuming palette.

- **clipse** supports a custom theme, and usefully `useCustomTheme` lives INSIDE
  custom_theme.json rather than config.json, so the whole thing is one generated file and
  config.json is left alone. The bundle emits `clipse-theme.json` per mode and activation
  symlinks `~/.config/clipse/custom_theme.json` at it. Verified the generated file matches the
  schema clipse ships exactly - 26/26 keys, none missing, none extra. clipse is launched fresh
  from the keybind each time, so next-launch pickup is all that is needed.
- **claude code** has no auto/system theme, only a `theme` key in ~/.claude/settings.json.
  theme-apply now sets it with `jq '.theme = $t'` into a temp file then `mv -f`, so a malformed or
  unreadable settings.json leaves the original untouched (verified: a deliberately corrupt file
  was left as-is and the temp cleaned up). All other keys are preserved - verified against a copy
  of the real settings.json: model, effortLevel, enabledPlugins, alwaysThinkingEnabled etc. all
  survive. Claude reads the theme at startup, so a running session needs a restart or `/config`.

  Caveat: claude-code ships as a compiled binary, so I could not extract its theme enum to
  confirm. Using the documented `dark`/`light` values. The `*-ansi` variants would inherit the
  retrobox terminal palette exactly if a closer match is ever wanted.

## The rb.dim polarity trap (bit me three times)
`rb.dim` is retrobox's LineNr: #7c6f64 on dark, #a89984 on light. It is deliberately subtle, so
it is the WRONG token anywhere "faint but still visible" is needed - on light it lands around
2.45:1. It caused faint btop box frames, a near-invisible clipse PreviewBorder, and faint tmux
pane borders.

Correct token for that role is `rb.comment` (#928374), which is mid-grey and therefore works in
both polarities: 4.64:1 on dark, 3.24:1 on light. All three sites now use it and `rb.dim` is no
longer referenced anywhere.

Related fix: the clipse title bar was cream-on-accent at 3.33:1. Inverted it to
TitleFore=bg / TitleBack=fg, which is both much stronger (12.4:1 dark, 10.2:1 light) and matches
retrobox's own StatusLine, which upstream styles as `bold,reverse`.

## tmux reload silently skipped from the keybind (TMUX_TMPDIR)
Post-activation sweep found everything in light EXCEPT tmux, which was still showing the dark
surface (#303030 instead of #e5d4b1).

Cause: this machine has `TMUX_TMPDIR=/run/user/1000`, so the server socket is
`/run/user/1000/tmux-1000/default` and `/tmp/tmux-1000/` is empty. A hyprland keybind does not
inherit TMUX_TMPDIR, so `tmux list-sessions` looked in /tmp, found nothing, and the guard skipped
the whole tmux block - silently, because of the `|| true` and output redirection.

Proof: `env -u TMUX -u TMUX_TMPDIR tmux list-sessions` ->
`error connecting to /tmp/tmux-1000/default (No such file or directory)`.

My earlier "verified" test was invalid: I unset TMUX but NOT TMUX_TMPDIR, so the test environment
was strictly more favourable than the real keybind environment. Worth remembering when faking a
keybind context - unset every var the interactive shell contributes, not just the obvious one.

Fix: stop assuming a socket path. theme-apply now scans `"$TMUX_TMPDIR"`, `/run/user/$(id -u)`
and `/tmp` for `tmux-$(id -u)/*` sockets and does `tmux -S <socket> source-file` +
`refresh-client -S` on each. Handles any TMUX_TMPDIR, multiple servers, and no server at all.

Verified with BOTH vars unset: two toggles, tmux tracks state exactly
(#e5d4b1 light <-> #303030 dark).

## claude code unreadable in DARK mode -> switched to the ANSI theme variants
Light mode was fine, dark was not. Confirmed live: state=dark, claude theme="dark", terminal bg
#1c1c1c (retrobox dark), ghostty background-opacity 0.95.

Cause: Claude Code's built-in `dark` theme uses its OWN hardcoded greys, tuned for a near-black
terminal. Against #1c1c1c a typical such grey (#3a3a3a) measures 1.50:1, which matches the
reported screenshot. Nothing in our palette was wrong - the built-in theme simply does not know
what background it is sitting on.

Fix: theme-apply now writes `$mode-ansi` rather than `$mode`, i.e. dark-ansi / light-ansi. The
ANSI variants derive from the terminal's own 16-colour palette, which is retrobox and already
measured: bright-black #928374 = 4.64:1 for dim/secondary text, fg #ebdbb2 = 12.42:1 for body.
That also makes Claude Code consistent with every other TUI instead of carrying an independent
palette.

UNVERIFIED, and worth stating plainly: claude-code ships as a compressed binary - `strings`
finds zero matches even for known setting names like `alwaysThinkingEnabled` - and the CLI does
not validate settings (`--settings '{"theme":"totally-bogus-theme"}' --version` exits 0
silently). So the `*-ansi` names could not be confirmed against the real enum. The authoritative
list is the in-app `/theme` picker. If the names differ, the fix is one string in theme-apply.
