{ lib, config, inputs, pkgs, ... }:
with lib;
let
  chinaListRaw = (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/accelerated-domains.china.conf") + (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/apple.china.conf");
  chinaList = builtins.replaceStrings [ "server=" "114.114.114.114" ] [ "nameserver " "china" ] chinaListRaw;
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
    environment.etc."smartdns/china-list.conf".text = chinaList;

    services.smartdns = {
      settings = {
        response-mode = "fastest-response";
        conf-file = "china-list.conf";
        server = (map (i: "${i} -group china -exclude-default-group") config.services.smartdns.chinaDns) ++ config.services.smartdns.nonChinaDns;
        cache-persist = "yes";
        cache-file = "/var/cache/smartdns/smartdns.cache";
        log-file = "/dev/null";
      };
    };

    systemd.services.smartdns.serviceConfig = import ../lib/systemd-harden.nix // {
      Type = "simple";
      PIDFile = "";
      ExecStart = [ "" "${pkgs.smartdns}/bin/smartdns -f -x -p - $SMART_DNS_OPTS" ];
      CacheDirectory = "%N";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      PrivateNetwork = false;
      PrivateUsers = false;
      SocketBindAllow = config.services.smartdns.bindPort;
    };
  };
}
