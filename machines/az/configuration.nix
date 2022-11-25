{ config, lib, pkgs, ... }:
let
  host = "az";
  wg0 = import ../../lib/wg0.nix;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "wireguard_key".owner = "systemd-network";
    "etebase/secret".owner = config.services.etebase-server.user;
    "etebase/postgresql".owner = config.services.etebase-server.user;
    "shadowsocks" = { };
    "miniflux" = { };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = false;

  networking.hostName = host;
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      config.services.shadowsocks.port
    ];
    allowedUDPPorts = [
      wg0.peers.${host}.endpointPort
      config.services.shadowsocks.port
    ];
  };

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      MTUBytes = "1340";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.peers.${host}.endpointPort;
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        AllowedIPs = [ "0.0.0.0/0" "::/0" ];
        PublicKey = wg0.pubkey;
      };
    }];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.syncthing =
    let
      st = import ../../lib/syncthing.nix;
    in
    {
      enable = true;
      openDefaultPorts = true;
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      devices = lib.getAttrs [ "desktop" "xiaoxin" "iphone" ] st.devices;
      folders = {
        keepass = {
          id = "xudus-kdccy";
          label = "KeePass";
          path = "${config.services.syncthing.dataDir}/KeePass";
          devices = [ "desktop" "xiaoxin" "iphone" ];
          versioning = {
            type = "staggered";
            params.cleanInterval = "3600";
            params.maxAge = "15552000";
          };
        };
      };
    };

  services.etebase-server = {
    enable = true;
    unixSocket = "/run/etebase-server/etebase-server";
    settings = {
      global.secret_file = config.sops.secrets."etebase/secret".path;
      allowed_hosts.allowed_host1 = "ete.rvf6.com";
      database = {
        engine = "django.db.backends.postgresql";
        name = "etesync";
        user = "etesync";
        host = "rvfg.postgres.database.azure.com";
        port = 5432;
      };
      database-options = {
        passfile = config.sops.secrets."etebase/postgresql".path;
        sslmode = "verify-full";
        sslrootcert = "/etc/ssl/certs/ca-bundle.crt";
      };
    };
  };
  systemd.services.etebase-server.serviceConfig = import ../../lib/systemd-harden.nix // {
    DynamicUser = false;
    PrivateNetwork = false;
    RuntimeDirectory = "%p";
    StateDirectory = "%p";
  };

  systemd.services.miniflux = {
    description = "Miniflux";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      LISTEN_ADDR = "%t/%p/%p";
      RUN_MIGRATIONS = "1";
      POLLING_FREQUENCY = "30";
      POLLING_PARSING_ERROR_LIMIT = "16";
      HTTP_CLIENT_TIMEOUT = "60";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://rss.rvf6.com/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.rvf6.com/realms/rvfg";
    };
    serviceConfig = import ../../lib/systemd-harden.nix // {
      PrivateNetwork = false;
      Type = "notify";
      RuntimeDirectory = "%p";
      LoadCredential = "miniflux.conf:${config.sops.secrets.miniflux.path}";
      ExecStart = "${pkgs.miniflux}/bin/miniflux -c \${CREDENTIALS_DIRECTORY}/miniflux.conf";
    };
  };

  services.shadowsocks = {
    enable = true;
    fastOpen = false;
    passwordFile = "/run/credentials/shadowsocks-libev.service/shadowsocks";
    port = 13926;
    extraConfig.user = null;
  };
  systemd.services.shadowsocks-libev.serviceConfig = import ../../lib/systemd-harden.nix // {
    PrivateNetwork = false;
    LoadCredential = "shadowsocks:${config.sops.secrets.shadowsocks.path}";
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "le@rvf6.com";
  services.nginx =
    let
      hstsConfig = "add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;";
    in
    {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "ete.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          locations."/" = {
            proxyPass = "http://unix:/run/etebase-server/etebase-server:/";
          };
        };
        "rss.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          locations."/" = {
            proxyPass = "http://unix:/run/miniflux/miniflux:/";
          };
        };
      };
    };
}
