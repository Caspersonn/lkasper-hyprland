{ ... }:
{
  flake.homeManagerModules.lkh-zoxide =
    { ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
