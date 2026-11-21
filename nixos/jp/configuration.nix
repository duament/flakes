{ config, lib, ... }:
let
  inherit (lib) mkForce;
in
{

  imports = [
    ./swanctl.nix
  ];

  presets.nogui.enable = true;
  presets.disko.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/jp-bundle" = { };
    "pki/jp-pkcs8-key" = { };
    pocket-id-encryption-key.owner = config.services.pocket-id.user;
    "miniflux/admin_username" = { };
    "miniflux/admin_password" = { };
    "miniflux/oauth2_client_id" = { };
    "miniflux/oauth2_client_secret" = { };
  };

  networking.hostName = "jp";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "2403:71c0:2000:133b::a/64"
      "172.93.220.78/24"
    ];
    dns = [
      "8.8.8.8"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2403:71c0:2000::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "172.93.220.1";
        GatewayOnLink = true;
      }
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  networking.nftables.masquerade = [ "iifname gre-jp" ];
  networking.firewall = {
    extraInputRules = ''
      iifname wg-jp ip protocol gre accept
    '';
    extraForwardRules = ''
      iifname gre-jp accept
    '';
  };
  systemd.network.netdevs."30-gre-jp" = {
    netdevConfig = {
      Name = "gre-jp";
      Kind = "gre";
    };
    tunnelConfig = {
      Local = "10.6.18.29";
      Remote = "10.5.0.50";
      Independent = true;
    };
  };
  systemd.network.networks."25-xfrm-jp3-jp".routes = [ { Destination = "10.5.0.48/30"; } ];
  systemd.network.networks."30-gre-jp" = {
    name = "gre-jp";
    address = [
      "10.5.1.1/30"
      "fdc1::1/126"
    ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "pocket-id";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "pocket-id" ];
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://pocket-id.rvf6.com";
      ENCRYPTION_KEY_FILE = config.sops.secrets.pocket-id-encryption-key.path;
      ALLOW_INSECURE_CALLBACK_URLS = false;
      DB_CONNECTION_STRING = "postgres:///pocket-id";
      UNIX_SOCKET = "/run/pocket-id/sock";
      UNIX_SOCKET_MODE = "0660";
      ANALYTICS_DISABLED = true;
      VERSION_CHECK_DISABLED = true;
    };
  };
  systemd.services.pocket-id = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
    serviceConfig = {
      RuntimeDirectory = "pocket-id";
      RuntimeDirectoryMode = "0750";
    };
  };

  services.miniflux = {
    enable = true;
    config = {
      CREATE_ADMIN = false; # workaround assertions
      LISTEN_ADDR = "%t/%p/%p";
      ADMIN_USERNAME_FILE = "%d/admin_username";
      ADMIN_PASSWORD_FILE = "%d/admin_password";
      POLLING_FREQUENCY = "30";
      POLLING_PARSING_ERROR_LIMIT = "16";
      HTTP_CLIENT_TIMEOUT = "60";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID_FILE = "%d/oauth2_client_id";
      OAUTH2_CLIENT_SECRET_FILE = "%d/oauth2_client_secret";
      OAUTH2_REDIRECT_URL = "https://rss.rvf6.com/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://pocket-id.rvf6.com";
    };
  };
  systemd.services.miniflux = {
    before = [ "nginx.service" ];
    environment.CREATE_ADMIN = mkForce "1";
    serviceConfig.LoadCredential = [
      "admin_username:${config.sops.secrets."miniflux/admin_username".path}"
      "admin_password:${config.sops.secrets."miniflux/admin_password".path}"
      "oauth2_client_id:${config.sops.secrets."miniflux/oauth2_client_id".path}"
      "oauth2_client_secret:${config.sops.secrets."miniflux/oauth2_client_secret".path}"
    ];
  };

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "pocket-id.rvf6.com".locations."/".proxyPass =
        "http://unix:${config.services.pocket-id.settings.UNIX_SOCKET}:/";
      "rss.rvf6.com".locations."/".proxyPass = "http://unix:/run/miniflux/miniflux:/";
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    config.services.pocket-id.group
    "miniflux"
  ];

}
