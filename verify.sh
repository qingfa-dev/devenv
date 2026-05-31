#!/usr/bin/env bash
# Context: Comprehensive verification for self-contained devenv profiles.
#           Run from the devenv/ directory: bash verify.sh
#           Container: podman run --rm -v "$PWD":/workspace -w /workspace alpine:edge sh -c 'apk add bash jq && bash verify.sh'
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

assert() { local d="$1" c="$2"
  printf "  %-55s " "$d"
  if eval "$c" >/dev/null 2>&1; then
    echo "${GREEN}PASS${NC}"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC}"; FAIL=$((FAIL + 1)); eval "$c" 2>&1 | sed 's/^/    /'
  fi
}

assert_eq() { local d="$1" e="$2" a="$3"
  printf "  %-55s " "$d"
  if [ "$e" = "$a" ]; then
    echo "${GREEN}PASS${NC} (got: $a)"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC} (expected: $e, got: $a)"; FAIL=$((FAIL + 1))
  fi
}

banner() { echo ""; echo "${BLUE}${BOLD}── $* ──${NC}"; echo ""; }

banner "1. FILE STRUCTURE"

assert "profiles/core.nix exists"     "test -f profiles/core.nix"
assert "profiles/dotnet.nix exists"   "test -f profiles/dotnet.nix"
assert "profiles/python.nix exists"   "test -f profiles/python.nix"
assert "profiles/frontend.nix exists" "test -f profiles/frontend.nix"
assert "flake.nix exists"             "test -f flake.nix"
assert "Makefile exists"              "test -f Makefile"
assert "extensions.json exists"       "test -f .vscode/extensions.json"
assert "README exists"                "test -f README.md"
assert "verify.sh exists"             "test -f verify.sh"
assert "integration-test.sh exists"   "test -f integration-test.sh"

banner "2. NIX SYNTAX"

if command -v nix-instantiate &>/dev/null; then
  for f in flake.nix profiles/core.nix profiles/dotnet.nix profiles/python.nix profiles/frontend.nix; do
    assert "nix parse: $f" "nix-instantiate --parse $f"
  done
else
  echo "  (nix not installed — skip)"
fi

banner "3. IMPORT CHAINS"

assert "core.nix has no imports" \
  "! grep -q 'imports =' profiles/core.nix"
assert "dotnet.nix imports core.nix" \
  "grep -q './core.nix' profiles/dotnet.nix"
assert "python.nix imports core.nix" \
  "grep -q './core.nix' profiles/python.nix"
assert "frontend.nix imports core.nix" \
  "grep -q './core.nix' profiles/frontend.nix"
assert "flake.nix imports profiles/core.nix" \
  "grep -q './profiles/core.nix' flake.nix"
assert "flake.nix imports profiles/dotnet.nix" \
  "grep -q './profiles/dotnet.nix' flake.nix"
assert "flake.nix imports profiles/python.nix" \
  "grep -q './profiles/python.nix' flake.nix"
assert "flake.nix imports profiles/frontend.nix" \
  "grep -q './profiles/frontend.nix' flake.nix"

banner "4. FLAKE STRUCTURE"

DEVSHELLS=$(grep -cE '^\s+(default|dotnet|python|frontend|full)\s*=' flake.nix || echo 0)
assert_eq "flake has 5 devShells" "5" "$DEVSHELLS"

banner "5. PROFILE CONTENTS (LTS/stable attributes)"

assert "core: git"                 "grep -q 'git' profiles/core.nix"
assert "core: curl"                "grep -q 'curl' profiles/core.nix"
assert "core: gnumake"             "grep -q 'gnumake' profiles/core.nix"
assert "core: podman"              "grep -q 'podman' profiles/core.nix"
assert "core: docker-client"       "grep -q 'docker-client' profiles/core.nix"
assert "core: gh"                  "grep -q 'gh' profiles/core.nix"
assert "core: glab"                "grep -q 'glab' profiles/core.nix"
assert "core: editorconfig-checker" "grep -q 'editorconfig-checker' profiles/core.nix"
assert "core: jq"                  "grep -q 'jq' profiles/core.nix"
assert "core: yq-go"               "grep -q 'yq-go' profiles/core.nix"
assert "core: pre-commit"          "grep -q 'pre-commit' profiles/core.nix"
assert "core: slirp4netns"         "grep -q 'slirp4netns' profiles/core.nix"
assert "core: fuse-overlayfs"      "grep -q 'fuse-overlayfs' profiles/core.nix"

# Context: dotnet-sdk is the unversioned attribute → always latest stable in nixpkgs
assert "dotnet: dotnet-sdk (LTS)"   "grep -q 'dotnet-sdk' profiles/dotnet.nix"
assert "dotnet: ASPIRE_HINT"        "grep -q 'ASPIRE_HINT' profiles/dotnet.nix"

# Context: python3 is the unversioned attribute → always latest stable
assert "python: python3 (stable)"   "grep -q 'python3' profiles/python.nix"
assert "python: uv"                 "grep -q 'uv' profiles/python.nix"
assert "python: ruff"               "grep -q 'ruff' profiles/python.nix"

# Context: nodejs is the unversioned attribute → always latest LTS
assert "frontend: nodejs (LTS)"     "grep -q 'nodejs' profiles/frontend.nix"
assert "frontend: pnpm"             "grep -q 'pnpm' profiles/frontend.nix"
assert "frontend: corepack"         "grep -q 'corepack' profiles/frontend.nix"

banner "6. EXTENSIONS.JSON"

EXT_COUNT=$(jq '.recommendations | length' .vscode/extensions.json 2>/dev/null || echo 0)
assert "extensions: >= 20" "test $EXT_COUNT -ge 20"

banner "7. MAKEFILE TARGETS"

for t in verify integration-test shell-default shell-dotnet shell-python shell-frontend shell-full clean; do
  assert "Makefile target: $t" "grep -q '^$t:' Makefile"
done

echo ""
echo "${BLUE}${BOLD}═══ RESULTS ═══${NC}"
echo "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}"
[ "$FAIL" -eq 0 ] && echo "  All assertions passed." && exit 0 || exit 1
