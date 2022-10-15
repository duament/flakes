{ config, lib, ... }:
let
  host = "az";
  wg0 = import ../../lib/wg0.nix;
in {
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "wireguard_key".owner = "systemd-network";
    "etebase/secret".owner = config.services.etebase-server.user;
    "etebase/postgresql".owner = config.services.etebase-server.user;
    "shadowsocks" = {};
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = host;
  networking.nftables.inputAccept = ''
    tcp dport { 80, 443 } accept
    udp dport ${builtins.toString wg0.peers.${host}.endpointPort} accept comment "wireguard"
    udp dport { 21027, 22000 } accept comment "syncthing udp"
    tcp dport 22000 accept comment "syncthing tcp"
    meta l4proto { tcp, udp } th dport ${builtins.toString config.services.shadowsocks.port} accept comment "shadowsocks"
  '';

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
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
    address = [ "${wg0.peers.${host}.ip}/${builtins.toString wg0.mask}" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.syncthing = let
    st = import ../../lib/syncthing.nix;
  in {
    enable = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = lib.getAttrs [ "desktop" "xiaoxin" ] st.devices;
    folders = {
      keepass = {
        id = "xudus-kdccy";
        label = "KeePass";
        path = "${config.services.syncthing.dataDir}/KeePass";
        devices = [ "desktop" "xiaoxin" ];
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
      database-options.passfile = config.sops.secrets."etebase/postgresql".path;
    };
  };

  services.shadowsocks = {
    enable = true;
    fastOpen = false;
    passwordFile = config.sops.secrets.shadowsocks.path;
    port = 13926;
  };

  services.traefik = {
    enable = true;
    dynamicConfigOptions.http = {
      routers = {
        ete = {
          rule = "Host(`ete.rvf6.com`)";
          service = "ete";
        };
      };
      services = {
        ete.loadBalancer = let
          cfg = config.services.etebase-server;
        in {
          servers = [ { url = "http://127.0.0.1:${builtins.toString cfg.port}"; } ];
        };
      };
    };
  };
}
