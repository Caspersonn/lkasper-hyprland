## 1. Custom Scripts

- [x] 1.1 Create `config/waybar/scripts/fan.sh` -- lm-sensors based fan monitoring script outputting waybar JSON
- [x] 1.2 Create `config/waybar/scripts/tmux-brief.sh` -- tmux session listing script outputting waybar JSON with attached class
- [x] 1.3 Create `config/waybar/scripts/weather-brief.sh` -- wttr.in weather script with auto-location default, outputting waybar JSON

## 2. Waybar Config

- [x] 2.1 Update `config/waybar/config.jsonc` -- replace flat `modules-right` with `["group/right-cluster"]` and add `group/right-cluster` block with module order: tray, bluetooth, network, wireplumber, cpu, custom/fan, custom/tmux, custom/weather, battery
- [x] 2.2 Update `config/waybar/config.jsonc` -- remove `power-profiles-daemon` config block
- [x] 2.3 Update `config/waybar/config.jsonc` -- update `cpu` format to `"󰍛 {usage:>2}%"` and add `tooltip-format`
- [x] 2.4 Update `config/waybar/config.jsonc` -- update `bluetooth` on-click to `"ghostty -e bluetuith"`
- [x] 2.5 Update `config/waybar/config.jsonc` -- update `wireplumber` on-click to `"ghostty -e pulsemixer"`
- [x] 2.6 Update `config/waybar/config.jsonc` -- add `custom/fan`, `custom/tmux`, and `custom/weather` module config blocks

## 3. Waybar Styles

- [x] 3.1 Update `config/waybar/style.css` -- add `#group-right-cluster` pill container styling (background, border, border-radius, padding, box-shadow)
- [x] 3.2 Update `config/waybar/style.css` -- add border-left separator rules for `#bluetooth`, `#network`, `#wireplumber`, `#cpu`, `#custom-weather`, `#custom-tmux`
- [x] 3.3 Update `config/waybar/style.css` -- add icon module styling (font-size, min-width) for `#bluetooth`, `#network`, `#wireplumber`
- [x] 3.4 Update `config/waybar/style.css` -- add text module bold styling for `#cpu`, `#custom-weather`, `#custom-tmux`
- [x] 3.5 Update `config/waybar/style.css` -- add `#custom-tmux.attached` color rule
- [x] 3.6 Update `config/waybar/style.css` -- remove `#power-profiles-daemon` from existing style rules

## 4. Nix Module

- [x] 4.1 Update `modules/home-manager/waybar.nix` -- add `home.file` entry for `config/waybar/scripts/` with `executable = true`
- [x] 4.2 Update `modules/home-manager/waybar.nix` -- add `home.packages` for `bluetuith`, `pulsemixer`, `lm_sensors`, `python3`, `curl`, `jq`, `tmux`
