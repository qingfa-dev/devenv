# Context: devenv.sh entry point — all profiles combined (full shell).
#          Usage: devenv shell
#                 devenv shell --config devenv-dotnet.nix
# Invariant: Reuses the same profiles/*.nix modules via import.
{ pkgs, ... }:
let
  core     = import ./profiles/core.nix     { inherit pkgs; };
  dotnet   = import ./profiles/dotnet.nix   { inherit pkgs; };
  python   = import ./profiles/python.nix   { inherit pkgs; };
  frontend = import ./profiles/frontend.nix { inherit pkgs; };
in {
  packages = core.packages
    ++ dotnet.packages
    ++ python.packages
    ++ frontend.packages;

  enterShell = ''
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
    export ASPIRE_HINT="podman"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    export UV_LINK_MODE=copy
  '';
}
