{
  config,
  pkgs,
  self,
  ...
}:
let
  systemdHarden = self.data.systemdHarden;
in
{
  imports = [
    ./lan.nix
    ./wan.nix
    ./dns.nix
    ./proxy.nix
    ./wireguard.nix
    ./mosquitto.nix
    ./owntracks.nix
  ];

  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/all-ca".mode = "0444";
    "pki/t430-bundle" = { };
    "pki/t430-pkcs8-key" = { };
    "pki/rvf6.com.crt" = {
      group = "nginx";
      mode = "0440";
    };
    "pki/rvf6.com.key" = {
      group = "nginx";
      mode = "0440";
    };
    warp_key.owner = "systemd-network";
    duckdns = { };
    wireguard_key.owner = "systemd-network";
    #"syncthing/cert".owner = config.services.syncthing.user;
    #"syncthing/key".owner = config.services.syncthing.user;
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
    tailscale_auth_key = { };
    shadowsocks = { };
    radicale = { };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = "router";
  networking.firewall = {
    checkReversePath = "loose";
  };
  networking.nftables.mssClamping = true;

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "git"
    ];
  };

  presets.duckdns = {
    enable = true;
    family = "both";
    domain = "t430-rvfg.duckdns.org";
    interface = "ppp0";
    tokenFile = config.sops.secrets.duckdns.path;
  };

  services.tailscale = {
    enable = true;
    package = pkgs.tailscale.override { iptables = pkgs.nftables; };
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-exit-node"
      "--netfilter-mode=off"
    ];
  };
  router.dnsEnabledIfs = [ "tailscale0" ];
  router.lanEnabledIfs = [ "tailscale0" ];
  router.wanEnabledIfs = [ "tailscale0" ];
  router.wgEnabledIfs = [ "tailscale0" ];

  #presets.swanctl = {
  #  enable = true;
  #  underlyingNetwork = "10-enp1s0";
  #  #IPv6Middle = ":1";
  #  IPv4Prefix = "10.6.9.";
  #  privateKeyFile = config.sops.secrets."pki/t430-pkcs8-key".path;
  #  local.t430 = {
  #    auth = "pubkey";
  #    id = "t430.rvf6.com";
  #    certs = [ config.sops.secrets."pki/t430-bundle".path ];
  #  };
  #  cacerts = [
  #    config.sops.secrets."pki/ca".path
  #    config.sops.secrets."pki/ybk".path
  #  ];
  #  devices = [
  #    "ip13"
  #    "pixel7"
  #    "xiaoxin"
  #  ];
  #};

  #services.syncthing = {
  #  enable = true;
  #  openDefaultPorts = true;
  #  cert = config.sops.secrets."syncthing/cert".path;
  #  key = config.sops.secrets."syncthing/key".path;
  #  settings = {
  #    devices = self.data.syncthing.devices;
  #    folders = lib.getAttrs [
  #      "keepass"
  #      "notes"
  #      "session"
  #    ] self.data.syncthing.folders;
  #  };
  #};

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
      "roborock"
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
      "adg.rvf6.com".locations."/".proxyPass =
        "http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}";
      "radicale.rvf6.com".locations."/".proxyPass = "http://[::1]:5232";
    };
    selfSignedVirtualHosts = {
      "victorialogs.rvf6.com".locations."/".proxyPass =
        "http://${config.services.victorialogs.listenAddress}";
      "victoriametrics.rvf6.com".locations."/".proxyPass =
        "http://${config.services.victoriametrics.listenAddress}";
    };
  };

  presets.gammu-smsd = {
    enable = false;
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

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "[::1]:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = "/run/credentials/radicale.service/htpasswd";
        htpasswd_encryption = "plain";
      };
    };
  };
  systemd.services.radicale.serviceConfig.LoadCredential = [
    "htpasswd:${config.sops.secrets.radicale.path}"
  ];

  services.victorialogs = {
    enable = true;
    extraOptions = [
      "-enableTCP6"
      "-retention.maxDiskSpaceUsageBytes=64GiB"
      "-retentionPeriod=12w"
    ];
    listenAddress = "[::1]:9428";
  };

  services.victoriametrics = {
    enable = true;
    extraOptions = [
      "-enableTCP6"
    ];
    listenAddress = "[::1]:8428";
  };

}
