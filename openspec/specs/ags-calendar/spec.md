# ags-calendar Specification

## Purpose
Defines the calendar popover opened from the AGS bar clock.

## Requirements
### Requirement: Calendar popover
The center-island clock button SHALL open a calendar `Gtk.Popover` showing the current time including seconds, the current date, month navigation (previous/next chevrons), and a 7-column day grid for the displayed month with today highlighted in the accent colour. The popover SHALL auto-dismiss on outside click.

#### Scenario: Open from the clock
- **WHEN** the user clicks the clock
- **THEN** a calendar popover opens showing the large current time, the date, and the current month's day grid

#### Scenario: Today is highlighted
- **WHEN** the calendar popover shows the current month
- **THEN** today's cell is highlighted in the accent colour

#### Scenario: Month navigation
- **WHEN** the user clicks the next or previous chevron
- **THEN** the day grid advances or rewinds to that month
- **AND** the highlight only marks today when the displayed month is the current month

#### Scenario: Dismiss on outside click
- **GIVEN** the calendar popover is open
- **WHEN** the user clicks outside it
- **THEN** the popover closes
