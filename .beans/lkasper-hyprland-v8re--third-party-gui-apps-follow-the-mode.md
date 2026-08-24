---
# lkasper-hyprland-v8re
title: Third-party GUI apps follow the light/dark mode (slack, Aonsoku, teams-for-linux, firefox)
status: completed
type: feature
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

Slack, Aonsoku, teams-for-linux and Firefox should follow the desktop mode toggle.

## Important scoping reality
These apps follow POLARITY, not the palette. None of them accepts an arbitrary base16 palette,
so "dynamic theme" here means light/dark following, not wallpaper-derived colours. All four are
web-tech apps (Firefox; the other three Electron) and all consume the same signal:
`org.freedesktop.appearance color-scheme` on the portal Settings interface.

That signal was completely absent until bean xq4d was fixed - the portal had no Settings
interface at all - which is why none of them could ever follow. xq4d is the real enabler here.

## Verified: the signal is emitted live
`gdbus monitor` while toggling shows, on every single toggle:

    SettingChanged ('org.gnome.desktop.interface', 'color-scheme', 'prefer-dark')
    SettingChanged ('org.freedesktop.appearance', 'color-scheme', uint32 1)
    SettingChanged ('org.gnome.desktop.interface', 'gtk-theme', 'Adwaita-dark')
    ... and the prefer-light / uint32 2 / Adwaita triple on the way back

freedesktop encoding: 0 = no preference, 1 = prefer-dark, 2 = prefer-light.

## Per app
- **firefox** - declaratively fixed. `policies.Preferences` in lkasper-flake
  modules/users/shared/firefox.nix pins `widget.use-xdg-desktop-portal.settings = 1` (always
  read the portal, rather than "auto") plus toolbar-theme / content-theme /
  prefers-color-scheme.content-override = 2 (system). All `Status = "default"`, so they are
  defaults the user can still override in-app rather than locked values. Verified in the
  generated lib/firefox/distribution/policies.json, with the 5 existing ExtensionSettings intact.
  Deliberately NOT done: home-manager `profiles`. The module defines none today, so adding one
  would make HM manage profiles.ini and risk orphaning the real profile with its history and
  logins.
- **teams-for-linux** - nothing to do. 2.11.1 defaults `followSystemTheme` to true (changelog:
  "feat(config): default followSystemTheme to true") and registers an IPC listener on
  `system-theme-changed` that flips `clientPreferences.theme.userTheme` live. Deliberately did
  NOT write ~/.config/teams-for-linux/config.json: a read-only HM symlink there could block the
  app persisting its own settings, for zero benefit over the default.
- **slack** - no declarative lever exists. Theme choice lives in Slack's own storage, not a
  config file. Needs a ONE-TIME in-app change: Preferences > Themes > "Sync with OS setting".
  After that it follows the portal like any Electron app.
- **Aonsoku** - Electron (not Tauri, despite appearances). Its bundle uses `nativeTheme`,
  `themeSource`, `shouldUseDarkColors` and `matchMedia('prefers-color-scheme')`, so it can
  follow the OS, but the stored setting is `theme:"light"` / `theme:"dark"` in app storage.
  One-time in-app change to the system/auto option if it is currently pinned.

Rolls up under o51v. Depends on xq4d.

## Live round 2: one-way switching (slack, teams) + Aonsoku cannot follow at all

### slack / teams-for-linux switch light->dark but never back
Root cause is the still-live session env, NOT the apps. Measured on the machine:

    GTK_THEME=Adwaita-dark        <- still set
    ADW_DISABLE_PORTAL=1          <- still set
    gsettings color-scheme        <- correctly flips prefer-light / prefer-dark
    dconf writes per toggle       <- exactly 1 (verified with `dconf watch`; no double-apply)

Chromium/Electron decides dark from BOTH the portal colour-scheme AND the GTK theme name. With
GTK_THEME pinned to Adwaita-dark, the portal saying prefer-dark agrees with GTK and the app goes
dark; the portal then saying prefer-light DISAGREES with the pinned dark GTK theme, and the GTK
side wins on re-evaluation. Hence exactly the reported one-way behaviour.

`GTK_THEME` cannot be removed from a running session: it is in hyprland's own process
environment (from the config at hyprland start) and in the systemd user environment, so removing
the config line only affects the NEXT login. A relogin is the real fix.

