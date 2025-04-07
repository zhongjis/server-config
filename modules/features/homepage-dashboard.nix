{config, ...}: let
  cfg = config.services.homepage-dashboard;
in {
  services.homepage-dashboard = {
    enable = true;
  };

  services.nginx = {
    # placeholder for now
    virtualHosts."zshen.me" = {
      default = true;
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8082";
        recommendedProxySettings = true;
      };
    };

    virtualHosts."home.zshen.me" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8082";
        recommendedProxySettings = true;
      };
    };
  };
}
