{pkgs, ...}: {
  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      dates = "weekly";
      flags = [
        "--filter=until=24h"
        "--filter=label!=important"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.oci-containers.backend = "docker";
}
