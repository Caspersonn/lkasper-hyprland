## 1. Add runtime launcher and theme scripts

- [x] 1.1 Create `bin/omarchy-menu` with top-level and direct submenu invocation (`omarchy-menu theme`) using the existing wofi flow.
- [x] 1.2 Create `bin/omarchy-theme-list` to enumerate supported fixed themes from `modules/_themes.nix`-aligned names.
- [x] 1.3 Create `bin/omarchy-theme-current` to read active theme from `~/.config/omarchy/current/theme.name` with declarative fallback behavior.
- [x] 1.4 Create `bin/omarchy-theme-set` to validate theme names, update `~/.config/omarchy/current/theme.name`, refresh `~/.config/omarchy/current/theme/`, and run ordered reload hooks.

## 2. Wire scripts into home-manager and Hyprland keybinds

- [x] 2.1 Update `modules/home-manager/themes.nix` to install launcher/theme runtime scripts into `~/.local/share/omarchy/bin` and initialize runtime state when missing.
- [x] 2.2 Update `modules/home-manager/_hyprland/bindings.nix` to bind `SUPER ALT, SPACE` to `omarchy-menu`.
- [x] 2.3 Update `modules/home-manager/_hyprland/bindings.nix` to add a dedicated keybind for `omarchy-menu theme` direct invocation.
- [x] 2.4 Ensure `modules/home-manager/wofi.nix` supports the custom launcher menu UX required by `omarchy-menu`.

## 3. Integrate runtime theme application with themed components

- [x] 3.1 Update `modules/home-manager/waybar.nix` to consume runtime-applied theme outputs without requiring `home-manager switch`.
- [x] 3.2 Update `modules/home-manager/mako.nix` and `modules/home-manager/_hyprland/looknfeel.nix` so runtime theme changes can be reloaded/restarted in-session.
- [x] 3.3 Update `modules/home-manager/ghostty.nix`, `modules/home-manager/hyprlock.nix`, and `modules/home-manager/btop.nix` to follow runtime theme state or generated runtime theme files.
- [x] 3.4 Add/adjust script-driven reload commands in `bin/omarchy-theme-set` for waybar, mako, and Hyprland-adjacent UI components.

## 4. Verify formatting and behavior

- [ ] 4.1 Run `nix fmt` and resolve formatting changes in touched Nix files.
- [ ] 4.2 Run `nix flake check` and fix any evaluation or module wiring issues.
- [ ] 4.3 Validate session behavior manually: trigger `SUPER ALT, SPACE`, run `omarchy-menu theme`, select a theme, and confirm no rebuild command is required.
