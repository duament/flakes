{ lib, config, ... }:
let
  inherit (lib)
    # keep-sorted start
    concatMapStrings
    concatStringsSep
    imap0
    length
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    # keep-sorted end
    ;

  cfg = config.networking.nftables;

  markOffset = 65536;
in
{
  options = {

    networking.nftables.masqRules = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.masquerade = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "oifname \"extern*\"" ];
    };

    networking.nftables.mssClamping = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.allowContainerVeth = mkEnableOption { };

    # TODO RPDB, route table
    networking.nftables.inboundInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

  };

  config = mkIf cfg.enable {

    networking.nftables.masqRules = concatMapStrings (expr: ''
      ${expr} masquerade
    '') cfg.masquerade;

    networking.nftables.tables.misc = {
      family = "inet";
      content = ''
        chain masq {
          type nat hook postrouting priority srcnat;
          ${cfg.masqRules}
        }
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
            ct direction reply ct mark ${markOffset}-${
              markOffset + (length cfg.inboundInterfaces) - 1
            } meta mark set ct mark
          }
        ''}
      '';
    };

    networking.firewall.extraInputRules = ''
      meta iifkind veth udp dport {53, 67, 68} accept
    '';
    networking.firewall.extraForwardRules = ''
      meta iifkind veth accept
    '';

  };
}
