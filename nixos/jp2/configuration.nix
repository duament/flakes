{ ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.grub.enable = true;

  networking.hostName = "jp2";

  systemd.network.networks."10-ens17" = {
    name = "ens17";
    address = [
      "2602:fd6f:110::15d/64"
      "23.176.40.72/24"
    ];
    dns = [
      "2001:4860:4860::8888"
      "8.8.8.8"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2602:fd6f:110::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "23.176.40.1";
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
