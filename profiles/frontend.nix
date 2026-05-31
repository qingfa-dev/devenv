# Boundary: Frontend profile — builds on core + Node.js latest + pnpm + corepack.
# Context: nodejs    = Node.js 24 (latest, currently v24.15.0).
#          nodejs_22 = Node.js 22 (LTS) — switch here for LTS.
#          nodejs_20 = Node.js 20 (older LTS).
#          corepack manages pnpm version per project (locks version in package.json).
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
