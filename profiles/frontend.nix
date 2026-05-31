# Boundary: Frontend profile — builds on core + latest LTS nodejs + pnpm + corepack.
# Context: nodejs (LTS, currently v22) via nixpkgs; corepack manages pnpm version per project.
#          oxlint + oxfmt are installed via pnpm add -g on first shell entry (not in nixpkgs).
# Assume: Global npm packages installed via pnpm add -g need internet on first run.
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./core.nix { inherit pkgs; }).packages
    ++ [
      corepack
      nodejs
      pnpm
    ];

  shellHook = ''
    export PNPM_HOME="$PWD/.devenv/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
    corepack prepare pnpm@latest --activate 2>/dev/null || true
  '';
}
