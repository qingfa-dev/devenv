#!/usr/bin/env bash
# Integration test — actually builds nix shells and verifies tools are installed.
# Runs in a nixos/nix container with rw mount. Downloads nixpkgs (~1.5 GB).
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0; START=$(date +%s)
cd /workspace

banner() { echo ""; echo "${BLUE}${BOLD}── $* ──${NC}"; echo ""; }
check() { local label="$1" pattern="$2"; shift 2
  printf "  %-45s " "$label"
  if out=$("$@" 2>&1); then
    ver=$(echo "$out" | head -1)
    echo "${GREEN}PASS${NC} ($ver)"; PASS=$((PASS + 1))
  else
    echo "${RED}FAIL${NC}"; echo "    $out" | tail -3; FAIL=$((FAIL + 1))
  fi
}

banner "1. FLAKE EVALUATION"
nix --extra-experimental-features "nix-command flakes" flake show >/dev/null 2>&1 && \
  echo "  ${GREEN}flake evaluates OK${NC}" && PASS=$((PASS+1)) || \
  { echo "  ${RED}flake evaluation FAILED${NC}"; nix --extra-experimental-features "nix-command flakes" flake show 2>&1; FAIL=$((FAIL+1)); }

banner "2. CORE: nix develop .#default — git, podman, curl, jq, yq, make, ec"
nix develop --extra-experimental-features "nix-command flakes" .#default --command bash -c "
check() { local l=\"\$1\" p=\"\$2\"; shift 2; printf '  %-40s ' \"\$l\"; if out=\$(\"\$@\" 2>&1); then echo '${GREEN}PASS${NC} ('\$(echo \"\$out\" | head -1)')'; else echo '${RED}FAIL${NC}'; echo \"    \$out\" | tail -2; fi; }
check git        'git version'        git --version
check curl       'curl '              curl --version
check podman     'podman version'     podman --version
check editorconfig 'EditorConfig'     editorconfig-checker --version
check jq         'jq-'                jq --version
check yq         'yq '                yq --version
check make       'GNU Make'           make --version
check pre-commit 'pre-commit'         pre-commit --version
" 2>&1 || FAIL=$((FAIL + 1))

banner "3. DOTNET: nix develop .#dotnet — dotnet --version"
nix develop --extra-experimental-features "nix-command flakes" .#dotnet --command bash -c "
check() { local l=\"\$1\" p=\"\$2\"; shift 2; printf '  %-40s ' \"\$l\"; if out=\$(\"\$@\" 2>&1); then echo '${GREEN}PASS${NC} ('\$(echo \"\$out\" | head -1)')'; else echo '${RED}FAIL${NC}'; echo \"    \$out\" | tail -2; fi; }
check dotnet     '10.'                dotnet --version
" 2>&1 || FAIL=$((FAIL + 1))

banner "4. PYTHON: nix develop .#python — python + uv"
nix develop --extra-experimental-features "nix-command flakes" .#python --command bash -c "
check() { local l=\"\$1\" p=\"\$2\"; shift 2; printf '  %-40s ' \"\$l\"; if out=\$(\"\$@\" 2>&1); then echo '${GREEN}PASS${NC} ('\$(echo \"\$out\" | head -1)')'; else echo '${RED}FAIL${NC}'; echo \"    \$out\" | tail -2; fi; }
check python     '3.12'               python --version
check uv         'uv '                uv --version
" 2>&1 || FAIL=$((FAIL + 1))

banner "5. FRONTEND: nix develop .#frontend — node + pnpm"
nix develop --extra-experimental-features "nix-command flakes" .#frontend --command bash -c "
check() { local l=\"\$1\" p=\"\$2\"; shift 2; printf '  %-40s ' \"\$l\"; if out=\$(\"\$@\" 2>&1); then echo '${GREEN}PASS${NC} ('\$(echo \"\$out\" | head -1)')'; else echo '${RED}FAIL${NC}'; echo \"    \$out\" | tail -2; fi; }
check node       'v24'                node --version
check pnpm       ''                   pnpm --version
" 2>&1 || FAIL=$((FAIL + 1))

ELAPSED=$(( $(date +%s) - START ))
echo ""
echo "${BLUE}${BOLD}═══ RESULTS ═══${NC}"
echo "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  Time: ${ELAPSED}s"
[ "$FAIL" -eq 0 ] && echo "  All profiles verified — tools are installed." || exit 1
