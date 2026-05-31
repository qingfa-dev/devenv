# Boundary: Python profile — builds on core + latest stable python3 + uv + ruff.
# Context: uv replaces pip/venv/pipx with a single fast toolchain.
#          ruff replaces flake8 + isort + black in one binary.
# Contract: pre=python3, uv, ruff in nixpkgs, post=all three on PATH
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
