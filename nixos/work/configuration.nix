{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  efKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ ef";
in
{
  #nixpkgs.overlays = [
  #  (self: super: {
  #    llvmPackages_14 = super.llvmPackages_14 // {
  #      compiler-rt = super.llvmPackages_14.compiler-rt.overrideAttrs (oldAttrs: {
  #        cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DCOMPILER_RT_TSAN_DEBUG_OUTPUT=ON" ];
  #      });
  #    };
  #  })
  #];

  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    wireguard_key.owner = "systemd-network";
    "tuic/uuid" = { };
    "tuic/password" = { };
    "tuic/tls_cert" = { };
    "tuic/ech_config" = { };
  };

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "work";
  networking.firewall = {
    checkReversePath = "loose";
    allowedTCPPorts = [
      1080
    ];
  };
  systemd.network.networks."80-ethernet" = {
    matchConfig = {
      Type = "ether";
    };
    DHCP = "no";
    # dhcpV4Config = { SendOption = "50:ipv4address:172.26.0.2"; };
    address = [
      "172.26.0.2/24"
      "fc00::2/64"
    ];
    gateway = [
      "172.26.0.1"
      "fc00::1"
    ];
    dns = [ "10.9.231.5" ];
    domains = [
      "~${self.data.ef}"
      "~h.rvf6.com"
    ];
    routingPolicyRules =
      map
        (ip: {
          To = ip;
          Priority = 128;
        })
        [
          "172.16.0.0/12"
          "10.9.0.0/16"
          "10.12.0.0/16"
          "fc00::/64"
        ];
  };
  presets.wireguard.wg0 = {
    enable = true;
    clientPeers.router = {
      route = "all";
      routeBypass = [
        "172.16.0.0/12"
        "10.9.0.0/16"
        "10.12.0.0/16"
        "fc00::/64"
      ];
      endpoint = "[::1]:11111";
      keepalive = 25;
    };
  };

  services.tailscale.enable = false;

  users.users.rvfg.openssh.authorizedKeys.keys = [ efKey ];
  presets.users.sudoKeys = [ efKey ];

  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      "Downloads"
    ];
  };

  systemd.services.sing-box.serviceConfig.LoadCredential = [
    "uuid:${config.sops.secrets."tuic/uuid".path}"
    "password:${config.sops.secrets."tuic/password".path}"
    "tls_cert:${config.sops.secrets."tuic/tls_cert".path}"
    "ech_config:${config.sops.secrets."tuic/ech_config".path}"
  ];
  presets.sing-box = {
    enable = true;
    prepareScript = lib.mkAfter ''
      TXT_PATH=/var/lib/dns-txt/t430-rvfg.duckdns.org
      if [[ -f $TXT_PATH ]]; then
        IP=$(cat $TXT_PATH | ${pkgs.gawk}/bin/awk '{print $1}')
        PORT=$(cat $TXT_PATH | ${pkgs.gawk}/bin/awk '{print $2}')
        if [[ $IP ]] && [[ $PORT ]]; then
          cat /run/sing-box/config.json | ${pkgs.jq}/bin/jq --arg IP "$IP" --arg PORT "$PORT" '.outbounds[] |= if .type == "tuic" then (.server = $IP | .server_port = ($PORT | tonumber)) end' > /run/sing-box/config.json.tmp
          mv /run/sing-box/config.json.tmp /run/sing-box/config.json
        fi
      fi
    '';
    settings = {
      inbounds = [
        {
          type = "socks";
          listen = "::";
          listen_port = 1080;
        }
        {
          type = "direct";
          tag = "wg-tunnel";
          listen = "::1";
          listen_port = 11111;
          network = "udp";
          override_address = "::1";
          override_port = 11111;
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "http";
          tag = "http";
          server = "t430.rvf6.com";
          server_port = 8000;
        }
        {
          type = "tuic";
          tag = "tuic";
          routing_mark = 1;
          server = "0.0.0.0";
          server_port = 11113;
          uuid._secret = "/run/credentials/sing-box.service/uuid";
          password._secret = "/run/credentials/sing-box.service/password";
          congestion_control = "cubic";
          udp_relay_mode = "native";
          heartbeat = "10s";
          tls = {
            enabled = true;
            server_name = "mirror.sjtu.edu.cn";
            min_version = "1.3";
            certificate_path = "/run/credentials/sing-box.service/tls_cert";
            ech = {
              enabled = true;
              pq_signature_schemes_enabled = false;
              config_path = "/run/credentials/sing-box.service/ech_config";
            };
          };
        }
      ];
      route.rules = [
        {
          inbound = [ "wg-tunnel" ];
          outbound = "tuic";
        }
        {
          domain_suffix = [
            "byr.pt"
            "reddit.com"
          ];
          domain = [ "prod-ingress.nianticlabs.com" ];
          outbound = "tuic";
        }
        {
          domain_suffix = [ self.data.ef ];
          ip_cidr = [
            "10.9.0.0/16"
            "10.12.0.0/16"
            "172.16.0.0/12"
          ];
          outbound = "direct";
        }
        {
          outbound = "tuic";
        }
      ];
    };
  };

  systemd.services.sing-box-re-resolve = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = self.data.systemdHarden // {
      Type = "oneshot";
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      PrivateNetwork = false;
      DynamicUser = false;
      ReadWritePaths = [ "/var/lib/dns-txt" ];
    };
    path = with pkgs; [
      curl
      iproute2
      jq
    ];
    script = ''
      set -eu -o pipefail
      IP=$(curl -s --retry 3 -m 60 --fail "https://223.5.5.5/resolve?name=t430-rvfg.duckdns.org&type=1" | jq -r '.Answer[0].data')
      if [[ ! $IP ]] || [[ "$IP" == "null" ]]; then
        >&2 echo "Cannot get IP address"
        exit 1
      fi

      text_path="/var/lib/dns-txt/t430-rvfg.duckdns.org"
      new_text="$IP 11113"
      if [[ $(< "$text_path") != "$new_text" ]]; then
        echo "$new_text" > "$text_path"
        systemctl reload sing-box
      fi
    '';
  };
  presets.bpf-mark.sing-box-re-resolve = 1;
  systemd.timers.sing-box-re-resolve = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnStartupSec = 60;
      OnUnitActiveSec = 300;
    };
  };

}
