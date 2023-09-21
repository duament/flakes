{ config, lib, mypkgs, pkgs, self, ... }:
let
  wg0 = self.data.wg0;
  systemdHarden = self.data.systemdHarden;
  tailscale-ipv4 = "100.122.255.34, 100.102.34.2, 100.108.44.87";
  tailscale-ipv6 = "fd7a:115c:a1e0:ab12:4843:cd96:627a:ff22, fd7a:115c:a1e0:ab12:4843:cd96:6266:2202, fd7a:115c:a1e0:ab12:4843:cd96:626c:2c57";
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
    "home-assistant-secrets.yaml" = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = "t430";
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
      iifname { wg0, internet } meta l4proto { tcp, udp } th dport 53 accept
      iifname internet udp dport 67 accept
      ip saddr { 10.6.0.1, ${tailscale-ipv4} } udp dport 53 accept
    '';
    extraForwardRules = ''
      meta ipsec exists accept
      rt ipsec exists accept
      iifname { wg0, internet } accept
      oifname { wg0, internet } accept
      ip saddr { ${tailscale-ipv4} } accept
      ip6 saddr { ${tailscale-ipv6} } accept
    '';
  };
  networking.nftables.checkRuleset = false;
  networking.nftables.mssClamping = true;
  networking.nftables.masquerade = [ "ip saddr { ${tailscale-ipv4} }" "ip6 saddr { ${tailscale-ipv6} }" "oifname wg-or2" ];

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "git"
    ];
  };

  systemd.network.networks."10-enp1s0" = {
    matchConfig = { PermanentMACAddress = "04:0e:3c:2f:c9:9a"; };
    DHCP = "yes";
    dhcpV6Config = { PrefixDelegationHint = "::/63"; };
    vlan = [ "internet" ];
  };

  systemd.network.netdevs."50-internet" = {
    netdevConfig = { Name = "internet"; Kind = "vlan"; };
    vlanConfig = { Id = 4; };
  };
  systemd.network.networks."50-internet" = {
    name = "internet";
    address = [ "fd66::1/64" "10.6.1.1/24" ];
    ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "fd66::/64"; }];
    networkConfig = {
      DHCPServer = true;
      IPv6SendRA = true;
      DHCPPrefixDelegation = true;
      IPForward = true;
    };
    dhcpServerConfig = { DNS = "_server_address"; };
    ipv6SendRAConfig = { DNS = "fd66::1"; };
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

  systemd.network.netdevs."25-wg-or2" = {
    netdevConfig = { Name = "wg-or2"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      FirewallMark = 3;
      RouteTable = 11;
    };
    wireguardPeers = [
      {
        wireguardPeerConfig = {
          AllowedIPs = [ "0.0.0.0/0" "::/0" ];
          PublicKey = self.data.wg0.peers.or2.pubkey;
          Endpoint = "${self.data.wg0.peers.or2.endpointAddr}:11112";
        };
      }
    ];
  };
  systemd.network.networks."25-wg-or2" = {
    name = "wg-or2";
    address = [ "10.6.9.1/24" "fd66::1/120" ];
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          To = "34.117.196.143"; # prod-ingress.nianticlabs.com
          Table = 11;
          Priority = 9;
        };
      }
    ];
  };

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.193.1";
    mtu = 1412;
    mark = 3;
    routingId = "0x09c13f";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:84eb:bb94:4951:eb43:cae1/128" ];
    table = 20;
    extraMarkSettings.extraIPv4Rules = "ip saddr 10.6.7.0/24 accept";
  };
  presets.wireguard.keepAlive.interfaces = [ "warp" ];

  presets.smartdns.chinaDns = [ "[fd65::1]" ];
  presets.smartdns.settings.address = [
    "/t430.rvf6.com/${wg0.gateway4}"
    "/t430.rvf6.com/${wg0.gateway6}"
    "/ax6s.rvf6.com/fd65::1"
    "/ax6s.rvf6.com/-4"
    "/rpi3.rvf6.com/10.6.0.7"
    "/fava.rvf6.com/fd64::1"
    "/fava.rvf6.com/-4"
    "/luci.rvf6.com/fd64::1"
    "/luci.rvf6.com/-4"
    "/ha.rvf6.com/fd64::1"
    "/ha.rvf6.com/-4"
  ];

  services.uu = {
    enable = true;
    wanName = "10-enp1s0";
    uuidFile = config.sops.secrets.uuplugin-uuid.path;
  };

  system.activationScripts.strongswan-swanctl-private = lib.stringAfter [ "etc" ] ''
    mkdir -p /etc/swanctl/private
    ln -sf ${config.sops.secrets."pki/t430-pkcs8-key".path} /etc/swanctl/private/t430.key
  '';
  services.swanctlDynamicIPv6 = {
    enable = true;
    prefixInterface = "wg0";
    IPv6Middle = ":1";
    IPv4Prefix = wg0.ipv4Pre;
    local.t430 = {
      auth = "pubkey";
      id = "t430.rvf6.com";
      certs = [ config.sops.secrets."pki/t430-bundle".path ];
    };
    cacerts = [ config.sops.secrets."pki/ca".path config.sops.secrets."pki/ybk".path ];
    devices = [ "ip13" "pixel7" "xiaoxin" ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    settings = {
      devices = self.data.syncthing.devices;
      folders = lib.getAttrs [ "keepass" "notes" "session" ] self.data.syncthing.folders;
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
    extraPackages = python3Packages: with python3Packages; [
      hap-python
      pyqrcode
    ];
  };
  systemd.services.home-assistant.preStart = ''
    mkdir -p ${config.services.home-assistant.configDir}/custom_components
    ln -sf ${mypkgs.hass-xiaomi-miot}/share/hass/custom_components/xiaomi_miot ${config.services.home-assistant.configDir}/custom_components/
  '';

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
      authLocations = [ "/" "= /cgi-bin/luci/" ];
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
    };
  };

  presets.gammu-smsd = {
    enable = true;
    pinFile = config.sops.secrets.sim-pin.path;
    settings = {
      gammu.Device = "/dev/serial/by-id/usb-Android_Android-if02-port0";
      smsd.Service = "files";
    };
  };

  systemd.services.gammu-smsd.serviceConfig.LoadCredential = [ "tg-bot-token:${config.sops.secrets.tg-bot-token.path}" ];
  presets.gammu-smsd.settings.smsd.RunOnReceive = (pkgs.writers.writePython3 "gammu-smsd-on-receive"
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
  '').outPath;
}
