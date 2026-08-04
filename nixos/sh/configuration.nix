{ ... }:
let
  mark = 65536;
in
{
  imports = [
    ./wgphantun.nix
  ];

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/sda";
  };
  presets.nginx.enable = true;
  presets.swanctl-gfw.enableServer = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/sh-bundle" = { };
    "pki/sh-pkcs8-key" = { };
  };

  networking.hostName = "sh";

  networking.firewall.checkReversePath = "loose";
  networking.nftables.tables.interface-mark = {
    family = "inet";
    content = ''
      chain inbound-mark {
        type filter hook prerouting priority mangle;
        iifname ens19 ct state new ct mark set ${toString mark}
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
      chain output-restore-mark {
        type route hook output priority mangle;
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
    '';
  };

  systemd.network.config.routeTables.sh = 2;
  systemd.network.networks = {
    "10-ens18" = {
      name = "ens18";
      address = [ "10.0.3.148/23" ];
      dns = [ "8.8.8.8" ];
      networkConfig.IPv6AcceptRA = false;
      routes = [
        {
          Gateway = "10.0.2.1";
          GatewayOnLink = true;
        }
        {
          Source = "::/0";
        }
      ];
    };
    "10-ens19" = {
      name = "ens19";
      address = [ "240e:96c:7100:1fe:185:68f3:195c:ff41/72" ];
      networkConfig.IPv6AcceptRA = false;
      routes = [
        {
          Gateway = "240e:96c:7100:1fe:100::1";
          GatewayOnLink = true;
          Table = "sh";
        }
      ];
      routingPolicyRules = [
        {
          FirewallMark = mark;
          Priority = 64;
          Family = "both";
          Table = "sh";
        }
      ];
    };
  };

  home-manager.users.rvfg = import ./home.nix;

}
