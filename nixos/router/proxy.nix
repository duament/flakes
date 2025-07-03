{
  config,
  lib,
  pkgs,
  self,
  utils,
  ...
}:
let
  inherit (lib) mkForce;

  httpPort = 8000;
  tuicPort = 11113;
  ssPort = 11114;
in
{

  networking.firewall = {
    allowedUDPPorts = [
      tuicPort
      ssPort
    ];
    extraInputRules = ''
      iifname { ${config.router.wanEnabledIfs} } tcp dport ${toString httpPort} accept
    '';
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
          listen_port = httpPort;
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
          || host === 'prod-ingress.nianticlabs.com'
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
