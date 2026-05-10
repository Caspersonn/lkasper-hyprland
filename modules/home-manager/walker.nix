{ inputs, ... }:
{
  flake.homeManagerModules.lkh-walker =
    { ... }:
    {
      imports = [ inputs.walker.homeManagerModules.default ];

      programs.elephant = {
        enable = true;
        debug = false;
        installService = false;
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
        runAsService = false;
      };
    };
}
