{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.wireguardReResolve;
in
{
  options = {
    services.wireguardReResolve.interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = {
    systemd.services = builtins.listToAttrs (map
      (interface:
        let
          wg = import ../lib/${interface}.nix;
        in
        {
          name = "${interface}-re-resolve";
          value = {
            after = [ "network-online.target" ];
            path = [ pkgs.wireguard-tools pkgs.gawk ];
            script = ''
              set -o pipefail
              ENDPOINT=$(wg show ${interface} endpoints | grep ${wg.pubkey} | awk '{print $2}')
              IP_IN_USE=''${ENDPOINT%%:*}
              PORT=''${ENDPOINT##*:}
              IP_RESOLVED=$(resolvectl query -4 --legend=no ${wg.host} | awk '{print $2}')
              if [[ "$IP_IN_USE" != "$IP_RESOLVED" ]]; then
                wg set ${interface} peer ${wg.pubkey} endpoint "$IP_RESOLVED:$PORT"
              fi
            '';
            serviceConfig = import ../lib/systemd-harden.nix // {
              Type = "oneshot";
              AmbientCapabilities = [ "CAP_NET_ADMIN" ];
              CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
              RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
              PrivateNetwork = false;
              PrivateUsers = false;
              DynamicUser = false;
            };
          };
        })
      cfg.interfaces);

    systemd.timers = builtins.listToAttrs (map
      (interface: {
        name = "${interface}-re-resolve";
        value = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnStartupSec = 600;
            OnUnitActiveSec = 600;
          };
        };
      })
      cfg.interfaces);
  };
}
