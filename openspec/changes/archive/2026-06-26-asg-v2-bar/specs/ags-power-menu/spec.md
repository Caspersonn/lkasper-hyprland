## ADDED Requirements

### Requirement: Power menu popover
A power button in the right island SHALL open a power-menu `Gtk.Popover` listing rows, each with a coloured glyph: Lock, Suspend, Log out, Reboot, and Shut down. Selecting a row SHALL run the corresponding command and the popover SHALL auto-dismiss on outside click.

#### Scenario: Lock
- **WHEN** the user selects Lock
- **THEN** `hyprlock` is run

#### Scenario: Log out
- **WHEN** the user selects Log out
- **THEN** `hyprctl dispatch exit` is run

#### Scenario: Suspend
- **WHEN** the user selects Suspend
- **THEN** `systemctl suspend` is run

#### Scenario: Reboot
- **WHEN** the user selects Reboot
- **THEN** `systemctl reboot` is run

#### Scenario: Shut down
- **WHEN** the user selects Shut down
- **THEN** `systemctl poweroff` is run
