# wallpaper-palette-generation Specification (delta)

## MODIFIED Requirements

### Requirement: Base16 palette per wallpaper

The system SHALL derive a complete base16 palette (base00 through base0F) from each wallpaper image in the curated wallpaper set, using a base16-native generator (wallust). Every wallpaper image SHALL be a member of exactly one light/dark pair, and the palette flavour SHALL be selected by the member's role in its pair.

#### Scenario: Generate palettes for the wallpaper set
- **WHEN** the palette generation command is run over the wallpaper set
- **THEN** a base16 palette file (base00–base0F) is produced for every pair member in the set

#### Scenario: Palette flavour follows the pair role
- **WHEN** a palette is generated for a pair's dark member
- **THEN** the palette has dark polarity (base00 darker than base05)
- **AND WHEN** a palette is generated for a pair's light member
- **THEN** the palette has light polarity (base00 lighter than base05)

#### Scenario: New pair added
- **WHEN** a new light/dark image pair is added to the wallpaper set and declared in the pair registry, and the generation command is run
- **THEN** a palette file for each member is produced and ready to commit

## ADDED Requirements

### Requirement: Pair registry and completeness

The wallpaper set SHALL be declared as a registry of named pairs, each naming exactly one light image and one dark image. Evaluation SHALL fail when an image in the wallpaper directory is not a member of exactly one pair.

#### Scenario: Unpaired image rejected
- **WHEN** an image is present in the wallpaper directory but named by no pair
- **THEN** evaluation fails with an error identifying the unpaired image

#### Scenario: Image claimed twice rejected
- **WHEN** an image is named by more than one pair, or by both roles of one pair
- **THEN** evaluation fails with an error identifying the conflict

#### Scenario: Registry drives the available themes
- **WHEN** the configuration is evaluated
- **THEN** exactly one theme bundle exists per (pair, mode) combination in the registry, and none for images outside it

### Requirement: ANSI-faithful hues in both modes

Palettes SHALL preserve base16 ANSI slot semantics in both light and dark mode, so that base08 is red-family, base0A yellow-family, base0B green-family, base0C cyan-family, base0D blue-family and base0E magenta-family.

#### Scenario: Light palette keeps ANSI semantics
- **WHEN** a light palette is generated
- **THEN** each of base08, base0A, base0B, base0C, base0D and base0E lies within 45 degrees of its canonical ANSI hue

#### Scenario: Terminal colours stay trustworthy
- **WHEN** the desktop is in light mode and a terminal renders a diff
- **THEN** additions appear green-family and deletions appear red-family

### Requirement: Mode-aware contrast clamping

Generated colours that are used as foreground on the palette background SHALL meet a minimum contrast ratio of 4.5:1 against base00. The clamp SHALL brighten in dark mode and darken in light mode, and SHALL preserve hue.

#### Scenario: Light-mode accent darkened
- **WHEN** a light palette's extracted accent has less than 4.5:1 contrast against base00
- **THEN** the accent is darkened until it reaches at least 4.5:1, keeping its hue

#### Scenario: Dark-mode accent brightened
- **WHEN** a dark palette's extracted accent is too dark to read on base00
- **THEN** the accent is brightened to the dark-mode floor, keeping its hue

#### Scenario: Already-legible colour untouched
- **WHEN** an extracted colour already meets the contrast target for its mode
- **THEN** it is written through unchanged

### Requirement: Distinct surface ramp

Every palette SHALL provide visually distinct values for base00, base01 and base02, so that surfaces layered on the background remain separable. Where the generator collapses these slots, the system SHALL derive them from base00 stepped toward base05.

#### Scenario: Light palette surfaces separated
- **WHEN** a light palette is generated and the generator returns base01 equal to base00
- **THEN** base01 and base02 are derived as distinct steps between base00 and base05

#### Scenario: Surfaces usable by the shell
- **WHEN** any committed palette is inspected
- **THEN** base00, base01 and base02 are three different colour values

### Requirement: Palette declares its mode

Each palette file SHALL record the mode it was generated for, so that consumers can adapt polarity-dependent behaviour without inspecting file paths.

#### Scenario: Consumer reads the mode
- **WHEN** a consumer loads a palette file
- **THEN** the file states whether it is a light or dark palette
