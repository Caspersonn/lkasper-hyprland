## Context

The setup already has a single-source-of-truth colour pipeline: `modules/_themes.nix` registers base16 theme names, `modules/home-manager/themes.nix` picks one (`declarativeTheme = "gruvbox"`) and sets `nix-colors` `config.colorScheme`, which `foot`, `btop`, `hyprlock`, Hyprland borders (`looknfeel.nix`), ghostty, starship and opencode all read. `themes.nix` also writes runtime scaffolding — per-theme `~/.local/share/lkasper-hyprland/themes/<name>/colors.json`, a `~/.config/lkasper-hyprland/current/theme.name` pointer, and app config files written as defaults — i.e. the bones of a runtime theme switcher.

The AGS shell is the sole outlier: `ags/style.scss` hardcodes a gruvbox palette plus the static `$w-*` "Wood Dark" tokens from the recent bar redesign, compiled into the bundle at build time (`App.start({ css })`). The wallpaper is set statically by `hyprpaper` (`services.hyprpaper`, one preloaded path).

We want the wallpaper to drive every colour, chosen from a picker, with no static colours (see proposal). Requirements are in `specs/` (`wallpaper-palette-generation`, `wallpaper-theme-switching`, `wallpaper-picker`).

## Goals / Non-Goals

**Goals:**
- One palette derived from the active wallpaper drives the whole desktop, AGS included.
- Instant runtime switching among a curated wallpaper set via a picker, without a rebuild.
- Fully reproducible: palettes are committed; Nix never runs the generator at eval/build.
- No hardcoded colour palettes anywhere; semantics (ok/warn/crit) are wallpaper-derived.

**Non-Goals:**
- Theming arbitrary runtime images without first running the generator + committing.
- Animated/cross-fade colour transitions.
- Reworking non-colour styling (layout/spacing) beyond what the AGS colour refactor forces.

## Decisions

### D1 — Approach C: committed per-wallpaper base16, switched at runtime
Pre-generate a base16 palette for each wallpaper at dev time, commit it, and switch among them at runtime. **Alternatives:** (A) pure build-time — one palette baked, recolour needs a rebuild (rejected: no live switch, and a picker implies live); (B) pure runtime daemon generating for any image on the fly (rejected: impure, colours live outside Nix, more moving parts). C reuses the existing `themes/<name>/colors.json` + `current/theme.name` scaffolding and keeps Nix pure while allowing instant switches.

### D2 — Generator: `wallust` (base16-native)
`wallust` outputs base16 directly, matching the existing `nix-colors` pipeline with no lossy mapping. **Alternatives:** `matugen` (Material-You; needs an opinionated base16 mapping — rejected for friction), `pywal` (unmaintained relative to wallust). Base16's slot convention (base08≈red, 0A≈yellow, 0B≈green) also keeps wallpaper-derived semantics sane.

### D3 — Palette flows through the existing colour pipeline
The active wallpaper's palette feeds `config.colorScheme` as the build-time default/fallback (so first paint and non-live apps are correct), while the runtime `colors.json` + `current/theme.name` carry the live value that the switch updates. `_themes.nix`/`themes.nix` are reworked to register one entry per wallpaper sourced from its committed palette instead of a hardcoded theme name.

### D4 — AGS consumes colours at runtime via GTK named colours
AGS keeps its compiled structural stylesheet but moves its **colour layer** to GTK `@define-color`: at startup and on switch, AGS reads the active `colors.json`, builds a `@define-color …` block, and applies it with `App.apply_css` (reset only the colour provider). Widgets recolour without a rebuild. This retires the gruvbox `$…` and `$w-*` Sass variables (the `de2q` cleanup). **Alternative:** regenerate the full CSS from the palette in TS and re-apply — simpler conceptually but duplicates every selector. **Spike:** Sass and `@define-color` don't compose (the `@` collides with Sass directives), so the colour references likely move out of `.scss` into a GTK-native colour stylesheet; confirm the cleanest split (structure in Sass, colours in a hand-written GTK CSS provider).

### D5 — Wallpaper switching via hyprpaper IPC (no daemon swap)
Keep `hyprpaper`; switch with `hyprctl hyprpaper` at runtime rather than adopting `swww`. A `theme-switch <wallpaper>` script orchestrates: set wallpaper (IPC) → repoint `current/theme.name` → reload apps. **Alternative:** `swww` (nicer transitions) — deferred; not worth adding a second wallpaper daemon now.

