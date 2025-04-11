{
  modulesPath,
  lib,
  pkgs,
  config,
  custHostConfig,
  ...
}: let
  sopsFile = ../../secrets/homelab.yaml;
in {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      (import ./disko-config.nix {device = "/dev/sda";})

      ../../modules
      ../../modules/k3s.nix
      ../../modules/sops.nix
    ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration-${custHostConfig.hostName}.nix) ./hardware-configuration-${custHostConfig.hostName}.nix;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  networking.hostName = custHostConfig.hostName;
  networking.firewall.enable = false;
  # NOTE: for more defined firewall configurations
  # https://docs.k3s.io/installation/requirements#inbound-rules-for-k3s-nodes
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [2379 2380 6443 10250 5001 6443];
  #   allowedUDPPorts = [8472 51820 51821];
  # };

  time.timeZone = "America/Denver";

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];


  system.stateVersion = "24.05";
}
