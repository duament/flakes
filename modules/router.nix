{ lib, config, ... }:
with lib;
let
  cfg = config.networking.router;

  lanBr = "br-lan";
  lanAddr = "192.168.3.1";

  generateLan = name: {
    name = "50-${name}";
    value = {
      name = name;
      bridge = lanBr;
    };
  };
in {
  options = {
    networking.router.enable = mkOption {
      type = type.bool;
      default = false;
    };

    networking.router.wan = mkOption {
      type = types.str;
      default = "eth0";
    };

    networking.router.lan = mkOption {
      type = type.listOf types.str;
      default = [ "eth1" ];
    };
  };

  config = mkIf cfg.enable {
    services.resolved.extraConfig = "DNSStubListenerExtra=${lanAddr}";

    systemd.network.netdevs."50-${lanBr}".netdevConfig = {
      Name = lanBr;
      Kind = "bridge";
      MACAddress = "46:3F:3F:1D:3E:07";
    };

    systemd.network.networks = builtins.listToAttrs (map generateLan cfg.lan);

    systemd.network.networks."50-${lanBr}" = {
      name = lanBr;
      address = "${lanAddr}/24";
      networkConfig = {
        DHCPServer = true;
        IPForward = "ipv4";
        IPMasquerade = true;
      };
      dhcpServerConfig = { DNS = "_server_address"; };
      dhcpServerStaticLeases = [
        {
          # NS-wire
          dhcpServerStaticLeaseConfig = {
            MACAddress = "CC:5B:31:2F:D6:BD";
            Address = "192.168.3.2";
          };
        }
      ];
    };

    systemd.network.networks."50-${cfg.wan}" = {
      name = cfg.wan;
      DHCP = "yes";
    };

    networking.nftables.forwardAccept = concatStringsSep "\n" (map (i: "iifname ${i} oifname ${cfg.wan} accept;") cfg.lan);
  };
}
