# Makefile — devenv operations
# Context: Three entry points: nix develop (flakes), nix-shell (classic), devenv.sh.
# Usage: make <target>

.PHONY: verify integration-test clean

# Shell targets — each available in all three entry points
.PHONY: shell-default shell-dotnet shell-python shell-frontend shell-full
.PHONY: nix-shell-default nix-shell-dotnet nix-shell-python nix-shell-frontend nix-shell-full
.PHONY: devenv-default devenv-dotnet devenv-python devenv-frontend devenv-full

export NIX_CONFIG := extra-experimental-features = nix-command flakes

# ── Verify ───────────────────────────────────────────────────
# Context: 49+ assertion suite — syntax, structure, imports, file checks.
verify:
	@bash verify.sh

# ── Integration Test ─────────────────────────────────────────
# Context: Builds every shell in nixos/nix container, confirms all tools work.
integration-test:
	@echo "Running full integration test in nixos/nix container..."
	@echo "This downloads nixpkgs (~1.5 GB) on first run and takes ~3 min."
	@podman run --rm -v "$$PWD":/workspace:rw -w /workspace \
		nixos/nix:latest bash /workspace/integration-test.sh

# ── nix develop (flakes) ────────────────────────────────────
shell-default:
	@nix develop .#default

shell-dotnet:
	@nix develop .#dotnet

shell-python:
	@nix develop .#python

shell-frontend:
	@nix develop .#frontend

shell-full:
	@nix develop .#full

# ── nix-shell (classic, no flakes needed) ────────────────────
nix-shell-default:
	@nix-shell --argstr profile default

nix-shell-dotnet:
	@nix-shell --argstr profile dotnet

nix-shell-python:
	@nix-shell --argstr profile python

nix-shell-frontend:
	@nix-shell --argstr profile frontend

nix-shell-full:
	@nix-shell --argstr profile full

# ── devenv.sh ────────────────────────────────────────────────
devenv-default:
	@devenv shell

devenv-dotnet:
	@devenv shell --config devenv-dotnet.nix

devenv-python:
	@devenv shell --config devenv-python.nix

devenv-frontend:
	@devenv shell --config devenv-frontend.nix

devenv-full:
	@devenv shell --config devenv.nix

# ── Clean ────────────────────────────────────────────────────
clean:
	rm -f flake.lock
	rm -rf .devenv .direnv
