{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkMerge
    types
    optional
    ;
  cfg = config.services.uu;

  fakeIptables = pkgs.writeShellScriptBin "iptables" ''
    echo "$@" | ${config.systemd.package}/bin/systemd-cat
  '';

  iptablesPackage = if cfg.useFakeIptables then fakeIptables else pkgs.iptables;
in
{
  options.services.uu = {
    enable = mkEnableOption "uu";

    useFakeIptables = mkEnableOption "Whether to use a fake iptables binary";

    vethName = mkOption {
      type = types.str;
      default = "ve-uu";
    };

    extraInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    vlan = {
      enable = mkEnableOption "Whether to create a vlan and add it to the LAN bridge";

      id = mkOption {
        type = types.int;
        default = 2;
      };

      name = mkOption {
        type = types.str;
        default = "gaming";
      };

      parentName = mkOption {
        type = types.str;
        default = "80-ethernet";
        description = "systemd.network name of the parent interface";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.uuplugin-uuid.sopsFile = ../secrets/uu.yaml;

    systemd.network = mkMerge [
      (mkIf cfg.vlan.enable {
        networks.${cfg.vlan.parentName}.vlan = [ cfg.vlan.name ];
        netdevs."50-${cfg.vlan.name}" = {
          netdevConfig = {
            Name = cfg.vlan.name;
            Kind = "vlan";
          };
          vlanConfig.Id = cfg.vlan.id;
        };
      })
      {
        networks."50-${cfg.vethName}" = {
          name = cfg.vethName;
          address = [ "10.6.7.1/24" ];
          networkConfig.IPMasquerade = "both";
        };
        networks."50-simns" = {
          name = "simns";
          linkConfig = {
            MACAddress = "CC:5B:31:2F:BE:AE";
          };
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
            RouteTable = 10;
          };
          routingPolicyRules = [
            {
              FirewallMark = 3;
              Table = 10;
            }
            {
              To = "10.6.8.0/24";
              Table = 10;
            }
          ];
        };
      }
    ];

    networking.firewall.extraForwardRules = ''
      iifname ${cfg.vethName} accept
    '';
    networking.nftables.markChinaIP.extraIPv4Rules = "ip saddr 10.6.7.0/24 accept";

    containers.uu = {
      autoStart = true;
      enableTun = true;
      ephemeral = true;
      privateNetwork = true;
      extraVeths.${cfg.vethName} = { };
      extraVeths.simns = { };
      interfaces = (optional cfg.vlan.enable cfg.vlan.name) ++ cfg.extraInterfaces;
      extraFlags = [ "--load-credential=uuplugin-uuid:uuplugin-uuid" ];
      config =
        { config, ... }:
        {
          _module.args = {
            inherit inputs self;
          };
          imports = [
            inputs.home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
            ./common.nix
            ./nftables/firewall.nix
            ./nogui.nix
            ./router.nix
          ];
          users.allowNoPasswordLogin = true;
          services.openssh.enable = false;
          boot.initrd.systemd.enable = false;
          networking = {
            hostName = "uu";
            useHostResolvConf = false;
            firewall = {
              extraInputRules = ''
                iifname ${config.presets.router.lan.bridge.name} meta l4proto { tcp, udp } th dport 10000-65535 accept comment "uu"
                iifname "tun*" accept comment "uu"
              '';
              extraForwardRules = ''
                iifname "tun*" oifname ${config.presets.router.lan.bridge.name} accept
                iifname ${config.presets.router.lan.bridge.name} oifname "tun*" accept
              '';
            };
            nftables.tables.uumark = {
              enable = cfg.useFakeIptables;
              family = "inet";
              content = ''
                chain pre {
                  type filter hook prerouting priority mangle;
                  iifname ${config.presets.router.lan.bridge.name} mark 0 mark set 0x163
                }
              '';
            };
          };
          presets.nogui.enable = true;
          presets.router = {
            enable = true;
            wan = {
              interface = cfg.vethName;
              type = "static";
              address = "10.6.7.2/24";
              gateway = "10.6.7.1";
              dns = "10.6.0.1";
            };
            lan = {
              interfaces = [ "simns" ] ++ cfg.extraInterfaces ++ optional cfg.vlan.enable cfg.vlan.name;
              address = "10.6.8.1/24";
              staticLeases = [
                {
                  # simns
                  MACAddress = "CC:5B:31:2F:BE:AE";
                  Address = "10.6.8.2";
                }
                {
                  # NS
                  MACAddress = "CC:5B:31:F5:96:3A";
                  Address = "10.6.8.3";
                }
                {
                  # NS-wire
                  MACAddress = "CC:5B:31:2F:D6:BD";
                  Address = "10.6.8.4";
                }
              ];
            };
          };
          systemd.services.uuplugin = {
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [
              iproute2
              nettools
              iptablesPackage
            ]; # ip ifconfig iptables
            serviceConfig = self.data.systemdHarden // {
              AmbientCapabilities = [
                "CAP_NET_ADMIN"
                "CAP_NET_RAW"
              ];
              CapabilityBoundingSet = [
                "CAP_NET_ADMIN"
                "CAP_NET_RAW"
              ];
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
                "${pkgs.coreutils}/bin/ln -nsf \${CREDENTIALS_DIRECTORY}/uuplugin-uuid %S/%N/.uuplugin_uuid"
              ];
              ExecStart = "${pkgs.uuplugin}/bin/uuplugin ${pkgs.uuplugin}/share/uuplugin/uu.conf";
            };
          };
        };
    };
    systemd.services."container@uu".serviceConfig.LoadCredential =
      "uuplugin-uuid:${config.sops.secrets.uuplugin-uuid.path}";
  };
}
