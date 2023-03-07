{ config, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.presets.wireguard.keepAlive;
in
{
  options = {
    presets.wireguard.keepAlive.interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = {
    systemd.services = builtins.listToAttrs (map
      (interface: {
        name = "${interface}-keep-alive";
        value = {
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          path = with pkgs; [ iproute2 wireguard-tools ];
          script = ''
            # https://gist.github.com/Menci/99a4f1fc4590f326205f6582b7255605
            # When there's a upstream NAT bug, WireGuard will never succeed senting packets
            # and will never receive any packets then. Detect sent increase while receive not change
            # Change a random port for it.
            function wg_keep_alive() {
                # Wait init
                sleep 10

                # Configuration
                CHECK_INTERVAL=3
                MAX_FAILED_CHECKS=3
                PORT_MIN=24000
                PORT_MAX=30000
                RESET_WAIT=10

                function wg_reset_port() {
                    while true; do
                        ((NEW_PORT=RANDOM%(PORT_MAX-PORT_MIN)+PORT_MIN))
                        if ! ss -ulpn | grep "$NEW_PORT" >/dev/null 2>/dev/null; then
                            break
                        fi
                    done
                    wg set "$1" listen-port "$NEW_PORT"
                }

                declare -A PEER_RECEIVED_BYTES
                declare -A PEER_SENT_BYTES
                declare -A PEER_FAILED_CHECKES
                while true; do
                    while read PEER RECEIVED_BYTES SENT_BYTES; do
                        if [[ "$PEER" == "" ]]; then
                            break
                        fi
                        if [[ "''${PEER_RECEIVED_BYTES["$PEER"]}" != "$RECEIVED_BYTES" ]]; then
                            PEER_RECEIVED_BYTES["$PEER"]="$RECEIVED_BYTES"
                            PEER_SENT_BYTES["$PEER"]="$SENT_BYTES"
                            PEER_FAILED_CHECKES["$PEER"]="0"
                        elif [[ "''${PEER_SENT_BYTES["$PEER"]}" != "$SENT_BYTES" ]]; then
                            FAILED_CHECKES="''${PEER_FAILED_CHECKES["$PEER"]}"
                            ((FAILED_CHECKES=FAILED_CHECKES+1))
                            echo wg_keep_alive: check failed! current fails = $FAILED_CHECKES
                            if [[ "$FAILED_CHECKES" == "$MAX_FAILED_CHECKS" ]]; then
                                wg_reset_port "$1"
                                sleep "$RESET_WAIT"
                                PEER_FAILED_CHECKES["$PEER"]=0
                                break
                            fi
                            PEER_FAILED_CHECKES["$PEER"]="$FAILED_CHECKES"
                        fi
                    done <<< "$(wg show "$1" transfer)"
                    sleep "$CHECK_INTERVAL"
                done
            }
            wg_keep_alive ${interface}
          '';
          serviceConfig = self.data.systemdHarden // {
            AmbientCapabilities = [ "CAP_NET_ADMIN" ];
            CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
            RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
            PrivateNetwork = false;
            PrivateUsers = false;
          };
        };
      })
      cfg.interfaces);
  };
}
