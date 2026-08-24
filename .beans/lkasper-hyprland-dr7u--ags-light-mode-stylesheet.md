---
# lkasper-hyprland-dr7u
title: AGS light mode stylesheet
status: completed
type: task
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

The AGS shell is authored as a dark surface. An audit of all 1713 lines of `ags/style.scss` found exactly EIGHT dark-surface assumptions — white hairlines and black shadows at lines 52, 1291, 1294, 1380, 1381, 1464, 1546, 1590:

    rgba(255,255,255,.04/.02/.05/.06/.07/.1)   white hairlines and fills
    rgba(0,0,0,.7/.75)                          shadows

Everything else already survives inversion, because the hierarchy is built from `alpha(@base05, ...)` ramps off the FOREGROUND token — bean 9ura's legibility fix turns out to be polarity-agnostic.

So light mode is a token flip plus a delta sheet, not a second stylesheet: those eight become `hairline` / `shade` named colours injected per mode by `theme.ts`, the shared helpers move to `_tokens.scss`, and `light.scss` carries the genuine light-mode differences (shadow weight, translucency).

Two full 1713-line sheets was considered and rejected — the audit says there is nothing structural to diverge about, and a fork would drift on every future widget edit.

Also dark-pinned but out of scope: `iconTheme = "Gruvbox-Plus-Dark"` has no light sibling, so icons stay dark-tuned in light mode.

Rolls up under o51v.

## Implemented (opsx:apply)
S2 chosen (tokens + delta sheet) over two full stylesheets. ags/_tokens.scss holds the helpers and colour tokens; style.scss imports it and all eight hardcoded sites became ca(hairline, ...) / ca(shade, ...); ags/light.scss carries the light deltas. theme.ts reads mode from colors.json, injects hairline/shade, and appends light.scss only in light mode.

Verified in the decoded bundle: 8 alpha(@hairline|@shade, ...) usages, zero rgba(255,255,255,*) or rgba(0,0,0,*) remaining, light.scss selectors compiled in.

Also fixed while here: the picker painted its thumbnails once at construction, so they would have gone stale after a mode toggle. Thumbnails are now re-pointed on every open.

Gotcha for anyone touching this: sass partials are invisible to a local nix build until committed, because the flake source only includes git-tracked files. The first build failed with 'Can't find stylesheet to import' for exactly that reason, not a sass problem.
