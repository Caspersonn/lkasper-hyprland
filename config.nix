lib: {
  lkasperHyprlandOptions = {
    full_name = lib.mkOption {
      type = lib.types.str;
      description = "Main user's full name";
    };
    email_address = lib.mkOption {
      type = lib.types.str;
      description = "Main user's email address";
    };
    primary_font = lib.mkOption {
      type = lib.types.str;
      default = "Liberation Sans 11";
    };
    vscode_settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Monitor specs passed to hl.monitor(), e.g. { output = \"DP-1\"; mode = \"2560x1440@144\"; position = \"0x0\"; scale = 1; }.";
    };
    scale = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Display scale factor (1 for 1x displays, 2 for 2x displays)";
    };
    quick_app_bindings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = ''
        Single keystroke key bindings to launch common apps. Each entry is
        { keys; exec; description? }. `exec` is passed to hl.dsp.exec_cmd, so a
        plain string is a shell command and a lib.generators.mkLuaInline value is
        a raw Lua expression (for instance one of the app locals below).
      '';
      default = [
        {
          keys = "SUPER + return";
          exec = lib.generators.mkLuaInline "terminal";
        }
        {
          keys = "SUPER + E";
          exec = lib.generators.mkLuaInline "fileManager";
        }
        {
          keys = "SUPER + B";
          exec = lib.generators.mkLuaInline "browser";
        }
        {
          keys = "SUPER + M";
          exec = lib.generators.mkLuaInline "music";
        }
        {
          keys = "SUPER + O";
          exec = "foot btop";
        }
        {
          keys = "SUPER + D";
          exec = "foot lazydocker";
        }
        {
          keys = "SUPER + G";
          exec = lib.generators.mkLuaInline "messenger";
        }
        {
          keys = "SUPER + slash";
          exec = lib.generators.mkLuaInline "passwordManager";
        }
      ];
    };
    exclude_packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to exclude from the default system packages";
    };
  };
}
