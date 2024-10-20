{ ... }:
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    fsIdentifier = "label";
  };

  networking.hostName = "sg";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [ "2a02:6ea0:d158::522:5d47/112" "167.253.159.33/25" ];
    dns = [ "2606:4700:4700::1111" "1.1.1.1" "8.8.8.8" ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "167.253.159.126";
        GatewayOnLink = true;
      }
      {
        Gateway = "2a02:6ea0:d158::1337";
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
