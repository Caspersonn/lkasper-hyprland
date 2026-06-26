## REMOVED Requirements

### Requirement: Control center PopupWindow overlay
**Reason**: The QuickSettings subsystem is removed; its control-center function is replaced by the `ags-control-center` popover (`Gtk.Popover`, no full-screen overlay).
**Migration**: See the `ags-control-center` capability.

### Requirement: Panel close behavior
**Reason**: Dismissal is handled natively by `Gtk.Popover` (outside click); no PopupWindow.
**Migration**: See the `ags-control-center` capability.

### Requirement: Control center layout
**Reason**: Layout is redefined by the control-center popover (2×2 toggle grid, volume + brightness sliders, power-profile segmented control).
**Migration**: See the `ags-control-center` capability.

### Requirement: Trigger highlight state
**Reason**: Triggered from the right-island quick-controls cluster, not the former right-pill icons.
**Migration**: See the `ags-bar` "Quick-controls cluster" requirement.

### Requirement: Right-pill ordering includes bell at far right
**Reason**: The right-pill module ordering is superseded by the three-island layout.
**Migration**: See the `ags-bar` "Bar uses three-island layout" requirement.
