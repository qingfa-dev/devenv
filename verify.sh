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
    echo "${RED}FAIL${NC}"; FAIL=$((FAIL + 1)); eval "$c" 2>&1 | while IFS= read -r line; do printf "    %s\n" "$line"; done
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

# ── 1. FILE STRUCTURE ───────────────────────────────────────
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

# ── 2. NIX SYNTAX ───────────────────────────────────────────
banner "2. NIX SYNTAX"

if command -v nix-instantiate &>/dev/null; then
  for f in flake.nix profiles/core.nix profiles/dotnet.nix profiles/python.nix profiles/frontend.nix; do
    assert "nix parse: $f" "nix-instantiate --parse $f"
  done
else
  echo "  (nix not installed — skip)"
fi

# ── 3. IMPORT CHAINS ────────────────────────────────────────
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

# ── 4. FLAKE STRUCTURE ──────────────────────────────────────
banner "4. FLAKE STRUCTURE"

DEVSHELLS=$(grep -cE '^\s+(default|dotnet|python|frontend|full)\s*=' flake.nix || echo 0)
assert_eq "flake has 5 devShells" "5" "$DEVSHELLS"

# ── 5. PROFILE CONTENTS ─────────────────────────────────────
banner "5. PROFILE CONTENTS"

assert "core: git"           "grep -q 'git' profiles/core.nix"
assert "core: curl"          "grep -q 'curl' profiles/core.nix"
assert "core: gnumake"       "grep -q 'gnumake' profiles/core.nix"
assert "core: podman"        "grep -q 'podman' profiles/core.nix"
assert "core: docker-client" "grep -q 'docker-client' profiles/core.nix"
assert "core: gh"            "grep -q 'gh' profiles/core.nix"
assert "core: glab"          "grep -q 'glab' profiles/core.nix"
assert "core: jq"            "grep -q 'jq' profiles/core.nix"
assert "core: yq-go"         "grep -q 'yq-go' profiles/core.nix"
assert "core: pre-commit"    "grep -q 'pre-commit' profiles/core.nix"
assert "dotnet: dotnet-sdk"  "grep -q 'dotnet-sdk' profiles/dotnet.nix"
assert "dotnet: ASPIRE_HINT" "grep -q 'ASPIRE_HINT' profiles/dotnet.nix"
assert "python: python3"     "grep -q 'python3' profiles/python.nix"
assert "python: uv"          "grep -q 'uv' profiles/python.nix"
assert "python: ruff"        "grep -q 'ruff' profiles/python.nix"
assert "frontend: nodejs"    "grep -q 'nodejs' profiles/frontend.nix"
assert "frontend: pnpm"      "grep -q 'pnpm' profiles/frontend.nix"

# ── 6. EXTENSIONS.JSON ──────────────────────────────────────
banner "6. EXTENSIONS.JSON"

if command -v jq &>/dev/null; then
  EXT_COUNT=$(jq '.recommendations | length' .vscode/extensions.json)
  assert "extensions: >= 20" "test $EXT_COUNT -ge 20"
elif command -v python3 &>/dev/null; then
  EXT_COUNT=$(python3 -c "import json; print(len(json.load(open('.vscode/extensions.json'))['recommendations']))")
  assert "extensions: >= 20" "test $EXT_COUNT -ge 20"
fi

# ── 7. MAKEFILE TARGETS ─────────────────────────────────────
banner "7. MAKEFILE TARGETS"

for t in verify integration-test shell-default shell-dotnet shell-python shell-frontend shell-full clean; do
  assert "Makefile target: $t" "grep -q '^$t:' Makefile"
done

# ── 8. FILE INTEGRITY ───────────────────────────────────────
banner "8. FILE INTEGRITY"

