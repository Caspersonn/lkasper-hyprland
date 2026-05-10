## Context

The project currently derives themed application configuration from `config.colorScheme` during home-manager evaluation, so changing `omarchy.theme` requires a rebuild/switch cycle. The proposal introduces two capabilities: an Omarchy-style launcher menu and runtime theme switching without rebuild. The design must preserve flake/module conventions (`flake-parts`, `import-tree`, `omarchy.*` option ownership) while adding a runtime state path that scripts can mutate safely.

## Goals / Non-Goals

**Goals:**
- Provide a custom launcher command reachable from Hyprland keybinds, with direct entrypoints for Theme and related style actions.
- Enable runtime switching between supported non-generated themes by writing active state under `~/.config/omarchy/current/`.
- Apply selected theme immediately through controlled reload/restart hooks for themed applications.
- Keep declarative `omarchy.theme` as bootstrap/default behavior so first install and non-runtime paths remain predictable.

**Non-Goals:**
- Full Omarchy feature parity in one pass (package install/remove/update menus, all utility menus).
- Runtime support for `generated_light` and `generated_dark` palette extraction.
- Replacing current module structure or moving option declarations out of existing `omarchy.*` owners.

## Decisions

- **Decision: Introduce a runtime theme state directory and script API.**
  Use `~/.config/omarchy/current/theme.name` plus a theme payload directory (`~/.config/omarchy/current/theme/`) as the source of truth for active runtime theme. Add project scripts in `bin/` for `omarchy-menu`, `omarchy-theme-list`, `omarchy-theme-current`, and `omarchy-theme-set`.
  - Rationale: mirrors proven Omarchy behavior and decouples user interaction from Nix evaluation.
  - Alternative considered: keep switching declarative-only (`omarchy.theme` + rebuild). Rejected because it does not solve latency/usability goals.

- **Decision: Start with a wofi-backed menu frontend and Omarchy-compatible command shape.**
  Implement launcher menus using existing wofi integration, preserving command entrypoints so walker/elephant can be swapped in later without changing keybind contracts.
  - Rationale: minimal dependency churn and fastest path to usable feature.
  - Alternative considered: adopt walker+elephant immediately. Rejected for MVP due to higher integration surface.

- **Decision: Add Hyprland keybinds for custom menu entrypoints in `_hyprland/bindings.nix`.**
  Bind `SUPER ALT, SPACE` to `omarchy-menu` and add direct theme entrypoint (`omarchy-menu theme`) with a dedicated chord.
  - Rationale: preserves current workflow while introducing Omarchy-like access pattern.
  - Alternative considered: replace existing launcher bind entirely. Rejected to avoid regressing app launcher discoverability during transition.

- **Decision: Scope runtime theming to components that can be safely reloaded/restarted from user session scripts.**
  Initial apply hooks target waybar, mako, and Hyprland-adjacent UI config refreshes; additional app integrations can be layered later.
  - Rationale: controlled blast radius and clearer rollback.
  - Alternative considered: broad restarts for all themed apps at once. Rejected for higher disruption and harder debugging.

- **Decision: Treat runtime themes as curated fixed palettes first.**
  Runtime switching supports known static themes from `_themes.nix`; generated wallpaper-derived themes remain declarative until a runtime palette generation path is designed.
  - Rationale: avoids introducing a second, partial color-generation implementation prematurely.
  - Alternative considered: reimplement generated palette extraction in shell tooling. Rejected for complexity and consistency risk.

## Risks / Trade-offs

- [Runtime state drift from declarative config] -> On session start, initialize runtime state from `omarchy.theme` if missing and document precedence rules.
- [Partial reload leaves mixed theme state] -> Use deterministic apply order and explicit process reload/restart list; fail fast when a step errors.
- [Divergence from Omarchy UX expectations] -> Keep command naming and keybind entrypoints Omarchy-aligned so later parity changes are incremental.
- [Increased script maintenance burden] -> Keep script surface small and centralize shared helpers under existing project bin conventions.

## Migration Plan

1. Add runtime scripts and HM packaging so commands are available in the user session.
2. Add Hyprland keybind wiring for menu and theme entrypoint.
3. Implement runtime theme state initialization and `omarchy-theme-set` apply flow for fixed themes.
4. Wire targeted reload/restart hooks and validate no rebuild is needed for theme flips.
5. Keep declarative fallback: if runtime state is absent or invalid, default to `omarchy.theme` behavior.

Rollback strategy: remove new keybinds/scripts and rely on existing declarative theming path; no system-level migration is required.

## Open Questions

- Should `SUPER, SPACE` remain pure app launcher while `SUPER ALT, SPACE` is menu, or should both route through the custom launcher with an Apps submenu?
- Which additional apps beyond waybar/mako/hyprland should be included in first-pass runtime apply hooks in this repo?
- Do we want compatibility aliases for Omarchy command names beyond the MVP set to ease user transition?
