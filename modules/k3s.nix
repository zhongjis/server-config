{
  config,
  customConfig,
  ...
}: let
  sopsFile = ../../secrets/homelab.yaml;
in {
  # NOTE: Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  # NOTE: below is the age key to decrypt
  sops.age.keyFile = "keys.txt";
  sops.secrets = {
    k3s_token = {
      inherit sopsFile;
    };
  };

  # NOTE: k3s config
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets.k3s_token.path;
    extraFlags = toString ([
        "--write-kubeconfig-mode \"0644\""
        "--disable servicelb"
        "--disable traefik"
      ]
      ++ (
        if customConfig.isK3sMaster
        then []
        else [
          "--server https://${customConfig.masterAddr}:6443"
        ]
      ));
    clusterInit = customConfig.isK3sMaster;
  };

  # NOTE: storage - setup iscsi
  services.openiscsi.enable = true;
  services.openiscsi.discoverPortal = "ip:3260";
  services.openiscsi.name = "iqn.2016-04.com.open-iscsi:${customConfig.hostname}";

  # NOTE: storage - setup nfs
  boot.supportedFilesystems = ["nfs"];
}
