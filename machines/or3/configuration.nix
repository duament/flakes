{ config, lib, self, ... }:
let
  host = "or3";
  musicDir = "/var/lib/music";
  syncthing = self.data.syncthing;
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "cache" = { group = "hydra"; mode = "0440"; };
    "wireguard_key".owner = "systemd-network";
    "keycloak/database" = { };
    "vouch-prom/jwt" = { };
    "vouch-prom/client" = { };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = host;
  networking.hosts = { "fd64::1" = [ "t430.rvf6.com" ]; };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  home-manager.users.rvfg = import ./home.nix;

  users.groups."music" = { };
  systemd.tmpfiles.rules = [ "d ${musicDir} 2770 root music" "a ${musicDir} - - - - d:g::rwx" ];
  systemd.services.syncthing.serviceConfig.SupplementaryGroups = [ "music" ];
  systemd.services.navidrome.serviceConfig.SupplementaryGroups = [ "music" ];

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = syncthing.devices;
    folders = {
      music = {
        id = "hngav-zprin";
        label = "Music";
        path = musicDir;
        devices = [ "desktop" "xiaoxin" ];
      };
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
    enable = true;
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
      "id.rvf6.com".locations."/".proxyPass = with config.services.keycloak.settings; "http://${http-host}:${toString http-port}/";
      "prom.rvf6.com".locations."/" = {
        proxyPass = with config.services.prometheus; "http://${listenAddress}:${toString port}/";
        extraConfig = "auth_request /vouch/validate;";
      };
    };
  };
}
