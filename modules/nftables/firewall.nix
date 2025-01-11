{ lib, config, ... }:
with lib;
let
  cfg = config.networking.nftables;

  markOffset = 65536;
in
{
  options = {

    networking.nftables.masquerade = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "oifname \"extern*\"" ];
    };

    networking.nftables.mssClamping = mkOption {
      type = types.bool;
      default = false;
    };

    # TODO RPDB, route table
    networking.nftables.inboundInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

  };

  config = mkIf cfg.enable {

    networking.nftables.tables.misc = {
      family = "inet";
      content = ''
        ${optionalString (length cfg.masquerade != 0) ''
          chain masq {
            type nat hook postrouting priority srcnat;
            ${concatStringsSep " masquerade\n" cfg.masquerade} masquerade
          }
        ''}
        ${optionalString cfg.mssClamping ''
          chain mss-clamping {
            type filter hook postrouting priority mangle;
            tcp flags syn / syn,fin,rst tcp option maxseg size set rt mtu
          }
        ''}
        ${optionalString (length cfg.inboundInterfaces != 0) ''
          chain inbound-mark {
            type filter hook prerouting priority mangle;
            ct state new ct mark set iifname map { ${
              concatStringsSep ", " (imap0 (n: name: ''"${name}" : ${markOffset + n}'') cfg.inboundInterfaces)
            } }
          }
        ''}
        ${optionalString (length cfg.inboundInterfaces != 0) ''
          chain output-restore-mark {
            type route hook output priority mangle;
            ct direction reply ct mark ${markOffset}-${markOffset + (length cfg.inboundInterfaces) - 1} meta mark set ct mark
          }
        ''}
      '';
    };

  };
}
