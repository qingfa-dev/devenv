# Context: Core profile — base tools inherited by all other profiles.
#          gnumake is GNU Make; podman is the container runtime (preferred over Docker);
#          editorconfig-checker enforces .editorconfig conventions.
# Invariant: This module returns ONLY package lists — no languages.* or devenv imports.
{ pkgs, ... }: {
  packages = with pkgs; [
    git
    curl
    gnumake
    podman
    slirp4netns
    fuse-overlayfs
    editorconfig-checker
    jq
    yq-go
    pre-commit
  ];
}
