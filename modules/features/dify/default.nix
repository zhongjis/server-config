# Auto-generated using compose2nix v0.3.1.
{
  pkgs,
  lib,
  ...
}: let
  sharedApiWorkerEnv =
    import ./shared-api-worker-env.nix;

  difyRepo = pkgs.fetchFromGitHub {
    owner = "langgenius";
    repo = "dify";
    rev = "main";
    sha256 = "sha256-22CBYZC3VjPbesKeXGg+YgrPwAlnS3K+6NNYVvQyBKQ=";
    # sha256 = lib.fakeSha256;
  };
  nginxConfigDir = "${difyRepo}/docker/nginx";

  difyDockerInstall = pkgs.runCommand "dify-install" {} ''
    mkdir -p $out/docker
    cp -r ${difyRepo}/docker/* $out
  '';

  difyLib = "/lib/dify";
in {
  # Install the files to system
  environment.systemPackages = [difyDockerInstall];

  # Create a symlink in /lib/dify
  system.activationScripts.difyInstall =
    /*
    sh
    */
    ''
      # symlink
      mkdir -p ${difyLib}
      for file in $(find ${difyDockerInstall} -type f); do
        relPath=$(realpath --relative-to="${difyDockerInstall}" "$file")
        mkdir -p $(dirname "${difyLib}/$relPath")
        ln -sfn "$file" "${difyLib}/$relPath"
      done

      # Also handle directories that might be empty
      for dir in $(find ${difyDockerInstall} -type d); do
        relPath=$(realpath --relative-to="${difyDockerInstall}" "$dir")
        mkdir -p "${difyLib}/$relPath"
      done

      # add path for volumes
      mkdir -p /lib/dify/volumes/app/storage
      mkdir -p /lib/dify/volumes/db/data
      mkdir -p /lib/dify/volumes/certbot/conf/live
      mkdir -p /lib/dify/volumes/certbot/www
      mkdir -p /lib/dify/volumes/plugin_daemon
      mkdir -p /lib/dify/volumes/redis/data
      mkdir -p /lib/dify/volumes/weaviate
    '';

  # Containers
  virtualisation.oci-containers.containers."dify-api" = {
    image = "langgenius/dify-api:1.1.0";
    environment =
      sharedApiWorkerEnv
      // {
        "MODE" = "api";
        "SENTRY_DSN" = "";
        "SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
        "SENTRY_TRACES_SAMPLE_RATE" = "1.0";
        "PLUGIN_REMOTE_INSTALL_HOST" = "localhost";
        "PLUGIN_REMOTE_INSTALL_PORT" = "5003";
        "PLUGIN_MAX_PACKAGE_SIZE" = "52428800";
        "INNER_API_KEY_FOR_PLUGIN" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      };
    volumes = [
      "${difyLib}/volumes/app/storage:/app/api/storage"
    ];
    dependsOn = [
      "dify-db"
      "dify-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=api"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-api" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-db" = {
    image = "postgres:15-alpine";
    environment = {
      "PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGUSER" = "postgres";
      "POSTGRES_DB" = "dify";
      "POSTGRES_PASSWORD" = "difyai123456";
    };
    volumes = [
      "${difyLib}/volumes/db/data:/var/lib/postgresql/data"
    ];
    cmd = ["postgres" "-c" "max_connections=100" "-c" "shared_buffers=128MB" "-c" "work_mem=4MB" "-c" "maintenance_work_mem=64MB" "-c" "effective_cache_size=4096MB"];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"pg_isready\"]"
      "--health-interval=1s"
      "--health-retries=30"
      "--health-timeout=3s"
      "--network-alias=db"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-db" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-nginx" = {
    image = "nginx:latest";
    environment = {
      "CERTBOT_DOMAIN" = "your_domain.com";
      "NGINX_CLIENT_MAX_BODY_SIZE" = "15M";
      "NGINX_ENABLE_CERTBOT_CHALLENGE" = "false";
      "NGINX_HTTPS_ENABLED" = "false";
      "NGINX_KEEPALIVE_TIMEOUT" = "65";
      "NGINX_PORT" = "80";
      "NGINX_PROXY_READ_TIMEOUT" = "3600s";
      "NGINX_PROXY_SEND_TIMEOUT" = "3600s";
      "NGINX_SERVER_NAME" = "_";
      "NGINX_SSL_CERT_FILENAME" = "dify.crt";
      "NGINX_SSL_CERT_KEY_FILENAME" = "dify.key";
      "NGINX_SSL_PORT" = "443";
      "NGINX_SSL_PROTOCOLS" = "TLSv1.1 TLSv1.2 TLSv1.3";
      "NGINX_WORKER_PROCESSES" = "auto";
    };
    volumes = [
      "${nginxConfigDir}/conf.d:/etc/nginx/conf.d:rw"
      "${nginxConfigDir}/docker-entrypoint.sh:/docker-entrypoint-mount.sh:rw"
      "${nginxConfigDir}/https.conf.template:/etc/nginx/https.conf.template:rw"
      "${nginxConfigDir}/nginx.conf.template:/etc/nginx/nginx.conf.template:rw"
      "${nginxConfigDir}/proxy.conf.template:/etc/nginx/proxy.conf.template:rw"
      "${nginxConfigDir}/ssl:/etc/ssl:rw"
      "${difyLib}/nginx/ssl:/etc/ssl # cert dir (legacy)"
      "${difyLib}/volumes/certbot/conf/live:/etc/letsencrypt/live # cert dir (with certbot container)"
      "${difyLib}/volumes/certbot/conf:/etc/letsencrypt"
      "${difyLib}/volumes/certbot/www:/var/www/html"
    ];
    ports = [
      "8080:80/tcp"
      "8443:443/tcp"
    ];
    dependsOn = [
      "dify-api"
      "dify-web"
    ];
    log-driver = "journald";
    extraOptions = [
      "--entrypoint=[\"sh\", \"-c\", \"cp /docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/\\r$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh\"]"
      "--network-alias=nginx"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-nginx" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-plugin_daemon" = {
    image = "langgenius/dify-plugin-daemon:0.0.5-local";
    environment =
      sharedApiWorkerEnv
      // {
        "DB_DATABASE" = "dify_plugin";
        "SERVER_PORT" = "5002";
        "SERVER_KEY" = "lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi";
        "MAX_PLUGIN_PACKAGE_SIZE" = "52428800";
        "PPROF_ENABLED" = "false";
        "DIFY_INNER_API_KEY" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
        "DIFY_INNER_API_URL" = "http://api:5001";
        "PLUGIN_REMOTE_INSTALLING_HOST" = "0.0.0.0";
        "PLUGIN_REMOTE_INSTALLING_PORT" = "5003";
        "PLUGIN_WORKING_PATH" = "/app/storage/cwd";
        "FORCE_VERIFYING_SIGNATURE" = "true";
        "PYTHON_ENV_INIT_TIMEOUT" = "120";
        "PLUGIN_MAX_EXECUTION_TIMEOUT" = "600";
        "PIP_MIRROR_URL" = "";
      };
    volumes = [
      "${difyLib}/volumes/plugin_daemon:/app/storage"
    ];
    ports = [
      "5003:5003/tcp"
    ];
    dependsOn = [
      "dify-db"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=plugin_daemon"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-plugin_daemon" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-redis" = {
    image = "redis:6-alpine";
    environment = {
      "REDISCLI_AUTH" = "difyai123456";
    };
    volumes = [
      "${difyLib}/volumes/redis/data:/data"
    ];
    cmd = ["redis-server" "--requirepass" "difyai123456"];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"redis-cli\", \"ping\"]"
      "--network-alias=redis"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-sandbox" = {
    image = "langgenius/dify-sandbox:0.2.10";
    environment = {
      "API_KEY" = "dify-sandbox";
      "ENABLE_NETWORK" = "true";
      "GIN_MODE" = "release";
      "HTTPS_PROXY" = "http://ssrf_proxy:3128";
      "HTTP_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_PORT" = "8194";
      "WORKER_TIMEOUT" = "15";
    };
    volumes = [
      "${difyLib}/volumes/sandbox/dependencies:/dependencies"
      "${difyLib}/volumes/sandbox/conf:/conf"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"curl\", \"-f\", \"http://localhost:8194/health\"]"
      "--network-alias=sandbox"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-sandbox" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-ssrf_proxy" = {
    image = "ubuntu/squid:latest";
    environment = {
      "COREDUMP_DIR" = "/var/spool/squid";
      "HTTP_PORT" = "3128";
      "REVERSE_PROXY_PORT" = "8194";
      "SANDBOX_HOST" = "sandbox";
      "SANDBOX_PORT" = "8194";
    };
    volumes = [
      "${difyLib}/ssrf_proxy/squid.conf.template:/etc/squid/squid.conf.template"
      "${difyLib}/ssrf_proxy/docker-entrypoint.sh:/docker-entrypoint-mount.sh"
    ];
    log-driver = "journald";
    extraOptions = [
      "--entrypoint=sh"
      "--network-alias=ssrf_proxy"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
    cmd = [
      "-c"
      "cp /docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/\r$$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh"
    ];
  };
  systemd.services."podman-dify-ssrf_proxy" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-web" = {
    image = "langgenius/dify-web:1.1.0";
    environment = {
      "APP_API_URL" = "";
      "CONSOLE_API_URL" = "";
      "CSP_WHITELIST" = "";
      "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH" = "4000";
      "LOOP_NODE_MAX_COUNT" = "100";
      "MARKETPLACE_API_URL" = "https://marketplace.dify.ai";
      "MARKETPLACE_URL" = "https://marketplace.dify.ai";
      "MAX_TOOLS_NUM" = "10";
      "NEXT_TELEMETRY_DISABLED" = "0";
      "PM2_INSTANCES" = "2";
      "SENTRY_DSN" = "";
      "TEXT_GENERATION_TIMEOUT_MS" = "60000";
      "TOP_K_MAX_VALUE" = "10";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=web"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-web" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-worker" = {
    image = "langgenius/dify-api:1.1.0";
    environment =
      sharedApiWorkerEnv
      // {
        "MODE" = "worker";
        "API_SENTRY_DSN" = "";
        "API_SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
        "API_SENTRY_TRACES_SAMPLE_RATE" = "1.0";
        "PLUGIN_MAX_PACKAGE_SIZE" = "52428800";
        "INNER_API_KEY_FOR_PLUGIN" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      };
    volumes = [
      "${difyLib}/volumes/app/storage:/app/api/storage"
    ];
    dependsOn = [
      "dify-db"
      "dify-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=worker"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-worker" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  virtualisation.oci-containers.containers."dify-weaviate" = {
    image = "semitechnologies/weaviate:1.19.0";
    environment = {
      PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
      QUERY_DEFAULTS_LIMIT = "25";
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "false";
      DEFAULT_VECTORIZER_MODULE = "none";
      CLUSTER_HOSTNAME = "node1";
      AUTHENTICATION_APIKEY_ENABLED = "true";
      AUTHENTICATION_APIKEY_ALLOWED_KEYS = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      AUTHENTICATION_APIKEY_USERS = "hello@dify.ai";
      AUTHORIZATION_ADMINLIST_ENABLED = "true";
      AUTHORIZATION_ADMINLIST_USERS = "hello@dify.ai";
    };
    volumes = [
      "${difyLib}/volumes/weaviate:/var/lib/weaviate"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=weaviate"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-weaviate" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-dify_default" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f dify_default";
    };
    script = ''
      podman network inspect dify_default || podman network create dify_default
    '';
    partOf = ["podman-compose-dify-root.target"];
    wantedBy = ["podman-compose-dify-root.target"];
  };
  systemd.services."podman-network-dify_ssrf_proxy_network" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f dify_ssrf_proxy_network";
    };
    script = ''
      podman network inspect dify_ssrf_proxy_network || podman network create dify_ssrf_proxy_network --driver=bridge --internal
    '';
    partOf = ["podman-compose-dify-root.target"];
    wantedBy = ["podman-compose-dify-root.target"];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-dify-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = ["multi-user.target"];
  };

  services.nginx = {
    virtualHosts."dify.zshen.me" = {
      serverName = "dify.zshen.me";
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };
}
