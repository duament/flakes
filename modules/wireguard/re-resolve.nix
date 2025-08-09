{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with lib;
let
  cfg = config.presets.wireguard.reResolve;

  interfaces = attrNames cfg;

  interfaceOptions =
    { ... }:
    {
      options = {
        address = mkOption {
          type = types.str;
        };

        pubkey = mkOption {
          type = types.str;
        };

        mark = mkOption {
          type = types.int;
          default = 1;
        };
      };
    };
in
{
  options = {
    presets.wireguard.reResolve = mkOption {
      type = types.attrsOf (types.submodule interfaceOptions);
      default = { };
    };
  };

  config = {

    systemd.services = mapAttrs' (interface: option: {
      name = "${interface}-re-resolve";
      value = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [
          pkgs.wireguard-tools
          pkgs.gawk
          pkgs.curl
          pkgs.jq
        ];
        script = ''
          set -o pipefail
          ENDPOINT=$(wg show ${interface} endpoints | grep ${option.pubkey} | awk '{print $2}')
          IP_IN_USE=''${ENDPOINT%%:*}
          PORT=''${ENDPOINT##*:}
          IP_RESOLVED=$(curl -s --retry 3 -m 60 --fail "https://223.5.5.5/resolve?name=t430-rvfg.duckdns.org&type=1" | jq -r '.Answer[0].data')
          if [[ "$IP_IN_USE" != "$IP_RESOLVED" ]]; then
            wg set ${interface} peer ${option.pubkey} endpoint "$IP_RESOLVED:$PORT"
          fi
        '';
        serviceConfig = self.data.systemdHarden // {
          Type = "oneshot";
          AmbientCapabilities = [ "CAP_NET_ADMIN" ];
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          PrivateNetwork = false;
          PrivateUsers = false;
        };
      };
    }) cfg;

    systemd.timers = builtins.listToAttrs (
      map (interface: {
        name = "${interface}-re-resolve";
        value = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnStartupSec = 600;
            OnUnitActiveSec = 600;
          };
        };
      }) interfaces
    );

    presets.bpf-mark = mapAttrs' (interface: option: {
      name = "${interface}-re-resolve";
      value = option.mark;
    }) cfg;

  };
}
