## ADDED Requirements

### Requirement: Fan monitoring custom module
The `config/waybar/config.jsonc` SHALL define a `custom/fan` module with `return-type: "json"`, `exec` pointing to `$HOME/.config/waybar/scripts/fan.sh`, `interval: 3`, `hide-empty-text: true`, and `tooltip: true`. The format SHALL be `"{text}"`.

#### Scenario: Fan module displays RPM
- **WHEN** `sensors` command detects a fan with non-zero RPM
- **THEN** the fan module displays a fan icon followed by a compact RPM representation (e.g., "3.2k" for 3200 RPM)

#### Scenario: Fan module hides when no fan detected
- **WHEN** `sensors` command finds no fan or fan RPM is 0
- **THEN** the fan module outputs empty text and waybar hides it via `hide-empty-text: true`

### Requirement: Fan script using lm-sensors
A script at `config/waybar/scripts/fan.sh` SHALL use the `sensors` command to read fan speed. The script SHALL output JSON with `text` and `tooltip` fields compatible with waybar's `return-type: json`. The script SHALL output empty JSON text when no fan is detected or sensors is unavailable.

#### Scenario: Script output format with active fan
- **WHEN** `sensors` reports a fan running at 3200 RPM
- **THEN** the script outputs JSON with `text` containing a fan icon and compact RPM (e.g., `"󰈐 3.2k"`), and `tooltip` containing detailed fan information

#### Scenario: Script output when sensors unavailable
- **WHEN** the `sensors` command is not installed or returns no fan data
- **THEN** the script outputs JSON with empty `text` field

### Requirement: Tmux session custom module
The `config/waybar/config.jsonc` SHALL define a `custom/tmux` module with `return-type: "json"`, `exec` pointing to `$HOME/.config/waybar/scripts/tmux-brief.sh`, `interval: 5`, `hide-empty-text: true`, and `tooltip: true`. The format SHALL be `"{text}"`.

#### Scenario: Tmux module shows session count
- **WHEN** tmux has active sessions
- **THEN** the tmux module displays a tmux icon with the session count

#### Scenario: Tmux module hides when no sessions
- **WHEN** tmux has no sessions or tmux is not installed
- **THEN** the tmux module outputs empty text and waybar hides it

### Requirement: Tmux script
A script at `config/waybar/scripts/tmux-brief.sh` SHALL list tmux sessions, count them, and output JSON with `text`, `tooltip`, and `class` fields. The `class` field SHALL be `"attached"` when any session is in attached state. The script SHALL output empty JSON text when tmux is not installed or has no sessions.

#### Scenario: Script with attached sessions
- **WHEN** tmux has 3 sessions, 1 attached
- **THEN** the script outputs JSON with `text` showing session count, `tooltip` listing session names and states, and `class` set to `"attached"`

#### Scenario: Script with no tmux
- **WHEN** tmux is not installed
- **THEN** the script outputs JSON with empty `text` field

### Requirement: Weather custom module
The `config/waybar/config.jsonc` SHALL define a `custom/weather` module with `return-type: "json"`, `exec` pointing to `$HOME/.config/waybar/scripts/weather-brief.sh`, `interval: 900`, `tooltip: true`, and `on-click: "xdg-open https://wttr.in"`. The format SHALL be `"{text}"`.

#### Scenario: Weather module displays conditions
- **WHEN** wttr.in returns weather data
- **THEN** the weather module displays current temperature and condition

#### Scenario: Weather module click opens browser
- **WHEN** user clicks the weather module
- **THEN** the default browser opens wttr.in

### Requirement: Weather script with auto-location
A script at `config/waybar/scripts/weather-brief.sh` SHALL fetch weather from `wttr.in` using curl. The script SHALL default to `auto` location (IP-based geolocation). The `WAYBAR_WEATHER_LOCATION` environment variable SHALL override the default location. The script SHALL output JSON with `text` and `tooltip` fields.

#### Scenario: Default auto-location
- **WHEN** `WAYBAR_WEATHER_LOCATION` is not set
- **THEN** the script fetches weather using IP-based auto-location from wttr.in

#### Scenario: Custom location override
- **WHEN** `WAYBAR_WEATHER_LOCATION` is set to `"Amsterdam"`
- **THEN** the script fetches weather for Amsterdam from wttr.in

#### Scenario: Script handles network failure
- **WHEN** curl fails to reach wttr.in
- **THEN** the script outputs JSON with empty `text` field

### Requirement: Script executability
The `modules/home-manager/waybar.nix` SHALL ensure files in `config/waybar/scripts/` are deployed as executable. This SHALL be achieved via a separate `home.file` entry for the scripts directory with `executable = true`.

#### Scenario: Scripts are executable after deployment
- **WHEN** home-manager activates the waybar module
- **THEN** all files in `~/.config/waybar/scripts/` have executable permissions

### Requirement: Custom module package dependencies
The `modules/home-manager/waybar.nix` SHALL include `lm_sensors`, `python3`, `curl`, `jq`, and `tmux` in `home.packages` to support the custom module scripts.

#### Scenario: Script dependencies available
- **WHEN** the home-manager configuration is activated
- **THEN** `sensors`, `python3`, `curl`, `jq`, and `tmux` commands are available in PATH

### Requirement: Tmux attached CSS class
The `config/waybar/style.css` SHALL style `#custom-tmux.attached` with `color: alpha(@foreground, 0.96)` to visually distinguish when a tmux session is attached.

#### Scenario: Attached tmux highlighted
- **WHEN** the tmux module has CSS class `attached`
- **THEN** the module text color is `alpha(@foreground, 0.96)`
