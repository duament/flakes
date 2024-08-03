{ ... }:
{
  presets.nogui.enable = true;
  # presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    fsIdentifier = "label";
  };

  networking.hostName = "ak";

  systemd.network.networks."10-ens18" = {
    name = "ens18";
    address = [ "2401:b60:5:4a91:bd28:4be0:ccd2:80da/64" "141.11.148.85/23" ];
    dns = [ "2606:4700:4700::1111" "1.1.1.1" "8.8.8.8" ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "141.11.148.1";
        GatewayOnLink = true;
      }
      {
        Gateway = "2401:b60:5::1";
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
