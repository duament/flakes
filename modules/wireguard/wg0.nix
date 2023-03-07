{ config, lib, self, ... }:
let
  cfg = config.presets.wireguard.wg0;
  wg0 = self.data.wg0;
  peer = wg0.peers.${config.networking.hostName};
  wgMark = 1;
  wgTable = 10;
  routeMark = 2;
in
{
  options = {
    presets.wireguard.wg0.enable = lib.mkEnableOption "";

    presets.wireguard.wg0.mtu = lib.mkOption {
      type = lib.types.int;
      default = 1420;
    };

    presets.wireguard.wg0.route = lib.mkOption {
      type = with lib.types; nullOr (enum [ "all" "cn" ]);
      default = null;
    };

    presets.wireguard.wg0.routeBypass = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf (cfg.route == null) {
      allowedUDPPorts = [
        peer.endpointPort
      ];
    };

    networking.nftables = lib.mkIf (cfg.route == "cn") {
      masquerade = [ "oifname \"wg0\"" ];
      markChinaIP = {
        enable = true;
        mark = routeMark;
      };
    };

    systemd.network.netdevs."25-wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
        MTUBytes = toString cfg.mtu;
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      } // (if cfg.route == null then {
        ListenPort = peer.endpointPort;
      } else {
        FirewallMark = wgMark;
        RouteTable = wgTable;
      });
      wireguardPeers = [{
        wireguardPeerConfig = {
          AllowedIPs = [ "0.0.0.0/0" "::/0" ];
          PublicKey = wg0.pubkey;
        } // (if cfg.route == null then { } else {
          Endpoint = wg0.endpoint;
          PersistentKeepalive = 25;
        });
      }];
    };

    systemd.network.networks."25-wg0" = {
      name = "wg0";
      address = [ "${peer.ipv4}/24" "${peer.ipv6}/120" ];
    } // (if cfg.route == null then { } else {
      dns = [ wg0.gateway6 ];
      domains = [ "~." ];
      networkConfig = { DNSDefaultRoute = "yes"; };
      routingPolicyRules = map
        (ip:
          {
            routingPolicyRuleConfig = {
              To = ip;
              Priority = 9;
            };
          }
        )
        cfg.routeBypass ++ (if cfg.route == "all" then [
        {
          routingPolicyRuleConfig = {
            Family = "both";
            FirewallMark = wgMark;
            InvertRule = "yes";
            Table = wgTable;
            Priority = 10;
          };
        }
      ] else [
        {
          routingPolicyRuleConfig = {
            Family = "both";
            FirewallMark = wgMark;
            Priority = 9;
          };
        }
        {
          routingPolicyRuleConfig = {
            Family = "both";
            FirewallMark = routeMark;
            Table = wgTable;
            Priority = 10;
          };
        }
      ]);
    });

    presets.wireguard.reResolve = lib.mkIf (cfg.route != null) {
      interfaces = [ "wg0" ];
    };

    presets.bpf-mark = lib.mkIf (cfg.route != null) {
      wg0-re-resolve = wgMark;
    };
  };
}
