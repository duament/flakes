{ config, inputs, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.uu;

  vlan = "gaming";
  veth = "ve-uu";
in {
  options = {
    services.uu.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    systemd.network.networks."80-ethernet".vlan = [ vlan ];
    systemd.network.netdevs."50-${vlan}" = {
      netdevConfig = { Name = vlan; Kind = "vlan"; };
      vlanConfig = { Id = 2; };
    };
    systemd.network.networks."50-${veth}" = {
      name = veth;
      address = [ "10.6.7.1/24" ];
    };
    systemd.network.networks."50-simns" = {
      name = "simns";
      linkConfig = { MACAddress = "CC:5B:31:2F:BE:AD"; };
      networkConfig = { IPv6AcceptRA = false; };
      DHCP = "ipv4";
      dhcpV4Config = {
        SendHostname = false;
        ClientIdentifier = "mac";
        UseDNS = false;
        UseNTP = false;
        UseSIP = false;
        UseDomains = false;
        RouteTable = 10;
      };
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            FirewallMark = 3;
            Table = 10;
          };
        }
        {
          routingPolicyRuleConfig = {
            To = "10.6.8.0/24";
            Table = 10;
          };
        }
      ];
    };

    networking.nftables.forwardAccept = ''
      iifname ${veth} accept
    '';
    networking.nftables.masquerade = [ "iifname ${veth}" ];

    containers.uu = {
      autoStart = true;
      enableTun = true;
      ephemeral = true;
      privateNetwork = true;
      extraVeths.${veth} = {};
      extraVeths.simns = {};
      interfaces = [ vlan ];
      config = { ... }: {
        imports = [
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ./common.nix
          ./nftables/firewall.nix
          ./nogui.nix
          ./router.nix
        ];
        networking.hostName = "uu";
        networking.useHostResolvConf = false;
        networking.nftables.inputAccept = ''
          iifname ${config.presets.router.lan.bridge.name} tcp dport 16363 accept comment "uu"
        '';
        networking.nftables.forwardAccept = ''
          iifname "tun*" oifname ${config.presets.router.lan.bridge.name} accept
          iifname ${config.presets.router.lan.bridge.name} oifname "tun*" accept
        '';
        presets.nogui.enable = true;
        presets.router = {
          enable = true;
          wan = {
            interface = veth;
            type = "static";
            address = "10.6.7.2/24";
            gateway = "10.6.7.1";
            dns = "192.168.2.1";
          };
          lan = {
            interfaces = [ vlan "simns" ];
            address = "10.6.8.1/24";
            staticLeases = [
              {
                dhcpServerStaticLeaseConfig = { # simns
                  MACAddress = "CC:5B:31:2F:BE:AD";
                  Address = "10.6.8.2";
                };
              }
              {
                dhcpServerStaticLeaseConfig = { # NS
                  MACAddress = "CC:5B:31:F5:96:3A";
                  Address = "10.6.8.3";
                };
              }
              {
                dhcpServerStaticLeaseConfig = { # NS-wire
                  MACAddress = "CC:5B:31:2F:D6:BD";
                  Address = "10.6.8.4";
                };
              }
            ];
          };
        };
        systemd.services.uuplugin = let
          uu = pkgs.fetchzip {
            url = "https://uu.gdl.netease.com/uuplugin/openwrt-x86_64/v3.0.4/uu.tar.gz";
            hash = "sha256-79EIuoFs9kVbO/WF5qohNXbHUQdtDkwBBNP6DPyaSBY=";
            stripRoot = false;
          };
        in {
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.iptables ];
          serviceConfig = import ../lib/systemd-harden.nix // {
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
            CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
            RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
            PrivateNetwork = false;
            PrivateUsers = false;
            DeviceAllow = [ "/dev/net/tun rwm" ];
            BindReadOnlyPaths = [ "/proc/net" "/proc/sys/kernel/random/uuid" ];
            PIDFile = "/run/uuplugin.pid";
            ExecStartPre = "+/bin/sh -c 'touch /run/uuplugin.pid && chmod 777 /run/uuplugin.pid'";
            ExecStart = "${uu}/uuplugin ${uu}/uu.conf";
          };
        };
      };
    };
    systemd.services."container@uu".environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
  };
}
