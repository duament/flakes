{ config, lib, pkgs, ... }:
let
  host = "t430";
  wg0 = import ../../lib/wg0.nix;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
    swanctl = { };
    warp_key.owner = "systemd-network";
    wireguard_key.owner = "systemd-network";
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    cloudflare = { };
    "vouch-fava/jwt" = { };
    "vouch-fava/client" = { };
    "vouch-luci/jwt" = { };
    "vouch-luci/client" = { };
    luci-nginx-add-auth.owner = config.services.nginx.user;
    uuplugin-uuid = { };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;
  boot.tmpOnTmpfs = false;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = host;
  networking.firewall = {
    checkReversePath = "loose";
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      500 # IPsec
      4500 # IPsec
      wg0.port
    ];
    extraInputRules = ''
      ip protocol { ah, esp } accept
      meta ipsec exists meta l4proto { tcp, udp } th dport 53 accept
      iifname wg0 meta l4proto { tcp, udp } th dport 53 accept
    '';
    extraForwardRules = ''
      meta ipsec exists accept
      rt ipsec exists accept
      iifname wg0 accept
      oifname wg0 accept
    '';
  };
  networking.nftables.mssClamping = true;

  home-manager.users.rvfg = import ./home.nix;

  systemd.network.networks."10-enp1s0" = {
    matchConfig = { PermanentMACAddress = "04:0e:3c:2f:c9:9a"; };
    DHCP = "yes";
    dhcpV6Config = { PrefixDelegationHint = "::/64"; };
  };

  systemd.network.netdevs."25-wg0" = {
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.port;
    };
    wireguardPeers = wg0.peerConfigs;
  };
  systemd.network.networks."25-wg0" = {
    name = "wg0";
    address = [ "${wg0.gateway4}/24" "${wg0.gateway6}/120" ];
    networkConfig = { DHCPPrefixDelegation = true; };
    dhcpPrefixDelegationConfig = { Token = "::1"; };
    linkConfig = { RequiredForOnline = false; };
  };
  services.wireguardDynamicIPv6.interfaces = [ "wg0" ];

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.193.1";
    mtu = 1412;
    mark = 3;
    routingId = "0xac1789";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:8721:a63a:693c:cb0d:6de0/128" ];
    table = 20;
    extraIPv4MarkRules = "ip saddr 10.6.7.0/24 accept";
  };
  services.wireguardKeepAlive.interfaces = [ "warp" ];

  services.smartdns.chinaDns = [ "192.168.2.1" ];
  services.smartdns.settings.bind = [ "[::]:53" ];
  services.smartdns.settings.address = with builtins;
    concatLists
      (attrValues (mapAttrs
        (name: value: [
          "/${name}.rvf6.com/${value.ipv4}"
          "/${name}.rvf6.com/${value.ipv6}"
        ])
        wg0.peers)) ++ [
      "/t430.rvf6.com/${wg0.gateway4}"
      "/t430.rvf6.com/${wg0.gateway6}"
      "/owrt.rvf6.com/192.168.2.1"
      "/rpi3.rvf6.com/192.168.2.7"
      "/fava.rvf6.com/fd64::1"
      "/fava.rvf6.com/-4"
      "/luci.rvf6.com/fd64::1"
      "/luci.rvf6.com/-4"
    ];

  services.uu = {
    enable = true;
    wanName = "10-enp1s0";
    uuidFile = config.sops.secrets.uuplugin-uuid.path;
  };

  services.strongswan-swanctl.enable = true;
  services.strongswan-swanctl.strongswan.extraConfig = ''
    charon {
      install_routes = no
    }
  '';
  environment.etc."swanctl/swanctl.conf".enable = false;
  system.activationScripts.strongswan-swanctl-secret-conf = lib.stringAfter [ "etc" ] ''
    mkdir -p /etc/swanctl
    ln -sf ${config.sops.secrets.swanctl.path} /etc/swanctl/swanctl.conf
  '';
  services.swanctlDynamicIPv6 = {
    enable = true;
    prefixInterface = "wg0";
    suffix = ":1::2";
    poolName = "iphone_vip6";
    extraPools = ''
      iphone_vip {
        addrs = ${wg0.ipv4Pre}254/32
        dns = ${wg0.gateway4}
      }
    '';
  };

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
          devices = [ "desktop" "xiaoxin" "iphone" "az" "nl" ];
          versioning = {
            type = "staggered";
            params.cleanInterval = "3600";
            params.maxAge = "15552000";
          };
        };
        notes = {
          id = "m4f2r-yzqvs";
          label = "notes";
          path = "${config.services.syncthing.dataDir}/notes";
          devices = [ "desktop" "xiaoxin" ];
        };
        session = {
          id = "upou4-bdgln";
          label = "session";
          path = "${config.services.syncthing.dataDir}/session";
          devices = [ "desktop" "xiaoxin" ];
        };
      };
    };

  presets.git.enable = true;
  systemd.services.init-git-beancount = {
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "!/var/lib/git/beancount";
    serviceConfig = {
      Type = "oneshot";
      User = "git";
      Group = "git";
      WorkingDirectory = "/var/lib/git";
      ExecStart = [
        "${pkgs.git}/bin/git init -b main beancount"
        "${pkgs.git}/bin/git config --file ./beancount/.git/config receive.denyCurrentBranch updateInstead"
      ];
    };
  };
  systemd.services.fava = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/var/lib/git/beancount/main.beancount";
    serviceConfig = import ../../lib/systemd-harden.nix // {
      SupplementaryGroups = [ "git" ];
      ExecStart = "${pkgs.fava}/bin/fava -H ::1 -p 5000 /var/lib/git/beancount/main.beancount";
      PrivateNetwork = false;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "le@rvf6.com";
    certs."rvf6.com" = {
      domain = "*.rvf6.com";
      extraDomainNames = [ "rvf6.com" ];
      dnsProvider = "cloudflare";
      credentialsFile = "/dev/null";
      group = "nginx";
    };
  };
  systemd.services."acme-rvf6.com" = {
    environment.CF_DNS_API_TOKEN_FILE = "%d/cloudflare";
    serviceConfig.LoadCredential = "cloudflare:${config.sops.secrets.cloudflare.path}";
  };

  presets.vouch = {
    fava = {
      settings.vouch.port = 2001;
      jwtSecretFile = config.sops.secrets."vouch-fava/jwt".path;
      clientSecretFile = config.sops.secrets."vouch-fava/client".path;
    };

    luci = {
      settings.vouch.port = 2002;
      jwtSecretFile = config.sops.secrets."vouch-luci/jwt".path;
      clientSecretFile = config.sops.secrets."vouch-luci/client".path;
    };
  };

  services.nginx =
    let
      hstsConfig = "add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;";
    in
    {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${host}.rvf6.com" = {
          forceSSL = true;
          useACMEHost = "rvf6.com";
          extraConfig = hstsConfig;
          default = true;
        };
        "fava.rvf6.com" = {
          forceSSL = true;
          useACMEHost = "rvf6.com";
          extraConfig = hstsConfig;
          locations = {
            "/" = {
              proxyPass = "http://[::1]:5000";
              extraConfig = "auth_request /vouch/validate;";
            };
          };
        };
        "luci.rvf6.com" =
          let
            cert = pkgs.writeText "luci-cert" ''
              -----BEGIN CERTIFICATE-----
              MIIB+zCCAaGgAwIBAgIQcFw40pwuLjL+pf2hj/pUeTAKBggqhkjOPQQDAjBfMQsw
              CQYDVQQGEwJaWjESMBAGA1UECAwJU29tZXdoZXJlMRAwDgYDVQQHDAdVbmtub3du
              MRgwFgYDVQQKDA9PcGVuV3J0NDQwNDVhZDAxEDAOBgNVBAMMB09wZW5XcnQwIhgP
              MjAyMjA3MzAxNTEyNTFaGA8yMDI0MDczMDE1MTI1MVowXzELMAkGA1UEBhMCWlox
              EjAQBgNVBAgMCVNvbWV3aGVyZTEQMA4GA1UEBwwHVW5rbm93bjEYMBYGA1UECgwP
              T3BlbldydDQ0MDQ1YWQwMRAwDgYDVQQDDAdPcGVuV3J0MFkwEwYHKoZIzj0CAQYI
              KoZIzj0DAQcDQgAE3JY0GGHiGELBwwauOio7cBa8k6jv6OhUzpFRS09jgSsMZlfs
              KFe/ZRKwgCtWJLBCGjAXJsvNpUDO6Qs3V1z5qaM7MDkwEgYDVR0RBAswCYIHT3Bl
              bldydDAOBgNVHQ8BAf8EBAMCBeAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwCgYIKoZI
              zj0EAwIDSAAwRQIgfkMwUiWA6lvh7sJhTcSqlOPLv9AVpwZ5kmWjcYS0+0ACIQD7
              obh8c9tPl7tIo56av7HYI/PCTK6JIeCvgN7QXmAtJw==
              -----END CERTIFICATE-----
            '';
          in
          {
            forceSSL = true;
            useACMEHost = "rvf6.com";
            extraConfig = ''
              ${hstsConfig}
              proxy_ssl_trusted_certificate ${cert};
            '';
            locations = {
              "= /cgi-bin/luci/" = {
                proxyPass = "https://192.168.2.1";
                extraConfig = ''
                  auth_request /vouch/validate;
                  include ${config.sops.secrets.luci-nginx-add-auth.path};
                '';
              };
              "/" = {
                proxyPass = "https://192.168.2.1";
                extraConfig = "auth_request /vouch/validate;";
              };
            };
          };
      };
    };
}
