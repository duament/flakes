{ config, lib, pkgs, self, ... }:
let
  host = "t430";
  wg0 = self.data.wg0;
  syncthing = self.data.syncthing;
  systemdHarden = self.data.systemdHarden;
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
    "pki/ca" = { };
    "pki/ybk" = { };
    "pki/t430-bundle" = { };
    "pki/t430-pkcs8-key" = { };
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
    sim-pin = { };
    tg-bot-token = { };
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
  networking.nftables.checkRuleset = false;

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
  presets.wireguard.dynamicIPv6.interfaces = [ "wg0" ];

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.193.1";
    mtu = 1412;
    mark = 3;
    routingId = "0x38e45e";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:8445:a7a2:21a2:9279:bd82/128" ];
    table = 20;
    extraIPv4MarkRules = "ip saddr 10.6.7.0/24 accept";
  };
  presets.wireguard.keepAlive.interfaces = [ "warp" ];

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

  services.strongswan-swanctl = {
    enable = true;
    swanctl = {
      connections.iphone = {
        local.t430 = {
          auth = "pubkey";
          id = "t430.rvf6.com";
          certs = [ config.sops.secrets."pki/t430-bundle".path ];
        };
        remote.iphone = {
          auth = "pubkey";
          id = "iphone.rvf6.com";
          cacerts = [ config.sops.secrets."pki/ca".path config.sops.secrets."pki/ybk".path ];
        };
        children.iphone.local_ts = [ "0.0.0.0/0" "::/0" ];
        version = 2;
        pools = [ "iphone_vip" "iphone_vip6" ];
      };
      pools.iphone_vip = {
        addrs = "10.6.6.254/32";
        dns = [ "10.6.6.1" ];
      };
    };
    strongswan.extraConfig = ''
      charon {
        install_routes = no
      }
    '';
  };
  system.activationScripts.strongswan-swanctl-private = lib.stringAfter [ "etc" ] ''
    mkdir -p /etc/swanctl/private
    ln -sf ${config.sops.secrets."pki/t430-pkcs8-key".path} /etc/swanctl/private/t430.key
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

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = syncthing.devices;
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
    serviceConfig = systemdHarden // {
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

  presets.nginx = {
    enable = true;
    useACMEHost = "rvf6.com";
    virtualHosts = {
      "fava.rvf6.com".locations."/" = {
        proxyPass = "http://[::1]:5000";
        extraConfig = "auth_request /vouch/validate;";
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
          extraConfig = "proxy_ssl_trusted_certificate ${cert};";
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

  presets.gammu-smsd = {
    enable = true;
    pinFile = config.sops.secrets.sim-pin.path;
    settings = {
      gammu.Device = "/dev/ttyUSB2";
      smsd.Service = "files";
    };
  };

  systemd.services.gammu-smsd.serviceConfig.LoadCredential = [ "tg-bot-token:${config.sops.secrets.tg-bot-token.path}" ];
  presets.gammu-smsd.settings.smsd.RunOnReceive = toString (pkgs.writers.writePython3 "gammu-smsd-on-receive"
    {
      libraries = [ pkgs.python3Packages.requests ];
    } ''
    import os
    import requests

    cred_dir = os.environ['CREDENTIALS_DIRECTORY']
    with open(os.path.join(cred_dir, 'tg-bot-token')) as f:
        token = f.read()

    text = '''
    n = int(os.environ['SMS_MESSAGES'])
    for i in range(n):
        text += f'class: {os.environ[f"SMS_{i + 1}_CLASS"]}\n'
        text += f'number: {os.environ[f"SMS_{i + 1}_NUMBER"]}\n'
        text += f'text: {os.environ[f"SMS_{i + 1}_TEXT"]}\n\n'

    url = f'https://api.telegram.org/bot{token}/sendMessage'
    data = {
        'chat_id': 96994562,
        'text': text,
    }
    requests.post(url, json=data)
  '');
}
