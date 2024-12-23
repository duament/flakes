{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;

  nonCNMark = 2;
  wg0 = self.data.wg0;
in
{

  options.router.wgEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
    apply = v: concatStringsSep ", " v;
  };

  config = {

    router.wgEnabledIfs = [ "wg-*" ];
    router.wanEnabledIfs = [ "wg-*" ];
    router.dnsEnabledIfs = [ "wg-*" ];

    networking.firewall.extraForwardRules = ''
      iifname { ${config.router.wgEnabledIfs} } oifname { wg-*, warp } accept
    '';

    presets.wireguard.wg0 = {
      enable = true;
      clientPeers = {
        ak.mark = 3;
        az = {
          mark = 3;
          mtu = 1360;
        };
        or2.mark = 3;
        sg.mark = 3;
      };
    };

    systemd.network.networks."25-wg-az".routingPolicyRules =
      let
        table = 100 + wg0.peers.az.id;
      in
      [
        #{
        #  FirewallMark = nonCNMark;
        #  Table = table;
        #  Priority = 20;
        #  Family = "ipv4";
        #}
      ];

    systemd.network.networks."25-warp".routingPolicyRules =
      let
        table = 20;
      in
      [
        {
          FirewallMark = nonCNMark;
          Table = table;
          Priority = 20;
          #Family = "ipv6";
          Family = "both";
        }
        {
          To = "2001:da8:215:4078:250:56ff:fe97:654d"; # byr.pt
          Table = table;
          Priority = 9;
        }
      ];

    systemd.network.networks."25-wg-ak".routingPolicyRules =
      let
        table = 100 + wg0.peers.ak.id;
      in
      [
        {
          To = "34.117.196.143"; # prod-ingress.nianticlabs.com
          Table = table;
          Priority = 9;
        }
      ];

    networking.nftables.markChinaIP = {
      enable = true;
      mark = nonCNMark;
    };

    networking.warp = {
      enable = true;
      endpointAddr = "162.159.192.1";
      mtu = 1412;
      mark = 3;
      routingId = "0xc4d73d";
      keyFile = config.sops.secrets.warp_key.path;
      address = [
        "172.16.0.2/32"
        "2606:4700:110:8e72:bc3b:128a:dee:118/128"
      ];
      table = 20;
    };
    presets.wireguard.keepAlive.interfaces = [ "warp" ];

  };

}
