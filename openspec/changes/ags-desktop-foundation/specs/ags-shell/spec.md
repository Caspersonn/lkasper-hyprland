## ADDED Requirements

### Requirement: AGS project structure
The AGS v2 project SHALL reside at `ags/` in the repository root with the following structure:
- `ags/app.ts` — application entry point calling `app.start()`
- `ags/tsconfig.json` — TypeScript configuration
- `ags/env.d.ts` — type declarations for CSS/SCSS imports
- `ags/style.scss` — root SCSS stylesheet
- `ags/windows/` — window components (bar, future: launcher, notifications, osd)
- `ags/lib/` — shared utilities

#### Scenario: Project directory exists with entry point
- **WHEN** the repository is cloned
- **THEN** `ags/app.ts` exists and exports a valid AGS v2 GTK4 application entry point using `import { App } from "ags/gtk4/app"`

### Requirement: GTK4 application entry
The entry point `ags/app.ts` SHALL initialize a GTK4 application via `app.start()` with:
- A `css` property importing the compiled SCSS stylesheet
- A `main()` function that creates the Bar window

#### Scenario: Application starts successfully
- **WHEN** the bundled AGS binary is executed
- **THEN** a GTK4 application instance is created and the bar window is displayed

### Requirement: SCSS stylesheet pipeline
The root stylesheet `ags/style.scss` SHALL be imported natively by AGS (which supports SCSS imports). It SHALL define color variables as SCSS variables using Catppuccin Mocha values as defaults.

#### Scenario: SCSS compiles and applies
- **WHEN** AGS bundles the application
- **THEN** `style.scss` is compiled to CSS and applied to all windows

### Requirement: Nix build via ags bundle
The AGS project SHALL be built as a Nix derivation using `ags bundle ags/app.ts $out/bin/lkasper-shell`. The derivation SHALL include:
- `wrapGAppsHook3` for GObject introspection
- All required Astal libraries in `buildInputs`
- Runtime PATH dependencies in `gappsWrapperArgs`

#### Scenario: Nix build produces executable
- **WHEN** `nix build` is run
- **THEN** a standalone executable `lkasper-shell` is produced that starts the AGS shell

### Requirement: Flake inputs for AGS and Astal
The `flake.nix` SHALL add two inputs: `astal` pointing to `github:aylur/astal` (libraries) and `ags` pointing to `github:aylur/ags` (CLI/bundler, with `inputs.astal.follows = "astal"`). The `walker` and `elephant` inputs SHALL be removed.

#### Scenario: Flake inputs updated
- **WHEN** `flake.nix` is read
- **THEN** `inputs.astal` and `inputs.ags` exist, `ags` follows astal, and `inputs.walker` and `inputs.elephant` do not exist
