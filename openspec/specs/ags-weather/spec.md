# ags-weather Specification

## Purpose
Defines the AGS bar weather widget and weather popover.

## Requirements
### Requirement: Weather widget
The right island SHALL display a weather glyph, the current temperature, and the city name. Data SHALL be fetched over HTTP from a provider that resolves location by IP geolocation, refreshed every 15 minutes. On a failed fetch the widget SHALL render the last successful values rather than clearing or erroring. Weather conditions SHALL map to Nerd Font glyphs.

#### Scenario: Shows current conditions
- **WHEN** a weather fetch succeeds
- **THEN** the widget shows the condition glyph, current temperature, and city

#### Scenario: Refreshes on schedule
- **WHEN** 15 minutes elapse since the last fetch
- **THEN** the widget refetches and updates its values

#### Scenario: Stale data on failure
- **GIVEN** a previous fetch succeeded
- **WHEN** a subsequent fetch fails
- **THEN** the widget keeps showing the last successful values

### Requirement: Weather popover
The weather popover SHALL show the city and condition, a large condition icon with the current temperature, stat tiles for feels-like, humidity, and wind, and an hourly forecast row covering the next several hours (each with an icon and temperature). The popover SHALL auto-dismiss on outside click.

#### Scenario: Current detail
- **WHEN** the weather popover opens
- **THEN** it shows the city, condition, large temperature, and the feels-like, humidity, and wind tiles

#### Scenario: Hourly forecast
- **WHEN** the weather popover opens
- **THEN** it shows a row of upcoming hours, each with a condition icon and temperature
