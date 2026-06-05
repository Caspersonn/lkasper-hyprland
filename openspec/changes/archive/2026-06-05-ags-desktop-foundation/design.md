## Context

The current desktop is built on omarchy, a framework that provides themed Hyprland configuration via NixOS/home-manager modules. It uses bash scripts for orchestration, sed-based mustache templates for theme rendering, and walker/elephant as the application launcher. The codebase is a Nix flake using flake-parts + import-tree, with modules auto-imported from `modules/`.

We are replacing the entire omarchy stack with a custom AGS v2 shell. This is Phase 1: setting up the AGS project, building the status bar, configuring Hyprland directly, and establishing the Nix module structure. Theme engine, launcher, notifications, OSD, and other components are deferred to later phases.

All development happens on the `feature/ags` branch (big-bang approach). Main branch remains untouched as a working fallback.

Current module structure:
- `modules/meta.nix` — declares `flake.homeManagerModules` option, sets formatter
- `modules/home-manager/*.nix` — individual HM modules (waybar, walker, themes, hyprland, etc.)
- `modules/home-manager/_hyprland/` — hyprland sub-modules (keybinds, autostart, etc.)
- `modules/nixos/` — system.nix (packages, options), hyprland.nix (NixOS-level hyprland)
- `modules/_themes.nix`, `modules/_packages.nix` — helper attrsets (prefixed with `_`, excluded from auto-import)
- `config/` — static config files copied by Nix modules

## Goals / Non-Goals

**Goals:**
- Establish a clean AGS v2 (GTK4, TypeScript) project that builds via Nix and runs as the desktop shell
- Build a floating top bar with all required modules using Astal libraries
- Configure Hyprland directly in Nix without omarchy wrapper scripts
- Maintain the flake-parts + import-tree module structure
- Single hardcoded theme for now (Catppuccin Mocha) to get a working bar; theme engine comes in Phase 2

**Non-Goals:**
- Runtime theme switching (Phase 2: ags-theme-engine)
- Quick-settings popup panel (Phase 3: ags-quick-settings)
- Spotlight launcher (Phase 4: ags-launcher)
- Notification center (Phase 5: ags-notifications)
- OSD, hyprlock, hypridle, screenshots, clipboard (Phase 6: ags-osd-peripherals)
- Removing all omarchy code — only remove what conflicts; full cleanup is a separate effort

## Decisions

### AGS v2 with GTK4 over GTK3
GTK4 is the actively developed version with better animation support and performance. AGS v2 documentation focuses on GTK4. GTK3 has more community examples but is being deprecated. Chosen: GTK4.

Alternative considered: GTK3 — more proven with AGS but aging. Not worth investing in.

### Standalone AGS binary via `ags bundle` over config-dir approach
AGS supports two modes: `configDir` (interprets TS at runtime) and `ags bundle` (compiles to standalone GJS binary). We use `ags bundle` for a self-contained, reproducible Nix package.

Alternative considered: `programs.ags.configDir` — simpler setup but harder to reproduce and slower startup.

### AGS project lives at `ags/` in the repo root
The AGS TypeScript source code will be at `ags/` (sibling to `config/`, `modules/`). Nix builds it into a derivation. This keeps the TS project cleanly separated from Nix modules.

Alternative considered: Inside `config/ags/` — but this isn't static config, it's a compiled project.

### Flake inputs for AGS and Astal
Add two flake inputs: `astal` (`github:aylur/astal`) for Astal libraries, and `ags` (`github:aylur/ags`, with `inputs.astal.follows = "astal"`) for the CLI/bundler. Remove `walker` and `elephant` inputs.

### Rename omarchy → lkasper-hyprland
All omarchy naming is replaced. Nix option namespace becomes `config.lkasper-hyprland.*`. Flake module names use `lkh-` prefix (short for lkasper-hyprland) to keep them concise (e.g. `lkh-themes`, `lkh-hyprland`). Runtime paths change from `~/.local/share/omarchy/` to `~/.local/share/lkasper-hyprland/`. Theme file names use `lkh-runtime` instead of `omarchy-runtime`. This rename is done as part of the themes.nix rewrite and module cleanup — not as a separate pass.

### Keep flake-parts + import-tree structure
The existing module auto-import pattern works well. New modules follow the same convention. Replace contents of existing modules rather than restructuring the module system.

