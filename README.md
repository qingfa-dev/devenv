# Modular Dev Shells — Zero-Overhead Nix Profiles

> **Version 2.0** · Nix Flakes · Self-contained · 6-8 GB RAM compatible
>
> Deterministic, shell-level development environments. No containers, no daemons,
> no overhead. `nix develop .#profile` — that's it.

---

## Quickstart

This project supports **three entry points** — pick whichever fits your setup:

### Option A: nix develop (flakes, recommended)

```bash
cd devenv
make shell-dotnet       # nix develop .#dotnet
make shell-python       # nix develop .#python
make shell-frontend     # nix develop .#frontend
```

### Option B: nix-shell (classic, no flakes)

```bash
cd devenv
make nix-shell-dotnet   # nix-shell --argstr profile dotnet
make nix-shell-python   # nix-shell --argstr profile python
```

### Option C: devenv.sh

```bash
cd devenv
make devenv-dotnet      # devenv shell --config devenv-dotnet.nix
make devenv-python      # devenv shell --config devenv-python.nix
devenv shell            # devenv.nix = full profile
```

---

## Profiles

| Profile     | Make target         | Tools |
|-------------|--------------------|-------|
| **core**    | `make shell-default` | git, curl, make, podman, docker, gh, glab, jq, yq, editorconfig-checker, pre-commit |
| **dotnet**  | `make shell-dotnet`  | core + .NET SDK (latest stable), Aspire (NuGet) |
| **python**  | `make shell-python`  | core + Python 3 (stable), uv, ruff |
| **frontend**| `make shell-frontend`| core + Node.js (LTS), pnpm, corepack |
| **full**    | `make shell-full`    | everything above |

All profiles use **unversioned nixpkgs attributes** (`dotnet-sdk`, `python3`, `nodejs`) so they automatically track LTS/stable releases when nixpkgs-unstable updates.

---

## File Layout

```
devenv/
├── Makefile                    ← entry point (make verify, make shell-dotnet, etc.)
├── flake.nix                   ← Nix flake — 5 devShells
├── profiles/
│   ├── core.nix                ← base tools (git, podman, docker, gh, glab, etc.)
│   ├── dotnet.nix              ← .NET SDK + Aspire env vars
│   ├── python.nix              ← Python 3 + uv + ruff
│   └── frontend.nix            ← Node.js LTS + pnpm
├── verify.sh                   ← 49-assertion suite (syntax, structure, imports)
├── integration-test.sh         ← real nix develop builds — confirms every tool works
├── README.md
└── .vscode/
    └── extensions.json         ← 25 VS Code extension recommendations
```

### Import chain

```
flake.nix  ─────────  5 devShells via pkgs.mkShell
shell.nix  ─────────  1 derivation via --argstr profile
devenv.nix ─────────  devenv.sh module (full profile)
devenv-*.nix ───────  devenv.sh modules (per-profile)

profiles/
  ├─ core.nix          ← no imports (root)
  ├─ dotnet.nix        ← imports ./core.nix
  ├─ python.nix        ← imports ./core.nix
  └─ frontend.nix      ← imports ./core.nix
```

---

## Makefile Targets

| Target | Entry point | Action |
|--------|------------|--------|
| `make verify` | — | 53+ assertion suite |
| `make integration-test` | — | Build all shells in container |
| `make shell-dotnet` | nix develop | .NET shell (flakes) |
| `make shell-python` | nix develop | Python shell (flakes) |
| `make shell-frontend` | nix develop | Node shell (flakes) |
| `make nix-shell-dotnet` | nix-shell | .NET shell (classic) |
| `make nix-shell-python` | nix-shell | Python shell (classic) |
| `make devenv-dotnet` | devenv.sh | .NET shell (devenv) |
| `make devenv-python` | devenv.sh | Python shell (devenv) |
| `make clean` | — | Remove nix artifacts |

---

## Adding Tools / Customizing

Edit the relevant file in `profiles/`:

```nix
# profiles/core.nix — add a new tool
{ pkgs, ... }: {
  packages = with pkgs; [
    curl
    git
    # Add your tool here:
    ripgrep
    # ...
  ];
}
```

Rebuild: `exit` the shell and re-enter with `make shell-*`.

Search available nixpkgs: https://search.nixos.org/packages

