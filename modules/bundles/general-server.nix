{
  pkgs,
  lib,
  ...
}: {
  myNixOS.sops.enable = lib.mkDefault true;
  myNixOS.nh.enable = lib.mkDefault true;
  myNixOS.podman.enable = lib.mkDefault true;
  myNixOS.docker.enable = lib.mkDefault false;
  myNixOS.nginx.enable = lib.mkDefault true;
  myNixOS.homepage-dashboard.enable = lib.mkDefault false;
  myNixOS.portainer.enable = lib.mkDefault true;
  myNixOS.monitoring.enable = lib.mkDefault true;

  # xremap - bug. when xremap.nix is not enabled. for some reason this have to be set to false
  services.xremap.enable = false;

  environment.systemPackages = with pkgs;
    map lib.lowPrio [
      curl
      git

      bind
      neovim
      unzip
    ];
}
