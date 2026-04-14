## Context

The repository currently packages a partial subset of Omarchy themes under the local theme source consumed by `homeManagerModules.omarchy-hyprland`. Theme application is handled by `bin/omarchy-theme-set`, which stages selected theme files into `~/.config/omarchy/current/theme` and triggers generated/runtime assets such as Waybar CSS. Users requested parity with upstream Omarchy `dev/themes`, including backgrounds, while keeping the existing declarative mapping in `modules/_themes.nix` and local wallpaper assets in `config/themes/wallpapers/`.

## Goals / Non-Goals

**Goals:**
- Add all official upstream themes and bundled backgrounds from `https://github.com/basecamp/omarchy/tree/dev/themes` into repository-managed theme assets.
- Keep `modules/_themes.nix` as the declarative theme registry and expand it for every imported official theme.
- Keep wallpaper assets local in `config/themes/wallpapers/` and reference them through existing Nix-driven paths.
- Preserve current selection and apply flows (`omarchy-theme-set`, Walker/Elephant menu providers, generated template pipeline).
- Keep exported module contracts stable, especially `homeManagerModules.omarchy-hyprland` and existing `omarchy.theme` usage.

**Non-Goals:**
- Redesigning theme architecture or introducing a new theme format.
- Changing user-facing Nix option names or defaults unrelated to theme catalog completeness.
- Reworking application-specific theming logic beyond what is required to support newly imported official themes.
- Introducing dynamic runtime GitHub fetches or external source wiring for themes.

## Decisions

- **Source-of-truth decision:** Treat upstream Omarchy `dev/themes` as the canonical catalog, but vendor it into local committed files and keep `modules/_themes.nix` as the declarative registry.
  - Alternative considered: keep curated subset and add themes ad hoc.
  - Rationale: mirroring upstream minimizes drift and avoids repeated manual sync work.

- **Integration decision:** Reuse the existing local theme pipeline (`bin/omarchy-theme-set` + `bin/omarchy-theme-set-templates`) with local theme and wallpaper assets.
  - Alternative considered: direct runtime download from GitHub or dynamic import.
  - Rationale: existing pipeline already handles file staging, generated outputs, and restarts; online fetch at runtime conflicts with declarative Nix workflows.

- **Compatibility decision:** Keep module interfaces unchanged and implement changes in theme asset content plus any required script adjustments only where behavior gaps appear.
  - Alternative considered: add new toggles for "official-only" vs "local" catalogs.
  - Rationale: requested behavior is parity with upstream official catalog, not a new mode.

## Risks / Trade-offs

- **[Upstream drift]** Upstream can add/remove themes and backgrounds over time, causing local divergence again. → Mitigation: define a deterministic sync/update process and verify catalog parity during updates.
- **[Larger theme payload]** More bundled assets increase repository size and sync/update work. → Mitigation: preserve current layout (`modules/_themes.nix`, `config/themes/wallpapers/`) and automate catalog parity checks.
- **[Runtime regression]** New or updated theme files may expose gaps in generated asset or restart flow (for example Waybar runtime CSS behavior). → Mitigation: validate theme apply path with representative dark/light themes and menu-driven selection.

## Migration Plan

1. Import/mirror all upstream official theme directories and backgrounds into local committed assets.
2. Update `modules/_themes.nix` with every imported official theme mapping.
3. Place wallpaper files in `config/themes/wallpapers/` and keep references declarative.
4. Run existing generation flow to ensure required per-theme runtime outputs are present.
5. Validate selection and apply behavior through both CLI (`omarchy-theme-set`) and menu (`omarchy-launch-walker -m menus:omarchythemes`).
6. Keep rollback simple by reverting to previous theme asset snapshot if regressions appear.

## Open Questions

- Should upstream sync be implemented as a documented manual workflow or as an automated update command in this repo?
