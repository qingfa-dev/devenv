# Context: Nix flake — 5 devShells (core | dotnet | python | frontend | full).
#          Profiles live in profiles/ subdirectory for modular structure.
#          Uses pkgs.mkShell directly (no devenv.lib) for container/CI compatibility.
#
# Invariant: default = core only. Other shells = core + specialisation.
# Invariant: full = all profiles combined.
#
# Contract: pre=nixpkgs-unstable fetchable, post=5 devShells available for x86_64-linux
{
  description = "modular dev shells: core | dotnet | python | frontend | full";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      profile = path: (import path { inherit pkgs; });
    in {
      devShells.${system} = {
        default  = pkgs.mkShell (profile ./profiles/core.nix);
        dotnet   = pkgs.mkShell (profile ./profiles/dotnet.nix);
        python   = pkgs.mkShell (profile ./profiles/python.nix);
        frontend = pkgs.mkShell (profile ./profiles/frontend.nix);
        full = pkgs.mkShell {
          nativeBuildInputs =
            (profile ./profiles/core.nix).packages
            ++ (profile ./profiles/dotnet.nix).packages
            ++ (profile ./profiles/python.nix).packages
            ++ (profile ./profiles/frontend.nix).packages;
        };
      };
    };
}
