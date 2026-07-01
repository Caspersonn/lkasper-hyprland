## 1. Flatten island surface

- [x] 1.1 In `ags/style.scss`, change `$island-fill` from `rgba($base-dark, 0.8)` to solid `$base-dark`
- [x] 1.2 In `ags/style.scss`, remove the `box-shadow: $island-shadow` declaration from `.island`
- [x] 1.3 In `ags/style.scss`, delete the now-unused `$island-shadow` variable

## 2. Verify

- [x] 2.1 Run `nix fmt`
- [x] 2.2 Rebuild and visually confirm islands are opaque with no drop shadow (wallpaper visible only in the gaps between islands)
