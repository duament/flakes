{ lib, config, ... }:
with lib;
let
  cfg = config.networking.nftables;
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
  };

  config = mkIf cfg.enable {
    networking.nftables.ruleset = ''
      table inet fw_ext {
        ${optionalString (length cfg.masquerade != 0) ''
        chain masq {
          type nat hook postrouting priority srcnat;
          ${concatStringsSep " masquerade\n" cfg.masquerade} masquerade
        }
        ''}

        ${optionalString cfg.mssClamping ''
        chain mss_clamping {
          type filter hook forward priority mangle;
          tcp flags syn tcp option maxseg size set rt mtu
        }
        ''}
      }
    '';
  };
}
