# ags-system-stats Specification

## Purpose
Defines the AGS bar system stats cluster.

## Requirements
### Requirement: System stats cluster
The right island SHALL display CPU and RAM usage, each as a percentage accompanied by a thin progress bar, plus a temperature readout. Values SHALL be polled on a ~2-second timer: CPU usage from `/proc/stat` jiffy deltas, RAM usage from `/proc/meminfo`, and temperature from `/sys/class/thermal` (best-effort). Each glyph follows the design's colour (CPU green, RAM purple, temperature red).

#### Scenario: CPU and RAM update on poll
- **WHEN** the poll timer fires
- **THEN** the CPU and RAM percentages and their progress bars update to the latest readings

#### Scenario: Progress bars reflect usage
- **WHEN** CPU usage is 23% and RAM usage is 61%
- **THEN** the CPU bar is ~23% filled and the RAM bar is ~61% filled

#### Scenario: Temperature shown when a sensor resolves
- **WHEN** a thermal sensor is readable
- **THEN** the temperature readout shows the current temperature

#### Scenario: Temperature hidden when no sensor
- **WHEN** no thermal sensor resolves
- **THEN** the temperature readout is hidden rather than showing an error or zero
