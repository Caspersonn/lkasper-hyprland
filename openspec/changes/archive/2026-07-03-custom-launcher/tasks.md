## 1. Wire AstalApps into the bundle

- [x] 1.1 Add `apps` to the `astalLibs` list in `ags/flake.nix`

## 2. Launcher window

- [x] 2.1 Create `ags/windows/launcher/index.tsx`: layer-shell `OVERLAY` window, all-edge anchor, `Exclusivity.IGNORE`, `Keymode.EXCLUSIVE`, dimmed backdrop + centered card (shell copied from `ags/windows/shortcuts/index.tsx`)
- [x] 2.2 Add the search entry (top) and a vertical single-column result list (icon + name per row)
- [x] 2.3 Wire `AstalApps` fuzzy query as the result source over the search text
- [x] 2.4 Add `createState` for query text + selected index; highlight the selected row
- [x] 2.5 Add `EventControllerKey` on the entry: `Up`/`Down` move selection (clamped), `Return` launches selected app via `.launch()` + closes, `Escape` closes
- [x] 2.6 Add backdrop `GestureClick` to close; on open reset query/selection and focus the entry
- [x] 2.7 Export `initLauncher()` and `toggleLauncher()`

## 3. Wire into the shell

- [x] 3.1 In `ags/app.ts` add `import { initLauncher, toggleLauncher } from "./windows/launcher"`, a `toggle-launcher` branch in `requestHandler`, and `initLauncher()` in `main()`
- [x] 3.2 Point the bar launcher button in `ags/windows/bar/index.tsx` at `ags request toggle-launcher` instead of exec-ing walker

## 4. Styling

- [x] 4.1 Append `.launcher` / launcher-* styles (backdrop, card, search entry, result rows, selected-row highlight) to `ags/style.scss` using existing palette variables (no new literals)

## 5. Keybinds

- [x] 5.1 In `modules/home-manager/_hyprland/bindings.nix` rebind `SUPER, SPACE` → `bindd` `[Launcher]` `exec, ags request toggle-launcher`
- [x] 5.2 Add `SUPER CTRL, SPACE` → `exec, walker` backup bind; leave `SUPER SHIFT, SPACE` toggle-bars unchanged

## 6. Verify

- [ ] 6.1 `git add ags/windows/launcher/index.tsx` and confirm `ags bundle app.ts` resolves `gi://AstalApps` and compiles clean
- [x] 6.2 `openspec validate custom-launcher --strict` passes
- [ ] 6.3 `nix fmt` and rebuild; verify `gi://AstalApps` resolves via the nix build path (user)
- [ ] 6.4 Manual: `SUPER, SPACE` opens the launcher, typing filters, arrows move selection, `Enter` launches, `Escape`/backdrop close; walker still opens on `SUPER CTRL, SPACE` (user)
