{
  config,
  pkgs,
  custHostConfig,
  ...
}: {
  # NOTE: more see https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/examples/STORAGE.md
  environment.systemPackages = with pkgs; [nfs-utils];

  services.openiscsi = {
    enable = true;
    discoverPortal = "ip:3260";
    name = "iqn.2016-04.com.open-iscsi:${custHostConfig.hostName}";
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
}
