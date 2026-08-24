{ ... }:
{
  flake.homeManagerModules.lkh-foot =
    { ... }:
    {
      programs.foot = {
        enable = true;
        settings = { };
      };

      xdg.configFile."foot/foot.ini".text = ''
        include=~/.config/lkasper-hyprland/current/foot.ini

        [main]
        font=CaskaydiaMono NF:size=12
        pad=14x14
      '';
    };
}
