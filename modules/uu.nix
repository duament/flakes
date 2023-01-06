{ config, inputs, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.uu;

  vlan = "gaming";
  veth = "ve-uu";
in
{
  options = {
    services.uu.enable = mkOption {
      type = types.bool;
      default = false;
    };

    services.uu.wanName = mkOption {
      type = types.str;
      default = "80-ethernet";
    };

    services.uu.uuidFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    systemd.network.networks.${cfg.wanName}.vlan = [ vlan ];
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
      linkConfig = { MACAddress = "CC:5B:31:2F:BE:AE"; };
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

    networking.firewall.extraForwardRules = ''
      iifname ${veth} accept
    '';
    networking.nftables.masquerade = [ "iifname ${veth}" ];

    containers.uu = {
      autoStart = true;
      enableTun = true;
      ephemeral = true;
      privateNetwork = true;
      extraVeths.${veth} = { };
      extraVeths.simns = { };
      interfaces = [ vlan ];
      extraFlags = [ "--load-credential=uuplugin-uuid:uuplugin-uuid" ];
      config = { config, ... }: {
        _module.args.inputs = inputs;
        imports = [
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ./common.nix
          ./nftables/firewall.nix
          ./nogui.nix
          ./router.nix
        ];
        boot.initrd.systemd.enable = false;
        networking.hostName = "uu";
        networking.useHostResolvConf = false;
        networking.firewall.extraInputRules = ''
          iifname ${config.presets.router.lan.bridge.name} meta l4proto { tcp, udp } th dport 10000-65535 accept comment "uu"
          iifname "tun*" accept comment "uu"
        '';
        networking.firewall.extraForwardRules = ''
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
                dhcpServerStaticLeaseConfig = {
                  # simns
                  MACAddress = "CC:5B:31:2F:BE:AE";
                  Address = "10.6.8.2";
                };
              }
              {
                dhcpServerStaticLeaseConfig = {
                  # NS
                  MACAddress = "CC:5B:31:F5:96:3A";
                  Address = "10.6.8.3";
                };
              }
              {
                dhcpServerStaticLeaseConfig = {
                  # NS-wire
                  MACAddress = "CC:5B:31:2F:D6:BD";
                  Address = "10.6.8.4";
                };
              }
            ];
          };
        };
        systemd.services.uuplugin =
          let
            uu = pkgs.fetchzip {
              url = "https://uu.gdl.netease.com/uuplugin/openwrt-x86_64/v3.6.2/uu.tar.gz";
              hash = "sha256-stqtBRucMJByO6dOB5qUDqVsKGMPMxQdGDlPWlUMjbM=";
              stripRoot = false;
            };
          in
          {
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [ iproute2 nettools iptables ]; # ip ifconfig iptables
            serviceConfig = import ../lib/systemd-harden.nix // {
              AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
              CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
              RestrictAddressFamilies = "";
              PrivateNetwork = false;
              PrivateUsers = false;
              PrivateDevices = false;
              ProcSubset = "all";
              DeviceAllow = [ "/dev/net/tun rwm" ];
              StateDirectory = "%N";
              WorkingDirectory = "%S/%N";
              LoadCredential = "uuplugin-uuid";
              PIDFile = "/run/uuplugin.pid";
              ExecStartPre = [
                "+/bin/sh -c 'touch /run/uuplugin.pid && chmod 777 /run/uuplugin.pid'"
                "${pkgs.coreutils}/bin/ln -s \${CREDENTIALS_DIRECTORY}/uuplugin-uuid %S/%N/.uuplugin_uuid"
              ];
              ExecStart = "${uu}/uuplugin ${uu}/uu.conf";
            };
          };
      };
    };
    systemd.services."container@uu".serviceConfig.LoadCredential = "uuplugin-uuid:${cfg.uuidFile}";
  };
}
