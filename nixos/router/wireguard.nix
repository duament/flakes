{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;

  nonCNMark = 2;
in
{

  options.router.wgEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
  };

  config = {

    router.wgEnabledIfs = [ "wg-*" ];
    router.wanEnabledIfs = [ "wg-*" ];
    router.dnsEnabledIfs = [ "wg-*" ];

    networking.nftables.tables."nixos-fw".content = ''
      set wg_enabled_ifs {
        type ifname
        flags interval
        elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') config.router.wgEnabledIfs)} }
      }
    '';
    networking.firewall.extraForwardRules = ''
      iifname @wg_enabled_ifs oifname { wg-*, warp } accept
      mark ${toString nonCNMark} oifname { wg-*, warp } accept
    '';

    presets.wireguard.wg0 = {
      enable = true;
      clientPeers = {
        ak.mark = 3;
        or2.mark = 3;
        sg.mark = 3;
        or1 = {
          mark = 3;
          mtu = 1400;
        };
        jp = {
          mark = 3;
          mtu = 1400;
        };
      };
    };

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
