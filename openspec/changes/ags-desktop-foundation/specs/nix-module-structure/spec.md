## ADDED Requirements

### Requirement: AGS home-manager module
A new module `modules/home-manager/ags.nix` SHALL exist that:
- Builds the AGS shell from `ags/` source using `ags bundle`
- Installs the resulting binary
- Adds all required Astal libraries as dependencies: astal4, astal-io, astal-hyprland, astal-mpris, astal-battery, astal-bluetooth, astal-network, astal-wireplumber, astal-tray, astal-notifd
- Adds runtime dependencies to PATH (glib, dart-sass for future theme engine)

#### Scenario: Module builds AGS shell
- **WHEN** home-manager configuration is built
- **THEN** the `lkasper-shell` binary is available in the user's PATH

### Requirement: Flake inputs updated
`flake.nix` SHALL:
- Add `astal` input (`github:aylur/astal`) for Astal libraries
- Add `ags` input (`github:aylur/ags`) for CLI/bundler, with `inputs.astal.follows = "astal"`
- Remove `walker` input
- Remove `elephant` input
- Keep `nix-colors`, `hyprland`, `home-manager`, `nixpkgs`, `flake-parts`, `import-tree`

#### Scenario: Flake lock reflects changes
- **WHEN** `nix flake lock` is run
- **THEN** the lock file includes `astal` and `ags` and does not include `walker` or `elephant`

### Requirement: Remove walker module
`modules/home-manager/walker.nix` SHALL be removed. No module SHALL reference walker or elephant packages.

#### Scenario: Walker module absent
- **WHEN** the modules directory is listed
- **THEN** `walker.nix` does not exist

### Requirement: Remove waybar module
`modules/home-manager/waybar.nix` SHALL be removed. The `config/waybar/` directory MAY be removed or left for reference.

#### Scenario: Waybar module absent
- **WHEN** the modules directory is listed
- **THEN** `waybar.nix` does not exist

### Requirement: Rewrite themes.nix (strip omarchy infra, keep essentials)
`modules/home-manager/themes.nix` SHALL be rewritten in-place to:
- KEEP: `config.omarchy.*` option declarations (via `import ../../config.nix`)
- KEEP: nix-colors home-manager module import + `config.colorScheme` setup
- KEEP: `home.packages` (from `_packages.nix` with exclude filter)
- KEEP: GTK theme configuration (adwaita, cursor, icons)
- KEEP: Per-theme palette files (as JSON instead of TOML, for AGS consumption)
- KEEP: Per-theme wallpaper deployment
- KEEP: Declarative build-time configs for retained apps: hypr/theme.conf, btop theme, ghostty theme, opencode theme, starship.toml
- REMOVE: All `bin/` scripts deployment (`~/.local/share/omarchy/bin/`)
- REMOVE: `omarchy` PATH additions (`home.sessionPath` with omarchy bin)
- REMOVE: waybar runtime.css + waybar.css.tpl template
- REMOVE: wofi runtime.css + wofi.css.tpl template
- REMOVE: mako runtime.conf + mako.conf.tpl template
- REMOVE: walker.css.tpl template
- REMOVE: All `.tpl` template files (runtime theme switching via templates is removed)
- REMOVE: `theme-default` and `theme-list` file generation
- REMOVE: `light.mode` marker files

#### Scenario: themes.nix retains nix-colors
- **WHEN** home-manager configuration is built
- **THEN** `config.colorScheme.palette` is available to all modules

#### Scenario: themes.nix no longer deploys bin scripts
- **WHEN** the deployed home-manager generation is inspected
- **THEN** `~/.local/share/omarchy/bin/` is not populated by themes.nix

#### Scenario: Palette JSON files generated per theme
- **WHEN** home-manager configuration is built
- **THEN** each theme has a `.json` palette file under `~/.local/share/omarchy/themes/<name>/`

### Requirement: Remove wofi module
`modules/home-manager/wofi.nix` SHALL be removed (replaced by AGS launcher in a future phase).

#### Scenario: Wofi module absent
- **WHEN** the modules directory is listed
- **THEN** `wofi.nix` does not exist

### Requirement: Remove mako module
`modules/home-manager/mako.nix` SHALL be removed (replaced by AGS notifications in a future phase).

#### Scenario: Mako module absent
- **WHEN** the modules directory is listed
- **THEN** `mako.nix` does not exist

### Requirement: Clean up envs.nix
`modules/home-manager/_hyprland/envs.nix` SHALL:
- KEEP: All Wayland environment variables (XDG_SESSION_TYPE, QT_QPA_PLATFORM, etc.)
- KEEP: `GDK_SCALE` based on `config.omarchy.scale`
- REMOVE: `OMARCHY_PATH` environment variable
- REMOVE: omarchy bin/ PATH additions

#### Scenario: Wayland env vars preserved
- **WHEN** Hyprland config is generated
- **THEN** standard Wayland env vars are present and `OMARCHY_PATH` is absent

### Requirement: Preserve non-conflicting modules
Modules that do not conflict with the AGS shell SHALL be preserved: `ghostty.nix`, `btop.nix`, `direnv.nix`, `fonts.nix`, `starship.nix`, `zoxide.nix`, `zsh.nix`, `hyprlock.nix`, `hypridle.nix`, `hyprpaper.nix`, `hyprshot.nix`. These modules depend on `config.colorScheme.palette` (via nix-colors) and `config.omarchy.*` options, which remain available through the rewritten `themes.nix`.

#### Scenario: Utility modules remain
- **WHEN** the modules directory is listed
- **THEN** `ghostty.nix`, `btop.nix`, `zsh.nix` (and other utility modules) still exist

### Requirement: Rename omarchy → lkasper-hyprland
All `omarchy` naming SHALL be replaced with `lkasper-hyprland` conventions:
- `config.omarchy.*` → `config.lkasper-hyprland.*`
- `omarchyOptions` in `config.nix` → `lkasperHyprlandOptions`
- `flake.homeManagerModules.omarchy-*` → `flake.homeManagerModules.lkh-*`
- `flake.nixosModules.omarchy-*` → `flake.nixosModules.lkh-*`
- `~/.local/share/omarchy/` → `~/.local/share/lkasper-hyprland/`
- `~/.config/omarchy/` → `~/.config/lkasper-hyprland/`
- `omarchy-runtime` theme names → `lkh-runtime`
- Flake description updated

#### Scenario: No omarchy references remain
- **WHEN** `grep -r "omarchy" modules/ flake.nix config.nix` is run
- **THEN** no matches are found (excluding comments and openspec/)

### Requirement: Module auto-import compatibility
All new and modified modules SHALL follow the flake-parts + import-tree convention: non-prefixed `.nix` files in `modules/` are auto-imported as flake-parts modules. Helper files use `_` prefix.

#### Scenario: New module auto-imports
- **WHEN** `modules/home-manager/ags.nix` is created
- **THEN** it is automatically imported by `import-tree` and contributes to the home-manager configuration
