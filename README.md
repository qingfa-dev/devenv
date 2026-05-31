# Modular Devenv — Portable Development Shells

> **Version 1.0** · Nix/devenv · CC-BY-4.0
>
> Deterministic, shell-level development environments with zero container overhead.
> Designed for machines with 6-8 GB RAM. Replaces heavy devcontainer Docker images
> (10-15 GB) with lightweight Nix shells that modify PATH only.

---

## Table of Contents

1. [Quickstart](#1-quickstart)
2. [Profiles](#2-profiles)
3. [File Layout](#3-file-layout)
4. [Options & Configuration](#4-options--configuration)
5. [Verification](#5-verification)
6. [FAQ](#6-faq)
7. [Code Commenting Standard](#7-code-commenting-standard)

---

## 1. Quickstart

```bash
# Install Nix (one-time, any Linux distro)
sh <(curl -L https://nixos.org/nix/install)

# Enable Nix Flakes (required)
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# Clone and enter a profile
cd devenv                              # self-contained project root
nix develop .#dotnet                   # .NET 10 + Aspire
nix develop .#python                   # Python 3.12 + PyTorch + FastAPI
nix develop .#frontend                 # Node 24 + Vue + Angular
nix develop .#full                     # every tool combined
nix develop                            # core only (git, podman, make, etc.)
```

---

## 2. Profiles

| Profile     | Shell command          | Key tools |
|-------------|------------------------|-----------|
| **core**    | `nix develop .`       | git, curl, make, podman, editorconfig-checker, jq, yq, pre-commit |
| **dotnet**  | `nix develop .#dotnet` | core + .NET SDK 10, Aspire, dotnet-format, dotnet-ef |
| **python**  | `nix develop .#python` | core + Python 3.12, uv, ruff, PyTorch (CPU), FastAPI |
| **frontend**| `nix develop .#frontend` | core + Node.js 24, pnpm, oxlint, oxfmt, @angular/cli, create-vue |
| **full**    | `nix develop .#full`   | all of the above combined |

### 2.1 Core Profile (`devenv.nix`)

**Purpose:** Shared base tooling inherited by every other profile.

**Packages:**
- `git` — version control
- `curl` — HTTP client for API testing and downloads
- `make` — build automation via Makefile
- `podman` — rootless container runtime (preferred over Docker)
- `slirp4netns` — user-mode networking for rootless Podman
- `fuse-overlayfs` — overlay filesystem for rootless container images
- `editorconfig-checker` — enforces `.editorconfig` compliance across all file types
- `jq` — JSON processor for scripting and CI
- `yq` — YAML processor for configuration management
- `pre-commit` — Git hook framework for lint/format gates

**Environment variables set:**
- `DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock` — Docker CLI compatibility
- `CONTAINER=podman` — used by Makefiles that detect Podman vs Docker

### 2.2 .NET Profile (`dotnet.nix`)

**Purpose:** .NET 10 SDK with Aspire orchestration and code formatting.

**Packages:**
- `dotnet-sdk_10` — .NET 10 SDK (includes C# compiler, MSBuild, NuGet)

**Environment variables set:**
- `ASPIRE_HINT=podman` — directs Aspire to use Podman instead of Docker
- `DOTNET_CLI_TELEMETRY_OPTOUT=1` — disables telemetry
- `DOTNET_NOLOGO=1` — suppresses SDK banner

**Helper scripts:**
| Script | Description |
|--------|-------------|
| `scripts.dotnet-restore` | `dotnet tool restore` + `dotnet restore --locked-mode` (if lockfiles exist) |
| `scripts.dotnet-format` | `dotnet format --verify-no-changes` — CI-style format check |

**What you CAN do in this shell:**
- Build and run .NET 10 + Aspire projects
- Run xUnit v3 tests with Testcontainers (PostgreSQL, Redis via Podman)
- Scaffold new .NET projects with `dotnet new`
- Manage EF Core migrations with `dotnet ef`

### 2.3 Python Profile (`python.nix`)

**Purpose:** Python 3.12 with uv toolchain, PyTorch, FastAPI, and ruff linter.

**Packages:**
- `python312` — Python 3.12 interpreter
- `uv` — Fast Python package installer and resolver (10-100x pip)

**Environment variables set:**
- `UV_LINK_MODE=copy` — uses copies instead of symlinks (Nix compatibility)

**Helper scripts:**
| Script | Description |
|--------|-------------|
| `scripts.python-lint` | `ruff check .` — lint all Python files |
| `scripts.python-fix` | `ruff check --fix . && ruff format .` — auto-fix + format |
| `scripts.install-torch` | `uv pip install torch` (CPU) + fastapi + uvicorn + pydantic + httpx + pytest |

**What you CAN do in this shell:**
- Create Python projects with `uv init`
- Install packages with `uv pip install` or `uv add`
- Run FastAPI servers with `uvicorn`
- Train PyTorch models (CPU-only — designed for 6-8GB RAM)
- Use `ruff` for lint + format in one tool

### 2.4 Frontend Profile (`frontend.nix`)

**Purpose:** Node.js 24 with pnpm, Vue, Angular, and fast lint/format tools.

**Packages:**
- `nodejs_24` — Node.js 24 runtime
- `corepack_24` — Corepack for pnpm/yarn version management
- `pnpm` — Fast, disk-efficient package manager

**Globally installed (via `scripts.setup-frontend-globals`):**
- `oxlint` — Rust-based TypeScript/JavaScript linter (100x faster than ESLint)
- `oxfmt` — Companion formatter matching oxlint rules
- `@angular/cli` — Angular project scaffolding and build toolchain
- `create-vue` — Official Vue project scaffolding

**Helper scripts:**
| Script | Description |
|--------|-------------|
| `scripts.setup-frontend-globals` | Installs global CLI tools via pnpm (runs on first shell entry) |
| `scripts.frontend-lint` | `oxlint .` — lint TypeScript/JavaScript |
| `scripts.frontend-format` | `oxfmt .` — format TypeScript/JS/JSON/Markdown |
| `scripts.vue-create` | `pnpm create vue@latest <name>` — scaffold Vue project |
| `scripts.ng-new` | `npx @angular/cli new <name>` — scaffold Angular project |

**What you CAN do in this shell:**
- Create Vue 3 + TypeScript + Vite projects
- Create Angular projects with pnpm
- Run vitest, vue-tsc, eslint-vue
- Build frontend SPAs for .NET Aspire apps

---

## 3. File Layout

```
devenv/
├── README.md                  ← this file
├── flake.nix                  ← Nix flake — 5 devShells (entry point)
├── devenv.nix                 ← core profile — inherited by all others
├── dotnet.nix                 ← .NET 10 + Aspire profile
├── python.nix                 ← Python 3.12 + PyTorch profile
├── frontend.nix               ← Node 24 + Vue + Angular profile
├── verify.sh                  ← comprehensive verification (59 assertions)
├── plan/
│   └── infrastructure-devenv-profiles-1.md  ← implementation plan
└── .vscode/
    └── extensions.json        ← VS Code extension recommendations (25 extensions)
```

### Import chain

```
devenv/flake.nix
  ├─ import ./devenv.nix        → core
  ├─ import ./dotnet.nix        → core + .NET
  ├─ import ./python.nix        → core + Python
  ├─ import ./frontend.nix      → core + Node
  └─ import ALL → full

Each profile .nix:
  imports = [ ./devenv.nix ]    → pulls in git, podman, curl, make, etc.
```

---

## 4. Options & Configuration

### 4.1 Switching container runtime to Docker

Edit `devenv/devenv.nix`:

```nix
# Before (default):
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
export CONTAINER="podman"

# After (Docker):
export DOCKER_HOST="unix:///var/run/docker.sock"
export CONTAINER="docker"
```

### 4.2 Using a different .NET SDK version

Edit `devenv/dotnet.nix`:

```nix
packages = with pkgs; [
  dotnet-sdk_9    # change 10 → 9
];
```

Search available versions: https://search.nixos.org/packages?query=dotnet-sdk

### 4.3 Adding a new tool to a profile

Edit the profile's `.nix` file — add to `packages` list:

```nix
packages = with pkgs; [
  dotnet-sdk_10
  csharpier           # add this line
];
```

Rebuild: `exit` and re-enter `nix develop .#dotnet`.

### 4.4 Creating a custom profile

1. Copy an existing profile: `cp dotnet.nix myprofile.nix`
2. Edit packages and scripts
3. Add to `flake.nix`:

```nix
devShells.${system} = {
  myprofile = mkShell [ (import ./myprofile.nix) ];
};
```

4. Use: `nix develop .#myprofile`

### 4.5 VS Code extensions

`devenv/.vscode/extensions.json` lists 25 recommended extensions. Copy this file to
your project's `.vscode/extensions.json` when you want VS Code to prompt for
installing them.

---

## 5. Verification

Run the comprehensive assertion suite:

```bash
cd devenv && bash verify.sh
```

Run in containers for cross-environment testing:

```bash
# Alpine Linux (core checks only)
podman run --rm -v "$PWD":/workspace -w /workspace alpine:edge sh -c '
  apk add --no-cache bash jq && bash /workspace/verify.sh'

# NixOS/nix container (Nix syntax + flake evaluation)
podman run --rm -v "$PWD":/workspace -w /workspace nixos/nix:latest sh -c '
  bash /workspace/verify.sh'
```

**Verification results (last run):**
- **59/59** assertions passed on host
- **5/5** Nix syntax parsed successfully in nixos container
- All 5 .nix files validated

---

## 6. FAQ

### Does this create a container?

No. Nix modifies only your `$PATH` and environment variables within the shell session.
Exit the shell (`Ctrl+D` or `exit`) and everything is clean. No daemon, no VM, no
container overhead.

### Why not Docker devcontainers?

A devcontainer image with .NET + Node + Python + tools is **10-15 GB** and consumes
**3-4 GB RAM** just to idle. On a 6-8 GB machine, that leaves almost nothing for your
actual application, database, and IDE.

Nix shells consume **0 extra RAM** — tools only use memory when you run them.

### Can I use Docker instead of Podman?

Yes. See [Section 4.1](#41-switching-container-runtime-to-docker). Core profile sets
Podman by default. Edit `devenv.nix` to switch.

### What if nixpkgs doesn't have the version I need?

Nix uses `nixpkgs-unstable` which tracks the latest releases. If a package hasn't
landed yet, you can:
1. Pin an older nixpkgs revision in `flake.nix`
2. Use an overlay to override the package version
3. Install the tool via its native manager (dotnet, npm, pip) inside the shell

### How do I install Node packages globally?

```bash
nix develop .#frontend
pnpm add -g <package-name>
# Stored in $DEVENV_STATE/pnpm — persists across shell sessions
```

### How do I install Python packages?

```bash
nix develop .#python
uv pip install <package-name>
# or: uv add <package-name>  (in a uv project)
```

### My flake evaluation fails on `.ServiceHub` or `.DS_Store` files?

Close VS Code before running `nix flake check`. Nix flakes traverse the entire
workspace tree and fail on binary socket files. Add `!.ServiceHub` to `.gitignore`.

### Is this x86_64 only?

The flake is declared for `x86_64-linux`. For ARM64 (Raspberry Pi, Apple Silicon),
change `system = "x86_64-linux"` to `system = "aarch64-linux"` in `flake.nix`.
All packages in use have ARM64 builds available.

---

## 7. Code Commenting Standard

The `.nix` files in this project follow the **Code Commenting Standard v3.0**
(language-agnostic, machine-parseable). Labels used:

| Label | Meaning | Used in |
|-------|---------|---------|
| `Boundary:` | Architectural layer boundary — prevents cross-layer dependency leaks | Each profile .nix |
| `Invariant:` | Property that must always hold true for this module | `devenv.nix`, `flake.nix` |
| `Contract:` | Pre/post-condition contract for a function or module | `dotnet.nix`, `python.nix`, `frontend.nix` |
| `Context:` | Background context needed for correct interpretation | Throughout, especially for env vars |
| `Assume:` | Assumption not enforced by a guard | `frontend.nix` (corepack availability) |
| `AgentHint:` | Explicit guidance to AI coding agents | `dotnet.nix`, `frontend.nix` |
| `Compute:` | Derived calculation or algorithm | `devenv.nix` (DOCKER_HOST) |
| `Update:` | In-place mutation or modification | `python.nix` (ruff fix) |
| `Validate:` | Input validation or format check | `python.nix` (ruff lint) |
| `Retry:` | Re-attempt after transient failure | `dotnet.nix`, `frontend.nix` |

For the full standard, see `plan/references/code-commenting/` or the authoritative
XML source at `CommentingRules.xml` in the ReSys.FashionShop guide.

---

## 8. Requirements

| Requirement | Minimum | Notes |
|------------|---------|-------|
| **RAM** | 6 GB | devenv shells are PATH-only (zero overhead); builds consume memory |
| **Disk** | 2 GB free | Nix store for nixpkgs (~1.5 GB on first `nix develop`) |
| **OS** | Any Linux | Tested: Ubuntu, Alpine, NixOS |
| **Arch** | x86_64, aarch64 | Raspberry Pi 4/5 compatible via `system` change in flake.nix |
| **Internet** | Once | Nix fetches packages on first `nix develop` invocation |