assert ".gitignore contains flake.lock"      "grep -q 'flake.lock' .gitignore"
assert ".gitignore contains .direnv"         "grep -q '^\\.direnv' .gitignore"
assert ".gitignore contains .devenv"         "grep -q '^\\.devenv' .gitignore"
assert "verify.sh is executable"             "test -x verify.sh"
assert "integration-test.sh is executable"   "test -x integration-test.sh"
assert ".nix files have LF endings"          "! grep -rl 'CRLF' flake.nix profiles/*.nix 2>/dev/null"
assert "No trailing whitespace in .nix"     "! grep -rl '[[:space:]]$' flake.nix profiles/*.nix 2>/dev/null"

# ── 9. STRUCTURE HARDENING ──────────────────────────────────
banner "9. STRUCTURE HARDENING"

assert "Exactly 4 profile files"            "test \"\$(ls profiles/*.nix 2>/dev/null | wc -l)\" -eq 4"
if git rev-parse --git-dir >/dev/null 2>&1; then
  assert "flake.nix is git-tracked"         "git ls-files --error-unmatch flake.nix >/dev/null 2>&1"
  assert "profiles/*.nix are git-tracked"   "for f in profiles/*.nix; do git ls-files --error-unmatch \"\$f\" >/dev/null 2>&1 || exit 1; done"
else
  echo "  (no git repo — skip git tracking checks)"
fi

# ── 10. CONTENT DEEPENING ────────────────────────────────────
banner "10. CONTENT DEEPENING"

assert "core: includes fuse-overlayfs"      "grep -q 'fuse-overlayfs' profiles/core.nix"
assert "core: includes slirp4netns"         "grep -q 'slirp4netns' profiles/core.nix"
assert "core: no direct imports"            "! grep -q 'imports =' profiles/core.nix"
assert "dotnet: shellHook defined"          "grep -q 'shellHook' profiles/dotnet.nix"
assert "dotnet: DOTNET_CLI_TELEMETRY_OPTOUT" "grep -q 'DOTNET_CLI_TELEMETRY_OPTOUT' profiles/dotnet.nix"
assert "python: shellHook defined"          "grep -q 'shellHook' profiles/python.nix"
assert "python: UV_LINK_MODE set"           "grep -q 'UV_LINK_MODE' profiles/python.nix"
assert "frontend: shellHook defined"        "grep -q 'shellHook' profiles/frontend.nix"
assert "frontend: corepack included"        "grep -q 'corepack' profiles/frontend.nix"
if command -v jq &>/dev/null; then
  assert "extensions.json: valid JSON"       "jq empty .vscode/extensions.json"
elif command -v python3 &>/dev/null; then
  assert "extensions.json: valid JSON"       "python3 -c 'import json; json.load(open(\".vscode/extensions.json\"))'"
fi

# ── 11. CROSS-REFERENCE ─────────────────────────────────────
banner "11. CROSS-REFERENCE"

assert "Makefile has shell-default target"  "grep -q '^shell-default:' Makefile"
assert "Makefile has shell-dotnet target"   "grep -q '^shell-dotnet:' Makefile"
assert "Makefile has shell-python target"   "grep -q '^shell-python:' Makefile"
assert "Makefile has shell-frontend target" "grep -q '^shell-frontend:' Makefile"
assert "Makefile has shell-full target"     "grep -q '^shell-full:' Makefile"
assert "Makefile has clean target"          "grep -q '^clean:' Makefile"
assert "README documents all 5 profiles"    "for p in core dotnet python frontend full; do grep -qi \"\$p\" README.md || exit 1; done"
assert "README references nix develop"      "grep -q 'nix develop' README.md"
assert "verify.sh checks all profile files"  "for f in core dotnet python frontend; do grep -q \"profiles/\$f.nix\" verify.sh || exit 1; done"

echo ""
echo "${BLUE}${BOLD}═══ RESULTS ═══${NC}"
echo "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}"
if [ "$FAIL" -eq 0 ]; then
  echo "  All assertions passed." && exit 0
else
  echo ""
  echo "Troubleshooting:"
  echo "  File missing?   → git add profiles/ && git commit"
  echo "  Import missing?  → check profiles/<name>.nix imports"
  echo "  Full guide:      → README.md Troubleshooting"
  exit 1
fi
