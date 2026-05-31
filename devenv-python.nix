# Context: devenv.sh — Python + uv + ruff profile.
#          Usage: devenv shell --config devenv-python.nix
{ pkgs, ... }:
let mod = import ./profiles/python.nix { inherit pkgs; };
in {
  packages = mod.packages;
  enterShell = mod.shellHook or "";
}
