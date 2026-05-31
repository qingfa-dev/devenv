# Boundary: Python profile — builds on core + python3 (latest stable) + uv + ruff.
# Context: python3    = Python 3.13 (latest stable — follows nixpkgs-unstable).
#          python312  = Python 3.12 (previous stable) — uncomment to pin.
#          python313  = Python 3.13 (explicit) — same as python3 currently.
#          uv replaces pip/venv/pipx with a single fast toolchain.
#          ruff replaces flake8 + isort + black in one binary.
# Contract: post=python + uv + ruff on PATH
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./core.nix { inherit pkgs; }).packages
    ++ [
      python3
      ruff
      uv
    ];

  shellHook = ''
    export UV_LINK_MODE=copy
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
