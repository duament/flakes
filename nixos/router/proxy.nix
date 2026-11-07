{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let

  inherit (lib) mkForce concatStringsSep concatMapStringsSep;

  fakeIPv4 = "198.18.0.0/15";
  fakeIPv6 = "fc80:ffff::/64";

  tproxyMark = 256;
  tproxyPort = 2080;
  httpPort = 8000;
  httpCNPort = 8001;
  tuicPort = 11113;
  ssPort = 11114;
  apiPort = 9090;

  servicePorts = [
    # keep-sorted start
    apiPort
    httpCNPort
    httpPort
    tproxyPort
    # keep-sorted end
  ];

  downloadDomains = [
    # NixOS
    "cache.nixos.org"
    "releases.nixos.org"
  ];

  msDomains = [
    "software-download.microsoft.com"
    "delivery.mp.microsoft.com"
    "download.prss.microsoft.com"
    "update.microsoft.com"
    "windowsupdate.com"
    "packages.microsoft.com"
    "windowsupdate.microsoft.com"
    "download.microsoft.com"
  ];

  EUDomains = [
    "splatoon.oatmealdome.me"
  ];

  redditDomains = [
    "www.reddit.com"
  ];

  fakeDNSDomains = downloadDomains ++ msDomains ++ EUDomains ++ redditDomains;

in
{

  sops.secrets = {
    sing-box-api-secret = { };
    "tuic/uuid" = { };
    "tuic/password" = { };
    "tuic/tls_cert" = { };
    "tuic/tls_key" = { };
    "tuic/ech_key" = { };
    shadowsocks = { };
    shadowsocks-jp2 = { };
  };

  networking.firewall = {
    allowedUDPPorts = [
      tuicPort
    ];
    extraInputRules = ''
      iifname @wan_enabled_ifs tcp dport { ${
        concatMapStringsSep ", " (port: toString port) servicePorts
      } } accept
    '';
    extraReversePathFilterRules = ''
      ip daddr ${fakeIPv4} accept
      ip6 daddr ${fakeIPv6} accept
    '';
  };

  networking.nftables.tables.fakeip = {
    family = "inet";
    content = ''
      chain router {
        type filter hook prerouting priority mangle;
        ip daddr ${fakeIPv4} jump do_tproxy
        ip6 daddr ${fakeIPv6} jump do_tproxy
      }
      chain do_tproxy {
        meta l4proto tcp tproxy to :${toString tproxyPort} meta mark set ${toString tproxyMark} accept
        reject
      }
      chain local_reroute {
        type route hook output priority mangle;
        ip daddr ${fakeIPv4} jump do_reroute
        ip6 daddr ${fakeIPv6} jump do_reroute
      }
      chain do_reroute {
        meta l4proto tcp meta mark set ${toString tproxyMark} accept
        reject
      }
    '';
  };

  systemd.network.config.routeTables.tproxy = 200;

  systemd.network.networks."20-lo" = {
    name = "lo";
    networkConfig.KeepConfiguration = "static";
    routingPolicyRules = [
      {
        FirewallMark = tproxyMark;
        Table = "tproxy";
        Family = "both";
        Priority = 512;
      }
    ];
    routes = [
      {
        Source = "0.0.0.0/0";
        Scope = "host";
        Table = "tproxy";
        Type = "local";
      }
      {
        Source = "::/0";
        Table = "tproxy";
        Type = "local";
      }
    ];
  };

  presets.adguardhome.extraUpstream = ''
    [/${concatStringsSep "/" fakeDNSDomains}/][::1]:2053
  '';

  systemd.services.sing-box.serviceConfig.LoadCredential = [
    "uuid:${config.sops.secrets."tuic/uuid".path}"
    "password:${config.sops.secrets."tuic/password".path}"
    "tls_cert:${config.sops.secrets."tuic/tls_cert".path}"
    "tls_key:${config.sops.secrets."tuic/tls_key".path}"
    "ech_key:${config.sops.secrets."tuic/ech_key".path}"
    "api_secret:${config.sops.secrets."sing-box-api-secret".path}"
    "shadowsocks-jp2:${config.sops.secrets.shadowsocks-jp2.path}"
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
            rewrite_ttl = 15;
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
          type = "shadowsocks";
          tag = "jp2";
          server = self.data.dns.jp2.ipv6;
          server_port = 13926;
          method = "2022-blake3-aes-256-gcm";
          password._secret = "/run/credentials/sing-box.service/shadowsocks-jp2";
        }
        {
          type = "socks";
          tag = "work";
          server = "work.rvf6.com";
          server_port = 1080;
        }
        {
          type = "selector";
          tag = "download";
          outbounds = [
            "cn"
            "nl"
            "de2"
            "jp3"
            "g2"
          ];
          default = "de2";
          interrupt_exist_connections = false;
        }
        {
          type = "selector";
          tag = "ms";
          outbounds = [
            "cn"
            "nl"
            "de2"
            "jp3"
          ];
          default = "cn";
          interrupt_exist_connections = true;
        }
        {
          type = "selector";
          tag = "eu";
          outbounds = [
            "nl"
            "de2"
            "jp3"
            "g2"
          ];
          default = "de2";
          interrupt_exist_connections = false;
        }
      ]
      ++ (map (
        peer:
        let
          inherit (import ../../modules/swanctl-gfw/common.nix { inherit config lib self; })
            peerKey
            proxyPort
            ;
        in
        {
          type = "http";
          tag = peerKey peer;
          server = peer.serverIPv4;
          server_port = proxyPort;
        }
      ) self.data.swanctl-gfw);
      route.default_domain_resolver = "local";
      route.rules =
        let
          rejectLocalhost = {
            ip_cidr = [
              "127.0.0.1/8"
              "::1/128"
            ];
            action = "reject";
          };
        in
        [
          {
            inbound = "dns";
            action = "hijack-dns";
          }
          {
            ip_cidr = [ "::1/128" ];
            network = "udp";
            port = 11111;
            outbound = "direct";
          }
          # cn-in start
          {
            inbound = "cn-in";
            action = "resolve";
          }
          rejectLocalhost
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
          # cn-in end
          {
            domain_suffix = downloadDomains;
            outbound = "download";
          }
          {
            domain_suffix = msDomains;
            outbound = "ms";
          }
          {
            domain_suffix = EUDomains;
            outbound = "eu";
          }
          {
            domain_suffix = redditDomains;
            outbound = "jp2";
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
          { action = "resolve"; }
          rejectLocalhost
          { outbound = "direct"; }
        ];
      experimental = {
        cache_file = {
          enabled = true;
          store_fakeip = true;
        };
        clash_api = {
          external_controller = "[::]:9090";
          secret._secret = "/run/credentials/sing-box.service/api_secret";
          access_control_allow_origin = [ "https://board.zash.run.place" ];
          access_control_allow_private_network = true;
        };
      };
    };
  };

  presets.shadowsocks = {
    enable = true;
    settings.server_port = ssPort;
    passwordFile = config.sops.secrets.shadowsocks.path;
    openFirewall = true;
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
