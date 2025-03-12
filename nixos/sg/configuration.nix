{ config, lib, ... }:
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
    "miniflux" = { };
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    fsIdentifier = "label";
  };

  networking.hostName = "sg";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "2a02:6ea0:d158::522:5d47/112"
      "167.253.159.33/25"
    ];
    dns = [
      "2606:4700:4700::1111"
      "1.1.1.1"
      "8.8.8.8"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "167.253.159.126";
        GatewayOnLink = true;
      }
      {
        Gateway = "2a02:6ea0:d158::1337";
        GatewayOnLink = true;
      }
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "rss.rvf6.com".locations."/".proxyPass = "http://unix:/run/miniflux/miniflux:/";
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "miniflux" ];

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      LISTEN_ADDR = "%t/%p/%p";
      POLLING_FREQUENCY = "30";
      POLLING_PARSING_ERROR_LIMIT = "16";
      HTTP_CLIENT_TIMEOUT = "60";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://rss.rvf6.com/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.rvf6.com/realms/rvfg";
    };
  };
  systemd.services.miniflux.serviceConfig = {
    LoadCredential = "miniflux.conf:${config.sops.secrets.miniflux.path}";
    ExecStart = lib.mkForce "${lib.getExe config.services.miniflux.package} -c \${CREDENTIALS_DIRECTORY}/miniflux.conf";
    EnvironmentFile = lib.mkForce "";
  };

}
