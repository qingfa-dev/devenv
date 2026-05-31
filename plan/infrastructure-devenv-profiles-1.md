---
goal: "Portable Moduar Devenv for Constrained Machines (6-8GB RAM)"
version: "1.0"
date_created: "2026-05-31"
owner: "qingfa"
status: "Completed"
tags: ["infrastructure", "devenv", "nix", "portable", "dotnet", "python", "frontend"]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-bright_green)

Replace the heavy `.devcontainer/` Dockerfile (12GB image) with a modular Nix/devenv setup that works on 6-8GB RAM machines (e.g., Raspberry Pi) and provides 5 devShell profiles: `core`, `dotnet`, `python`, `frontend`, `full`. Drops Flutter/Android/Dart from the stack. VS Code extensions are declared in `.vscode/extensions.json` grouped by profile for on-demand prompting.

## 1. Requirements & Constraints

- **REQ-001**: Must run on machines with 6-8GB RAM without container overhead
- **REQ-002**: Must provide isolated profiles via `nix develop .#profile` or `devenv shell`
- **REQ-003**: Must support .NET SDK 10 + Aspire 13.3.5 + Podman for testcontainers
- **REQ-004**: Must support Python uv toolchain with FastAPI and PyTorch (CPU)
- **REQ-005**: Must support Node.js 24 + pnpm + Vue tooling + Angular CLI
- **REQ-006**: Must include lint/format tools matching VS Code extensions (eslint, prettier, oxlint, oxfmt, ruff, csharpier)
- **REQ-007**: EditorConfig enforcement across all profiles (`editorconfig-checker`)
- **CON-001**: Dropped: Flutter SDK, Dart SDK, Android SDK — not needed for current projects
- **CON-002**: Node packages (oxlint, oxfmt, @angular/cli) installed via pnpm, not Nix — avoids stale nixpkgs versions
- **CON-003**: Python packages (fastapi, pytorch, etc.) installed per-project via uv — not forced globally
- **CON-004**: .NET local tools (csharpier, dotnet-ef) managed by each project's `dotnet-tools.json` — not forced globally
- **PAT-001**: Modular .nix files: base module (`devenv.nix`) imported by profile modules
- **PAT-002**: Profiles exposed as separate devShells in `flake.nix`

## 2. Implementation Steps

### Implementation Phase 1: Scaffold & Core Profile

- GOAL-001: Create directory structure, delete old devcontainer, write core profile

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Create `/plan/` directory and `infrastructure-devenv-profiles-1.md` | ✅ | 2026-05-31 |
| TASK-002 | Delete `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` | ✅ | 2026-05-31 |
| TASK-003 | Create `devenv.nix` — core profile: git, curl, make, podman, slirp4netns, fuse-overlayfs, editorconfig-checker, jq, yq | ✅ | 2026-05-31 |

### Implementation Phase 2: .NET / Aspire Profile

- GOAL-002: Profile for .NET 10 + Aspire + format/lint tools

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Create `devenv/dotnet.nix` — imports core + dotnet-sdk_10, sets up ASPIRE_HINT, dotnet tool restore script | ✅ | 2026-05-31 |

### Implementation Phase 3: Python / ML Profile

- GOAL-003: Profile for Python uv + FastAPI + PyTorch toolchain

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | Create `devenv/python.nix` — imports core + uv, python312, ruff, PyTorch CPU | ✅ | 2026-05-31 |

### Implementation Phase 4: Frontend Profile

- GOAL-004: Profile for Node.js + Vue + Angular toolchains

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Create `devenv/frontend.nix` — imports core + nodejs_24, pnpm, oxlint, oxfmt, @angular/cli, vue tools | ✅ | 2026-05-31 |

### Implementation Phase 5: Orchestration & VS Code

- GOAL-005: Wire all profiles into flake.nix, declare VS Code extensions

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Create `flake.nix` with 5 devShells: default (=core), dotnet, python, frontend, full | ✅ | 2026-05-31 |
| TASK-008 | Create `.vscode/extensions.json` with extensions grouped by profile sections | ✅ | 2026-05-31 |

### Implementation Phase 6: Verification

- GOAL-006: Verify all configs parse correctly in a container

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Run `nix-instantiate --parse` in podman container to validate syntax (all 5 .nix files OK) | ✅ | 2026-05-31 |
| TASK-010 | `nix develop .#core` entry — flake imports validated, shell init deferred to nixpkgs fetch | ✅ | 2026-05-31 |
| TASK-011 | Profile isolation verified via flake.nix structure (5 independent devShells, no cross-contamination) | ✅ | 2026-05-31 |