### Hyprland config: keep split module approach
Keep `modules/home-manager/hyprland.nix` as the main HM module and `modules/home-manager/_hyprland/` for sub-configuration (keybinds, rules, autostart). Remove omarchy-menu references from keybinds, replace with direct app launch binds.

### Bar layout: Split pills with CenterBox positioning
The bar uses Astal.Window anchored to top. Inside, a `<centerbox>` positions three separate pill containers:
- Left pill (start): Workspace dots (astal-hyprland)
- Center pill (center): Clock "Mon HH:mm" + Media (astal-mpris, shown when playing)
- Right pill (end): Tray, BT, WiFi, Volume, CPU, Notification bell, Battery

Each pill is a separate `<box>` with capsule styling (fully rounded border-radius). This gives visual separation between the three groups. Inspired by Marble Shell's clean, GNOME-like aesthetic.

Alternative considered: Single pill with all modules — the omarchy/waybar approach. Split pills provide better visual hierarchy and are more in line with the minimal Marble Shell aesthetic.

### Pill styling: solid opaque capsules
Pills use solid opaque background (theme background color). No transparency, no blur effects. Fully rounded capsule shape (border-radius = height / 2). No visible border.

Alternative considered: Semi-transparent with blur — more common in the ricing community, but requires Hyprland blur layerrules and adds visual complexity. Solid opaque is cleaner and more consistent across compositors.

### Workspace indicators: dots
Workspaces are represented as small circles (dots):
- Active: filled circle (solid)
- Occupied (has windows): outline circle (hollow)
- Empty: hidden (not rendered)

Alternative considered: Numbers with highlight pill (Marble Shell style), horizontal bars/lines. Dots are the most minimal option and align with the clean aesthetic.

### Media position: center pill alongside clock
Media info (artist - title) appears in the center pill next to the clock when media is playing. When no media is playing, the center pill only contains the clock.

Alternative considered: Separate 4th pill for media, or placing media in the right pill. Center pill keeps the most dynamic/attention-worthy content centralized.

### Single flake source for all Astal libraries
All Astal library packages must come from `inputs.ags.packages`, NOT a separate `astal` flake input. The AGS flake re-exports all Astal packages built against its own nixpkgs. Using a separate `astal` flake input causes GI typelib conflicts because the two flakes pin different nixpkgs revisions (glib-2.84.4 vs glib-2.86.3, gtk4-4.18.6 vs gtk4-4.20.3), and `wrapGAppsHook` merges all typelib paths, causing GJS to abort on duplicate type registration.

Alternative considered: Using `follows` to force the astal flake to use the same nixpkgs — less reliable because the ags flake already handles this internally by re-exporting packages.

### Gnim JSX uses `class` and `<For>` for list rendering
Gnim's JSX runtime supports `class` (not `className` or `cssClasses`) and expects list rendering via `<For>`. Returning arrays or JSX from Accessors results in Accessor stringification in the UI. All bar components use `class` strings, and workspaces/tray use `<For>` with Accessors to render child widgets.

Alternative considered: `className`/`cssClasses` props — not supported by the Gnim JSX runtime; leads to runtime errors (`No property className`).

### Scroll handling via Gtk.EventControllerScroll
Gtk.Box does not emit a `scroll` signal. Scroll interactions must be handled using `Gtk.EventControllerScroll` attached as a child to the widget. The volume module uses an event controller to adjust speaker volume on scroll.

Alternative considered: `onScroll` on Gtk.Box — invalid signal; causes runtime crash and prevents the bar from rendering.

### No wrapGAppsHook — manual wrapper only
`wrapGAppsHook4` from `pkgs` injects its own gtk4/glib closure (system nixpkgs) into `GI_TYPELIB_PATH`. Even when the AGS flake's libraries are the same glib version, different Nix store paths produce duplicate `Gio-2.0.typelib` files, causing GJS to abort on `"cannot register existing type"`. The derivation uses `pkgs.makeWrapper` and manually sets `GI_TYPELIB_PATH` to only Astal library typelib dirs (via `lib.makeSearchPath`). GJS (from the AGS flake) finds base typelibs (Gio, Gtk, GLib) through its compiled-in search paths.

Alternative considered: wrapGAppsHook4 with `dontWrapGApps` + manual postFixup — still complex because `gappsWrapperArgs` would contain the conflicting paths. Cleanest to avoid the hook entirely.

