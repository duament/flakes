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
  '';

  home-manager.users.rvfg = import ./home.nix;

  users.groups."music" = {};
  systemd.tmpfiles.rules = [ "d ${musicDir} 2770 root music" "a ${musicDir} - - - - d:g::rwX" ];
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
      };
      services = {
        navidrome.loadBalancer = let
          cfg = config.services.navidrome.settings;
        in {
          servers = [ { url = "http://${cfg.Address}:${builtins.toString cfg.Port}"; } ];
        };
      };
    };
  };
}