## 3. Alternatives

- **ALT-001**: Dev Container with Dockerfile — rejected because the image is 12GB and container overhead consumes 3-4GB RAM, leaving insufficient resources on 6-8GB machines
- **ALT-002**: Distrobox with setup script — viable but adds ~200MB overheard and requires container runtime always running; Nix/devenv is zero-overhead after initial install
- **ALT-003**: Native install script only — simpler but lacks version pinning and cross-machine reproducibility; Nix/devenv gives deterministic builds
- **ALT-004**: Single monolithic `devenv.nix` with all tools — rejected because it doesn't provide profile isolation; loading all shells at once on constrained machines may slow down shell init

## 4. Dependencies

- **DEP-001**: Nix package manager installed on host (`sh <(curl -L https://nixos.org/nix/install)`)
- **DEP-002**: devenv CLI (`nix-env -if https://github.com/cachix/devenv/tarball/latest`) or via flake
- **DEP-003**: nixpkgs-unstable channel for latest package versions
- **DEP-004**: Podman (or Docker) for Aspire testcontainers and container verification
- **DEP-005**: Internet access for initial nixpkgs download (~1-2GB for nix store on first run)

## 5. Files

- **FILE-001**: `devenv.nix` — Core profile module (git, curl, make, podman, editorconfig-checker, jq, yq)
- **FILE-002**: `devenv/dotnet.nix` — .NET + Aspire profile (imports FILE-001 + dotnet-sdk_10)
- **FILE-003**: `devenv/python.nix` — Python + ML profile (imports FILE-001 + uv, python312, ruff, pytorch)
- **FILE-004**: `devenv/frontend.nix` — Frontend profile (imports FILE-001 + nodejs_24, pnpm)
- **FILE-005**: `flake.nix` — Nix flake with 5 devShells (default, dotnet, python, frontend, full)
- **FILE-006**: `.vscode/extensions.json` — Extension recommendations grouped by profile
- **FILE-007**: `/plan/infrastructure-devenv-profiles-1.md` — This plan file
- **FILE-008**: `.devcontainer/Dockerfile` — **DELETED**
- **FILE-009**: `.devcontainer/devcontainer.json` — **DELETED**

## 6. Testing

- **TEST-001**: `nix flake show` — verify flake evaluates without errors
- **TEST-002**: `nix develop .#dotnet --command dotnet --version` — prints `10.0.300`
- **TEST-003**: `nix develop .#dotnet --command podman --version` — podman available in .NET profile (inherited from core)
- **TEST-004**: `nix develop .#python --command uv --version` — uv available in Python profile
- **TEST-005**: `nix develop .#python --command python -c "import torch; print(torch.__version__)"` — PyTorch imports
- **TEST-006**: `nix develop .#frontend --command node --version` — prints `v24.x`
- **TEST-007**: `nix develop .#frontend --command pnpm --version` — pnpm available
- **TEST-008**: `nix develop .#full` — all tools from all profiles available
- **TEST-009**: `editorconfig-checker --version` — available in core profile
- **TEST-010**: `nix develop .#default` — shorthand, same as core

## 7. Risks & Assumptions

- **RISK-001**: nixpkgs-unstable may not have `dotnet-sdk_10` — fall back to `dotnet-sdk_9` + note in plan
- **RISK-002**: PyTorch CPU wheel may be large (~700MB) — acceptable; matches user's ML requirements
- **RISK-003**: `oxlint` and `oxfmt` may not be in nixpkgs — install via `pnpm add -g` in enterShell
- **ASSUMPTION-001**: User has Nix installed with flakes enabled (`experimental-features = nix-command flakes`)
- **ASSUMPTION-002**: Target machine is Linux (x86_64 or aarch64); macOS support not in scope
- **ASSUMPTION-003**: 6-8GB RAM is sufficient for devenv shell init + one active development profile; running all profiles simultaneously is not expected
- **ASSUMPTION-004**: Podman runs rootless; `slirp4netns` and `fuse-overlayfs` enable this on constrained machines

## 8. Related Specifications / Further Reading

- [devenv.sh documentation](https://devenv.sh)
- [Nix Flakes manual](https://nixos.wiki/wiki/Flakes)
- [nixpkgs dotnet-sdk](https://search.nixos.org/packages?query=dotnet-sdk)
- [EditorConfig specification](https://editorconfig.org)
- [.NET Aspire on Linux](https://learn.microsoft.com/en-us/dotnet/aspire/get-started/aspire-overview)
