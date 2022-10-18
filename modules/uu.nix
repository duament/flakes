{ config, inputs, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.services.uu;

  vlan = "gaming";
  vethHost = "ve-uu";
  vethContainer = "ve-uu";
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
    systemd.network.networks."50-${vethHost}" = {
      name = vethHost;
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
          };
        }
      ];
    };

    networking.nftables.forwardAccept = ''
      iifname ${vethHost} accept
    '';
    networking.nftables.masquerade = [ "iifname ${vethHost}" ];

    containers.uu = {
      autoStart = true;
      enableTun = true;
      ephemeral = true;
      privateNetwork = true;
      extraVeths."ve-uu" = {};
      extraVeths.simns = {};
      interfaces = [ vlan ];
      config = { ... }: {
        imports = [
          #self.nixosModules.myModules
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ./common.nix
          ./nftables/firewall.nix
          ./nogui.nix
          ./router.nix
        ];
        networking.hostName = "uu";
        networking.useHostResolvConf = false;
        networking.nftables.forwardAccept = ''
          iifname "tun*" oifname ${config.presets.router.lan.bridge.name} accept
          iifname ${config.presets.router.lan.bridge.name} oifname "tun*" accept
        '';
        presets.nogui.enable = true;
        presets.router = {
          enable = true;
          wan = {
            interface = vethContainer;
            type = "static";
            address = "10.6.7.2/24";
            gateway = "10.6.7.1";
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
            ExecStartPre = "+/bin/sh -c 'touch /run/uuplugin.pid && chmod 777 /run/uuplugin.pid'";
            ExecStart = "${uu}/uuplugin ${uu}/uu.conf";
          };
        };
      };
    };
  };
}
