{
  config,
  custHostConfig,
  ...
}: let
  sopsFile = ../secrets/homelab.yaml;
in {
  imports = [
    ./longhorn.nix
    ./nfs.nix
  ];

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
    extraFlags = toString [
      "--write-kubeconfig-mode \"0644\""
      "--disable servicelb"
      "--disable traefik"
    ];
    clusterInit = custHostConfig.isK3sMaster;
    serverAddr =
      if custHostConfig.isK3sMaster
      then "https://${custHostConfig.masterAddr}:6443"
      else "";
  };
}
