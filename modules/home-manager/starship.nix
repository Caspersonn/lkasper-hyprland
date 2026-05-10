{ ... }:
{
  flake.homeManagerModules.lkh-starship =
    { ... }:
    {
      programs.starship = {
        enable = true;
        settings = {
          aws = {
            format = "on [$symbol$profile]($style) ";
            style = "bold blue";
            symbol = "🅰  ";
            profile_aliases = {
              Enterprise_Naming_Scheme-voidstars = "void**";
            };
          };
          terraform = {
            format = "via [$symbol$version $workspace]($style) ";
          };
        };
      };
    };
}
