{ config, lib, pkgs, self, ... }:
let
  systemdHarden = self.data.systemdHarden;
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

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

  networking.hostName = "az";
  networking.firewall = {
    allowedTCPPorts = [
      config.services.shadowsocks.port
    ];
    allowedUDPPorts = [
      config.services.shadowsocks.port
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1340;
  };

  home-manager.users.rvfg = import ./home.nix;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = self.data.syncthing.devices;
    folders = lib.getAttrs [ "keepass" ] self.data.syncthing.folders;
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
  systemd.services.etebase-server.serviceConfig = systemdHarden // {
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
    serviceConfig = systemdHarden // {
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
  systemd.services.shadowsocks-libev.serviceConfig = systemdHarden // {
    PrivateNetwork = false;
    LoadCredential = "shadowsocks:${config.sops.secrets.shadowsocks.path}";
  };

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "ete.rvf6.com".locations."/".proxyPass = "http://unix:/run/etebase-server/etebase-server:/";
      "rss.rvf6.com".locations."/".proxyPass = "http://unix:/run/miniflux/miniflux:/";
    };
  };
}
