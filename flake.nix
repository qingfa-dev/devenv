# Context: Nix flake that defines 5 independent devShells.
#          Uses pkgs.mkShell directly (not devenv.lib.mkShell) to avoid
#          devenv root-detection issues in containers and CI environments.
#          Each profile is a self-contained Nix module that imports core.
#
# Invariant: The 'default' shell = core only. Other shells import core + their specialisation.
# Invariant: 'full' imports ALL modules — every tool from every profile.
#
# Contract: pre=nixpkgs-unstable is fetchable,
#           post=5 devShells available for x86_64-linux
{
  description = "modular devenv profiles (core → dotnet | python | frontend | full)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Context: Import a profile module and extract packages + shellHook.
      buildShell = module: pkgs.mkShell ((import module { inherit pkgs; }) // {
        nativeBuildInputs = (import module { inherit pkgs; }).packages or [];
      });
    in
    {
      devShells.${system} = {
        # Core profile — git, curl, make, podman, editorconfig-checker, jq, yq
        default = buildShell ./devenv.nix;

        # .NET 10 + Aspire — inherits core tools via devenv.nix import chain
        dotnet = buildShell ./dotnet.nix;

        # Python 3.12 + PyTorch CPU + FastAPI — inherits core tools
        python = buildShell ./python.nix;

        # Node 24 + pnpm + Vue + Angular CLI — inherits core tools
        frontend = buildShell ./frontend.nix;

        # All tools combined — every package from all profiles
        full = pkgs.mkShell {
          name = "devenv-full";
          nativeBuildInputs = with pkgs;
            (import ./devenv.nix { inherit pkgs; }).packages
            ++ (import ./dotnet.nix { inherit pkgs; }).packages
            ++ (import ./python.nix { inherit pkgs; }).packages
            ++ (import ./frontend.nix { inherit pkgs; }).packages;
        };
      };
    };
}
