{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) mkForce;

  systemdHarden = self.data.systemdHarden;

  selfSignedHostnames = builtins.attrNames config.presets.nginx.selfSignedVirtualHosts;
in
{
  imports = [
    # keep-sorted start
    ./cn-slice.nix
    ./dns.nix
    ./fakesip.nix
    ./home-assistant
    ./lan.nix
    ./mosquitto.nix
    ./owntracks.nix
    ./proxy.nix
    ./vpn.nix
    ./wan.nix
    ./wgphantun.nix
    ./wireguard-dns.nix
    ./wireguard.nix
    # keep-sorted end
  ];

  presets.nogui.enable = true;
  presets.metrics.enable = true;
  presets.swanctl-gfw.enableClient = true;

  systemd.network.networks."25-xfrm-jp3".routingPolicyRules = [
    {
      FirewallMark = 2;
      Table = 1024 + 16 + 3;
      Priority = 16384;
      Family = "both";
    }
    {
      To = "2001:da8:215:4078:250:56ff:fe97:654d"; # byr.pt
      Table = 1024 + 16 + 3;
      Priority = 128;
    }
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/all-ca".mode = "0444";
    "pki/router-bundle" = { };
    "pki/router-pkcs8-key" = { };
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
    "tuic/uuid" = { };
    "tuic/password" = { };
    "tuic/tls_cert" = { };
    "tuic/tls_key" = { };
    "tuic/ech_key" = { };
    tailscale_auth_key = { };
    shadowsocks = { };
    radicale = { };
    sing-box-api-secret = { };
  };
  systemd.services.sops-install-secrets.before = [ "sysinit.target" ];

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.core.wmem_max" = 33554432;
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";
  };

  networking.hostName = "router";
  networking.hosts = {
    "10.8.0.1" = selfSignedHostnames;
    "fdd0::1" = selfSignedHostnames;
  };
  networking.firewall = {
    checkReversePath = "loose";
  };
  networking.nftables.mssClamping = true;

  home-manager.users.rvfg = import ./home.nix;

  preservation.preserveAt."/persist".users.rvfg = {
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

  security.acme = {
    acceptTerms = true;
    defaults.email = "le@rvf6.com";
    certs."rvf6.com" = {
      domain = "*.rvf6.com";
      extraDomainNames = [ "rvf6.com" ];
      dnsProvider = "cloudflare";
      group = "nginx";
      credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare.path;
    };
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
      "adg.rvf6.com".locations."/".proxyPass =
        "http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}";
      "radicale.rvf6.com".locations."/".proxyPass = "http://[::1]:5232";
    };
    selfSignedVirtualHosts = {
      "victorialogs.rvf6.com".locations."/".proxyPass = "http://unix:/run/victorialogs/sock:/";
      "victoriametrics.rvf6.com".locations."/".proxyPass =
        "http://${config.services.victoriametrics.listenAddress}:/";
      "modem.rvf6.com".locations."/".proxyPass = "http://192.168.1.1";
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    "victoriametrics"
    "victorialogs"
  ];
  systemd.services.nginx.wants = [
    "victoriametrics.service"
    "victorialogs.service"
  ];
  systemd.services.nginx.after = [
    "victoriametrics.service"
    "victorialogs.service"
  ];

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
  systemd.services.victorialogs.serviceConfig = {
    PrivateNetwork = true;
    RuntimeDirectoryMode = mkForce "0750";
  };
  systemd.services.proxy-to-victorialogs = {
    requires = [
      "victorialogs.service"
      "proxy-to-victorialogs.socket"
    ];
    after = [
      "victorialogs.service"
      "proxy-to-victorialogs.socket"
    ];
    unitConfig.JoinsNamespaceOf = "victorialogs.service";
    serviceConfig = systemdHarden // {
      Type = "notify";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ::1:9428";
    };
  };
  systemd.sockets.proxy-to-victorialogs = {
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "/run/victorialogs/sock" ];
  };

  services.victoriametrics = {
    enable = true;
    package = pkgs.victoriametrics.overrideAttrs (prev: {
      patches = (prev.patches or [ ]) ++ [
        ./victoriametrics-10331.patch
      ];
    });
    extraOptions = [
      "-enableTCP6"
    ];
    listenAddress = "unix:/run/victoriametrics/sock";
    prometheusConfig.scrape_configs = [
      {
        job_name = "telegraf";
        static_configs = [
          { targets = [ "http://[::1]:9273/metrics" ]; }
        ];
      }
    ];
  };
  systemd.services.victoriametrics = {
    postStart = mkForce "";
    serviceConfig.RuntimeDirectoryMode = mkForce "0750";
  };

  services.telegraf.package = pkgs.telegraf.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        url = "https://github.com/influxdata/telegraf/commit/56b98de33ba897ab9fe80d3791d8798cfb98fbcf.patch";
        hash = "sha256-uMK1qzBMCmkq28uGQAWkS+NsG7+xjIhT7GUCYX8yHIo=";
      })
    ];
  });
  services.telegraf.extraConfig.inputs.ping = {
    urls = [
      "10.5.0.17" # nl
      "10.5.0.33" # de2
      "10.5.0.49" # jp3
    ];
    method = "native";
    count = 10;
    ping_interval = "0.2s";
    deadline = "10s";
    privileged = false;
  };

}
