{ ... }:
{
  flake.homeManagerModules.lkh-foot =
    { config, pkgs, ... }:
    let
      palette = config.colorScheme.palette;
    in
    {
      programs.foot = {
        enable = true;
        settings = {
          main = {
            font = "CaskaydiaMono NF:size=12";
            pad = "14x14";
          };
          colors = {
            background = palette.base00;
            foreground = palette.base05;
            selection-background = palette.base02;
            selection-foreground = palette.base00;
            regular0 = palette.base00;
            regular1 = palette.base08;
            regular2 = palette.base0B;
            regular3 = palette.base0A;
            regular4 = palette.base0D;
            regular5 = palette.base0E;
            regular6 = palette.base0C;
            regular7 = palette.base05;
            bright0 = palette.base03;
            bright1 = palette.base08;
            bright2 = palette.base0B;
            bright3 = palette.base0A;
            bright4 = palette.base0D;
            bright5 = palette.base0E;
            bright6 = palette.base0C;
            bright7 = palette.base07;
          };
        };
      };
    };
}
