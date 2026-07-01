## 1. Add the float gap

- [x] 1.1 In `ags/style.scss`, add `margin-top` to the existing `.popover-wrap > contents` rule (start at ~10px). Keep `background: none`, `border: none`, `box-shadow: none`, `padding: 0` unchanged.

## 2. Measure and test

- [x] 2.1 Rebuild and open each of the six popovers (calendar, media, weather, control center, notifications, power); confirm each floats with an even gap below the bar.
- [x] 2.2 Tune the `margin-top` value against the 42px islands until the gap looks right; settle the final value. **Settled at 10px.**
- [x] 2.3 Confirm click-outside still dismisses each popover (note whether clicking *inside the gap* dismisses; if the dead-zone is annoying, fall back to per-popover `set_offset`). No dead-zone issue reported; `margin-top` approach kept. (Also tested a temporary drop shadow — rejected, kept flat/no-shadow.)

## 3. Verify

- [x] 3.1 Run `nix fmt`.
