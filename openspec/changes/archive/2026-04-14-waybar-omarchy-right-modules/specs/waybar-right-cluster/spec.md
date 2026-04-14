## ADDED Requirements

### Requirement: Right-cluster group wrapper
The `config/waybar/config.jsonc` SHALL define `modules-right` as `["group/right-cluster"]`. The `group/right-cluster` object SHALL contain an `orientation` of `"inherit"` and a `modules` array with the following order: tray, bluetooth, network, wireplumber, cpu, custom/fan, custom/tmux, custom/weather, battery.

#### Scenario: Modules-right uses group wrapper
- **WHEN** waybar loads `config/waybar/config.jsonc`
- **THEN** `modules-right` contains exactly one entry: `"group/right-cluster"`
- **THEN** `group/right-cluster.modules` lists tray, bluetooth, network, wireplumber, cpu, custom/fan, custom/tmux, custom/weather, battery in that order

### Requirement: Pill-shaped container styling
The `config/waybar/style.css` SHALL style `#group-right-cluster` with a semi-transparent background using `alpha(@background, 0.78)`, a border of `1px solid alpha(@foreground, 0.12)`, a `border-radius` of `11px`, and an inset box-shadow of `inset 0 1px 0 alpha(@foreground, 0.04)`.

#### Scenario: Right cluster renders as pill shape
- **WHEN** waybar renders the right-cluster group
- **THEN** the container has rounded corners (`border-radius: 11px`), a semi-transparent background, and a subtle border using theme colors from `@background` and `@foreground`

### Requirement: CSS border-left separators
The `config/waybar/style.css` SHALL apply `border-left: 1px solid alpha(@foreground, 0.08)`, `padding-left: 7px`, and `margin-left: 5px` to the following modules: `#bluetooth`, `#network`, `#wireplumber`, `#cpu`, `#custom-weather`, `#custom-tmux`. The `#tray`, `#custom-fan`, and `#battery` modules SHALL NOT have `border-left` separators.

#### Scenario: Separator between bluetooth and tray
- **WHEN** waybar renders the right-cluster modules
- **THEN** `#bluetooth` has a `border-left` of `1px solid alpha(@foreground, 0.08)` creating a visual pipe separator after `#tray`

#### Scenario: No separator before tray
- **WHEN** waybar renders the right-cluster modules
- **THEN** `#tray` does not have a `border-left` property

#### Scenario: Fan module blends with CPU
- **WHEN** waybar renders the right-cluster modules
- **THEN** `#custom-fan` does not have a `border-left` property, visually grouping it with `#cpu`

### Requirement: Power-profiles-daemon removed
The `config/waybar/config.jsonc` SHALL NOT include `power-profiles-daemon` in any module list. The `power-profiles-daemon` configuration block SHALL be removed. The `config/waybar/style.css` SHALL NOT reference `#power-profiles-daemon`.

#### Scenario: Power-profiles-daemon absent from config
- **WHEN** waybar loads `config/waybar/config.jsonc`
- **THEN** no module named `power-profiles-daemon` exists in any module array or as a configuration block

### Requirement: CPU module shows usage percentage
The `cpu` module in `config/waybar/config.jsonc` SHALL use `format` value `"󰍛 {usage:>2}%"` and include a `tooltip-format` of `"CPU {usage}%\nLoad {load}\nAvg {avg_frequency} GHz"`.

#### Scenario: CPU displays usage percentage
- **WHEN** waybar renders the cpu module
- **THEN** the displayed text shows the CPU icon followed by usage percentage (e.g., "󰍛 42%")

### Requirement: TUI click handlers for bluetooth and wireplumber
The `bluetooth` module in `config/waybar/config.jsonc` SHALL use `on-click` value `"ghostty -e bluetuith"`. The `wireplumber` module SHALL use `on-click` value `"ghostty -e pulsemixer"`.

#### Scenario: Bluetooth click opens TUI
- **WHEN** user clicks the bluetooth module
- **THEN** ghostty terminal launches with bluetuith

#### Scenario: Wireplumber click opens TUI
- **WHEN** user clicks the wireplumber module
- **THEN** ghostty terminal launches with pulsemixer

### Requirement: Icon-sized and text-based module styling
The `config/waybar/style.css` SHALL apply `font-size: 13px`, `min-width: 14px`, and `padding-right: 2px` to `#bluetooth`, `#network`, `#wireplumber`. It SHALL apply `font-weight: 700` to `#cpu`, `#custom-weather`, `#custom-tmux`.

#### Scenario: Icon modules have increased font size
- **WHEN** waybar renders bluetooth, network, and wireplumber modules
- **THEN** these modules display at 13px font size with a minimum width of 14px

#### Scenario: Text modules are bold
- **WHEN** waybar renders cpu, custom-weather, and custom-tmux modules
- **THEN** these modules display with font-weight 700

### Requirement: Package dependencies for right-cluster
The `modules/home-manager/waybar.nix` SHALL include `bluetuith` and `pulsemixer` in `home.packages`.

#### Scenario: TUI packages available
- **WHEN** the home-manager configuration is activated
- **THEN** `bluetuith` and `pulsemixer` are installed and available in PATH
