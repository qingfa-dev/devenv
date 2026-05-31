#!/usr/bin/env bash
# Integration test — builds every nix shell and verifies tools are installed.
# Runs in nixos/nix container with rw mount. Downloads nixpkgs (~1.5 GB first run).
# Usage: make integration-test  or  podman run ... bash integration-test.sh
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; FAIL=0; START=$(date +%s); cd /workspace

banner() { echo ""; echo "${BLUE}── $* ──${NC}"; }
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

# Context: Run a command inside a nix develop shell and check exit code + version
wrap() { local shell="$1" label="$2"; shift 2
  printf "  %-30s " "$label"
  if out=$(nix develop ".#$shell" --command bash -c "$* 2>&1" 2>&1); then
    echo "${GREEN}PASS${NC} ($(echo "$out" | head -c 80))"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC}"; echo "    $(echo "$out" | tail -3)"; FAIL=$((FAIL + 1))
  fi
}

banner "1. FLAKE"
if nix flake show >/dev/null 2>&1; then echo "  ${GREEN}OK${NC}"; PASS=$((PASS+1)); else echo "  ${RED}FAIL${NC}"; FAIL=$((FAIL+1)); fi

banner "2. CORE — 13 tools"
wrap default git           git --version
wrap default curl          curl --version
wrap default make          make --version
wrap default podman        podman --version
wrap default docker        docker --version
wrap default gh            gh --version
wrap default glab          glab version
wrap default editorconfig  editorconfig-checker --version
wrap default jq            jq --version
wrap default yq            yq --version
wrap default pre-commit    pre-commit --version

banner "3. DOTNET — SDK + Aspire"
wrap dotnet  "dotnet sdk"         dotnet --version
wrap dotnet  "dotnet --list-sdks" dotnet --list-sdks

banner "4. PYTHON — python + uv + ruff"
wrap python python   python --version
wrap python uv       uv --version
wrap python ruff     ruff --version

banner "5. FRONTEND — node + pnpm"
wrap frontend node   node --version
wrap frontend pnpm   pnpm --version

echo ""
echo "${BLUE}═══ RESULTS: ${GREEN}$PASS PASS${NC} ${RED}$FAIL FAIL${NC}  (${SECONDS}s) ═══${NC}"
[ "$FAIL" -eq 0 ] && echo "All profiles verified." && exit 0 || exit 1
