{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sops.enable = lib.mkDefault true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.k3s
    pkgs.cifs-utils
    pkgs.nfs-utils
    pkgs.git
    pkgs.neovim
    pkgs.unzip
  ];
}
