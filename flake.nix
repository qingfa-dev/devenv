# Context: Nix flake that defines 5 independent devShells.
#          Each devShell is a modular Nix devenv profile.
#          Usage: nix develop .#dotnet | nix develop .#python | nix develop .#frontend | nix develop .#full
#
# Invariant: The 'default' shell = core only. Other shells import core + their specialisation.
# Invariant: 'full' imports ALL modules — intended for development, not documentation.
#
# Contract: pre=nixpkgs-unstable and devenv inputs are fetchable,
#           post=5 devShells available for x86_64-linux
{
  description = "modular devenv profiles (core → dotnet | python | frontend | full)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Compute: Factory function — reduces boilerplate for every devShell.
      mkShell = modules: devenv.lib.mkShell {
        inherit inputs pkgs modules;
      };
    in
    {
      devShells.${system} = {
        # Context: Core profile — git, curl, make, podman, editorconfig-checker, jq, yq
        default  = mkShell [ (import ./devenv.nix) ];

        # Context: .NET 10 + Aspire — inherits core tools via devenv.nix import chain
        dotnet   = mkShell [ (import ./dotnet.nix) ];

        # Context: Python 3.12 + PyTorch CPU + FastAPI — inherits core tools
        python   = mkShell [ (import ./python.nix) ];

        # Context: Node 24 + pnpm + Vue + Angular CLI — inherits core tools
        frontend = mkShell [ (import ./frontend.nix) ];

        # Context: All tools combined — every package from all profiles
        full     = mkShell [
          (import ./devenv.nix)
          (import ./dotnet.nix)
          (import ./python.nix)
          (import ./frontend.nix)
        ];
      };
    };
}