---

## Troubleshooting & FAQ

### Error: `nix: command not found`

Nix is not installed. Install it:

```bash
sh <(curl -L https://nixos.org/nix/install)
# restart your shell, then:
nix --version
```

Docs: https://nixos.org/download.html

### Error: `error: experimental Nix feature 'nix-command' is disabled`

Flakes not enabled. Add to config:

```bash
mkdir -p ~/.config/nix
echo 'extra-experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
# restart shell
```

Docs: https://nixos.wiki/wiki/Flakes

### Error: `error: file 'profiles/core.nix' is not tracked by Git`

Nix flakes require all referenced files to be git-tracked. Run:

```bash
git add profiles/ flake.nix
git commit -m "track profile files"
```

Every new `.nix` file must be committed before `nix develop` can use it.

Docs: `nix flake --help` or https://nixos.wiki/wiki/Flakes#Git_requirements

### Error: `error: undefined variable 'make'` or similar

Package name mismatch in nixpkgs. Run `make integration-test`
to find exact errors. Common fixes:
- `make` → `gnumake`
- `yq` → `yq-go`
- `aspire` — does **not** exist as a standalone nixpkgs package.
  Aspire is consumed via NuGet (`.csproj` PackageReference), not a CLI.
  The dotnet profile sets `ASPIRE_HINT=podman` for container orchestration.

Search packages: https://search.nixos.org/packages

### Error: `error: cannot open connection to podman socket`

Podman daemon is not running. Start it:

```bash
podman system service --time=0 unix:///run/user/$(id -u)/podman/podman.sock &
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
```

Verify: `podman ps` (should return empty table, not an error).

Docs: https://docs.podman.io/en/latest/markdown/podman-system-service.1.html

### Error: `make: *** No rule to make target 'shell-xxx'`

You're not in the `devenv/` directory. Run from the devenv project root:

```bash
cd /path/to/devenv
make shell-dotnet
```

### Error: `warning: Git tree is dirty`

You have uncommitted changes. Nix flakes warn but still work.
To silence: `git add -A && git commit -m "wip"`

### Error: `error: flake 'git+file:///...' does not provide attribute 'devShells...'`

The flake structure is broken. Run `make verify` to diagnose:

```bash
make verify          # checks syntax, imports, devShells count
```

### Error: `copying path from 'https://cache.nixos.org'... FAIL`

Network issue or cache unreachable. Ensure internet access.
Nix needs to download ~1.5 GB on first `nix develop`.

### How do I know what version of a tool I'm getting?

```bash
nix develop .#dotnet --command dotnet --version
nix develop .#python --command python --version
nix develop .#frontend --command node --version
```

Or browse nixpkgs: https://search.nixos.org/packages

### Does this create a container?

No. Nix modifies only PATH. Exit the shell and everything is clean.

### Why not Docker devcontainers?

A devcontainer image with .NET + Node + Python is 10-15 GB, consuming 3-4 GB RAM idle. Nix shells use 0 extra RAM.

### Can I use Docker CLI instead of Podman?

Yes. Edit each profile's `shellHook` in `profiles/` to point DOCKER_HOST at `docker.sock`:

```bash
export DOCKER_HOST="unix:///var/run/docker.sock"
```

### How do I pin a specific .NET/Node/Python version?

Replace the unversioned attribute with a specific one:
- `dotnet-sdk` → `dotnet-sdk_10` (pin .NET 10)
- `nodejs` → `nodejs_22` (pin Node 22 LTS)
- `python3` → `python312` (pin Python 3.12)

### What if nixpkgs doesn't have a package I need?

Install it via the tool's native package manager inside the shell:
- .NET: `dotnet tool install`
- Python: `uv pip install`
- Node: `pnpm add -g`

### How do I find more docs?

| Topic | URL |
|-------|-----|
| Nix install | https://nixos.org/download.html |
| Nix Flakes | https://nixos.wiki/wiki/Flakes |
| nixpkgs search | https://search.nixos.org/packages |
| nix develop manual | https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-develop |
| Podman rootless | https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md |
| .NET Aspire | https://learn.microsoft.com/en-us/dotnet/aspire/get-started/aspire-overview |
| devenv.sh (alternative) | https://devenv.sh |
