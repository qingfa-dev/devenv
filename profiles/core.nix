# Context: Core profile — base tooling inherited by every other profile.
#          All tools use unversioned nixpkgs attributes (LTS/stable by default).
#          podman is the container runtime; docker-client provides Docker CLI on Podman socket.
#          gh = GitHub CLI; glab = GitLab CLI.
# Invariant: This module returns ONLY package lists — no language modules or import chains.
{ pkgs, ... }: {
  packages = with pkgs; [
    curl
    docker-client
    editorconfig-checker
    gh
    git
    glab
    gnumake
    jq
    podman
    pre-commit
    yq-go
    fuse-overlayfs
    slirp4netns
  ];
}
