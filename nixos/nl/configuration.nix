{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  ssPort = 13926;
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

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

  networking.hostName = "nl";
  networking.firewall = {
    allowedTCPPorts = [
      25 # SMTP
      465 # SMTPS
      993 # IMAPS
      ssPort
    ];
    allowedUDPPorts = [
      ssPort
    ];
  };

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "2a04:52c0:106:496f::1/48"
      "5.255.101.158/24"
    ];
    gateway = [
      "2a04:52c0:106::1"
      "5.255.101.1"
    ];
    dns = [
      "2a01:6340:1:20:4::10"
      "2a01:1b0:7999:446::1:4"
      "185.31.172.240"
      "89.188.29.4"
    ];
    networkConfig.IPv6AcceptRA = false;
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "git"
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    settings = {
      devices = self.data.syncthing.devices;
      folders = lib.getAttrs [ "keepass" ] self.data.syncthing.folders;
    };
  };

  presets.shadowsocks = {
    enable = true;
    settings = {
      server = "::";
      server_port = ssPort;
      method = "chacha20-ietf-poly1305";
    };
    passwordFile = config.sops.secrets.shadowsocks.path;
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
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

  presets.restic = {
    enable = true;
    exclude = [
      "/persist/var/lib/transmission"
    ];
  };

  presets.vouch.bt = {
    settings.vouch.port = 2001;
    jwtSecretFile = config.sops.secrets."vouch-bt/jwt".path;
    clientSecretFile = config.sops.secrets."vouch-bt/client".path;
    authLocations = [
      "/flood/"
      "/twc/"
      "/tc/"
      "/og/"
      "/rpc"
    ];
  };

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "d.rvf6.com" = {
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
        locations."/Nginx-Fancyindex-Theme/".alias =
          "${pkgs.Nginx-Fancyindex-Theme}/share/Nginx-Fancyindex/";
      };
      "transmission.rvf6.com" = {
        basicAuthFile = config.sops.secrets.transmission.path;
        locations = {
          "/".proxyPass = "http://[::1]:9091/";
        };
      };
      "bt.rvf6.com" = {
        locations = {
          "= /".return = "301 /flood/";
          "/flood/".alias = "${pkgs.flood-for-transmission}/share/flood-for-transmission/";
          "/twc/".alias = "${pkgs.transmission-web-control}/share/transmission-web-control/";
          "/tc/".alias = "${pkgs.transmission-client}/share/transmission-client/";
          "/og/".proxyPass = "http://[::1]:9091/transmission/web/";
          "/rpc".proxyPass = "http://[::1]:9091/transmission/rpc";
        };
      };
    };
  };
  services.nginx = {
    additionalModules = with pkgs.nginxModules; [ fancyindex ];
    commonHttpConfig = "dav_ext_lock_zone zone=default:10m;";
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ config.services.transmission.group ];
}
