{
  config,
  lib,
  pkgs,
  self,
  utils,
  ...
}:
let
  inherit (lib) mkForce concatStringsSep;

  fakeIPv4 = "198.18.0.0/15";
  fakeIPv6 = "fc80:ffff::/64";

  tproxyMark = 256;
  tproxyPort = 2080;
  httpPort = 8000;
  httpCNPort = 8001;
  tuicPort = 11113;
  ssPort = 11114;

  downloadDomains = [
    # NixOS
    "cache.nixos.org"
    "releases.nixos.org"
    # Apple
    "appldnld.apple.com"
    "gg.apple.com"
    "gs.apple.com"
    "updates-http.cdn-apple.com"
    "updates.cdn-apple.com"
  ];
in
{

  networking.firewall = {
    allowedUDPPorts = [
      tuicPort
      ssPort
    ];
    extraInputRules = ''
      iifname @wan_enabled_ifs tcp dport { ${toString tproxyPort}, ${toString httpPort}, ${toString httpCNPort} } accept
    '';
    extraReversePathFilterRules = ''
      ip daddr ${fakeIPv4} accept
      ip6 daddr ${fakeIPv6} accept
    '';
  };

  networking.nftables.tables.fakeip = {
    family = "inet";
    content = ''
      chain fakeip {
        type filter hook prerouting priority mangle;
        ip daddr ${fakeIPv4} jump do_tproxy
        ip6 daddr ${fakeIPv6} jump do_tproxy
      }
      chain do_tproxy {
        meta l4proto tcp tproxy to :${toString tproxyPort} meta mark set ${toString tproxyMark} accept
        reject
      }
    '';
  };

  systemd.network.networks."20-lo" = {
    name = "lo";
    networkConfig.KeepConfiguration = "static";
    routingPolicyRules = [
      {
        FirewallMark = tproxyMark;
        Table = 200;
        Family = "both";
        Priority = 512;
      }
    ];
    routes = [
      {
        Source = "0.0.0.0/0";
        Scope = "host";
        Table = 200;
        Type = "local";
      }
      {
        Source = "::/0";
        Table = 200;
        Type = "local";
      }
    ];
  };

  presets.adguardhome.extraUpstream = ''
    [/${concatStringsSep "/" downloadDomains}/][::1]:2053
  '';

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
      dns = {
        servers = [
          {
            type = "local";
            tag = "local";
          }
          {
            type = "udp";
            tag = "cn";
            server = "::1";
            server_port = 5300;
          }
          {
            type = "fakeip";
            tag = "fakeip";
            inet4_range = fakeIPv4;
            inet6_range = fakeIPv6;
          }
        ];
        rules = [
          {
            inbound = [ "dns" ];
            server = "fakeip";
          }
          { server = "local"; }
        ];
      };
      inbounds = [
        {
          type = "direct";
          tag = "dns";
          listen = "::1";
          listen_port = 2053;
        }
        {
          type = "tproxy";
          tag = "tproxy";
          listen = "::";
          listen_port = tproxyPort;
        }
        {
          type = "http";
          listen = "::";
          listen_port = httpPort;
        }
        {
          type = "http";
          tag = "cn-in";
          listen = "::";
          listen_port = httpCNPort;
        }
        {
          type = "tuic";
          tag = "tuic-in";
          listen = "::";
          listen_port = tuicPort;
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
            server_name = "mirror.sjtu.edu.cn";
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
          tag = "cn";
          routing_mark = 1;
          domain_resolver = "cn";
        }
        {
          type = "direct";
          tag = "warp";
          routing_mark = config.networking.warp.table;
        }
        {
          type = "direct";
          tag = "ak";
          routing_mark = 100 + self.data.wg0.peers.ak.id;
        }
        {
          type = "socks";
          tag = "work";
          server = "work.rvf6.com";
          server_port = 1080;
        }
        {
          type = "http";
          tag = "de";
          server = "10.5.0.1";
          server_port = 8000;
        }
        {
          type = "http";
          tag = "nl";
          server = "10.5.0.17";
          server_port = 8000;
        }
        {
          type = "http";
          tag = "de2";
          server = "10.5.0.33";
          server_port = 8000;
        }
        {
          type = "selector";
          tag = "download";
          outbounds = [
            "direct"
            "cn"
            "de"
            "nl"
            "de2"
          ];
          default = "nl";
          interrupt_exist_connections = false;
        }
      ];
      route.default_domain_resolver = "local";
      route.rules = [
        {
          inbound = "dns";
          action = "hijack-dns";
        }
        {
          inbound = "cn-in";
          domain_suffix = [
            "googleapis.com"
          ];
          outbound = "direct";
        }
        {
          inbound = "cn-in";
          outbound = "cn";
        }
        {
          domain = downloadDomains;
          outbound = "download";
        }
        {
          domain_suffix = [
            "byr.pt"
            "reddit.com"
          ];
          outbound = "warp";
        }
        {
          domain = [ "prod-ingress.ingress.com" ];
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

  systemd.services.shadowsocks-rust = {
    serviceConfig = self.data.systemdHarden // {
      PrivateNetwork = false;
      LoadCredential = [ "shadowsocks:${config.sops.secrets."shadowsocks".path}" ];
      RuntimeDirectory = "shadowsocks-rust";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = pkgs.writeShellScript "shadowsocks-replace-secrets" (
        utils.genJqSecretsReplacementSnippet {
          server = "::";
          server_port = ssPort;
          password._secret = "/run/credentials/shadowsocks-rust.service/shadowsocks";
          method = "2022-blake3-aes-256-gcm";
        } "/run/shadowsocks-rust/config.json"
      );
      ExecStart = "${pkgs.shadowsocks-rust}/bin/ssserver -c \${RUNTIME_DIRECTORY}/config.json";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # TODO
  presets.nginx.virtualHosts."wpad.rvf6.com".locations."= /wpad.dat" = {
    extraConfig = "add_header Content-Type application/x-ns-proxy-autoconfig;";
    alias = pkgs.writeText "wpad.dat" ''
      function FindProxyForURL(url, host) {
        let ipv4_regex = /^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)){3}$/gm;
        if (
          host.endsWith('byr.pt')
          || host.endsWith('reddit.com')
          || host === 'prod-ingress.ingress.com'
          || host.endsWith('${self.data.ef}')
        ) {
          return 'PROXY 10.6.0.8:${toString httpPort}';
        } else if (ipv4_regex.test(host) && (
          isInNet(host, '10.9.0.0', '255.255.0.0')
          || isInNet(host, '10.12.0.0', '255.255.0.0')
          || isInNet(host, '172.16.0.0', '255.240.0.0')
        )) {
          return 'PROXY 10.6.0.8:${toString httpPort}';
        } else {
          return 'DIRECT';
        }
      }
    '';
  };
  services.nginx.virtualHosts."wpad.rvf6.com" = {
    addSSL = true;
    forceSSL = mkForce false;
  };

}