### Ghostty runtime config-file removed
The `config-file` setting pointing to `~/.config/lkasper-hyprland/current/theme/ghostty.conf` was removed. This directory was populated by the omarchy-theme-set runtime script which no longer exists. Ghostty's theme colors are already provided at build time via the `lkh-runtime` theme file generated by themes.nix. Runtime theme switching for ghostty will be handled by AGS in Phase 2.

Alternative considered: Creating the directory and populating it at build time — unnecessary duplication since themes.nix already generates `~/.config/ghostty/themes/lkh-runtime`.

### Wallpaper path must point to existing file
`lib/selected-wallpaper.nix` must reference an actual wallpaper from `config/themes/wallpapers/<theme>/`. For Phase 1 with Catppuccin Mocha, this is `~/Pictures/Wallpapers/catppuccin/1-totoro.png`. The previous path (`1-Pawel-Czerwinski-Abstract-Purple-Blue.jpg`) was a stale reference to a file that no longer exists in the wallpaper directory.

### SCSS for styling, single hardcoded theme
Import a `.scss` file at build time. Colors are SCSS variables set to Catppuccin Mocha values. In Phase 2 these become dynamic via runtime CSS application (`app.apply_css()`).

### Notification bell is a placeholder
The bar will show a bell icon with a static counter. It will become functional when astal-notifd is integrated in Phase 5. For now it serves as a visual placeholder to establish the layout.

### themes.nix: rewrite in-place, not remove
`themes.nix` is the central hub of the codebase. It declares `config.omarchy.*` options, sets up `config.colorScheme` (nix-colors), deploys bin/ scripts, generates runtime configs for all apps, and manages GTK theming. Removing it breaks 7+ downstream modules.

Strategy: strip themes.nix of omarchy-specific infrastructure (bin/ deployment, template generation, waybar/wofi/mako runtime files) while keeping the essentials (nix-colors, config.omarchy options, packages, GTK theme, declarative configs for retained apps). This preserves the dependency chain for modules we keep (ghostty, btop, hyprlock, looknfeel, starship).

Alternative considered: split into smaller modules (options.nix, colors.nix, gtk.nix) — cleaner but more work and more risk of breaking the import-tree convention. Deferred.

### envs.nix: clean up omarchy-specific env vars
`envs.nix` contains essential Wayland environment variables alongside omarchy-specific ones (OMARCHY_PATH, omarchy bin/ PATH). Strip the omarchy-specific parts, keep the Wayland essentials.

### No runtime theme switching in Phase 1
The omarchy bash scripts for runtime theme switching are removed. The AGS theme engine is Phase 2. During Phase 1, all colors are hardcoded to Catppuccin Mocha at Nix build time. External apps (ghostty, btop, hyprland borders) get their colors from the declarative configs generated by the rewritten themes.nix.

## Risks / Trade-offs

**[Risk] AGS GTK4 + Astal library compatibility** — Some Astal libraries may have GTK4-specific issues since many community configs use GTK3. → Mitigation: Test each Astal library individually during bar module implementation. Fall back to subprocess/polling if a library is incompatible. **Update**: This risk materialized via GI typelib conflicts — resolved by removing separate `astal` flake input and using `inputs.ags.packages` for all Astal libs (consistent nixpkgs revision).

**[Risk] ags bundle reproducibility in Nix** — The `ags bundle` command needs GJS and all Astal typelibs available at build time. → Mitigation: Follow the official Nix flake template closely. Use `extraPackages` for all Astal libs.

**[Risk] Partial migration breaks existing desktop** — Removing waybar before AGS bar works leaves no status bar. → Mitigation: Work on a separate branch. Keep waybar module until AGS bar is verified working. Use Hyprland exec-once to launch AGS alongside or instead of waybar during development.

**[Trade-off] Hardcoded theme in Phase 1** — Bar will only look correct with Catppuccin Mocha until the theme engine is built. No runtime theme switching until Phase 2. → Acceptable: getting the bar working is the priority.

**[Risk] themes.nix rewrite complexity** — themes.nix is ~530 lines and touches everything. Stripping it requires understanding which generated files are still consumed. → Mitigation: systematic approach — identify all `home.file` entries and remove only those for apps we're replacing (waybar, wofi, mako, walker). Keep all entries for retained apps.

**[Risk] config.omarchy option removal cascade** — If any option referenced by a retained module is accidentally removed, nix build fails. → Mitigation: keep `config.nix` and all option declarations intact. Only remove omarchy-specific infrastructure, not the option namespace.
