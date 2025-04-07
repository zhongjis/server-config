{pkgs, ...}: let
  # https://nixos.wiki/wiki/Helm_and_Helmfile
  my-kubernetes-helm = with pkgs;
    wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    };

  my-helmfile = pkgs.helmfile-wrapped.override {
    inherit (my-kubernetes-helm) pluginsDir;
  };
in {
  environment.systemPackages = with pkgs; [
    kubectl
    kustomize
    k9s

    my-kubernetes-helm
    my-helmfile
  ];
}
