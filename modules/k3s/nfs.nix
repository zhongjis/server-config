{...}: {
  # NOTE: more see https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/examples/STORAGE.md

  boot.supportedFilesystems = ["nfs"];
  services.rpcbind.enable = true;
}
