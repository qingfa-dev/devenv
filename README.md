# Modular Dev Shells — Zero-Overhead Nix Profiles

> **Version 2.0** · Nix Flakes · Self-contained · 6-8 GB RAM compatible
>
> Deterministic, shell-level development environments. No containers, no daemons,
> no overhead. `nix develop .#profile` — that's it.

---

## Quickstart

```bash
# 1. Install Nix (one-time, any Linux distro)
sh <(curl -L https://nixos.org/nix/install)

# 2. Enable flakes
mkdir -p ~/.config/nix
echo 'extra-experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 3. Enter a profile
cd devenv
make shell-dotnet       # .NET SDK + Aspire
make shell-python       # Python + PyTorch + FastAPI
make shell-frontend     # Node.js + Vue + Angular
make shell-full         # everything combined
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
flake.nix
  ├─ profiles/core.nix          ← no imports (root)
  ├─ profiles/dotnet.nix        ← imports ./core.nix
  ├─ profiles/python.nix        ← imports ./core.nix
  └─ profiles/frontend.nix      ← imports ./core.nix
```

---

## Verification

```bash
make verify                    # 49 assertions (syntax, structure, import chains)
make integration-test          # builds all shells in nixos/nix container (~3 min)
```

**Last integration test results (in nixos/nix container, 220s):**

| Profile | Tools verified |
|---------|---------------|
| core | git, curl, make, podman, docker, gh, glab, editorconfig-checker, jq, yq, pre-commit |
| dotnet | dotnet SDK (latest stable), dotnet --list-sdks |
| python | python3, uv, ruff |
| frontend | node (LTS), pnpm |
| **Total** | **19/19 PASS** |

---

## Makefile Targets

| Target | Action |
|--------|--------|
| `make verify` | Run 49-assertion suite locally |
| `make integration-test` | Build all shells in container, confirm tools work |
| `make shell-default` | Enter core shell |
| `make shell-dotnet` | Enter .NET shell |
| `make shell-python` | Enter Python shell |
| `make shell-frontend` | Enter frontend shell |
| `make shell-full` | Enter combined shell |
| `make clean` | Remove nix artifacts |

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

## FAQ

**Q: Does this create a container?**
No. Nix modifies only PATH. Exit the shell and everything is clean.

**Q: Why not Docker devcontainers?**
A devcontainer image with .NET + Node + Python is 10-15 GB, consuming 3-4 GB RAM idle. Nix shells use 0 extra RAM.

**Q: Can I use Docker CLI instead of Podman?**
Yes. Edit `profiles/core.nix` — change `export DOCKER_HOST` in the shellHook of each profile to point to `docker.sock`.

**Q: How do I pin a specific .NET/Node/Python version?**
Replace the unversioned attribute with a specific one:
- `dotnet-sdk` → `dotnet-sdk_10` (pin .NET 10)
- `nodejs` → `nodejs_22` (pin Node 22 LTS)
- `python3` → `python312` (pin Python 3.12)

**Q: What if nixpkgs doesn't have a package I need?**
Install it via the tool's native package manager inside the shell:
- `.NET`: `dotnet tool install`
- Python: `uv pip install`
- Node: `pnpm add -g`
