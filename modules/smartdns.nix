{ lib, config, inputs, ... }:
let
  chinaListRaw = (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/accelerated-domains.china.conf") + (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/apple.china.conf");
  chinaListReplaced = builtins.replaceStrings [ "server=" "114.114.114.114" ] [ "" "china" ] chinaListRaw;
  chinaList = builtins.filter (line: line != "") (lib.splitString "\n" chinaListReplaced);
in {
  services.smartdns = lib.mkIf config.networking.nftables.tproxy.enable {
    enable = true;
    bindPort = config.networking.nftables.tproxy.dnsPort;
    settings = {
      response-mode = "fastest-response";
      server = [
        "223.5.5.5 -group china -exclude-default-group"
        "119.29.29.29 -group china -exclude-default-group"
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.googleDNS.port}"
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.cfDNS.port}"
      ];
      server-tcp = [
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.googleDNS.port}"
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.cfDNS.port}"
      ];
      nameserver = chinaList;
    };
  };
}
