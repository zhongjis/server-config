{
  config,
  lib,
  ...
}: let
  sopsFile = ../../../secrets/freshrss.yaml;
  cfg = config.services.freshrss;
  user = "freshrss";
in {
  # reference from: https://github.com/viperML/neoinfra/blob/master/modules/rss.nix

  sops.secrets = {
    # github - personal
    freshrss_password = {
      inherit sopsFile;
      owner = lib.mkIf cfg.enable user;
    };
  };

  services.freshrss = {
    enable = true;
    passwordFile = config.sops.secrets.freshrss_password.path;
    virtualHost = "rss.zshen.me";
    baseUrl = "https://${cfg.virtualHost}";
    inherit user;
    database = {
      type = "sqlite";
      passFile = config.sops.secrets.freshrss_password.path;
    };

    extensions = [];
  };

  services.nginx = {
    virtualHosts.${cfg.virtualHost} = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
