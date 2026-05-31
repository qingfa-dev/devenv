# Makefile — devenv operations
# Context: Single entry point for verify, integration-test, shell-*, and clean.
# Usage: make verify | make integration-test | make shell-dotnet | make clean

.PHONY: verify integration-test clean shell-default shell-dotnet shell-python shell-frontend shell-full

export NIX_CONFIG := extra-experimental-features = nix-command flakes

# Verify: Run 49+ assertion suite on host (syntax, structure, import chains)
verify:
	@bash verify.sh

# Integration-Test: Build all shells in nixos/nix container and confirm every tool works
integration-test:
	@echo "Running full integration test in nixos/nix container..."
	@echo "This downloads nixpkgs (~1.5 GB) on first run and takes ~3 min."
	@podman run --rm -v "$$PWD":/workspace:rw -w /workspace \
		nixos/nix:latest bash /workspace/integration-test.sh

# Shell-<profile>: Enter a nix develop shell for the given profile
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

# Clean: Remove nix build artifacts
clean:
	rm -f flake.lock
	rm -rf .devenv .direnv
