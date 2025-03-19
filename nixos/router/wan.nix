{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
in
{

  options.router = {

    wanIf = mkOption {
      type = types.str;
      default = "enp1s0";
    };

    wanEnabledIfs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      apply = v: concatStringsSep ", " v;
    };

  };

  config = {

    sops.secrets.pppoe = { };

    networking.firewall.extraForwardRules = ''
      iifname { ${config.router.wanEnabledIfs} } oifname ppp0 accept
    '';
    networking.nftables.masquerade = [
      "meta nfproto ipv4 oifname ppp0"
      "ip6 saddr fc00::/7 oifname ppp0"
    ];

    networking.nftables.tables.interface-mark = {
      family = "inet";
      content = ''
        chain inbound-mark {
          type filter hook prerouting priority mangle;
          iifname ppp0 ct state new ct mark set 65536
          ct direction reply ct mark 65536 meta mark set ct mark
        }
        chain output-restore-mark {
          type route hook output priority mangle;
          ct direction reply ct mark 65536 meta mark set ct mark
        }
      '';
    };

    systemd.services.pppd-isp.serviceConfig.LoadCredential = [
      "pppoe:${config.sops.secrets.pppoe.path}"
    ];
    services.pppd = {
      enable = true;
      peers.isp.config = ''
        plugin pppoe.so
        ${config.router.wanIf}
        persist
        noauth
        defaultroute
        defaultroute-metric 512
        usepeerdns
        file /run/credentials/pppd-isp.service/pppoe
      '';
    };
    environment.etc."ppp/ip-up".source = pkgs.writeShellScript "ppp-ip-up" ''
      set -eu -o pipefail
      umask 0022
      if [[ ! -z "$DNS1" ]]; then
        echo "$DNS1" > /run/dns/ppp
        if [[ ! -z "$DNS2" ]]; then
          echo "$DNS2" >> /run/dns/ppp
        fi
      fi
    '';

    systemd.network.networks = {
      "10-enp1s0" = {
        name = "enp1s0";
        networkConfig = {
          IPv6AcceptRA = false;
        };
        DHCP = "ipv4";
        dhcpV4Config = {
          SendHostname = false;
          ClientIdentifier = "mac";
          UseDNS = false;
          UseNTP = false;
          UseSIP = false;
          UseDomains = false;
          UseGateway = false;
        };
      };
      "10-ppp" = {
        matchConfig.Type = "ppp";
        DHCP = "ipv6";
        networkConfig = {
          IPv6AcceptRA = true;
          KeepConfiguration = true;
        };
        dhcpV6Config.WithoutRA = "solicit";
        routingPolicyRules = [
          {
            FirewallMark = 65536;
            Priority = 64;
            Family = "both";
          }
        ];
      };
    };

    services.networkd-dispatcher = {
      enable = true;
      rules."dns" = {
        onState = [
          "configured"
        ];
        script = ''
          #!${pkgs.runtimeShell}
          set -eu -o pipefail
          if [[ $IFACE == "ppp0" ]]; then
            DNS=$(echo "$json" | ${lib.getExe pkgs.jq} -r '.DNS[] // empty')
            if [[ ! -z "$DNS" ]]; then
              echo "$DNS"
              echo "$DNS" > /run/dns/networkd
            fi
          fi
        '';
      };
    };

  };

}
