{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.presets.duckdns;
in
{
  options.presets.duckdns = {
    enable = mkEnableOption "";

    domain = mkOption {
      type = types.str;
    };

    interface = mkOption {
      type = types.str;
    };

    tokenFile = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.duckdns = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = self.data.systemdHarden // {
        Type = "oneshot";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        PrivateNetwork = false;
        LoadCredential = "token:${cfg.tokenFile}";
      };
      path = with pkgs; [
        curl
        iproute2
        jq
      ];
      script = ''
        TOKEN=$(systemd-creds cat token)
        IPV6=$(ip -j -6 a show dev ${cfg.interface} scope global | jq -r '[.[0].addr_info[] | select(.local[:2] != "fc" and .local[:2] != "fd" and .local != null)][0].local')
        if [[ ! $IPV6 ]]; then
          >&2 echo "Cannot get IPv6 addresses"
          exit
        fi
        curl -s --retry 3 -m 60 "https://www.duckdns.org/update?domains=${cfg.domain}&token=$TOKEN&verbose=true&ipv6=$IPV6"
      '';
    };

    systemd.timers.duckdns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnStartupSec = 60;
        OnUnitActiveSec = 300;
      };
    };

  };
}
