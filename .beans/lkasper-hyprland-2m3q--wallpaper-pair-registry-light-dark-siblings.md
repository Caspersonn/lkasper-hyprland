---
# lkasper-hyprland-2m3q
title: Wallpaper pair registry (light/dark siblings)
status: completed
type: task
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

A wallpaper stops being a standalone image and becomes a PAIR of a light and a dark sibling, declared in `wallpapers/pairs.nix`. Theme state becomes (pair, mode); toggling mode swaps the image and the palette together.

An explicit nix registry rather than a `-light`/`-dark` filename convention, so siblings can have unrelated names and completeness is checkable. Eval-time assertion: every image in `wallpapers/` must be a member of exactly one pair, and no image may be claimed twice. An unpaired image fails the build instead of producing a ghost theme.

Consequence: one palette per IMAGE, not two per image — the member's role in the pair picks the generator flavour.

Only the `beach` pair is in scope for the first landing. `wood-dark`, `planet-zoo`, `princess-mononoke` and `studio-ghibli-style` had no siblings and were moved to `wallpaper.ignored/`; their palettes are deleted. Finding light siblings for them is user work, tracked separately.

Rolls up under o51v.

## Implemented (opsx:apply)
wallpapers/pairs.nix declares the beach pair. themes.nix asserts five conditions at eval time: malformed pair (not exactly light+dark), unpaired image, image claimed twice, pair naming a missing image, and missing committed palette. Verified the unpaired-image assertion by adding a stray png - eval failed naming it. Stale palettes for the four moved wallpapers deleted; wallpaper.ignored/ gitignored; hyprpaper.nix and the default theme now derive from the registry instead of a hardcoded wood-dark.
