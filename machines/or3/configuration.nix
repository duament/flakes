{ config, lib, ... }:
let
  musicDir = "/var/lib/music";
  wg0 = import ../../lib/wg0.nix;
in {
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "cache" = { group = "hydra"; mode = "0440"; };
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or3";
  networking.nftables.inputAccept = ''
    tcp dport { 80, 443 } accept
    udp dport ${builtins.toString wg0.peers.or3.endpointPort} accept comment "wireguard"
    udp dport { 21027, 22000 } accept comment "syncthing udp"
    tcp dport 22000 accept comment "syncthing tcp"
  '';

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.peers.or3.endpointPort;
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
    address = [ "${wg0.peers.or3.ipv4}/24" "${wg0.peers.or3.ipv6}/120" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  users.groups."music" = {};
  systemd.tmpfiles.rules = [ "d ${musicDir} 2770 root music" "a ${musicDir} - - - - d:g::rwx" ];
  systemd.services.syncthing.serviceConfig.SupplementaryGroups = [ "music" ];
  systemd.services.navidrome.serviceConfig.SupplementaryGroups = [ "music" ];

  services.syncthing = let
    st = import ../../lib/syncthing.nix;
  in {
    enable = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = lib.getAttrs [ "desktop" "xiaoxin" ] st.devices;
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
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.rvf6.com";
    useSubstitutes = true;
    notificationSender = "hydra@rvf6.com";
    extraConfig = ''
      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>
    '';
  };
  nix.settings = { allowed-uris = [ "https://github.com" "https://gitlab.com" ]; };
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 5000;
    secretKeyFile = config.sops.secrets.cache.path;
  };

  services.traefik = {
    enable = true;
    dynamicConfigOptions.http = {
      routers = {
        navidrome = {
          rule = "Host(`music.rvf6.com`)";
          service = "navidrome";
        };
        hydra = {
          rule = "Host(`hydra.rvf6.com`)";
          service = "hydra";
        };
        cache = {
          rule = "Host(`cache.rvf6.com`)";
          service = "cache";
        };
      };
      services = {
        navidrome.loadBalancer = let
          cfg = config.services.navidrome.settings;
        in {
          servers = [ { url = "http://${cfg.Address}:${builtins.toString cfg.Port}"; } ];
        };
        hydra.loadBalancer = let
          cfg = config.services.hydra;
        in {
          servers = [ { url = "http://${cfg.listenHost}:${builtins.toString cfg.port}"; } ];
        };
        cache.loadBalancer = let
          cfg = config.services.nix-serve;
        in {
          servers = [ { url = "http://${cfg.bindAddress}:${builtins.toString cfg.port}"; } ];
        };
      };
    };
  };
}
