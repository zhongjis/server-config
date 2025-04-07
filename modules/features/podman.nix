{
  pkgs,
  lib,
  config,
  ...
}: let
  dockerCfg = config.virtualisation.docker;
in {
  virtualisation.libvirtd.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat =
      if dockerCfg.enable
      then false
      else true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [
        "--filter=until=24h"
        "--filter=label!=important"
      ];
    };
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [53];

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  virtualisation.oci-containers.backend = lib.mkForce "podman";
}
