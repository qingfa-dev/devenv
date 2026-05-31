# Boundary: Frontend profile — builds on core packages + Node.js 24 + pnpm.
# Context: Node.js 24 LTS with corepack for pnpm version management.
#          oxlint + oxfmt (Rust-based) replace ESLint + Prettier (100x faster).
#          @angular/cli and create-vue for project scaffolding.
# Assume: Global npm packages installed via pnpm add -g on first entry.
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./devenv.nix { inherit pkgs; }).packages
    ++ [
      nodejs_24
      corepack_24
      pnpm
    ];

  # Context: PNPM_HOME stores globally installed packages per-project state.
  #          corepack prepare locks the pnpm version declared in package.json.
  shellHook = ''
    export PNPM_HOME="$PWD/.devenv/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
    corepack prepare pnpm@latest --activate 2>/dev/null || true
  '';
}
