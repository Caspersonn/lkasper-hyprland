## 1. Flatten island surface

- [ ] 1.1 In `ags/style.scss`, change `$island-fill` from `rgba($base-dark, 0.8)` to solid `$base-dark`
- [ ] 1.2 In `ags/style.scss`, remove the `box-shadow: $island-shadow` declaration from `.island`
- [ ] 1.3 In `ags/style.scss`, delete the now-unused `$island-shadow` variable

## 2. Verify

- [ ] 2.1 Run `nix fmt`
- [ ] 2.2 Rebuild and visually confirm islands are opaque with no drop shadow (wallpaper visible only in the gaps between islands)
