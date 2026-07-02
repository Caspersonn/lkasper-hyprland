## Context

`ags/windows/bar/workspaces.tsx` already reads each workspace's `clients` binding (for the app icons and the `occupied`/underline-visible state). The underline is a plain `<box class="ws-underline" halign={Gtk.Align.CENTER} visible={underlineVisible} />` whose size comes entirely from `ags/style.scss` (`min-width: 14px; min-height: 2px`). Because the width is a static CSS floor, every underline is 14px wide regardless of client count.

## Goals

- Underline width is a function of client count on the workspace.
- Busier workspaces read as visibly busier, but the underline never overflows the cell.
- No change to colour, height, monitor-accent hashing, or focus/occupied/empty behaviour.

## Decision

Compute the width in the widget and bind it to the box's `widthRequest`, and remove the static `min-width` from SCSS so there is a single source of truth for the width.

In `WorkspaceButton`, add a computed accessor over the existing `clients` binding:

```tsx
const BASE = 14      // width for a single client (matches today's fixed 14px)
const STEP = 6       // extra px per additional client
const MAX = 46       // cap so the underline stays within the cell

const underlineWidth = createComputed([clients], (cs) => {
    const n = cs.length
    if (n <= 1) return BASE
    return Math.min(BASE + (n - 1) * STEP, MAX)
})
```

Bind it on the underline box:

```tsx
<box
    class="ws-underline"
    halign={Gtk.Align.CENTER}
    widthRequest={underlineWidth}
    visible={underlineVisible}
/>
```

And drop `min-width: 14px` from `.ws-underline` in `ags/style.scss` (keep `min-height`, `margin-top`, `border-radius`, and `background-color`).

### Rationale

- **`widthRequest` over CSS classes**: a numeric `widthRequest` gives smooth per-client growth without generating a class per possible count; it reuses the `clients` binding already in the widget.
- **Base = 14** keeps the single-client (and focused-empty) case pixel-identical to today, so the change is purely additive for busy workspaces.
- **Clamp at MAX** prevents a workspace with many windows from stretching the cell or the left island. The `ws-num`/`ws-icons` row still determines the cell width; the capped underline sits centered under it.
- Values `STEP`/`MAX` are cosmetic constants and can be tuned during the visual-confirm task.

### Empty focused workspace

`underlineVisible` is true for a focused workspace even with zero clients. With `n <= 1 → BASE`, an empty focused workspace keeps the 14px underline it has today. No special-casing needed.

## Alternatives considered

- **A CSS class per bucket (`.apps-1`, `.apps-2+`)**: coarser, more stylesheet churn, and still needs a computed accessor to pick the class — no benefit over binding `widthRequest` directly.
- **Percentage width of the cell**: GTK4 boxes don't take percentage widths cleanly, and the cell width itself varies with icon count, making the mapping to "app count" indirect.
