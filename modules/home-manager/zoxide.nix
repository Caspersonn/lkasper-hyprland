{ ... }:
{
  flake.homeManagerModules.omarchy-zoxide =
    { ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
