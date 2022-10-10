{ config, lib, ... }:
let
  musicDir = "/var/lib/music";
in {
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or3";
  networking.nftables.inputAccept = ''
    tcp dport { 80, 443 } accept
    udp dport { 21027, 22000 } accept comment "syncthing udp"
    tcp dport 22000 accept comment "syncthing tcp"
  '';

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
      };
    };
  };

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.rvf6.com";
    useSubstitutes = true;
    notificationSender = "hydra@rvf6.com";
  };
}
