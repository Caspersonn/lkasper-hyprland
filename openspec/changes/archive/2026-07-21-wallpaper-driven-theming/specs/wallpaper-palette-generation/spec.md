## ADDED Requirements

### Requirement: Base16 palette per wallpaper

The system SHALL derive a complete base16 palette (base00 through base0F) from each wallpaper image in the curated wallpaper set, using a base16-native generator (wallust).

#### Scenario: Generate palettes for the wallpaper set
- **WHEN** the palette generation command is run over the wallpaper set
- **THEN** a base16 palette file (base00–base0F) is produced for every wallpaper in the set

#### Scenario: New wallpaper added
- **WHEN** a new image is added to the wallpaper set and the generation command is run
- **THEN** a palette file for that wallpaper is produced and ready to commit

### Requirement: Committed and reproducible palettes

Generated palettes SHALL be committed to the repository and consumed by Nix directly, without Import-From-Derivation and without invoking the generator during Nix evaluation or build.

#### Scenario: Nix consumes committed palettes
- **WHEN** the configuration is evaluated or built
- **THEN** it reads the committed palette files and does not invoke the generator

#### Scenario: Deterministic output
- **WHEN** the same wallpaper is regenerated with the same generator version and settings
- **THEN** the resulting palette is identical

### Requirement: Repeatable generation command

The system SHALL provide a single command that (re)generates palettes for all wallpapers in the set.

#### Scenario: Regenerate all
- **WHEN** the user runs the regeneration command
- **THEN** palette files for all wallpapers are written, overwriting stale ones, leaving them staged for commit
