{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStrings
    listToAttrs
    mapAttrsToList
    ;

  cfg = config.presets.wireguard.wg0;
  clientPeerNames = attrNames cfg.clientPeers;

in
{

  config = {

    router.dnsPorts = mapAttrsToList (_: p: p.dnsPort) cfg.clientPeers;

    networking.nftables.tables.dnsmasq = {
      family = "inet";
      content = ''
        ${concatStrings (
          map (h: ''
            set ${h} {
              type cgroupsv2
            }
          '') clientPeerNames
        )}

        chain do-mark {
          fib daddr type local accept
          ${concatStrings (
            map (h: ''
              socket cgroupv2 level 2 @${h} meta l4proto { tcp, udp } th dport 53 mark 0 mark set ${
                toString cfg.clientPeers.${h}.table
              }
            '') clientPeerNames
          )}
        }

        chain out {
          type route hook output priority -500;
          goto do-mark
        }
      '';
    };

    systemd.services = listToAttrs (
      map (h: {
        name = "dnsmasq-wg-${h}";
        value = {
          description = "Dnsmasq DNS for wg-${h}";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = self.data.systemdHarden // {
            Type = "simple";
            ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k -C ${pkgs.writeText "dnsmasq-wg-${h}.conf" ''
              port=${toString cfg.clientPeers.${h}.dnsPort}
              listen-address=::
              listen-address=0.0.0.0
              interface=lo
              interface=v1-lan
              interface=xfrm0
              interface=wg-router
              no-resolv
              server=2606:4700:4700::1111
              server=2001:4860:4860::8888
              server=1.1.1.1
              server=8.8.8.8
            ''}";
            Restart = "on-failure";
            PrivateNetwork = false;
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
            ];
            NFTSet = "cgroup:inet:dnsmasq:${h}";
          };
        };
      }) clientPeerNames
    );

  };

}
