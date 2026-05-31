# Boundary: Python profile → imports core profile for shared base tooling.
# Contract: pre=python312 and uv are in nixpkgs, post=fastapi + torch available via uv pip
# Context: PyTorch CPU-only to keep image size small for 6-8GB constrained machines.
#          Use install-torch helper for initial setup; subsequent runs use cached wheels.
{ pkgs, ... }: {
  imports = [ ./devenv.nix ];

  packages = with pkgs; [
    uv
    python312
  ];

  # Context: Enables Python 3.12 with uv as the package manager.
  #          uv replaces pip + venv with a single toolchain (10-100x faster).
  languages.python = {
    enable = true;
    version = "3.12";
    uv.enable = true;
  };

  # Validate: ruff checks code formatting and lint rules in one pass.
  scripts.python-lint.exec = ''
    ruff check .
  '';

  # Update: Apply auto-fixes for ruff lint violations + format in one pass.
  scripts.python-fix.exec = ''
    ruff check --fix . && ruff format .
  '';

  # Context: Installs PyTorch CPU-only (no CUDA) to reduce disk/RAM footprint.
  #          Includes FastAPI, uvicorn, pydantic, httpx, pytest as common deps.
  # AgentHint: Add additional pip packages above, not in a separate install step.
  scripts.install-torch.exec = ''
    uv pip install torch --index-url https://download.pytorch.org/whl/cpu \
      fastapi uvicorn[standard] pydantic httpx pytest
  '';

  # Context: UV_LINK_MODE=copy avoids symlink issues in Nix shells.
  #          Alias pip to uv pip for muscle-memory compatibility.
  enterShell = ''
    export UV_LINK_MODE=copy
    alias pip="uv pip"
  '';
}
