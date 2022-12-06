{ config, lib, pkgs, self, ... }:
let
  host = "nl";
  wg0 = import ../../lib/wg0.nix;
  flood = pkgs.fetchzip {
    url = "https://github.com/johman10/flood-for-transmission/releases/download/2022-11-27T11-31-25/flood-for-transmission.tar.gz";
    hash = "sha256-fWmiGFq0IZIApzQmZkz7kGTsNGI2i8HJPy9raArQ3GM=";
  };
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "wireguard_key".owner = "systemd-network";
    "shadowsocks" = { };
    "transmission".owner = config.services.transmission.user;
    "basic_auth".owner = config.services.nginx.user;
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    fsIdentifier = "label";
  };
  boot.tmpOnTmpfs = false;

  networking.hostName = host;
  networking.firewall = {
    allowedTCPPorts = [
      25 # SMTP
      80 # HTTP
      443 # HTTPS
      465 # SMTPS
      993 # IMAPS
      config.services.shadowsocks.port
    ];
    allowedUDPPorts = [
      wg0.peers.${host}.endpointPort
      config.services.shadowsocks.port
    ];
  };

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [ "2a04:52c0:106:496f::1/48" "5.255.101.158/24" ];
    gateway = [ "2a04:52c0:106::1" "5.255.101.1" ];
    dns = [ "2a01:6340:1:20:4::10" "2a01:1b0:7999:446::1:4" "185.31.172.240" "89.188.29.4" ];
    networkConfig.IPv6AcceptRA = false;
  };

  systemd.network.netdevs."25-wg0" = {
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      MTUBytes = "1364";
    };
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
    name = "wg0";
    address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.syncthing =
    let
      st = import ../../lib/syncthing.nix;
      devs = [ "desktop" "xiaoxin" "iphone" "az" ];
    in
    {
      enable = true;
      openDefaultPorts = true;
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      devices = lib.getAttrs devs st.devices;
      folders = {
        keepass = {
          id = "xudus-kdccy";
          label = "KeePass";
          path = "${config.services.syncthing.dataDir}/KeePass";
          devices = devs;
          versioning = {
            type = "staggered";
            params.cleanInterval = "3600";
            params.maxAge = "15552000";
          };
        };
      };
    };

  services.shadowsocks = {
    enable = true;
    fastOpen = false;
    passwordFile = "/run/credentials/shadowsocks-libev.service/shadowsocks";
    port = 13926;
    extraConfig.user = null;
  };
  systemd.services.shadowsocks-libev.serviceConfig = import ../../lib/systemd-harden.nix // {
    PrivateNetwork = false;
    LoadCredential = "shadowsocks:${config.sops.secrets.shadowsocks.path}";
  };

  services.transmission = {
    enable = true;
    openPeerPorts = true;
    credentialsFile = config.sops.secrets.transmission.path;
    downloadDirPermissions = "770";
    settings = {
      rpc-authentication-required = true;
      rpc-bind-address = "::1";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      umask = 7; # 007
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "le@rvf6.com";
  services.nginx =
    let
      hstsConfig = "add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;";
    in
    {
      enable = true;
      package = pkgs.nginxMainline;
      additionalModules = with pkgs.nginxModules; [ dav fancyindex ];
      commonHttpConfig = "dav_ext_lock_zone zone=default:10m;";
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "d.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          root = config.services.transmission.settings.download-dir;
          basicAuthFile = config.sops.secrets."basic_auth".path;
          locations."/".extraConfig = ''
            dav_ext_methods PROPFIND OPTIONS;
            fancyindex on;
            fancyindex_localtime on;
            fancyindex_exact_size off;
            fancyindex_header "/Nginx-Fancyindex-Theme/header.html";
            fancyindex_footer "/Nginx-Fancyindex-Theme/footer.html";
          '';
          locations."/Nginx-Fancyindex-Theme/".alias = "${self.inputs.Nginx-Fancyindex-Theme.outPath}/Nginx-Fancyindex/";
        };
        "transmission.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          locations = {
            "/".proxyPass = "http://[::1]:9091/";
            "= /".return = "301 /transmission/web/";
            "/transmission/web/".alias = flood + "/";
          };
        };
      };
    };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ config.services.transmission.group ];
}