Mitigation added so a rebuild gets further without a relogin: activation now runs
`systemctl --user unset-environment GTK_THEME ADW_DISABLE_PORTAL`, so apps started via
systemd/D-Bus activation or from a new shell are no longer pinned. Apps launched from a hyprland
keybind still inherit hyprland's stale environment - only a relogin clears that.

Quick way to confirm without relogging: quit slack, then `env -u GTK_THEME -u ADW_DISABLE_PORTAL slack`.

### Aonsoku: cannot follow the system, and not just for lack of an option
Read the shipped bundle (0.14.0). The data flow is INVERTED - the renderer owns the choice and
pushes it into Electron:

    ipcMain.on(UpdateNativeTheme, (e, a) => { nativeTheme.themeSource = a ? "dark" : "light" })

and the renderer store only ever holds `theme:"dark"` or `theme:"light"`. It never reads
`nativeTheme.shouldUseDarkColors` for its own theme (it uses it only to pick tray icon assets),
and there is no "system" value in the theme enum.

So no configuration or signal can make 0.14.0 follow the mode; it needs an upstream option.
Rewriting its persisted setting is not a viable workaround either: the store is renderer-side
(Electron localStorage/leveldb, and `~/.config/Aonsoku` does not even exist until first run), so
it is not safely writable from outside, and the app would not re-read it live anyway.

## Confirmed by the user
`env -u GTK_THEME -u ADW_DISABLE_PORTAL slack` follows the toggle in BOTH directions. That
settles two things:

1. The one-way behaviour was entirely the stale `GTK_THEME` pin, not an app or portal defect.
2. Slack's in-app Appearance is ALREADY set to "Sync with OS setting" - otherwise unsetting the
   env would have changed nothing. So the "one-time in-app change" caveat recorded earlier does
   NOT apply to slack; nothing to do there beyond the relogin. Same expected for
   teams-for-linux, whose followSystemTheme already defaults true.

Verified the relogin will be clean: the entire new home-manager generation contains exactly ONE
occurrence of GTK_THEME - the `systemctl --user unset-environment` cleanup line - and zero
definitions. The NixOS system sessionVariables carry only GTK_A11Y=none. Neither repo sets
GTK_THEME or ADW_DISABLE_PORTAL any more.

Caveat on the mitigation, restated because it matters for this user's workflow: apps launched
from a hyprland keybind or the AGS launcher inherit HYPRLAND's process environment, which still
holds the stale vars until hyprland restarts. The systemd unset-environment only helps apps
started via systemd/D-Bus activation or from a new shell. So for slack-from-the-launcher, the
relogin really is the fix.

## Live round 3: firefox still dark after relogin - stale about:config overrides
Relogin fixed the system side completely:

    GTK_THEME / ADW_DISABLE_PORTAL   unset
    gsettings                        prefer-light / Adwaita
    portal appearance color-scheme   uint32 2 (prefer-light)
    running firefox                  the build carrying the new policies

Cause is inside the profile. `~/.mozilla/firefox/personal/prefs.js` (Default=1) holds:

    user_pref("ui.systemUsesDarkTheme", 1);        <- line 317, the killer
    user_pref("browser.theme.toolbar-theme", 0);   <- line 80, 0 = dark

`ui.systemUsesDarkTheme` is Firefox's OVERRIDE for what the OS reports. Once it has a user
value, Firefox never asks the portal at all - so the UI can truthfully say "follow system theme"
(`extensions.activeThemeID` really is `default-theme@mozilla.org`, the auto theme) while
following a value that was faked to dark. Almost certainly a workaround the user added back when
the Settings portal was missing (bean xq4d), i.e. a leftover for the bug we just fixed.

`browser.theme.toolbar-theme = 0` is a USER value, and my policy uses `Status = "default"`, which
by design does not override a user value.

Cross-check that confirms the reading: the `work` profile has neither pref and should render
light already.

### Why this cannot be fixed declaratively
- A policy cannot UNSET a user pref.
- `ui.systemUsesDarkTheme = 0` is not "no override", it is "force light" - that would break dark
  mode instead of following.
- user.js only ever SETS user prefs, so it has the same problem.

The pref must be removed. Manual reset in about:config, or edit prefs.js with firefox closed
(prefs.js is rewritten on shutdown, so editing it while running is lost).

Optional hardening, NOT applied - it removes the in-app toggle: policy
`browser.theme.toolbar-theme` with `Status = "locked"`, `Value = 2` would prevent recurrence.
