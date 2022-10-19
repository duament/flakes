{ lib, config, ... }:
with lib;
let
  cfg = config.presets.router;

  lanIP = builtins.dirOf cfg.lan.address;

  generateLan = name: {
    name = "50-${name}";
    value = {
      name = name;
      bridge = [ cfg.lan.bridge.name ];
    };
  };
in {
  options = {
    presets.router.enable = mkOption {
      type = types.bool;
      default = false;
    };

    presets.router.wan.interface = mkOption {
      type = types.str;
      default = "eth0";
    };

    presets.router.wan.type = mkOption {
      type = types.enum [ "static" "DHCP" ];
      default = "DHCP";
    };

    presets.router.wan.address = mkOption {
      type = types.str;
      default = "";
    };

    presets.router.wan.gateway = mkOption {
      type = types.str;
      default = "";
    };

    presets.router.wan.dns = mkOption {
      type = types.str;
      default = cfg.wan.gateway;
    };

    presets.router.lan.interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "eth0" ];
    };

    presets.router.lan.address = mkOption {
      type = types.str;
      default = "192.168.1.1/24";
    };

    presets.router.lan.bridge.name = mkOption {
      type = types.str;
      default = "br-lan";
    };

    presets.router.lan.bridge.MACAddress = mkOption {
      type = types.str;
      default = "46:3F:3F:1D:3E:07";
    };

    presets.router.lan.staticLeases = mkOption {
      type = types.listOf types.attrs;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    services.resolved.extraConfig = "DNSStubListenerExtra=${lanIP}";

    systemd.network.netdevs."50-${cfg.lan.bridge.name}".netdevConfig = {
      Name = cfg.lan.bridge.name;
      Kind = "bridge";
      MACAddress = cfg.lan.bridge.MACAddress;
    };

    systemd.network.networks = builtins.listToAttrs (map generateLan cfg.lan.interfaces)
    // {
      "50-${cfg.lan.bridge.name}" = {
        name = cfg.lan.bridge.name;
        address = [ cfg.lan.address ];
        networkConfig = {
          DHCPServer = true;
          IPForward = "ipv4";
          IPMasquerade = "ipv4";
        };
        dhcpServerConfig = { DNS = "_server_address"; };
        dhcpServerStaticLeases = cfg.lan.staticLeases;
      };

      "50-${cfg.wan.interface}" = if cfg.wan.type == "DHCP" then {
        name = cfg.wan.interface;
        DHCP = "yes";
      } else {
        name = cfg.wan.interface;
        address = [ cfg.wan.address ];
        gateway = [ cfg.wan.gateway ];
        dns = [ cfg.wan.dns ];
      };
    };

    networking.nftables.inputAccept = ''
      iifname ${cfg.lan.bridge.name} meta l4proto { tcp, udp } th dport 53 accept comment "DNS"
      iifname ${cfg.lan.bridge.name} meta nfproto ipv4 udp dport 67 accept comment "DHCP server"
    '';
    networking.nftables.forwardAccept = ''
      iifname ${cfg.lan.bridge.name} oifname ${cfg.wan.interface} accept
    '';
  };
}
