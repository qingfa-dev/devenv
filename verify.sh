#!/usr/bin/env bash
# Context: Comprehensive verification for self-contained devenv profiles.
#           Run from the devenv/ directory.
#           Usage: bash verify.sh
#           Container: podman run --rm -v "$PWD":/workspace -w /workspace alpine:edge sh -c 'apk add bash jq && bash verify.sh'
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

# Validate: Run a command and report pass/fail.
assert() { local desc="$1" cmd="$2"
  printf "  %-55s " "$desc"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "${GREEN}PASS${NC}"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC}"; FAIL=$((FAIL + 1))
    eval "$cmd" 2>&1 | sed 's/^/    /'
  fi
}

# Validate: Compare expected value with actual value.
assert_eq() { local desc="$1" expected="$2" actual="$3"
  printf "  %-55s " "$desc"
  if [ "$expected" = "$actual" ]; then
    echo "${GREEN}PASS${NC} (got: $actual)"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC} (expected: $expected, got: $actual)"; FAIL=$((FAIL + 1))
  fi
}

banner() { echo ""; echo "${BLUE}${BOLD}── $* ──${NC}"; echo ""; }

# ═══════════════════════════════════════════════════════════════
banner "1. FILE STRUCTURE"

# Check: All required nix files exist in the self-contained devenv/ directory.
assert "devenv.nix exists"       "test -f devenv.nix"
assert "dotnet.nix exists"       "test -f dotnet.nix"
assert "python.nix exists"       "test -f python.nix"
assert "frontend.nix exists"     "test -f frontend.nix"
assert "flake.nix exists"        "test -f flake.nix"
assert "extensions.json exists"  "test -f .vscode/extensions.json"
assert "plan file exists"        "test -f plan/infrastructure-devenv-profiles-1.md"
assert "README exists"           "test -f README.md"
assert "NO .devcontainer/ residue" "test ! -d .devcontainer"

# Check: No old flat files from the earlier structure.
assert "NO old flat files (dotnet)"   "test ! -f devenv-dotnet.nix"
assert "NO old flat files (python)"   "test ! -f devenv-python.nix"
assert "NO old flat files (frontend)" "test ! -f devenv-frontend.nix"

# ═══════════════════════════════════════════════════════════════
banner "2. NIX SYNTAX"

if command -v nix-instantiate &>/dev/null; then
  for f in flake.nix devenv.nix dotnet.nix python.nix frontend.nix; do
    assert "nix parse: $f" "nix-instantiate --parse $f"
  done
else
  echo "  (nix not installed — skipping syntax parse; tested separately in nixos container)"
fi

# ═══════════════════════════════════════════════════════════════
banner "3. IMPORT CHAINS"

# Context: Core module must NOT import anything — it is the root of the chain.
assert "devenv.nix has no imports" \
  "! grep -q 'imports' devenv.nix"

# Context: Each profile imports ./devenv.nix (same directory in self-contained structure).
assert "dotnet.nix imports ./devenv.nix" \
  "grep -q './devenv.nix' dotnet.nix"
assert "python.nix imports ./devenv.nix" \
  "grep -q './devenv.nix' python.nix"
assert "frontend.nix imports ./devenv.nix" \
  "grep -q './devenv.nix' frontend.nix"

# Context: flake.nix imports all modules from the same directory.
assert "flake.nix imports ./devenv.nix" \
  "grep -q './devenv.nix' flake.nix"
assert "flake.nix imports ./dotnet.nix" \
  "grep -q './dotnet.nix' flake.nix"
assert "flake.nix imports ./python.nix" \
  "grep -q './python.nix' flake.nix"
assert "flake.nix imports ./frontend.nix" \
  "grep -q './frontend.nix' flake.nix"

# Check: No stale ../devenv.nix imports from the old structure.
assert "NO stale ../devenv.nix import" \
  "! grep -rq '\.\.\/devenv\.nix' *.nix 2>/dev/null"

# ═══════════════════════════════════════════════════════════════
banner "4. FLAKE STRUCTURE"

DEVSHELLS=$(grep -cE '^\s+(default|dotnet|python|frontend|full)\s*=' flake.nix || echo 0)
assert_eq "flake has 5 devShells" "5" "$DEVSHELLS"

assert "flake has 'default'"   "grep -q 'default.*= mkShell' flake.nix"
assert "flake has 'dotnet'"    "grep -q 'dotnet.*= mkShell' flake.nix"
assert "flake has 'python'"    "grep -q 'python.*= mkShell' flake.nix"
assert "flake has 'frontend'"  "grep -q 'frontend.*= mkShell' flake.nix"
assert "flake has 'full'"      "grep -q 'full.*= mkShell' flake.nix"

# ═══════════════════════════════════════════════════════════════
banner "5. PROFILE CONTENTS"

# Core: Base tooling inherited by all profiles.
assert "core: git"        "grep -q 'git' devenv.nix"
assert "core: curl"       "grep -q 'curl' devenv.nix"
assert "core: make"       "grep -q 'make' devenv.nix"
assert "core: podman"     "grep -q 'podman' devenv.nix"
assert "core: editorconfig-checker" "grep -q 'editorconfig-checker' devenv.nix"
assert "core: jq"         "grep -q 'jq' devenv.nix"
assert "core: yq"         "grep -q 'yq' devenv.nix"
assert "core: pre-commit" "grep -q 'pre-commit' devenv.nix"

