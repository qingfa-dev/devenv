# Context: Classic nix-shell entry point (no flakes required).
#          Usage: nix-shell --argstr profile dotnet
#                 nix-shell --argstr profile python
#                 nix-shell                    # defaults to core
# Invariant: Reuses the same profiles/*.nix modules as the flake.
{ profile ? "default" }:
let
  pkgs = import <nixpkgs> {};

  name = if profile == "default" then "core" else profile;

  mod = import (./profiles + "/${name}.nix") { inherit pkgs; };
in
pkgs.mkShell mod
