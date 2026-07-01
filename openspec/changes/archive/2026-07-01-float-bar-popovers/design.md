## Context

All six bar popovers (calendar, media, weather, control center, notifications, power) are Astal **GTK4** `Gtk.Popover` instances built with the same recipe:

```
new Gtk.Popover()
  .set_has_arrow(false)          // no arrow → anchors flush to the button edge
  .add_css_class("popover-wrap") // shared class across all six
  .set_parent(triggerButton)
```

Because `has_arrow` is false and the default position is `BOTTOM`, each popover surface sits flush against the bottom of its trigger button in the bar. The visible card (`.calendar-popover`, etc.) is drawn *inside* the popover's `contents` node, which `ags/style.scss` already neutralizes:

```scss
.popover-wrap > contents {
    background: none;
    border: none;
    box-shadow: none;
    padding: 0;
}
```

The GTK4 popover node tree is `popover > (arrow) + contents`, and `.popover-wrap` is on the `popover` node, so `.popover-wrap > contents` is the single shared surface every popover routes through.

## Goals / Non-Goals

**Goals**
- A consistent vertical gap so every popover floats below the bar.
- One edit that reaches all six popovers.
- Empirical gap value, tuned against the flattened 42px islands.

**Non-Goals**
- No drop shadow (explicit user decision — stay flat, consistent with `flatten-bar-islands`).
- No horizontal inset / re-anchoring, no per-popover custom offsets.
- No widget/TSX changes.

## Decisions

### Decision 1 — Gap mechanism: `margin-top` on `.popover-wrap > contents`

Add a `margin-top` to the existing shared `.popover-wrap > contents` rule rather than calling `set_offset(0, gap)` on each of the six `Gtk.Popover` instances.

| | `margin-top` on `.popover-wrap > contents` (chosen) | `set_offset(0, gap)` per popover |
|---|---|---|
| Edits | 1 (shared class) | 6 (one per popover TSX) |
| Consistency | guaranteed identical | manual, drift-prone |
| Matches prior pattern | yes (flatten-bar-islands used a single shared lever) | no |
| Trade-off | the transparent margin band is part of the popover surface, so clicking *in the gap* won't dismiss | whole surface moves, no dead zone |

**Rationale:** one shared lever mirrors the flatten-bar-islands approach and keeps all six popovers in lockstep with zero TSX churn. The click-in-gap dead-zone is the known trade-off flagged for the "measured **and tested**" step — if it proves annoying in testing, the fallback is to switch to per-popover `set_offset`.

### Decision 2 — No shadow

Per explicit user decision, popovers stay flat. `.popover-wrap > contents` keeps `box-shadow: none`. The gap alone communicates "floating"; this keeps popovers visually consistent with the now-shadowless islands. The solid `$base-dark` card against the wallpaper carries the separation.

### Decision 3 — Gap value is empirical

Start at ~10px `margin-top` and tune against the 42px island height and 14px island radius during testing. The bean explicitly calls for the distance to be "measured and tested," so the exact value is settled visually, not prescribed here.

## Risks / Trade-offs

- **Click-in-gap does not dismiss** (Decision 1 trade-off) — acceptable; revisit with `set_offset` only if testing shows it matters.
- **Gap too large** could make the popover feel disconnected from its trigger — mitigated by keeping the value small (~10px) and tuning.

## Open Questions

- Final gap value — resolved during the test step.
