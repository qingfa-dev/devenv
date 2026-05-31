# Context: Base profile shared by all devShell profiles.
# Invariant: Must not import other modules — it is the root of the import chain.
# Invariant: Every profile inherits podman, git, curl, make, and editorconfig-checker.
{ pkgs, ... }: {
  packages = with pkgs; [
    git
    curl
    make
    podman
    slirp4netns
    fuse-overlayfs
    editorconfig-checker
    jq
    yq
    pre-commit
  ];

  languages.bash.enable = true;

  # Compute: DOCKER_HOST via podman socket for Docker CLI compatibility
  enterShell = ''
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export CONTAINER="podman"
  '';
}
