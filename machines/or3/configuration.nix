{ config, lib, self, ... }:
let
  host = "or3";
  musicDir = "/var/lib/music";
  wg0 = self.data.wg0;
  syncthing = self.data.syncthing;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "cache" = { group = "hydra"; mode = "0440"; };
    "wireguard_key".owner = "systemd-network";
    "keycloak/database" = { };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = host;
  networking.firewall = {
    allowedUDPPorts = [
      wg0.peers.${host}.endpointPort
    ];
  };

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      MTUBytes = "1320";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.peers.${host}.endpointPort;
    };
    wireguardPeers = [
      {
        wireguardPeerConfig = {
          AllowedIPs = [ "0.0.0.0/0" "::/0" ];
          PublicKey = wg0.pubkey;
        };
      }
    ];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
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

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "music.rvf6.com".locations."/".proxyPass = with config.services.navidrome.settings; "http://${Address}:${toString Port}/";
      "hydra.rvf6.com".locations."/".proxyPass = with config.services.hydra; "http://${listenHost}:${toString port}/";
      "cache.rvf6.com".locations."/".proxyPass = with config.services.nix-serve; "http://${bindAddress}:${toString port}/";
      "id.rvf6.com".locations."/".proxyPass = with config.services.keycloak.settings; "http://${http-host}:${toString http-port}/";
    };
  };
}
