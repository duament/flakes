{
  lib,
  config,
  inputs,
  pkgs,
  self,
  ...
}:
let
  cfg = config.presets.smartdns;

  chinaListRaw =
    (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/accelerated-domains.china.conf")
    + (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/apple.china.conf");
  chinaList = pkgs.writeText "china-list" (
    builtins.replaceStrings
      [
        "server="
        "114.114.114.114"
      ]
      [
        "nameserver "
        "china"
      ]
      chinaListRaw
  );

  confFile = pkgs.writeText "smartdns.conf" (
    with lib.generators;
    toKeyValue {
      mkKeyValue = mkKeyValueDefault {
        mkValueString = v: if lib.isBool v then if v then "yes" else "no" else mkValueStringDefault { } v;
      } " ";
      listsAsDuplicateKeys = true;
    } cfg.settings
  );
in
{
  options = {
    presets.smartdns.enable = lib.mkEnableOption "";

    presets.smartdns.bindPort = lib.mkOption {
      type = lib.types.port;
      default = 53;
    };

    presets.smartdns.settings = lib.mkOption {
      type =
        with lib.types;
        let
          atom = oneOf [
            str
            int
            bool
          ];
        in
        attrsOf (coercedTo atom lib.toList (listOf atom));
    };

    presets.smartdns.chinaDns = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "[2400:3200::1]"
        "[2402:4e00::]"
        "223.5.5.5"
        "119.29.29.29"
      ];
    };

    presets.smartdns.nonChinaDns = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "[2606:4700:4700::1111]"
        "[2001:4860:4860::8888]"
      ];
    };
  };

  config = lib.mkIf cfg.enable {

    services.resolved.enable = false;

    environment.etc."resolv.conf".text = ''
      nameserver ::1
    '';

    presets.smartdns.settings = {
      bind = [ "[::]:${toString cfg.bindPort}" ];
      response-mode = "fastest-response";
      conf-file = chinaList.outPath;
      server = (map (i: "${i} -group china -exclude-default-group") cfg.chinaDns) ++ cfg.nonChinaDns;
      cache-persist = true;
      cache-file = "/var/cache/smartdns/smartdns.cache";
      log-file = "/dev/null";
      log-console = true;
    };

    systemd.services.smartdns = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = self.data.systemdHarden // {
        ExecStart = "${pkgs.smartdns}/bin/smartdns -f -x -p - -c ${confFile}";
        CacheDirectory = "%N";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        PrivateNetwork = false;
        PrivateUsers = false;
        SocketBindAllow = cfg.bindPort;
      };
    };

  };
}
