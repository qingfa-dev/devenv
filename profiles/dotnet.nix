# Boundary: .NET profile — builds on core + dotnet-sdk_10.
# Context: dotnet-sdk_10 = .NET 10.0.300 (latest, used by resys.fashion).
#          dotnet-sdk   = .NET 8 (LTS) — use this for LTS projects.
#          dotnet-sdk_9 = .NET 9 (STS) — use this for .NET 9 projects.
#          Aspire is consumed via NuGet packages (Aspire.Hosting.*) at build time.
# Contract: pre=dotnet-sdk_10 in nixpkgs-unstable, post=dotnet CLI on PATH
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./core.nix { inherit pkgs; }).packages
    ++ [ dotnet-sdk_10 ];

  shellHook = ''
    export ASPIRE_HINT="podman"
    export ASPIRE_ALLOW_INSECURE_REGISTRIES="true"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
