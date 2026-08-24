---
# lkasper-hyprland-9k58
title: Neovim follows the wallpaper palette
status: completed
type: feature
priority: normal
created_at: 2026-08-24T00:00:00Z
updated_at: 2026-08-24T00:00:00Z
---

Neovim is completely outside the colour pipeline: the `nixvim` repo is a separate flake built as a package (`home.packages = [ inputs.nixvim.packages....default ]`) with `melange` enabled statically and no knowledge of the wallpaper palette.

## The cross-repo insight
`~/.config/lkasper-hyprland/current/` is the contract. Three repos, one well-known runtime path, no build-time coupling in either direction — nixvim gains no input on lkasper-hyprland and vice versa. nixvim falls back to melange when the path is absent, so it stays usable standalone.

This bean covers THIS repo's half: emit `nvim.lua` and `colors-ansi.json` in the theme bundle, carrying the ANSI-faithful palette plus the mode. The nixvim-side implementation is separate work in the nixvim repo.

## Critical detail
Neovim must read the ANSI-FAITHFUL palette, not `colors.json`. `themes.nix` deliberately remaps base0A-base0F onto the three-colour accent triple for AGS ("everything dynamic", bean 9ura), which collapses several slots onto the same hue. Feeding that to a syntax highlighter makes strings, types and keywords look alike.

## nixvim-side options (for the follow-up)
- N1 `mini.base16` fed the runtime palette + `vim.uv.fs_event` watch for live recolour. Exact sync, but auto-generated base16 highlighting is flat.
- N2 nearest named colourscheme. Pretty, approximate — not what was asked for.
- N3 N1 plus ~15 curated `nvim_set_hl` overrides for comments/strings/diagnostics/diff. Recommended.

Rolls up under o51v.

## This repo's half implemented (opsx:apply)
The bundle emits current/nvim.lua (Lua table: mode, background, base00-base0F) and current/colors-ansi.json. Verified the editor palette stays ANSI-faithful where the shell palette does not: light nvim.lua has base0A=#787A00 (yellow) while colors.json has base0A=AA624B (accent2). Contract documented in the README.

Still open: the nixvim-side implementation (N3 recommended - mini.base16 from the runtime palette plus ~15 curated nvim_set_hl overrides, falling back to melange when the path is absent).

## Superseded by t3wx
The user chose retrobox for neovim, so it no longer consumes the wallpaper palette. The N1/N3
mini.base16 options are moot, along with the "flat auto-generated highlighting" trade-off. The
contract this bean established is still what neovim reads - it just reads `colorscheme` and
`background` from it now instead of the palette. Implemented in the nixvim repo as
config/themes/retrobox.nix.
