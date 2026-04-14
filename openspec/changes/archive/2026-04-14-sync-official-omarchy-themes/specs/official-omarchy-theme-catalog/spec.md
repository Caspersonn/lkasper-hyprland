## ADDED Requirements

### Requirement: Official Omarchy Theme Catalog Parity
The repository SHALL include every official theme directory published under upstream Omarchy `dev/themes`, SHALL declare each supported theme in `modules/_themes.nix`, and SHALL expose those themes to the existing local selection and apply flows without requiring interface changes to `homeManagerModules.omarchy-hyprland`.

#### Scenario: Upstream theme directories are mirrored locally
- **GIVEN** upstream Omarchy `dev/themes` defines a set of official theme directories
- **WHEN** this change is applied in the repository theme assets
- **THEN** each upstream official theme directory is present in the local theme source used by `bin/omarchy-theme-set`

#### Scenario: Declarative theme map includes imported themes
- **GIVEN** official themes have been imported from upstream
- **WHEN** the repository theme registry is evaluated
- **THEN** `modules/_themes.nix` includes an entry for each supported imported theme

### Requirement: Official Background Assets Are Included
For each imported official theme, the repository SHALL include that theme's bundled background assets in local committed files under `config/themes/wallpapers/` so that local theme application can rotate/apply official backgrounds without network access.

#### Scenario: Theme backgrounds are available after theme apply
- **GIVEN** a selected official theme contains bundled backgrounds upstream
- **WHEN** the user applies that theme through `omarchy-theme-set` or menu-driven theme selection
- **THEN** the local active theme directory `~/.config/omarchy/current/theme` contains backgrounds required by `omarchy-theme-bg-next`

#### Scenario: Wallpapers are managed declaratively
- **GIVEN** the repository includes official wallpaper assets
- **WHEN** Nix-managed configuration is evaluated/applied
- **THEN** wallpaper source files are read from `config/themes/wallpapers/` and no runtime download from upstream is required

### Requirement: Generated Runtime Assets Stay Compatible
Imported official themes SHALL remain compatible with the current runtime generation/apply pipeline, including template-generated files and runtime CSS consumption paths used by Waybar and other themed components.

### Requirement: No Dynamic Theme Source Fetching
Theme and wallpaper assets SHALL be vendored in this repository and SHALL NOT be dynamically imported from upstream repositories at runtime.

#### Scenario: Theme apply works offline
- **GIVEN** the system has no network connectivity
- **WHEN** the user switches to any imported official theme
- **THEN** theme and wallpaper assets resolve from local repository-managed files and apply successfully

#### Scenario: Runtime theme assets resolve through existing paths
- **GIVEN** an imported official theme is selected
- **WHEN** `bin/omarchy-theme-set` runs its generation and restart sequence
- **THEN** runtime theme artifacts are generated and copied to existing expected paths (including `~/.config/waybar/runtime.css`) without requiring new user-facing options
