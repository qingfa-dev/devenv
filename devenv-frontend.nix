# Context: devenv.sh — Node.js + pnpm profile.
#          Usage: devenv shell --config devenv-frontend.nix
{ pkgs, ... }:
let mod = import ./profiles/frontend.nix { inherit pkgs; };
in {
  packages = mod.packages;
  enterShell = mod.shellHook or "";
}
