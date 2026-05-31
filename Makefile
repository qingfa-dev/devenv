# Makefile — devenv operations
# Context: Single entry point: nix develop (flakes). Profiles in profiles/.
# Usage: make verify | make shell-dotnet | make integration-test | make clean

.PHONY: verify integration-test clean
.PHONY: shell-default shell-dotnet shell-python shell-frontend shell-full

export NIX_CONFIG := extra-experimental-features = nix-command flakes

verify:
	@bash verify.sh

integration-test:
	@echo "Running full integration test in nixos/nix container..."
	@echo "This downloads nixpkgs (~1.5 GB) on first run and takes ~3 min."
	@podman run --rm -v "$$PWD":/workspace:rw -w /workspace \
		nixos/nix:latest bash /workspace/integration-test.sh

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

clean:
	rm -f flake.lock
	rm -rf .devenv .direnv
