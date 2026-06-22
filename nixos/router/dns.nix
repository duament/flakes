{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    ;

  dnsPortCN = 5300;

  updateDnsScript = pkgs.writeShellScript "update-run-dns-resolv-conf" ''
    set -eu -o pipefail
    umask 0022
    DNS=$(cat /run/dns/* 2>/dev/null || true)
    DNS_RESOLV_CONF=$(echo "$DNS" | sed 's/^/nameserver /')
    RESOLV_CONF_PATH="/run/dns/resolv.conf"
    if [[ ! -z "$DNS" ]]; then
      echo "Writing $RESOLV_CONF_PATH"
      echo "$DNS_RESOLV_CONF"
      TMP_FILE="$(mktemp -p /run/dns resolv.XXXXXXXXXX.conf)"
      chmod 644 "$TMP_FILE"
      echo "$DNS_RESOLV_CONF" > "$TMP_FILE"
      mv "$TMP_FILE" "$RESOLV_CONF_PATH"
    elif [[ ! -f "$RESOLV_CONF_PATH" ]]; then
      echo "Creating empty $RESOLV_CONF_PATH"
      touch "$RESOLV_CONF_PATH"
    fi
  '';
in
{

  options.router.dnsEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
  };

  options.router.dnsPorts = mkOption {
    type = types.listOf types.port;
    default = [ ];
  };

  config = {

    router.dnsPorts = [
      53
      dnsPortCN
    ];

    networking.nftables.tables."nixos-fw".content = ''
      set dns_enabled_ifs {
        type ifname
        flags interval
        elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') config.router.dnsEnabledIfs)} }
      }
    '';
    networking.firewall = {
      extraInputRules = ''
        iifname @dns_enabled_ifs meta l4proto { tcp, udp } th dport { ${concatStringsSep ", " (map toString config.router.dnsPorts)} } accept
      '';
    };

    presets.adguardhome = {
      enable = true;
      chinaDns = [ "[::1]:5300" ];
    };

    systemd.tmpfiles.rules = [
      "d /run/dns 777 - - -"
    ];

    systemd.services.reload-dns.serviceConfig = {
      Type = "oneshot";
      ExecStart = updateDnsScript;
    };

    systemd.paths.reload-dns = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = [
        "/run/dns/networkd"
        "/run/dns/ppp"
      ];
    };

    systemd.services.dnsmasq-cn = {
      description = "Dnsmasq DNS CN";
      after = [ "network.target" ];
      before = [ "adguardhome.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = self.data.systemdHarden // {
        Type = "simple";
        ExecStartPre = "+${updateDnsScript}";
        ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k -C ${pkgs.writeText "dnsmasq-cn.conf" ''
          port=${toString dnsPortCN}
          listen-address=::
          listen-address=0.0.0.0
          interface=lo
          interface=v1-lan
          interface=xfrm0
          interface=wg-router
          resolv-file=/run/dns/resolv.conf
        ''}";
        Restart = "on-failure";
        PrivateNetwork = false;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
      };
    };

  };

}
