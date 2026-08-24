---
# lkasper-hyprland-4qcy
title: Runtime theme bundle behind one symlink
status: completed
type: task
priority: high
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

The enabling change for the mode toggle. Nix renders a complete config bundle for EVERY (pair, mode) combination into the store; `~/.config/lkasper-hyprland/current` is a runtime-owned symlink at the active one, and every consumer reads through it. Switching is one `ln -sfn` plus a fan-out of reload signals.

    themes/<pair>/<mode>/{colors.json,colors-ansi.json,foot.ini,btop.theme,
                          ghostty,starship.toml,hypr.conf,hyprlock.conf,
                          gtk.css,opencode.json,nvim.lua,wallpaper.path}

    ~/.config/lkasper-hyprland/current -> themes/beach/dark
    ~/.config/lkasper-hyprland/state   -> "beach dark"

Rejected alternatives: runtime templating with jq (duplicates every template in shell, reintroduces build/runtime skew) and rebuild-to-switch (~30s, unusable on a keybind).

Side benefit: settles the open question the archived design left dangling — because `current` is created only when absent and is never a `home.file`, a rebuild does not stomp a runtime selection.

Reload matrix: AGS + Hyprland + wallpaper + foot (SIGUSR1) + GTK (gsettings) are live; btop / ghostty / starship / opencode are next-instance. foot needs a hand-written foot.ini because its `include=` is a default-section directive and `pkgs.formats.ini` cannot emit a top-level scalar key.

Rolls up under o51v. Subsumes f0lk and mkrd.

## Implemented (opsx:apply)
12 files per (pair, mode) = 24 rendered and verified. `current` is relinked atomically via ln to current.new + mv -Tf, because plain `ln -sfn` onto an existing symlink-to-directory would create the link INSIDE the target. Verified: current stays a symlink after repeated toggles, never nests.

foot needed a hand-written xdg.configFile foot.ini with settings = { } to suppress home-manager's own file, since foot's include= is a default-section directive and pkgs.formats.ini cannot emit a top-level scalar key. hyprlock uses sourceFirst + settings.source with $lkh_* hyprlang variables so the vars are defined before use.

A shellcheck failure (SC2034, pair unused in theme-switch) turned the shared inline state snippet into a proper theme-state command that prints '<pair> <mode>' - less duplication and scriptable.

## Bug: first live theme-toggle failed (legacy `current` directory)
User hit two symptoms on the first real run:

    mv: cannot overwrite directory '~/.config/lkasper-hyprland/current' with non-directory '.../current.new'
    Config error in hm_hyprhyprland.conf at line 237: source= globbing error: found no match

One root cause. The OLD layout made `~/.config/lkasper-hyprland/current` a REAL DIRECTORY
holding `theme.name` (created by the previous themes.nix activation). Confirmed on disk: dir
dated 20 jul containing only `theme.name` = "wood-dark".

The new activation guarded creation with `if [ ! -e current ]`, which the stale directory
satisfied, so it created NEITHER the symlink NOR the state file. Then `mv -Tf` refused to
replace a directory with a symlink, and because no `current/hypr.conf` existed, Hyprland's
`source=` at line 237 found no match. The aborted mv also left a stray `current.new` symlink.

Fix: a shared `migrateCurrent` fragment used by both activation and theme-apply -- if `current`
exists and is not a symlink, drop `theme.name`, `rmdir` (falling back to `rm -rf`), and clear
any stray `current.new`. Activation's guard changed from `! -e` to `! -L || ! -d`, which also
self-heals a DANGLING symlink (removed pair / GC'd target), and the state file is now written
independently of the symlink's existence.

Verified against a sandbox reproducing the exact live layout (real dir + theme.name + stray
current.new + no state): migration succeeds, three consecutive toggles exit 0 and alternate,
a dangling symlink is recovered, and a stray current.new is cleaned. The old theme.name value
is deliberately NOT migrated - "wood-dark" is no longer a pair.

## Bug: ghostty did not re-theme (gtk-single-instance)
Symlinking `~/.config/ghostty/themes/lkh-runtime` into the bundle was not enough. ghostty is
configured with `gtk-single-instance = true`, so a "new window" is served by the process that
already parsed the config - the documented "new windows only" behaviour degenerated to "full
restart only", i.e. the terminal never followed the toggle.

Fix: ghostty 1.3 exports a `reload-config` action on `org.gtk.Actions` at
`com.mitchellh.ghostty`. theme-apply now activates it over D-Bus, guarded by a
`org.freedesktop.DBus.ListNames` check so it never D-Bus-ACTIVATES a ghostty that is not
running (an unguarded `gdbus call` would spawn a terminal out of nowhere).

Discovered via `gdbus call ... org.gtk.Actions.List` on the live instance:
['open-config', 'present-surface', 'quit', 'new-window-command', 'new-window', 'reload-config'].
Verified live: the call returns `()` and ghostty picks up the palette immediately.
