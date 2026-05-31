# Boundary: .NET profile — builds on core + latest stable dotnet-sdk from nixpkgs.
# Context: The .NET SDK includes C#, F#, MSBuild, NuGet, and dotnet-format.
#          Aspire is consumed via NuGet packages (Aspire.Hosting.*) at project build time.
#          No separate Aspire CLI package exists in nixpkgs.
# Contract: pre=dotnet-sdk in nixpkgs-unstable, post=dotnet CLI on PATH
{ pkgs, ... }: {
  packages = with pkgs;
    (import ./core.nix { inherit pkgs; }).packages
    ++ [ dotnet-sdk ];

  shellHook = ''
    export ASPIRE_HINT="podman"
    export ASPIRE_ALLOW_INSECURE_REGISTRIES="true"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
