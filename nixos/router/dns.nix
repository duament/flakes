{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep mapAttrsToList;

  wg0Cfg = config.presets.wireguard.wg0;
  dnsPorts = [ 53 ] ++ mapAttrsToList (_: p: p.dnsPort) wg0Cfg.clientPeers;

  # TODO reload
  updateDnsScript =
    reload:
    pkgs.writeShellScript "update-adguardhome-upstream" ''
      set -eu -o pipefail
      DNS=$(cat /run/dns/* 2>/dev/null || true)
      DNS_WITH_SPACE=$(echo "$DNS" | paste -sd' ')
      if [[ ! -z "$DNS" ]]; then
        echo "Setting DNS: $DNS_WITH_SPACE"
        sed -i -E '1s|/\][^/]*$|/\]'"$DNS_WITH_SPACE"'|' /var/lib/AdGuardHome/upstream
        ${lib.optionalString reload "systemctl restart adguardhome"}
      fi
    '';
in
{

  options.router.dnsEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
  };

  config = {

    networking.nftables.tables."nixos-fw".content = ''
      set dns_enabled_ifs {
        type ifname
        flags interval
        elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') config.router.dnsEnabledIfs)} }
      }
    '';
    networking.firewall = {
      extraInputRules = ''
        iifname @dns_enabled_ifs meta l4proto { tcp, udp } th dport { ${concatStringsSep ", " (map toString dnsPorts)} } accept
      '';
    };

    presets.adguardhome = {
      enable = true;
    };

    systemd.tmpfiles.rules = [
      "d /run/dns 777 - - -"
    ];

    systemd.services.adguardhome.serviceConfig.ExecStartPre = lib.mkAfter "+${updateDnsScript false}";

    systemd.services.reload-adguardhome = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${updateDnsScript true}
      '';
    };

    systemd.paths.reload-adguardhome = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = [
        "/run/dns/networkd"
        "/run/dns/ppp"
      ];
    };

  };

}
