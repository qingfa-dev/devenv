# Boundary: Dotnet profile → imports core profile for shared base tooling.
# Contract: pre=dotnet-sdk_10 is available in nixpkgs, post=ASPIRE_HINT=podman
{ pkgs, ... }: {
  imports = [ ./devenv.nix ];

  packages = with pkgs; [
    dotnet-sdk_10
  ];

  languages.dotnet.enable = true;

  # Context: Restore .NET tools and NuGet packages from lockfiles.
  # AgentHint: do NOT remove --locked-mode — CI enforces lock-file consistency.
  scripts.dotnet-restore.exec = ''
    if [ -f dotnet-tools.json ]; then
      echo "[dotnet] dotnet tool restore..."
      dotnet tool restore
    fi
    if [ -f Directory.Packages.props ]; then
      echo "[dotnet] dotnet restore --locked-mode..."
      dotnet restore --locked-mode
    fi
  '';

  # Context: Applies dotnet-format with verify-no-changes for CI gates.
  scripts.dotnet-format.exec = ''
    dotnet format --verify-no-changes
  '';

  # Context: Aspire uses Podman for container orchestration.
  # Assume: Podman is available via the core profile import.
  enterShell = ''
    export ASPIRE_HINT="podman"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1

    # Retry: dotnet tool restore on first shell entry — skip if already done.
    if [ ! -f "$DEVENV_STATE/dotnet-tools-restored" ]; then
      dotnet tool restore 2>/dev/null && touch "$DEVENV_STATE/dotnet-tools-restored" || true
    fi
  '';
}
