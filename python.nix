# Boundary: Python profile — builds on core packages + Python 3.12 + uv.
# Context: Python 3.12 interpreter with uv as the package manager (10-100x pip).
#          PyTorch CPU-only to keep image size small for 6-8GB constrained machines.
#          ruff replaces flake8+isort+black in a single tool.
# Contract: pre=python312 + uv in nixpkgs, post=python + uv available on PATH
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./devenv.nix { inherit pkgs; }).packages
    ++ [
      python312
      uv
      ruff
    ];

  # Context: UV_LINK_MODE=copy avoids symlink conflicts in Nix environments.
  shellHook = ''
    export UV_LINK_MODE=copy
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