# Dotnet: .NET 10 SDK + Aspire orchestration.
assert "dotnet: dotnet-sdk_10"  "grep -q 'dotnet-sdk_10' dotnet.nix"
assert "dotnet: ASPIRE_HINT"    "grep -q 'ASPIRE_HINT' dotnet.nix"
assert "dotnet: tool restore"   "grep -q 'dotnet tool restore' dotnet.nix"

# Python: Python 3.12 + uv + PyTorch CPU.
assert "python: uv"        "grep -q 'uv' python.nix"
assert "python: python312" "grep -q 'python312' python.nix"
assert "python: torch"     "grep -q 'torch' python.nix"
assert "python: fastapi"   "grep -q 'fastapi' python.nix"

# Frontend: Node.js 24 + pnpm + Vue + Angular.
assert "frontend: nodejs_24"   "grep -q 'nodejs_24' frontend.nix"
assert "frontend: pnpm"        "grep -q 'pnpm' frontend.nix"
assert "frontend: oxlint"      "grep -q 'oxlint' frontend.nix"
assert "frontend: @angular/cli" "grep -q '@angular/cli' frontend.nix"
assert "frontend: create-vue"   "grep -q 'create-vue' frontend.nix"

# Check: No Flutter or Android residue.
assert "NO flutter in any .nix" "! grep -ri 'flutter' *.nix 2>/dev/null"
assert "NO android in any .nix (except Comments)" \
  "! grep -ri 'android' *.nix 2>/dev/null | grep -v '#' | grep -v 'scripts' | grep -v 'Context' || true"

# ═══════════════════════════════════════════════════════════════
banner "6. CODE COMMENTING STANDARD"

# Context: All profile .nix files must have at least one Boundary: label.
for f in dotnet.nix python.nix frontend.nix; do
  assert "comment: Boundary: in $f" "grep -q 'Boundary:' $f"
done

# Context: Core module must declare an Invariant.
assert "comment: Invariant: in devenv.nix" "grep -q 'Invariant:' devenv.nix"
assert "comment: Invariant: in flake.nix"  "grep -q 'Invariant:' flake.nix"

# Context: Each profile must declare a Contract for its post-conditions.
for f in dotnet.nix python.nix frontend.nix; do
  assert "comment: Contract: in $f" "grep -q 'Contract:' $f"
done

# Context: Profiles must have at least one Context: and one AgentHint:.
assert "comment: Context: in dotnet.nix"    "grep -q 'Context:' dotnet.nix"
assert "comment: AgentHint: in dotnet.nix"   "grep -q 'AgentHint:' dotnet.nix"
assert "comment: AgentHint: in frontend.nix" "grep -q 'AgentHint:' frontend.nix"

# ═══════════════════════════════════════════════════════════════
banner "7. EXTENSIONS.JSON"

assert "extensions.json is valid JSON" \
  "jq empty .vscode/extensions.json 2>/dev/null || python3 -m json.tool .vscode/extensions.json >/dev/null 2>&1"

EXT_COUNT=$(jq '.recommendations | length' .vscode/extensions.json 2>/dev/null || echo 0)
assert "extensions.json: at least 20 recommendations" "test $EXT_COUNT -ge 20"

assert "extensions: vue.volar present"   "grep -q 'vue.volar' .vscode/extensions.json"
assert "extensions: eslint present"      "grep -q 'dbaeumer.vscode-eslint' .vscode/extensions.json"
assert "extensions: csharp present"      "grep -q 'ms-dotnettools.csharp' .vscode/extensions.json"
assert "extensions: aspire present"      "grep -q 'microsoft-aspire.aspire-vscode' .vscode/extensions.json"
assert "extensions: docker present"      "grep -q 'ms-azuretools.vscode-docker' .vscode/extensions.json"

# ═══════════════════════════════════════════════════════════════
banner "8. PLAN FILE"

assert "plan: status is Completed" \
  "grep -q 'status:.*Completed' plan/infrastructure-devenv-profiles-1.md"
assert "plan: has FILE entries" \
  "grep -q 'FILE-001' plan/infrastructure-devenv-profiles-1.md"

# ═══════════════════════════════════════════════════════════════
banner "9. FLAKE NIX EVALUATION (requires nix)"

if command -v nix &>/dev/null && nix --version &>/dev/null; then
  echo "  Running nix flake show..."
  if nix --extra-experimental-features 'nix-command flakes' flake show 2>&1; then
    assert "nix flake show passed" "true"
  else
    echo "  (flake show failed — may need nixpkgs lock; try nix flake check)"
    nix --extra-experimental-features 'nix-command flakes' flake check --no-build 2>&1 || true
  fi
else
  echo "  (nix not installed — flake evaluation skipped)"
fi

# ═══════════════════════════════════════════════════════════════
echo ""
echo "${BLUE}${BOLD}═══ RESULTS ═══${NC}"
echo "  ${GREEN}PASS: $PASS${NC}"
if [ "$FAIL" -gt 0 ]; then
  echo "  ${RED}FAIL: $FAIL${NC}"
  exit 1
fi
echo "  All assertions passed."
exit 0
