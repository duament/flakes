{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
in
{

  options.router.dnsEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
    apply = v: concatStringsSep ", " v;
  };

  config = {

    networking.firewall = {
      extraInputRules = ''
        iifname { ${config.router.dnsEnabledIfs} } meta l4proto { tcp, udp } th dport 53 accept
      '';
    };

    # TODO
    presets.adguardhome = {
      enable = true;
      chinaDns = [ "223.5.5.5" ];
    };

  };

}
