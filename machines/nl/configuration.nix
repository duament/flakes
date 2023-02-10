{ config, lib, mypkgs, pkgs, ... }:
let
  host = "nl";
  wg0 = import ../../lib/wg0.nix;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "wireguard_key".owner = "systemd-network";
    "shadowsocks" = { };
    "transmission".owner = config.services.nginx.user;
    "basic_auth".owner = config.services.nginx.user;
    "vouch-bt/jwt" = { };
    "vouch-bt/client" = { };
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
      MTUBytes = "1320";
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
    in
    {
      enable = true;
      openDefaultPorts = true;
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      devices = st.devices;
      folders = {
        keepass = {
          id = "xudus-kdccy";
          label = "KeePass";
          path = "${config.services.syncthing.dataDir}/KeePass";
          devices = [ "desktop" "xiaoxin" "iphone" "t430" "az" ];
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
    downloadDirPermissions = "770";
    settings = {
      rpc-authentication-required = false;
      rpc-bind-address = "::1";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      umask = 7; # 007
    };
  };

  presets.vouch.bt = {
    settings.vouch.port = 2001;
    jwtSecretFile = config.sops.secrets."vouch-bt/jwt".path;
    clientSecretFile = config.sops.secrets."vouch-bt/client".path;
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
      additionalModules = with pkgs.nginxModules; [ fancyindex ];
      commonHttpConfig = "dav_ext_lock_zone zone=default:10m;";
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${host}.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          default = true;
        };
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
          locations."/Nginx-Fancyindex-Theme/".alias = "${mypkgs.Nginx-Fancyindex-Theme}/share/Nginx-Fancyindex/";
        };
        "transmission.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          basicAuthFile = config.sops.secrets.transmission.path;
          locations = {
            "/".proxyPass = "http://[::1]:9091/";
          };
        };
        "bt.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          locations = {
            "= /".return = "301 /flood/";
            "/flood/" = {
              alias = "${mypkgs.flood-for-transmission}/share/flood-for-transmission/";
              extraConfig = "auth_request /vouch/validate;";
            };
            "/twc/" = {
              alias = "${mypkgs.transmission-web-control}/share/transmission-web-control/";
              extraConfig = "auth_request /vouch/validate;";
            };
            "/og/" = {
              proxyPass = "http://[::1]:9091/transmission/web/";
              extraConfig = "auth_request /vouch/validate;";
            };
            "/rpc" = {
              proxyPass = "http://[::1]:9091/transmission/rpc";
              extraConfig = "auth_request /vouch/validate;";
            };
          };
        };
      };
    };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ config.services.transmission.group ];
}
