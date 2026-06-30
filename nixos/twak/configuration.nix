{ ... }:
{
  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/sda";
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  networking.hostName = "twak";

  systemd.network.networks."10-ens18" = {
    name = "ens18";
    address = [
      "2407:cdc0:f004:ad20:5da5:6dab:cb83:70a3/64"
      "83.147.12.126/24"
    ];
    dns = [
      "1.1.1.1"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2407:cdc0:f004::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "83.147.12.1";
        GatewayOnLink = true;
      }
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