### D7 — Wallpapers move in-repo; static images only
The static wallpapers (`.png`/`.jpg`) move from `~/lkasper-flake/wallpapers/` into `lkasper-hyprland/wallpapers/`, colocated with the theming modules, so the feature is a self-contained change and palettes sit next to their images. `hyprpaper.nix` (and its `lkasper-flake` consumer) point at the in-repo copy. **Alternatives:** keep images in `lkasper-flake` with a `wallpaperDir` option (rejected: splits palette/image across repos), or palettes-only in-repo (rejected: more moving parts). **Scope:** video wallpapers (`.mp4`/`.gif`) are excluded here — hyprpaper can't display them and palette extraction needs a frame; they remain in `lkasper-flake` for a later change.

### D6 — Picker is an AGS overlay
Reuse the launcher/soltty overlay pattern: a per-monitor `Astal` window with a thumbnail grid of the wallpaper set, keyboard + click selection, opened by a keybind (and optionally a bar button). Selecting a thumbnail invokes `theme-switch`.

## Risks / Trade-offs

- **AGS Sass ↔ `@define-color` interop** → Mitigation: spike D4 early; if messy, fall back to a runtime-regenerated colour CSS (D4 alternative). This is the riskiest unknown.
- **Terminals/btop don't hot-reload cleanly** → Mitigation: reload via each app's supported path (e.g. foot `SIGUSR1`/OSC, btop theme file re-read); accept that some only apply on new windows and document it. Compositor + AGS update immediately, which covers the visible "recolour."
- **Wallpaper-derived semantics may be tinted or low-contrast** (user accepted) → Mitigation: rely on base16 slot roles; add an optional min-contrast clamp for bar/overlay text if a wallpaper produces unreadable pairings.
- **`wallust` output quality varies per image** → Mitigation: palettes are committed and reviewable; a bad palette can be hand-edited in its committed JSON without touching code.
- **Regeneration is a manual dev step** → Mitigation: single `regenerate-palettes` command; adding a wallpaper is "drop image → run command → commit."

## Migration Plan

0. Move the static wallpapers (`.png`/`.jpg`) into `wallpapers/` (git-add so the flake sees them); repoint `hyprpaper.nix` at the in-repo copy.
1. Add `wallust`; add the `regenerate-palettes` command; generate + commit a base16 palette for each image in `wallpapers/`.
2. Rework `_themes.nix`/`themes.nix` to register wallpaper-derived palettes and wire `colorScheme` to the active wallpaper (default = current).
3. Refactor the AGS colour layer to the runtime palette (D4); remove gruvbox `$…` and `$w-*` vars.
4. Add the `theme-switch` script (D5) and the picker overlay + keybind (D6).
5. Verify a switch recolours AGS + Hyprland immediately and the rest on their reload path.

**Rollback:** revert the change commit (palettes + modules + AGS); `colorScheme` returns to the `"gruvbox"` pick and AGS to its baked palette.

## Open Questions

- **Light/dark policy** — RESOLVED: **force dark.** The generator uses `ansidark16`, which always yields a near-black `base00`, and the AGS UI is authored as a dark surface with light text (foreground alpha-ramps for the dim/faint hierarchy). No light-mode variant. The built-in fallback palette is dark too, so the policy holds even when a wallpaper has no palette.
- **Contrast clamp** — RESOLVED: two layers. (1) wallust `check_contrast = true` already enforces fg/bg contrast for `base00–base0F`. (2) The wallpaper-derived accent triple (`accent`/`accent2`/`accent3`) is *not* covered by that check, so the generator clamps each accent to a minimum HSV brightness (`v ≥ 0.55`) so accent-coloured text/fills stay readable on the near-black bar. Threshold chosen from the real palettes: it leaves every current accent essentially unchanged and only lifts genuinely-dark future ones.
- **Boot source of truth**: at login, does the desktop read `current/theme.name` (runtime) or the Nix default? Define precedence so a rebuild doesn't stomp a runtime selection (or accept that a rebuild resets to default).
- **Terminal live-reload**: attempt foot/ghostty live reload, or accept next-window only?
