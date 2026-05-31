# Context: devenv.sh — .NET + Aspire profile.
#          Usage: devenv shell --config devenv-dotnet.nix
{ pkgs, ... }:
let mod = import ./profiles/dotnet.nix { inherit pkgs; };
in {
  packages = mod.packages;
  enterShell = mod.shellHook or "";
}
