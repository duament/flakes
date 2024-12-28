{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  wg0 = self.data.wg0;
  systemdHarden = self.data.systemdHarden;
  nonCNMark = 2;
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
    duckdns = { };
    wireguard_key.owner = "systemd-network";
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    cloudflare = { };
    "vouch-fava/jwt" = { };
    "vouch-fava/client" = { };
    "vouch-luci/jwt" = { };
    "vouch-luci/client" = { };
    luci-nginx-add-auth.owner = config.services.nginx.user;
    sim-pin = { };
    tg-bot-token = { };
    "home-assistant-secrets.yaml" = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };
    "tuic/uuid" = { };
    "tuic/password" = { };
    "tuic/tls_cert" = { };
    "tuic/tls_key" = { };
    "tuic/ech_key" = { };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = "t430";
  networking.firewall = {
    allowedUDPPorts = [
      11113
    ];
    checkReversePath = "loose";
    extraInputRules = ''
      iifname { wg-*, internet } meta l4proto { tcp, udp } th dport 53 accept
      ip saddr { 10.6.0.0/16, ${self.data.tailscale.ipv4} } meta l4proto { tcp, udp } th dport 53 accept
      ip6 saddr { 2606:4700:110:8395::/120, ${self.data.tailscale.ipv6} } meta l4proto { tcp, udp } th dport 53 accept
      iifname internet udp dport 67 accept
      iifname { wg-*, internet } tcp dport 8000 accept
      ip saddr { 10.6.0.0/16, ${self.data.tailscale.ipv4} } tcp dport 8000 accept
      ip6 saddr { 2606:4700:110:8395::/120, ${self.data.tailscale.ipv6} } tcp dport 8000 accept
    '';
    extraForwardRules = ''
      iifname { wg-*, internet } accept
      oifname { wg-*, internet } accept
      ip saddr { ${self.data.tailscale.ipv4} } accept
      ip6 saddr { ${self.data.tailscale.ipv6} } accept
    '';
  };
  networking.nftables.mssClamping = true;
  networking.nftables.masquerade = [
    "ip saddr { ${self.data.tailscale.ipv4} }"
    "ip6 saddr { ${self.data.tailscale.ipv6} }"
  ];

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "git"
    ];
  };

  systemd.network.networks."10-enp1s0" = {
    matchConfig = {
      PermanentMACAddress = "04:0e:3c:2f:c9:9a";
    };
    DHCP = "yes";
    networkConfig.IPv6AcceptRA = true;
    dhcpV6Config = {
      PrefixDelegationHint = "::/63";
    };
    vlan = [ "internet" ];
  };

  systemd.network.netdevs."50-internet" = {
    netdevConfig = {
      Name = "internet";
      Kind = "vlan";
    };
    vlanConfig = {
      Id = 4;
    };
  };
  systemd.network.networks."50-internet" = {
    name = "internet";
    address = [
      "fd66::1/64"
      "10.6.1.1/24"
    ];
    ipv6Prefixes = [ { Prefix = "fd66::/64"; } ];
    networkConfig = {
      DHCPServer = true;
      IPv6SendRA = true;
      #DHCPPrefixDelegation = true;
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };
    dhcpServerConfig = {
      DNS = "_server_address";
    };
    ipv6SendRAConfig = {
      DNS = "fd66::1";
    };
  };

  presets.wireguard.wg0 = {
    enable = true;
    clientPeers = {
      ak.mark = 3;
      az = {
        mark = 3;
        mtu = 1360;
      };
      or2.mark = 3;
      sg.mark = 3;
    };
  };

  systemd.network.networks."25-wg-az".routingPolicyRules =
    let
      table = 100 + wg0.peers.az.id;
    in
    [
      {
        FirewallMark = nonCNMark;
        Table = table;
        Priority = 20;
        Family = "ipv4";
      }
    ];

  systemd.network.networks."25-warp".routingPolicyRules =
    let
      table = 20;
    in
    [
      {
        FirewallMark = nonCNMark;
        Table = table;
        Priority = 20;
        Family = "ipv6";
      }
      {
        To = "2001:da8:215:4078:250:56ff:fe97:654d"; # byr.pt
        Table = table;
        Priority = 9;
      }
    ];

  systemd.network.networks."25-wg-ak".routingPolicyRules =
    let
      table = 100 + wg0.peers.ak.id;
    in
    [
      {
        To = "34.117.196.143"; # prod-ingress.nianticlabs.com
        Table = table;
        Priority = 9;
      }
    ];

  networking.nftables.markChinaIP = {
    enable = true;
    mark = nonCNMark;
  };

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.192.1";
    mtu = 1412;
    mark = 3;
    routingId = "0xb18031";
    keyFile = config.sops.secrets.warp_key.path;
    address = [
      "172.16.0.2/32"
      "2606:4700:110:89a4:12e0:be02:634:888f/128"
    ];
    table = 20;
  };
  presets.wireguard.keepAlive.interfaces = [ "warp" ];

  presets.adguardhome = {
    enable = true;
    chinaDns = [ "[fd65::1]" ];
  };

  systemd.services.sing-box.serviceConfig.LoadCredential = [
    "uuid:${config.sops.secrets."tuic/uuid".path}"
    "password:${config.sops.secrets."tuic/password".path}"
    "tls_cert:${config.sops.secrets."tuic/tls_cert".path}"
    "tls_key:${config.sops.secrets."tuic/tls_key".path}"
    "ech_key:${config.sops.secrets."tuic/ech_key".path}"
  ];
  presets.sing-box = {
    enable = true;
    settings = {
      inbounds = [
        {
          type = "http";
          listen = "::";
          listen_port = 8000;
        }
        {
          type = "tuic";
          tag = "tuic-in";
          listen = "::";
          listen_port = 11113;
          users = [
            {
              name = "rvfg";
              uuid._secret = "/run/credentials/sing-box.service/uuid";
              password._secret = "/run/credentials/sing-box.service/password";
            }
          ];
          congestion_control = "cubic";
          auth_timeout = "3s";
          heartbeat = "10s";
          tls = {
            enabled = true;
            server_name = "t430.rvf6.com";
            min_version = "1.3";
            certificate_path = "/run/credentials/sing-box.service/tls_cert";
            key_path = "/run/credentials/sing-box.service/tls_key";
            ech = {
              enabled = true;
              pq_signature_schemes_enabled = false;
              key_path = "/run/credentials/sing-box.service/ech_key";
            };
          };
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "direct";
          tag = "warp";
          routing_mark = config.networking.warp.table;
        }
        {
          type = "direct";
          tag = "ak";
          routing_mark = 100 + wg0.peers.ak.id;
        }
        {
          type = "socks";
          tag = "work";
          server = "work.rvf6.com";
          server_port = 1080;
        }
      ];
      route.rules = [
        {
          domain_suffix = [
            "byr.pt"
            "reddit.com"
          ];
          outbound = "warp";
        }
        {
          domain = [ "prod-ingress.nianticlabs.com" ];
          outbound = "ak";
        }
        {
          domain_suffix = [
            self.data.ef
          ];
          ip_cidr = [
            "10.9.0.0/16"
            "10.12.0.0/16"
            "172.16.0.0/12"
          ];
          outbound = "work";
        }
      ];
    };
  };

  services.uu = {
    enable = true;
    vlan = {
      enable = true;
      parentName = "10-enp1s0";
    };
  };

  presets.duckdns = {
    enable = true;
    domain = "t430-rvfg.duckdns.org";
    interface = "enp1s0";
    tokenFile = config.sops.secrets.duckdns.path;
  };

  presets.swanctl = {
    enable = true;
    underlyingNetwork = "10-enp1s0";
    #IPv6Middle = ":1";
    IPv4Prefix = "10.6.9.";
    privateKeyFile = config.sops.secrets."pki/t430-pkcs8-key".path;
    local.t430 = {
      auth = "pubkey";
      id = "t430.rvf6.com";
      certs = [ config.sops.secrets."pki/t430-bundle".path ];
    };
    cacerts = [
      config.sops.secrets."pki/ca".path
      config.sops.secrets."pki/ybk".path
    ];
    devices = [
      "ip13"
      "pixel7"
      "xiaoxin"
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    settings = {
      devices = self.data.syncthing.devices;
      folders = lib.getAttrs [
        "keepass"
        "notes"
        "session"
      ] self.data.syncthing.folders;
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

  services.home-assistant = {
    enable = true;
    config = {
      default_config = { };
      homeassistant = {
        name = "Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
        time_zone = config.time.timeZone;
      };
      http = {
        server_host = "::1";
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1/128" ];
      };
      xiaomi_miot = {
        username = "!secret mi_username";
        password = "!secret mi_password";
      };
    };
    extraComponents = [
      "default_config"
      "esphome"
      "ffmpeg"
      "met"
      "xiaomi_miio"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      xiaomi_miot
    ];
    extraPackages =
      python3Packages: with python3Packages; [
        hap-python
        pyqrcode
      ];
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
    serviceConfig.LoadCredential = [ "cloudflare:${config.sops.secrets.cloudflare.path}" ];
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
      authLocations = [
        "/"
        "= /cgi-bin/luci/"
      ];
    };
  };

  presets.nginx = {
    enable = true;
    useACMEHost = "rvf6.com";
    virtualHosts = {
      "fava.rvf6.com".locations."/".proxyPass = "http://[::1]:5000";
      "luci.rvf6.com" =
        let
          cert = pkgs.writeText "luci-cert" ''
            -----BEGIN CERTIFICATE-----
            MIIB/DCCAaGgAwIBAgIQH4+jZYxJ7lpaGsEr6XC9ADAKBggqhkjOPQQDAjBfMQsw
            CQYDVQQGEwJaWjESMBAGA1UECAwJU29tZXdoZXJlMRAwDgYDVQQHDAdVbmtub3du
            MRgwFgYDVQQKDA9PcGVuV3J0NzA5Nzg1NzUxEDAOBgNVBAMMB09wZW5XcnQwIhgP
            MjAyMzA0MjYyMDI4MTZaGA8yMDI1MDQyNjIwMjgxNlowXzELMAkGA1UEBhMCWlox
            EjAQBgNVBAgMCVNvbWV3aGVyZTEQMA4GA1UEBwwHVW5rbm93bjEYMBYGA1UECgwP
            T3BlbldydDcwOTc4NTc1MRAwDgYDVQQDDAdPcGVuV3J0MFkwEwYHKoZIzj0CAQYI
            KoZIzj0DAQcDQgAE5VL2ordJudf99KmQKYpEHBXUDwQuAsByT8ewBnN5ESlmnABI
            abNb0Z1clNty0CM6GjLD9eGmdIMxA70Ct2f9xKM7MDkwEgYDVR0RBAswCYIHT3Bl
            bldydDAOBgNVHQ8BAf8EBAMCBeAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwCgYIKoZI
            zj0EAwIDSQAwRgIhAKq6so7IrZSLu237t0vuB3xEDWpMxSPRnWvIFWgB+sbRAiEA
            4VO+gwl3UrNuUpXAd0Wj8j5H+emsEqL8Glu7M9fxpow=
            -----END CERTIFICATE-----
          '';
        in
        {
          extraConfig = "proxy_ssl_trusted_certificate ${cert};";
          locations = {
            "= /cgi-bin/luci/" = {
              proxyPass = "https://10.6.0.1";
              extraConfig = "include ${config.sops.secrets.luci-nginx-add-auth.path};";
            };
            "/".proxyPass = "https://10.6.0.1";
          };
        };
      "ha.rvf6.com".locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.home-assistant.config.http.server_port}";
        proxyWebsockets = true;
      };
      "adg.rvf6.com".locations."/".proxyPass = "http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}";
      "wpad.rvf6.com".locations."= /wpad.dat" = {
        extraConfig = "add_header Content-Type application/x-ns-proxy-autoconfig;";
        alias = pkgs.writeText "wpad.dat" ''
          function FindProxyForURL(url, host) {
            let ipv4_regex = /^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)){3}$/gm;
            if (
              host.endsWith('byr.pt')
              || host.endsWith('reddit.com')
              || host === 'prod-ingress.nianticlabs.com'
              || host.endsWith('${self.data.ef}')
            ) {
              return 'PROXY 10.6.0.8:8000';
            } else if (ipv4_regex.test(host) && (
              isInNet(host, '10.9.0.0', '255.255.0.0')
              || isInNet(host, '10.12.0.0', '255.255.0.0')
              || isInNet(host, '172.16.0.0', '255.240.0.0')
            )) {
              return 'PROXY 10.6.0.8:8000';
            } else {
              return 'DIRECT';
            }
          }
        '';
      };
    };
  };
  services.nginx.virtualHosts."wpad.rvf6.com" = {
    addSSL = true;
    forceSSL = lib.mkForce false;
  };

  presets.gammu-smsd = {
    enable = true;
    pinFile = config.sops.secrets.sim-pin.path;
    settings = {
      gammu.Device = "/dev/serial/by-id/usb-Android_Android-if02-port0";
      smsd.Service = "files";
    };
  };

  systemd.services.gammu-smsd.serviceConfig.LoadCredential = [
    "tg-bot-token:${config.sops.secrets.tg-bot-token.path}"
  ];
  presets.gammu-smsd.settings.smsd.RunOnReceive =
    (pkgs.writers.writePython3 "gammu-smsd-on-receive"
      {
        libraries = [ pkgs.python3Packages.requests ];
      }
      ''
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
      ''
    ).outPath;
}
