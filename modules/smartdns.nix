{ lib, config, inputs, ... }:
with lib;
let
  chinaListRaw = (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/accelerated-domains.china.conf") + (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/apple.china.conf");
  chinaListReplaced = builtins.replaceStrings [ "server=" "114.114.114.114" ] [ "" "china" ] chinaListRaw;
  chinaList = builtins.filter (line: line != "") (lib.splitString "\n" chinaListReplaced);
in {
  options = {
    services.smartdns.chinaDns = mkOption {
      type = types.listOf types.str;
      default = [ "223.5.5.5" "119.29.29.29" ];
    };

    services.smartdns.nonChinaDns = mkOption {
      type = types.listOf types.str;
      default = [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  config = lib.mkIf config.services.smartdns.enable {
    services.smartdns = {
      settings = {
        response-mode = "fastest-response";
        nameserver = chinaList;
        server = (map (i: "${i} -group china -exclude-default-group") config.services.smartdns.chinaDns) ++ config.services.smartdns.nonChinaDns;
      };
    };
  };
}
