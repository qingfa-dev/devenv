# Boundary: Frontend profile → imports core profile for shared base tooling.
# Contract: pre=nodejs_24 and corepack_24 in nixpkgs, post=pnpm + oxlint + @angular/cli available
# Assume: Global npm packages are installed via scripts.setup-frontend-globals on first entry.
{ pkgs, ... }: {
  imports = [ ./devenv.nix ];

  packages = with pkgs; [
    nodejs_24
    corepack_24
    pnpm
  ];

  # Context: JavaScript language support with corepack for pnpm/yarn version management.
  #          Nix provides Node.js 24; corepack locks pnpm version per project.
  languages.javascript = {
    enable = true;
    corepack.enable = true;
    pnpm.enable = true;
  };

  # Context: Installs globally-useful frontend CLI tools via pnpm.
  #          oxlint: fast TypeScript-aware linter (Rust-based, 100x ESLint)
  #          oxfmt: companion formatter matching oxlint rules
  #          @angular/cli: Angular project scaffolding and build toolchain
  #          create-vue: Vue project scaffolding (official Vue CLI replacement)
  scripts.setup-frontend-globals.exec = ''
    pnpm add -g oxlint oxfmt @angular/cli create-vue 2>/dev/null || true
  '';

  # Validate: oxlint checks TypeScript/JavaScript for errors (no fix mode).
  scripts.frontend-lint.exec = ''
    oxlint .
  '';

  # Update: oxfmt auto-formats TypeScript/JavaScript/JSON/Markdown files.
  scripts.frontend-format.exec = ''
    oxfmt .
  '';

  # Context: Scaffold a new Vue 3 + TypeScript + Vite project.
  scripts.vue-create.exec = ''
    pnpm create vue@latest "''${1:-my-vue-app}"
  '';

  # Context: Scaffold a new Angular project using pnpm as package manager.
  scripts.ng-new.exec = ''
    npx @angular/cli new "''${1:-my-angular-app}" --package-manager=pnpm
  '';

  # Context: PNPM_HOME stores globally installed packages per devenv state.
  #          corepack prepare activates the pnpm version declared in package.json.
  enterShell = ''
    export PNPM_HOME="$DEVENV_STATE/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    corepack prepare pnpm@latest --activate 2>/dev/null || true

    # Retry: Install global CLI tools on first shell entry only.
    if [ ! -f "$DEVENV_STATE/frontend-globals" ]; then
      pnpm add -g oxlint oxfmt @angular/cli create-vue 2>/dev/null && \
        touch "$DEVENV_STATE/frontend-globals" || true
    fi
  '';
}
