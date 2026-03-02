{ inputs, ... }:
{
  flake.homeManagerModules.omarchy-walker =
    { ... }:
    {
      imports = [ inputs.walker.homeManagerModules.default ];

      programs.elephant = {
        enable = true;
        debug = false;
        installService = true;
        providers = [
          "desktopapplications"
          "calc"
          "runner"
          "clipboard"
          "symbols"
          "websearch"
          "menus"
          "providerlist"
        ];
        settings = {
          providers = {
            desktopapplications = {
              launch_prefix = "uwsm app --";
              min_score = 60;
            };
            calc = {
              icon = "accessories-calculator";
            };
          };
        };
      };

      programs.walker = {
        enable = true;
        runAsService = true;
        config = builtins.fromTOML (builtins.readFile ../../config/walker/config.toml);
      };

      home.file = {
        ".local/share/omarchy/default/walker/themes/omarchy-default/style.css".source =
          ../../config/walker/themes/omarchy-default/style.css;
        ".local/share/omarchy/default/walker/themes/omarchy-default/layout.xml".source =
          ../../config/walker/themes/omarchy-default/layout.xml;
        ".config/elephant/menus/omarchy_themes.lua".source = ../../config/elephant/menus/omarchy_themes.lua;
        ".config/elephant/menus/omarchy_background_selector.lua".source =
          ../../config/elephant/menus/omarchy_background_selector.lua;
      };
    };
}
