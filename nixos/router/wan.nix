{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
in
{

  options.router = {

    wanIf = mkOption {
      type = types.str;
      default = "enp1s0";
    };

    wanEnabledIfs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      apply = v: concatStringsSep ", " v;
    };

  };

  config = {

    sops.secrets.pppoe = { };

    networking.firewall.extraForwardRules = ''
      iifname { ${config.router.wanEnabledIfs} } oifname ppp0 accept
    '';
    networking.nftables.masquerade = [ "oifname ppp0" ];

    systemd.services.pppd-isp.serviceConfig.LoadCredential = [
      "pppoe:${config.sops.secrets.pppoe.path}"
    ];
    services.pppd = {
      enable = true;
      peers.isp.config = ''
        plugin pppoe.so
        ${config.router.wanIf}
        persist
        noauth
        defaultroute
        defaultroute-metric 512
        file /run/credentials/pppd-isp.service/pppoe
      '';
    };

    systemd.network.networks = {
      "10-enp1s0" = {
        networkConfig = {
          IPv6AcceptRA = false;
        };
        DHCP = "ipv4";
        dhcpV4Config = {
          SendHostname = false;
          ClientIdentifier = "mac";
          UseDNS = false;
          UseNTP = false;
          UseSIP = false;
          UseDomains = false;
          UseGateway = false;
        };
      };
      "10-ppp" = {
        matchConfig.Type = "ppp";
        DHCP = "ipv6";
        networkConfig = {
          IPv6AcceptRA = true;
          KeepConfiguration = true;
        };
        dhcpV6Config.WithoutRA = "solicit";
      };
    };

  };

}
