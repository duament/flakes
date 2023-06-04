{ config, lib, self, ... }:
let
  musicDir = "/var/lib/music";
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "cache" = { };
    "wireguard_key".owner = "systemd-network";
    "keycloak/database" = { };
    "vouch-prom/jwt" = { };
    "vouch-prom/client" = { };
    "grafana/oidc" = { };
    "grafana/secret_key" = { };
    mastodon.owner = "mastodon";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or3";
  networking.hosts = { "fd64::1" = [ "t430.rvf6.com" ]; };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  home-manager.users.rvfg = import ./home.nix;

  users.groups."music" = { };
  systemd.tmpfiles.rules = [ "d ${musicDir} 2770 root music -" "a ${musicDir} - - - - d:g::rwx" ];
  systemd.services.syncthing.serviceConfig.SupplementaryGroups = [ "music" ];
  systemd.services.navidrome.serviceConfig.SupplementaryGroups = [ "music" ];

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = self.data.syncthing.devices;
    folders = lib.recursiveUpdate (lib.getAttrs [ "music" ] self.data.syncthing.folders) {
      music.path = musicDir;
    };
  };

  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = musicDir;
      Address = "[::1]";
      Port = 4533;
    };
  };

  services.hydra = {
    enable = false;
    listenHost = "localhost";
    hydraURL = "https://hydra.rvf6.com";
    useSubstitutes = true;
    notificationSender = "hydra@rvf6.com";
    extraConfig = ''
      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>
    '';
  };
  nix.settings = { allowed-uris = [ "https://github.com" "https://gitlab.com" "https://git.sr.ht" ]; };
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services.nix-serve = {
    enable = true;
    bindAddress = "localhost";
    port = 5000;
    secretKeyFile = config.sops.secrets.cache.path;
  };

  services.keycloak = {
    enable = true;
    database.passwordFile = config.sops.secrets."keycloak/database".path;
    settings = {
      hostname = "id.rvf6.com";
      hostname-strict-backchannel = true;
      http-host = "[::1]";
      http-port = 6000;
      proxy = "edge";
    };
  };
  systemd.services.keycloak.environment.JAVA_OPTS_APPEND = "-Djava.net.preferIPv4Stack=false -Djava.net.preferIPv6Addresses=true";

  services.prometheus = {
    enable = true;
    listenAddress = "[::1]";
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "metrics";
        scheme = "https";
        static_configs = [{ targets = [ "t430.rvf6.com" "nl.rvf6.com" "az.rvf6.com" "or2.rvf6.com" "or3.rvf6.com" ]; }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    provision = {
      enable = true;
      dashboards.settings.providers = [
      ];
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = with config.services.prometheus; "http://${listenAddress}:${toString port}";
        }
      ];
    };
    settings = {
      security = {
        admin_email = "i@rvf6.com";
        secret_key = "$__file{/run/credentials/grafana.service/secret_key}";
      };
      server = {
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
        root_url = "https://graf.rvf6.com";
      };
      auth = {
        login_maximum_inactive_lifetime_duration = "1h";
        disable_login_form = true;
      };
      "auth.generic_oauth" = {
        name = "Keycloak";
        enabled = true;
        allow_sign_up = false;
        auto_login = true;
        client_id = "graf";
        client_secret = "$__file{/run/credentials/grafana.service/oidc}";
        scopes = "openid profile email";
        auth_url = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/auth";
        token_url = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/token";
        api_url = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/userinfo";
        signout_redirect_url = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/logout";
        tls_skip_verify_insecure = false;
        tls_client_ca = "/etc/ssl/certs/ca-bundle.crt";
        use_pkce = true;
      };
      users.default_theme = "system";
    };
  };
  systemd.services.grafana.serviceConfig.LoadCredential = [
    "oidc:${config.sops.secrets."grafana/oidc".path}"
    "secret_key:${config.sops.secrets."grafana/secret_key".path}"
  ];

  services.mastodon = {
    enable = true;
    configureNginx = true;
    localDomain = "m.rvf6.com";
    smtp = {
      createLocally = false;
      fromAddress = "mastodon@rvf6.com";
    };
    extraConfig = {
      OIDC_ENABLED = "true";
      OIDC_DISPLAY_NAME = "Keycloak";
      OIDC_DISCOVERY = "true";
      OIDC_ISSUER = "https://id.rvf6.com/realms/rvfg";
      OIDC_AUTH_ENDPOINT = "https://id.rvf6.com/realms/rvfg/.well-known/openid-configuration";
      OIDC_SCOPE = "openid,profile,email";
      OIDC_UID_FIELD = "preferred_username";
      OIDC_CLIENT_ID = "mastodon";
      OIDC_REDIRECT_URI = "https://m.rvf6.com/auth/auth/openid_connect/callback";
      OIDC_SECURITY_ASSUME_EMAIL_IS_VERIFIED = "true";
    };
    extraEnvFiles = [ config.sops.secrets.mastodon.path ];
  };

  presets.restic = {
    enable = true;
    enablePg = true;
    exclude = [
      "/persist/var/lib/mastodon/public-system/cache"
      "/persist/var/lib/music"
      "/persist/var/lib/prometheus2"
    ];
  };

  presets.vouch.prom = {
    settings.vouch.port = 2001;
    jwtSecretFile = config.sops.secrets."vouch-prom/jwt".path;
    clientSecretFile = config.sops.secrets."vouch-prom/client".path;
  };

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "music.rvf6.com".locations."/".proxyPass = with config.services.navidrome.settings; "http://${Address}:${toString Port}/";
      "hydra.rvf6.com".locations."/".proxyPass = with config.services.hydra; "http://${listenHost}:${toString port}/";
      "cache.rvf6.com".locations."/".proxyPass = with config.services.nix-serve; "http://${bindAddress}:${toString port}/";
      "id.rvf6.com".locations."/" = {
        proxyPass = with config.services.keycloak.settings; "http://${http-host}:${toString http-port}/";
        extraConfig = "proxy_buffer_size 128k";
      };
      "prom.rvf6.com".locations."/".proxyPass = with config.services.prometheus; "http://${listenAddress}:${toString port}/";
      "graf.rvf6.com".locations."/".proxyPass = "http://unix:${config.services.grafana.settings.server.socket}:/";
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];
}
