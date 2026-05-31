# Boundary: .NET profile — builds on core packages + dotnet-sdk_10.
# Context: .NET SDK 10 includes C# compiler, MSBuild, NuGet, dotnet-format.
#          Aspire uses Podman (from core) for testcontainers.
# Contract: pre=dotnet-sdk_10 in nixpkgs, post=dotnet CLI available on PATH
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./devenv.nix { inherit pkgs; }).packages
    ++ [
      dotnet-sdk_10
    ];

  # Context: Set ASPIRE_HINT so .NET Aspire uses Podman, not Docker.
  #          Disable telemetry and logo for CI/headless environments.
  shellHook = ''
    export ASPIRE_HINT="podman"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
