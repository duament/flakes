{ config, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.presets.wireguard.dynamicIPv6;
in
{
  options = {
    presets.wireguard.dynamicIPv6.interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = {
    systemd.services = builtins.listToAttrs (map
      (interface: {
        name = "${interface}-dynamic-ipv6";
        value = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          path = [ pkgs.iproute2 pkgs.jq pkgs.sipcalc pkgs.gawk pkgs.wireguard-tools ];
          script = ''
            set -o pipefail
            IPV6=$(ip -j -6 a show dev ${interface} scope global | jq -r '.[0].addr_info[] | select(.local[:2] != "fc" and .local[:2] != "fd").local' | head -n 1)
            IPV6_EXPANDED=$(sipcalc -6 "$IPV6" | grep 'Expanded Address' | awk '{print $NF}')
            IPV6_PREFIX=''${IPV6_EXPANDED%:*:*:*:*}
            if [[ -z "$IPV6_PREFIX" ]]; then exit; fi
            wg show ${interface} allowed-ips | while read line; do
              pubkey=$(echo "$line" | awk '{print $1}')
              ip1=$(echo "$line" | awk '{print $2}')
              ip2=$(echo "$line" | awk '{print $3}')
              ip3=$(echo "$line" | awk '{print $4}')
              if [[ "$ip1" == 10* ]]; then
                ipv4="$ip1"
              else
                ipv4="$ip2"
              fi
              ipv4_host=$(sipcalc -4 "$ipv4" | grep 'Host address' | head -n 1 | awk '{print $NF}')
              host_num=''${ipv4_host##*.}
              if [[ -z "$host_num" ]]; then exit; fi
              host_hex=$(printf '%x' "$host_num")
              if [[ -n "$ipv6" ]]; then
                ipv6_expanded=$(sipcalc -6 "$ipv6" | grep 'Expanded Address' | awk '{print $NF}')
                ipv6_prefix=''${ipv6_expanded%:*:*:*:*}
              fi
              if [[ "$IPV6_PREFIX" != "$ipv6_prefix" ]]; then
                wg set ${interface} peer "$pubkey" allowed-ips "$ip1,$ip2,$IPV6_PREFIX::$host_hex/128"
              fi
            done
          '';
          serviceConfig = self.data.systemdHarden // {
            Type = "oneshot";
            AmbientCapabilities = [ "CAP_NET_ADMIN" ];
            CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
            RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
            PrivateNetwork = false;
            PrivateUsers = false;
          };
        };
      })
      cfg.interfaces);

    systemd.timers = builtins.listToAttrs (map
      (interface: {
        name = "${interface}-dynamic-ipv6";
        value = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnStartupSec = 60;
            OnUnitActiveSec = 300;
          };
        };
      })
      cfg.interfaces);
  };
}
